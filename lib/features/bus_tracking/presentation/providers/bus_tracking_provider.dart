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
import '../../domain/usecases/get_all_students_for_bus.dart';
import '../state/bus_tracking_state.dart';
import 'dart:async';
import 'package:catchybus/core/services/notification_service.dart';
import 'package:catchybus/features/bus_tracking/domain/entities/bus_route.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/di/injection.dart';
import 'package:catchybus/features/auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BusTrackingNotifier extends StateNotifier<BusTrackingState> {
  final GetBusRoute getBusRoute;
  final TrackBusLocation trackBusLocation;
  final GetStudentsForStop getStudentsForStop;
  final GetAllStudentsForBus getAllStudentsForBus;
  final MapsService mapsService;
  final BusTrackingRepository repository;
  final UserEntity? currentUser;
  StreamSubscription? _trackingSubscription;
  StreamSubscription? _tripStatusSubscription;
  bool _isFetchingRoadRoute = false;

  BusTrackingNotifier({
    required this.getBusRoute,
    required this.trackBusLocation,
    required this.getStudentsForStop,
    required this.getAllStudentsForBus,
    required this.mapsService,
    required this.repository,
    this.currentUser,
  }) : super(const BusTrackingState.initial());

  Future<void> loadBusRoute(String busNumber) async {
    state = const BusTrackingState.loading();

    final result = await getBusRoute(GetBusRouteParams(busNumber: busNumber));
    final studentManifestResult = await getAllStudentsForBus(busNumber);

    result.fold((failure) => state = BusTrackingState.error(failure.message), (
      busRoute,
    ) async {
      final List<Map<String, dynamic>> students = studentManifestResult.fold(
        (_) => [],
        (s) => s,
      );

      state = BusTrackingState.loaded(busRoute.copyWith(students: students));

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

        const double atStopRadiusM = 30.0; // only "at stop" within 30m

        // Precompute distances from bus to every stop (in meters)
        final List<double> distancesToStops = stops.map((stop) {
          return Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            stop.latitude,
            stop.longitude,
          );
        }).toList();

        // Find the closest stop
        double minDist = distancesToStops[0];
        int closestIdx = 0;
        for (int i = 1; i < distancesToStops.length; i++) {
          if (distancesToStops[i] < minDist) {
            minDist = distancesToStops[i];
            closestIdx = i;
          }
        }

        if (minDist <= atStopRadiusM) {
          // ── Bus is AT a stop ───────────────────────────────────────────────
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
              transitProgress: -1.0,
              transitFromStopIndex: -1,
            ),
          );
        } else {
          // ── Bus is IN TRANSIT ─────────────────────────────────────────────
          // Use perpendicular-projection scoring to find which segment
          // [stops[i] → stops[i+1]] the bus GPS point lies closest to.
          //
          // For each segment A→B we project the bus point P onto the line AB.
          // The projection parameter t ∈ [0,1] gives the fractional position.
          // We keep the segment whose clamped projection point is nearest to P.

          int bestSegment = 0;
          double bestSegmentDist = double.infinity;
          double bestT = 0.5;

          for (int i = 0; i < stops.length - 1; i++) {
            final ax = stops[i].longitude;
            final ay = stops[i].latitude;
            final bx = stops[i + 1].longitude;
            final by = stops[i + 1].latitude;
            final px = position.longitude;
            final py = position.latitude;

            // Use real-world Haversine distances for robust fractional progress
            // avoiding perpendicular projection errors on curved roads.
            final distAP = Geolocator.distanceBetween(ay, ax, py, px);
            final distPB = Geolocator.distanceBetween(py, px, by, bx);
            final segmentLength = Geolocator.distanceBetween(ay, ax, by, bx);

            // True deviation distance (triangle inequality difference)
            // Smaller deviation means the bus is closer to this segment
            final deviation = (distAP + distPB) - segmentLength;

            double t = 0.0;
            if (distAP + distPB > 0) {
              t = (distAP / (distAP + distPB)).clamp(0.0, 1.0);
            }

            if (deviation < bestSegmentDist) {
              bestSegmentDist = deviation;
              bestSegment = i;
              bestT = t;
            }
          }

          // Clamp progress away from exact 0 / 1 to avoid snapping to stop icons
          final transitProg = bestT.clamp(0.02, 0.98);

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
              transitFromStopIndex: bestSegment,
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

      if (type == 'attendance_marked') {
        final studentId = event['studentId'] as String?;
        final studentName = event['studentName'] as String?;
        final stopName = event['pickupStop'] as String?;
        final busNo = event['busNumber'] as String?;
        
        // CRITICAL FILTER: Only show notification to the student concerned
        if (currentUser != null && (studentId == currentUser?.id || (currentUser?.name == studentName))) {
          showAttendanceNotification(
            studentName: studentName ?? currentUser?.name ?? 'Student',
            busNumber: busNo ?? busNumber,
            stopName: stopName ?? 'your stop',
          );
        }
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
        // ── Step 0: Remember current transit position BEFORE overwriting ─────
        // Needed to prevent backward snapping when server sends stale GPS.
        double prevTransitProg   = -1.0;
        int    prevTransitFromIdx = -1;
        state.maybeWhen(
          loaded: (snap) {
            prevTransitProg   = snap.transitProgress;
            prevTransitFromIdx = snap.transitFromStopIndex;
          },
          orElse: () {},
        );

        // ── Step 1: Compute fine-grained GPS transit position ─────────────────
        updateLocalPosition(busRoute.busPosition);

        // ── Step 2: Capture the GPS-computed transit values ───────────────────
        double computedTransitProg   = -1.0;
        int    computedTransitFromIdx = -1;
        state.maybeWhen(
          loaded: (snapshot) {
            computedTransitProg   = snapshot.transitProgress;
            computedTransitFromIdx = snapshot.transitFromStopIndex;
          },
          orElse: () {},
        );

        // ── Step 2b: FORWARD-ONLY protection ─────────────────────────────────
        // If new GPS reading puts the bus BEHIND its current animated position
        // (earlier segment, or lower fraction on the same segment), keep the
        // previous higher value. Prevents static emulator GPS or server lag
        // from snapping the bus backward while the simulation moves it forward.
        if (prevTransitProg > 0 && prevTransitFromIdx >= 0) {
          final goesBackward =
              computedTransitFromIdx < prevTransitFromIdx ||
              (computedTransitFromIdx == prevTransitFromIdx &&
               computedTransitProg   >= 0 &&
               computedTransitProg   <  prevTransitProg);
          if (goesBackward) {
            computedTransitProg   = prevTransitProg;
            computedTransitFromIdx = prevTransitFromIdx;
          }
        }

        // ── Step 3: Merge server update, preserving forward transit values ────
        state.maybeWhen(
          loaded: (currentRoute) {
            final updatedIsTripActive = busRoute.isTripActive
                ? true
                : currentRoute.isTripActive;
            state = BusTrackingState.loaded(
              currentRoute.copyWith(
                busPosition: busRoute.busPosition,
                currentLocation: busRoute.currentLocation,
                nextStop: busRoute.nextStop,
                isOnTime: busRoute.isOnTime,
                arrivalTimeMinutes: busRoute.arrivalTimeMinutes,
                stops: busRoute.stops,
                isTripActive: updatedIsTripActive,
                transitProgress: computedTransitProg,
                transitFromStopIndex: computedTransitFromIdx,
              ),
            );
          },
          orElse: () => state = BusTrackingState.loaded(busRoute),
        );

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

  void markStudentAsBoarded(Map<String, dynamic> studentData) {
    state.maybeWhen(
      loaded: (busRoute) {
        final String studentId = studentData['id']?.toString() ?? '';
        bool exists = busRoute.students.any((s) => s['id'] == studentId);

        List<Map<String, dynamic>> newStudents;
        if (exists) {
          newStudents = busRoute.students.map((student) {
            if (student['id'] == studentId) {
              return {...student, 'isBoarded': true};
            }
            return student;
          }).toList();
        } else {
          // Add new student (e.g. from QR scan of student not in current manifest)
          newStudents = [
            ...busRoute.students,
            {...studentData, 'isBoarded': true}
          ];
        }

        state = BusTrackingState.loaded(
          busRoute.copyWith(students: newStudents),
        );
      },
      orElse: () {},
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

final getAllStudentsForBusUseCaseProvider = Provider<GetAllStudentsForBus>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return GetAllStudentsForBus(repository);
});

final busTrackingProvider =
    StateNotifierProvider<BusTrackingNotifier, BusTrackingState>((ref) {
      final repository = ref.watch(busTrackingRepositoryProvider);
      final authState = ref.watch(authProvider);
      
      return BusTrackingNotifier(
        getBusRoute: ref.watch(getBusRouteUseCaseProvider),
        trackBusLocation: ref.watch(trackBusLocationUseCaseProvider),
        getStudentsForStop: ref.watch(getStudentsForStopUseCaseProvider),
        getAllStudentsForBus: ref.watch(getAllStudentsForBusUseCaseProvider),
        mapsService: getIt<MapsService>(),
        repository: repository,
        currentUser: authState.user,
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
