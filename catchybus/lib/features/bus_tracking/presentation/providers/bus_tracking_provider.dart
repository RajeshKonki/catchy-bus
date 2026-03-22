import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/maps_service.dart';
import '../../domain/usecases/get_available_buses.dart';
import '../../domain/usecases/get_bus_route.dart';
import '../../domain/usecases/get_college_stops.dart';
import '../../domain/usecases/submit_support_query.dart';
import '../../domain/usecases/track_bus_location.dart';
import '../../domain/repositories/bus_tracking_repository.dart';
import '../../data/repositories/bus_tracking_repository_impl.dart';
import '../../data/datasources/bus_tracking_socket_data_source.dart';
import '../../domain/usecases/get_students_for_stop.dart';
import '../state/bus_tracking_state.dart';
import 'dart:async';
import '../../../../core/network/socket_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/bus_route.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BusTrackingNotifier extends StateNotifier<BusTrackingState> {
  final GetBusRoute getBusRoute;
  final TrackBusLocation trackBusLocation;
  final GetStudentsForStop getStudentsForStop;
  final MapsService mapsService;
  final BusTrackingRepository repository;
  StreamSubscription? _trackingSubscription;
  StreamSubscription? _tripStatusSubscription;
  bool _isFetchingRoadRoute = false;

  BusTrackingNotifier({
    required this.getBusRoute,
    required this.trackBusLocation,
    required this.getStudentsForStop,
    required this.mapsService,
    required this.repository,
  }) : super(const BusTrackingState.initial());

  Future<void> loadBusRoute(String busNumber) async {
    state = const BusTrackingState.loading();

    final result = await getBusRoute(GetBusRouteParams(busNumber: busNumber));

    result.fold((failure) => state = BusTrackingState.error(failure.message), (
      busRoute,
    ) async {
      state = BusTrackingState.loaded(busRoute);

      // If route path is missing or just basic points, fetch better road-mapped directions
      if ((busRoute.routePath.length <= busRoute.stops.length) &&
          busRoute.stops.length >= 2) {
        print(
          'DEBUG: [loadBusRoute] Path is basic, fetching road directions for ${busRoute.stops.length} stops...',
        );
        final origin = LatLng(
          busRoute.stops.first.latitude,
          busRoute.stops.first.longitude,
        );
        final destination = LatLng(
          busRoute.stops.last.latitude,
          busRoute.stops.last.longitude,
        );

        // Google Directions API limits waypoints (usually 23 for standard tier)
        final intermediateStops = busRoute.stops.sublist(
          1,
          busRoute.stops.length - 1,
        );
        final waypoints = intermediateStops
            .take(23)
            .map((s) => LatLng(s.latitude, s.longitude))
            .toList();

        if (intermediateStops.length > 23) {
          print(
            'DEBUG: Too many stops (${intermediateStops.length}), limited waypoints to first 23',
          );
        }

        final path = await mapsService.getDirections(
          origin: origin,
          destination: destination,
          waypoints: waypoints,
        );

        if (path.isNotEmpty) {
          print('DEBUG: Success! Received ${path.length} road points');
          final routePoints = path
              .map(
                (p) => RoutePoint(latitude: p.latitude, longitude: p.longitude),
              )
              .toList();
          state = BusTrackingState.loaded(
            busRoute.copyWith(routePath: routePoints),
          );
        } else {
          print('DEBUG: Failed to fetch road directions from API');
        }
      }
    });
  }

  void reset() {
    _trackingSubscription?.cancel();
    state = const BusTrackingState.initial();
  }

  void updateLocalPosition(BusPosition position) {
    state.maybeWhen(
      loaded: (currentRoute) {
        final stops = currentRoute.stops;
        if (stops.isEmpty) return;

        // --- Find which leg the bus is currently on ---
        // Strategy: the bus is on segment [i, i+1] if projecting the bus GPS
        // onto that segment gives the smallest perpendicular-ish combined distance.
        // Simpler reliable approach: find last stop within AT_STOP_RADIUS, then
        // determine progress to next stop.

        const double atStopRadiusM = 200.0; // within 200m = "at" a stop

        // 1. Calculate distance from bus to every stop (in meters)
        final List<double> distancesToStops = stops.map((stop) {
          return Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            stop.latitude,
            stop.longitude,
          );
        }).toList();

        // 2. Find the closest stop
        double minDist = distancesToStops[0];
        int closestIdx = 0;
        for (int i = 1; i < distancesToStops.length; i++) {
          if (distancesToStops[i] < minDist) {
            minDist = distancesToStops[i];
            closestIdx = i;
          }
        }

        int transitFromIdx = -1;
        double transitProg = -1.0;

        if (minDist <= atStopRadiusM) {
          // Bus is AT a stop
          transitFromIdx = -1;
          transitProg = -1.0;

          // Mark stops as passed/current/future
          final updatedStops = stops.asMap().entries.map((entry) {
            final i = entry.key;
            final stop = entry.value;
            if (i < closestIdx) return stop.copyWith(type: StopType.passedStop);
            if (i == closestIdx)
              return stop.copyWith(type: StopType.currentLocation);
            return stop.copyWith(type: StopType.futureStop);
          }).toList();

          state = BusTrackingState.loaded(
            currentRoute.copyWith(
              busPosition: position,
              currentLocation: stops[closestIdx].name,
              stops: updatedStops,
              transitProgress: transitProg,
              transitFromStopIndex: transitFromIdx,
            ),
          );
        } else {
          // Bus is IN TRANSIT between two stops.
          // Find the segment [from, from+1] by checking which pair has the smallest
          // sum of (dist to from) + (dist to from+1) vs the direct stop-to-stop dist.
          // Best segment = bus is closest to being ON that vector.

          int bestSegment = 0;
          double bestScore = double.infinity;
          for (int i = 0; i < stops.length - 1; i++) {
            final distToA = distancesToStops[i];
            final distToB = distancesToStops[i + 1];
            final distAtoB = Geolocator.distanceBetween(
              stops[i].latitude,
              stops[i].longitude,
              stops[i + 1].latitude,
              stops[i + 1].longitude,
            );
            // Score: how much "deviation" from segment A→B
            final score = (distToA + distToB) - distAtoB;
            if (score < bestScore) {
              bestScore = score;
              bestSegment = i;
            }
          }

          transitFromIdx = bestSegment;

          final distFromA = distancesToStops[bestSegment];
          final distAtoB = Geolocator.distanceBetween(
            stops[bestSegment].latitude,
            stops[bestSegment].longitude,
            stops[bestSegment + 1].latitude,
            stops[bestSegment + 1].longitude,
          );
          transitProg = distAtoB > 0
              ? (distFromA / distAtoB).clamp(0.05, 0.95)
              : 0.5;

          // Mark stops as passed/future relative to this segment
          final updatedStops = stops.asMap().entries.map((entry) {
            final i = entry.key;
            final stop = entry.value;
            if (i <= bestSegment)
              return stop.copyWith(type: StopType.passedStop);
            return stop.copyWith(type: StopType.futureStop);
          }).toList();

          state = BusTrackingState.loaded(
            currentRoute.copyWith(
              busPosition: position,
              currentLocation: 'In Transit (to ${stops[bestSegment + 1].name})',
              stops: updatedStops,
              transitProgress: transitProg,
              transitFromStopIndex: transitFromIdx,
            ),
          );
        }
      },
      orElse: () {},
    );
  }

  Future<void> startTracking(String busNumber) async {
    _trackingSubscription?.cancel();
    _tripStatusSubscription?.cancel();

    // Only set to loading if we don't already have some data, to avoid UI flicker
    state.maybeWhen(
      loaded: (_) {},
      orElse: () => state = const BusTrackingState.loading(),
    );

    // Subscribe to real-time trip status changes from the server
    // This keeps isTripActive in sync across driver and student views
    _tripStatusSubscription = repository.streamTripStatus(busNumber).listen((
      event,
    ) {
      final type = event['type'] as String?;
      final isTripActive = event['isTripActive'] as bool?;

      if (type == 'stop_skipped') {
        // Driver skipped a stop — update student route list instantly
        final skippedStop = event['stopName'] as String?;
        if (skippedStop != null) markStopSkipped(skippedStop);
        return;
      }

      if (isTripActive != null) {
        // Trip started / ended / cancelled — sync isTripActive
        state.maybeWhen(
          loaded: (busRoute) {
            state = BusTrackingState.loaded(
              busRoute.copyWith(isTripActive: isTripActive),
            );
          },
          orElse: () {},
        );
      }
    });

    _trackingSubscription = trackBusLocation(TrackBusLocationParams(busNumber: busNumber)).listen((
      result,
    ) {
      result.fold((failure) => state = BusTrackingState.error(failure.message), (
        busRoute,
      ) async {
        state.maybeWhen(
          loaded: (currentRoute) {
            // Merge position updates while preserving local stop and student state.
            // IMPORTANT: If we receive a bus_location_update, the server only emits
            // this inside an active trip block — so isTripActive MUST be true.
            state = BusTrackingState.loaded(
              currentRoute.copyWith(
                busPosition: busRoute.busPosition,
                currentLocation: busRoute.currentLocation,
                nextStop: busRoute.nextStop,
                isOnTime: busRoute.isOnTime,
                arrivalTimeMinutes: busRoute.arrivalTimeMinutes,
                stops: busRoute.stops,
                isTripActive: true, // receiving location = trip is active
              ),
            );
          },
          orElse: () => state = BusTrackingState.loaded(
            busRoute.copyWith(isTripActive: true),
          ),
        );

        // Compute precise transit position (between-stop progress)
        // so both driver AND student see the same bus icon placement
        updateLocalPosition(busRoute.busPosition);

        // Only fetch better road route once if it's missing or basic
        if (_isFetchingRoadRoute) return;

        final currentState = state;
        bool isMissingPath = false;
        currentState.maybeMap(
          loaded: (s) {
            final route = s.busRoute;
            // If path has very few points (less than stops or significantly small), it's likely just straight lines
            if (route.routePath.length <= route.stops.length + 5 &&
                route.stops.length >= 2) {
              isMissingPath = true;
            }
          },
          orElse: () {},
        );

        if (isMissingPath) {
          _isFetchingRoadRoute = true;
          print(
            'DEBUG: Tracking path is basic (${busRoute.routePath.length} pts), fetching road directions for ${busRoute.busNumber}...',
          );
          final origin = LatLng(
            busRoute.stops.first.latitude,
            busRoute.stops.first.longitude,
          );
          final destination = LatLng(
            busRoute.stops.last.latitude,
            busRoute.stops.last.longitude,
          );
          final waypoints = busRoute.stops
              .sublist(1, busRoute.stops.length - 1)
              .map((s) => LatLng(s.latitude, s.longitude))
              .toList();

          final path = await mapsService.getDirections(
            origin: origin,
            destination: destination,
            waypoints: waypoints,
          );

          if (path.isNotEmpty) {
            final routePoints = path
                .map(
                  (p) =>
                      RoutePoint(latitude: p.latitude, longitude: p.longitude),
                )
                .toList();
            state = BusTrackingState.loaded(
              busRoute.copyWith(routePath: routePoints),
            );
          }
          _isFetchingRoadRoute = false;
        }
      });
    });
  }

  Future<void> fetchStudentsForStop(
    String busNumber,
    String stopName, {
    void Function(List<Map<String, dynamic>> students)? onData,
  }) async {
    final result = await getStudentsForStop(
      GetStudentsForStopParams(busNumber: busNumber, stopName: stopName),
    );

    result.fold(
      (failure) {
        // Silently fail or log error
        print('Error fetching students: ${failure.message}');
      },
      (students) {
        // DO NOT update state with stop-specific students as it would overwrite the entire route manifest
        if (onData != null) {
          onData(students);
        }
      },
    );
  }

  void markStopReached(
    String stopName, {
    int? boardedCount,
    List<String>? boardedStudentIds,
  }) {
    state.maybeWhen(
      loaded: (busRoute) {
        final now = DateTime.now();
        final newStops = busRoute.stops.map((stop) {
          if (stop.name == stopName) {
            return stop.copyWith(
              type: StopType.passedStop,
              actualArrivalTime: now,
              boardedStudentCount: boardedCount,
            );
          }
          return stop;
        }).toList();

        final newStudents = busRoute.students.map((student) {
          if (boardedStudentIds != null &&
              boardedStudentIds.contains(student['id'])) {
            return {...student, 'isBoarded': true};
          }
          return student;
        }).toList();

        state = BusTrackingState.loaded(
          busRoute.copyWith(
            stops: newStops,
            currentLocation: stopName,
            students: newStudents,
          ),
        );
      },
      orElse: () {},
    );
  }

  void markStopSkipped(String stopName) {
    state.maybeWhen(
      loaded: (busRoute) {
        final newStops = busRoute.stops.map((stop) {
          if (stop.name == stopName) {
            return stop.copyWith(type: StopType.skippedStop);
          }
          return stop;
        }).toList();

        state = BusTrackingState.loaded(busRoute.copyWith(stops: newStops));
      },
      orElse: () {},
    );
  }

  void clearActiveTrip() {
    state.maybeWhen(
      loaded: (busRoute) {
        state = BusTrackingState.loaded(busRoute.copyWith(isTripActive: false));
      },
      orElse: () {
        state = const BusTrackingState.initial();
      },
    );
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    super.dispose();
  }
}

class BusListNotifier extends StateNotifier<BusListState> {
  final GetAvailableBuses getAvailableBuses;

  BusListNotifier({required this.getAvailableBuses})
    : super(const BusListState.initial());

  Future<void> loadAvailableBuses() async {
    state = const BusListState.loading();

    // 1. Get student current location
    Position? studentPosition;
    try {
      studentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Fallback or handle error - for now proceed with null or dummy if needed
    }

    // 2. Fetch buses
    final result = await getAvailableBuses(NoParams());

    result.fold((failure) => state = BusListState.error(failure.message), (
      buses,
    ) {
      if (studentPosition == null) {
        state = BusListState.loaded(buses);
        return;
      }

      // 3. Calculate distances and sort
      final busesWithDistance = buses.map((bus) {
        final distance =
            Geolocator.distanceBetween(
              studentPosition!.latitude,
              studentPosition.longitude,
              bus.latitude,
              bus.longitude,
            ) /
            1000; // to km
        return bus.copyWith(distance: distance);
      }).toList();

      busesWithDistance.sort((a, b) {
        if (a.distance == null || b.distance == null) return 0;
        return a.distance!.compareTo(b.distance!);
      });

      state = BusListState.loaded(busesWithDistance);
    });
  }
}

class CollegeStopsNotifier extends StateNotifier<CollegeStopsState> {
  final GetCollegeStops getCollegeStops;

  CollegeStopsNotifier({required this.getCollegeStops})
    : super(const CollegeStopsState.initial());

  Future<void> loadStops() async {
    state = const CollegeStopsState.loading();
    final result = await getCollegeStops(NoParams());
    result.fold(
      (failure) => state = CollegeStopsState.error(failure.message),
      (stops) => state = CollegeStopsState.loaded(stops),
    );
  }
}

class SupportNotifier extends StateNotifier<HelpDeskState> {
  final SubmitSupportQuery submitSupportQuery;

  SupportNotifier({required this.submitSupportQuery})
    : super(const HelpDeskState.initial());

  Future<void> sendQuery({
    required String query,
    required String subject,
    String? email,
  }) async {
    state = const HelpDeskState.loading();
    final result = await submitSupportQuery(
      SubmitSupportQueryParams(query: query, subject: subject, email: email),
    );
    result.fold(
      (failure) => state = HelpDeskState.error(failure.message),
      (_) => state = const HelpDeskState.success(),
    );
  }

  void reset() {
    state = const HelpDeskState.initial();
  }
}

// Providers
final busTrackingRepositoryProvider = Provider<BusTrackingRepository>((ref) {
  // Reuse the singleton SocketService so driver and student share one connection.
  final socketService = getIt<SocketService>();

  // Ensure socket is connected (no-op if already connected).
  // Token is read for the auth header but the socket connect() is a no-op
  // if already established by the driver page.
  final lastIdToken = ref.read(authProvider).lastIdToken;
  if (!socketService.isConnected) {
    socketService.connect(token: lastIdToken);
  }

  final remoteDataSource = BusTrackingSocketDataSourceImpl(
    socketService: socketService,
    dioClient: getIt<DioClient>(),
  );
  return BusTrackingRepositoryImpl(remoteDataSource: remoteDataSource);
});
final getBusRouteUseCaseProvider = Provider<GetBusRoute>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return GetBusRoute(repository);
});

final trackBusLocationUseCaseProvider = Provider<TrackBusLocation>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return TrackBusLocation(repository: repository);
});

final getAvailableBusesUseCaseProvider = Provider<GetAvailableBuses>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return GetAvailableBuses(repository);
});

final getCollegeStopsUseCaseProvider = Provider<GetCollegeStops>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return GetCollegeStops(repository);
});

final submitSupportQueryUseCaseProvider = Provider<SubmitSupportQuery>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return SubmitSupportQuery(repository);
});

final getStudentsForStopUseCaseProvider = Provider<GetStudentsForStop>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return GetStudentsForStop(repository);
});

final busTrackingProvider =
    StateNotifierProvider<BusTrackingNotifier, BusTrackingState>((ref) {
      final repository = ref.watch(busTrackingRepositoryProvider);
      return BusTrackingNotifier(
        getBusRoute: ref.watch(getBusRouteUseCaseProvider),
        trackBusLocation: ref.watch(trackBusLocationUseCaseProvider),
        getStudentsForStop: ref.watch(getStudentsForStopUseCaseProvider),
        mapsService: getIt<MapsService>(),
        repository: repository,
      );
    });

final busListProvider = StateNotifierProvider<BusListNotifier, BusListState>((
  ref,
) {
  return BusListNotifier(
    getAvailableBuses: ref.watch(getAvailableBusesUseCaseProvider),
  );
});

final collegeStopsProvider =
    StateNotifierProvider<CollegeStopsNotifier, CollegeStopsState>((ref) {
      return CollegeStopsNotifier(
        getCollegeStops: ref.watch(getCollegeStopsUseCaseProvider),
      );
    });

final supportProvider = StateNotifierProvider<SupportNotifier, HelpDeskState>((
  ref,
) {
  return SupportNotifier(
    submitSupportQuery: ref.watch(submitSupportQueryUseCaseProvider),
  );
});
