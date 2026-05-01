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
  bool? _lockedDirection;
  bool _isReloading = false;

  BusTrackingNotifier({
    required this.getBusRoute,
    required this.trackBusLocation,
    required this.getStudentsForStop,
    required this.getAllStudentsForBus,
    required this.mapsService,
    required this.repository,
    this.currentUser,
  }) : super(const BusTrackingState.initial());

  Future<void> loadBusRoute(String busNumber, {String? routeId}) async {
    if (_isReloading) return;
    _isReloading = true;

    // Only show loading if we have NO data. If we already have a route,
    // keep it on screen while we refresh to prevent white-screen flickering.
    final bool isNotLoaded = state.maybeWhen(
      loaded: (_) => false,
      orElse: () => true,
    );

    if (isNotLoaded) {
      state = const BusTrackingState.loading();
    }

    final result = await getBusRoute(
      GetBusRouteParams(busNumber: busNumber, routeId: routeId),
    );
    if (!mounted) return;

    final studentManifestResult = await getAllStudentsForBus(busNumber);
    if (!mounted) return;

    result.fold((failure) {
      _isReloading = false;
      if (mounted) {
        state = BusTrackingState.error(failure.message);
      }
    }, (
      busRoute,
    ) async {
      final List<Map<String, dynamic>> students = studentManifestResult.fold(
        (_) => [],
        (s) => s,
      );

      // IMPORTANT: Preserve the current direction and trip status if we already set it
      // This prevents UI flickering while waiting for slow server REST refreshes.
      // Use the direction from the server result.
      final bool isReverseMode = busRoute.isReverse;

      // CRITICAL: Ensure stops and routePath always match the intended direction.
      // If we are in reverse mode but the data is in forward order, FLIP IT.
      // If we are in forward mode but the data is in reverse order, FLIP IT.
      final bool currentlyReversed = busRoute.isReverse;
      final bool needsFlip = isReverseMode != currentlyReversed;

      state = BusTrackingState.loaded(
        busRoute.copyWith(
          students: students,
          isReverse: isReverseMode,
          isTripActive: busRoute.isTripActive,
          stops: needsFlip ? busRoute.stops.reversed.toList() : busRoute.stops,
          routePath: needsFlip
              ? busRoute.routePath.reversed.toList()
              : busRoute.routePath,
        ),
      );

      // Lock the direction to prevent socket updates from flipping the route
      _lockedDirection ??= isReverseMode;

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

        if (!mounted) return;

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
      _isReloading = false;
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
        final path = currentRoute.routePath;
        if (stops.isEmpty) return;

        // ── STEP 0: JITTER FILTER ───────────────────────────────────────────
        // Ignore micro-movements (less than 5 meters) to prevent the "ratchet"
        // effect where GPS jitter makes the stationary bus crawl forward.
        final double distFromLast = Geolocator.distanceBetween(
          currentRoute.busPosition.latitude,
          currentRoute.busPosition.longitude,
          position.latitude,
          position.longitude,
        );
        if (distFromLast < 5.0 && currentRoute.transitProgress > 0) {
          return;
        }

        // ── STEP 1: SNAP BUS POSITION TO ROAD (if path available) ──────────
        BusPosition snappedPosition = position;
        if (path.isNotEmpty) {
          double minPathDist = double.infinity;
          RoutePoint? closestPoint;

          for (int i = 0; i < path.length - 1; i++) {
            final p1 = path[i];
            final p2 = path[i + 1];

            // Find closest point on segment p1-p2
            final projected = _findClosestPointOnSegment(
              position.latitude,
              position.longitude,
              p1.latitude,
              p1.longitude,
              p2.latitude,
              p2.longitude,
            );

            final dist = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              projected.latitude,
              projected.longitude,
            );

            if (dist < minPathDist) {
              minPathDist = dist;
              closestPoint = projected;
            }
          }

          if (closestPoint != null && minPathDist < 100) {
            // Only snap if within 100m of road
            snappedPosition = position.copyWith(
              latitude: closestPoint.latitude,
              longitude: closestPoint.longitude,
            );
          }
        }

        const double atStopRadiusM =
            200.0; // matched with server's 200m threshold

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
            // The list is always in travel order (reversed during load if it's a return trip),
            // so stops before the current index are always "passed".
            if (i < closestIdx) {
              return stop.type == StopType.skippedStop
                  ? stop
                  : stop.copyWith(type: StopType.passedStop);
            }
            if (i == closestIdx)
              return stop.copyWith(type: StopType.currentLocation);
            return stop.type == StopType.skippedStop
                ? stop
                : stop.copyWith(type: StopType.futureStop);
          }).toList();

          state = BusTrackingState.loaded(
            currentRoute.copyWith(
              busPosition: snappedPosition,
              currentLocation: stops[closestIdx].name,
              stops: updatedStops,
              transitProgress: -1.0,
              transitFromStopIndex: -1,
            ),
          );
        } else {
          // ── Bus is IN TRANSIT ─────────────────────────────────────────────
          // Retrieve previously confirmed segment for hysteresis.
          final int prevSegment = currentRoute.transitFromStopIndex;

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

            final distAP = Geolocator.distanceBetween(ay, ax, py, px);
            final distPB = Geolocator.distanceBetween(py, px, by, bx);
            final segmentLength = Geolocator.distanceBetween(ay, ax, by, bx);

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

          // ── HYSTERESIS: Only switch segments when the improvement is clear (>5m) ──
          // This prevents the bus icon from flickering between adjacent stops when
          // the GPS deviation scores are nearly equal near stop boundaries.
          if (prevSegment >= 0 &&
              prevSegment < stops.length - 1 &&
              bestSegment != prevSegment) {
            // Calculate deviation for the previously confirmed segment
            final ax = stops[prevSegment].longitude;
            final ay = stops[prevSegment].latitude;
            final bx = stops[prevSegment + 1].longitude;
            final by = stops[prevSegment + 1].latitude;
            final px = position.longitude;
            final py = position.latitude;
            final distAP = Geolocator.distanceBetween(ay, ax, py, px);
            final distPB = Geolocator.distanceBetween(py, px, by, bx);
            final segmentLength = Geolocator.distanceBetween(ay, ax, by, bx);
            final prevDeviation = (distAP + distPB) - segmentLength;

            // Only switch if the new segment is clearly better by more than 5 metres
            if ((prevDeviation - bestSegmentDist) < 5.0) {
              // Keep the previous segment; recompute t for it
              bestSegment = prevSegment;
              final dAP = Geolocator.distanceBetween(ay, ax, py, px);
              final dPB = Geolocator.distanceBetween(py, px, by, bx);
              bestT = (dAP + dPB > 0)
                  ? (dAP / (dAP + dPB)).clamp(0.0, 1.0)
                  : currentRoute.transitProgress.clamp(0.0, 1.0);
            }
          }

          final transitProg = bestT.clamp(0.02, 0.98);

          final updatedStops = stops.asMap().entries.map((entry) {
            final i = entry.key;
            final stop = entry.value;
            // The list is always in travel order. If we are in segment i (between i and i+1),
            // then all stops up to index i are already passed.
            if (i <= bestSegment) {
              return stop.type == StopType.skippedStop
                  ? stop
                  : stop.copyWith(type: StopType.passedStop);
            }
            return stop.type == StopType.skippedStop
                ? stop
                : stop.copyWith(type: StopType.futureStop);
          }).toList();

          state = BusTrackingState.loaded(
            currentRoute.copyWith(
              busPosition: snappedPosition,
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

  RoutePoint _findClosestPointOnSegment(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    double dx = bx - ax;
    double dy = by - ay;
    if (dx == 0 && dy == 0) return RoutePoint(latitude: ax, longitude: ay);

    double t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);

    return RoutePoint(latitude: ax + t * dx, longitude: ay + t * dy);
  }

  Future<void> startTracking(String busNumber, {bool? initialIsReverse, String? routeId}) async {
    _trackingSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    _lockedDirection = initialIsReverse;

    // Proactively update state with direction if provided
    if (initialIsReverse != null) {
      state.maybeWhen(
        loaded: (busRoute) {
          final bool wasAlreadyReversed = busRoute.isReverse;
          final bool needsFlip = initialIsReverse != wasAlreadyReversed;

          state = BusTrackingState.loaded(
            busRoute.copyWith(
              isReverse: initialIsReverse,
              stops: needsFlip
                  ? busRoute.stops.reversed.toList()
                  : busRoute.stops,
              routePath: needsFlip
                  ? busRoute.routePath.reversed.toList()
                  : busRoute.routePath,
            ),
          );
        },
        orElse: () {},
      );
    }

    // Subscribe to real-time trip status changes from the server
    // This keeps isTripActive in sync across driver and student views
    _tripStatusSubscription = repository.streamTripStatus(busNumber).listen((
      event,
    ) {
      final type = event['type'] as String?;
      final isTripActive = event['isTripActive'] as bool?;

      if (type == 'stop_skipped') {
        final skippedStop = event['stopName'] as String?;
        if (skippedStop != null) markStopSkipped(skippedStop);
        return;
      }

      if (type == 'attendance_marked') {
        final studentId = event['studentId'] as String?;
        final studentName = event['studentName'] as String?;
        final stopName = event['pickupStop'] as String?;
        final busNo = event['busNumber'] as String?;

        if (currentUser != null &&
            (studentId == currentUser?.id ||
                (currentUser?.name == studentName))) {
          showAttendanceNotification(
            studentName: studentName ?? currentUser?.name ?? 'Student',
            busNumber: busNo ?? busNumber,
            stopName: stopName ?? 'your stop',
          );
        }
        return;
      }

      if (isTripActive != null) {
        final bool? isReverse =
            (event['isReverse'] as bool?) ??
            (event['is_reverse'] as bool?);

        // STRICTURE DIRECTION LOCK: If this event is for the opposite trip, ignore it completely.
        if (isReverse != null && _lockedDirection != null && isReverse != _lockedDirection) {
          return;
        }

        state.maybeWhen(
          loaded: (busRoute) {
            final bool tripStarted = isTripActive && !busRoute.isTripActive;
            final bool tripEnded = !isTripActive && busRoute.isTripActive;

            if (tripStarted) {
              // ── A new trip started for our specific direction ──
              state = BusTrackingState.loaded(
                busRoute.copyWith(isTripActive: true),
              );
            } else if (tripEnded) {
              // ── Trip just ended ──
              stopTrackingOnly();
              
              showTripCompletedNotification(
                busNumber: busNumber,
                isReverse: busRoute.isReverse,
              );

              state = BusTrackingState.loaded(
                busRoute.copyWith(isTripActive: false),
              );
            }
          },
          orElse: () {
            if (isTripActive == true) {
              state = const BusTrackingState.loading();
              loadBusRoute(busNumber, routeId: routeId).then((_) {
                if (!mounted) return;
                startTracking(busNumber, initialIsReverse: isReverse ?? false, routeId: routeId);
              });
            }
          },
        );
      }
    });

    _trackingSubscription = trackBusLocation(
      TrackBusLocationParams(
        busNumber: busNumber,
        initialIsReverse: _lockedDirection,
        routeId: routeId,
      ),
    ).listen((
      result,
    ) {
      result.fold((failure) => state = BusTrackingState.error(failure.message), (
        busRoute,
      ) async {
        // ── Direction Filter ────────────────────────────────────────────────
        // Ignore updates if they belong to an ACTIVE opposite trip.
        if (busRoute.isTripActive && _lockedDirection != null && busRoute.isReverse != _lockedDirection) {
          return;
        }

        // If the trip is inactive, the server might send noisy isReverse flags. 
        // Accept the GPS update to keep the bus moving on the map, but FORCE 
        // the direction to stay locked so our UI doesn't flicker.
        if (!busRoute.isTripActive && _lockedDirection != null && busRoute.isReverse != _lockedDirection) {
          busRoute = busRoute.copyWith(isReverse: _lockedDirection);
        }
        // ── Step 0: Remember current transit position BEFORE overwriting ─────
        // Needed to prevent backward snapping when server sends stale GPS.
        double prevTransitProg = -1.0;
        int prevTransitFromIdx = -1;
        state.maybeWhen(
          loaded: (snap) {
            prevTransitProg = snap.transitProgress;
            prevTransitFromIdx = snap.transitFromStopIndex;
          },
          orElse: () {},
        );

        // ── Step 1: Compute fine-grained GPS transit position ─────────────────
        updateLocalPosition(busRoute.busPosition);

        // ── Step 2: Capture the GPS-computed transit values ───────────────────
        double computedTransitProg = -1.0;
        int computedTransitFromIdx = -1;
        state.maybeWhen(
          loaded: (snapshot) {
            computedTransitProg = snapshot.transitProgress;
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
          // Forward means index increases (0 -> N)
          final bool goesBackward =
              computedTransitFromIdx < prevTransitFromIdx ||
              (computedTransitFromIdx == prevTransitFromIdx &&
                  computedTransitProg < prevTransitProg);

          if (goesBackward) {
            computedTransitProg = prevTransitProg;
            computedTransitFromIdx = prevTransitFromIdx;
          }
        }

        // ── Step 3: Merge server update, preserving forward transit values ────
        // IMPORTANT: Only use server stops on first load (when local state has none yet).
        // updateLocalPosition() exits early when stops are empty, so the first socket
        // update would leave stops permanently empty if we don't seed from the server.
        // After that, preserve GPS-computed stop types to avoid server-lag flickering.
        state.maybeWhen(
          loaded: (currentRoute) {
            final updatedIsTripActive = busRoute.isTripActive
                ? true
                : currentRoute.isTripActive;
            // ── Step 1: Resolve stops list ──────────────────────────────────────────
            // If the direction changed, we MUST use the new stops.
            final bool directionChanged =
                busRoute.isReverse != currentRoute.isReverse;
            final stopsToUse = (currentRoute.stops.isEmpty || directionChanged)
                ? busRoute.stops
                : currentRoute.stops;
            state = BusTrackingState.loaded(
              currentRoute.copyWith(
                busPosition: busRoute.busPosition,
                currentLocation: busRoute.currentLocation,
                nextStop: busRoute.nextStop,
                isOnTime: busRoute.isOnTime,
                arrivalTimeMinutes: busRoute.arrivalTimeMinutes,
                stops: stopsToUse,
                isTripActive: updatedIsTripActive,
                isReverse: busRoute.isReverse,
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
            {...studentData, 'isBoarded': true},
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

  void stopTracking() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
    _tripStatusSubscription?.cancel();
    _tripStatusSubscription = null;
  }

  void stopTrackingOnly() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  void clearActiveTrip() {
    state = const BusTrackingState.initial();
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        studentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      }
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

final getAllStudentsForBusUseCaseProvider = Provider<GetAllStudentsForBus>((
  ref,
) {
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
