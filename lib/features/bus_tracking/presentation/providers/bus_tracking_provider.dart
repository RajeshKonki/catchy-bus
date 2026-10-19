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
import '../../domain/entities/trip_direction.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/di/injection.dart';
import 'package:catchybus/features/auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BusTrackingNotifier extends StateNotifier<BusTrackingState> {
  final Ref ref;
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
  TripDirection? _lockedDirection;
  bool _isReloading = false;
  TripDirection? _lastFetchedDirection;

  // ── Route Deviation Detection ────────────────────────────────────────────
  /// Threshold distance (in metres) from the route path before firing an alert.
  static const double _deviationThresholdM = 300.0;

  /// Hysteresis: once off-route, bus must come within this distance to be "back on route".
  static const double _onRouteHysteresisM = 200.0;

  /// Minimum gap between successive deviation notifications (prevents spam).
  static const Duration _deviationNotificationCooldown = Duration(minutes: 3);
  bool _isOffRoute = false;
  DateTime? _offRouteNotifiedAt;

  BusTrackingNotifier({
    required this.ref,
    required this.getBusRoute,
    required this.trackBusLocation,
    required this.getStudentsForStop,
    required this.getAllStudentsForBus,
    required this.mapsService,
    required this.repository,
    this.currentUser,
  }) : super(const BusTrackingState.initial());

  Future<void> loadBusRoute(
    String busNumber, {
    String? routeId,
    TripDirection? initialDirection,
  }) async {
    if (_isReloading) return;
    _isReloading = true;

    final bool isDifferentBus = state.maybeWhen(
      loaded: (r) => r.busNumber != busNumber,
      orElse: () => false,
    );

    final bool directionChanged = state.maybeWhen(
      loaded: (r) =>
          initialDirection != null && r.tripDirection != initialDirection,
      orElse: () => false,
    );

    final bool isNotLoaded = state.maybeWhen(
      loaded: (_) => false,
      orElse: () => true,
    );

    if (isNotLoaded || isDifferentBus || directionChanged) {
      state = const BusTrackingState.loading();
      _lastFetchedDirection = null;
    }

    final result = await getBusRoute(
      GetBusRouteParams(busNumber: busNumber, routeId: routeId),
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        _isReloading = false;
        if (mounted) {
          state = BusTrackingState.error(failure.message);
        }
      },
      (busRoute) async {
        try {
          // Fetch students in the background to avoid blocking the UI if socket is slow
          getAllStudentsForBus(busNumber).then((studentManifestResult) {
            if (!mounted) return;
            final List<Map<String, dynamic>> fetchedStudents =
                studentManifestResult.fold((_) => [], (s) => s);
            state.maybeWhen(
              loaded: (currentRoute) {
                final boardedIds = currentRoute.students
                    .where((s) => s['isBoarded'] == true)
                    .map((s) => s['id']?.toString())
                    .whereType<String>()
                    .toSet();

                final mappedStudents = fetchedStudents.map((s) {
                  final id = s['id']?.toString();
                  if (id != null && boardedIds.contains(id)) {
                    return {...s, 'isBoarded': true};
                  }
                  return s;
                }).toList();

                state = BusTrackingState.loaded(
                  currentRoute.copyWith(students: mappedStudents),
                );
              },
              orElse: () {},
            );
          });

          List<Map<String, dynamic>> existingStudents = [];
          state.maybeWhen(
            loaded: (s) {
              existingStudents = s.students;
            },
            orElse: () {},
          );

          final List<Map<String, dynamic>> students =
              existingStudents.isNotEmpty
              ? existingStudents
              : busRoute.students;

          // IMPORTANT: Preserve the current direction and trip status if we already set it
          // This prevents UI flickering while waiting for slow server REST refreshes.
          // BUT if the server indicates there is an active trip, we MUST trust the server's direction
          // UNLESS an explicit initialDirection was provided (e.g. from the socket or UI).
          // If the trip is not active, we ALWAYS show only the forward trip route unless explicitly overridden.
          final TripDirection currentDirection =
              initialDirection ??
              (busRoute.isTripActive
                  ? busRoute.tripDirection
                  : TripDirection.forward);

          // CRITICAL: Ensure stops and routePath always match the intended direction.
          // Since the API response data (stops and routePath) is always parsed in forward order,
          // we flip it if and only if the current direction does not match the parsed route's direction.
          final bool needsFlip = currentDirection != busRoute.tripDirection;

          BusPosition? existingPos;
          String? existingCurrentLoc;
          double? existingTransitProg;
          int? existingTransitIdx;

          state.maybeWhen(
            loaded: (s) {
              final bool directionChanged = s.tripDirection != currentDirection;
              final bool isNewTrip = busRoute.isTripActive && !s.isTripActive;
              if (!directionChanged && !isNewTrip) {
                existingPos = s.busPosition;
                existingCurrentLoc = s.currentLocation;
                existingTransitProg = s.transitProgress;
                existingTransitIdx = s.transitFromStopIndex;
              }
            },
            orElse: () {},
          );

          // Calculate the final merged route
          // IMPORTANT: Always use fresh server isTripActive on refresh — never preserve
          // a stale value, as that's what causes "On Time" to show when trip not started.
          final bool isRouteActive = busRoute.isTripActive;
          final mergedRoute = busRoute.copyWith(
            students: students,
            tripDirection: currentDirection,
            isTripActive: isRouteActive,
            busPosition: existingPos ?? busRoute.busPosition,
            currentLocation: isRouteActive
                ? (existingCurrentLoc ?? busRoute.currentLocation)
                : busRoute.currentLocation,
            transitProgress: isRouteActive
                ? (existingTransitProg ?? busRoute.transitProgress)
                : busRoute.transitProgress,
            transitFromStopIndex: isRouteActive
                ? (existingTransitIdx ?? busRoute.transitFromStopIndex)
                : busRoute.transitFromStopIndex,
            stops: (() {
              final baseStops = needsFlip
                  ? busRoute.stops.reversed.toList()
                  : busRoute.stops;
              return baseStops.asMap().entries.map((entry) {
                final i = entry.key;
                var stop = entry.value;
                if (needsFlip) {
                  if (i == 0) {
                    stop = stop.copyWith(type: StopType.passedStop);
                  } else if (i == baseStops.length - 1) {
                    stop = stop.copyWith(type: StopType.futureStop);
                  } else {
                    stop = stop.type == StopType.skippedStop
                        ? stop
                        : stop.copyWith(type: StopType.futureStop);
                  }
                }
                // Re-apply passed status based on preserved transit index
                if (isRouteActive &&
                    existingTransitIdx != null &&
                    existingTransitIdx! >= 0) {
                  if (i <= existingTransitIdx!) {
                    return stop.copyWith(type: StopType.passedStop);
                  } else if (i == existingTransitIdx! + 1) {
                    return stop.type == StopType.skippedStop
                        ? stop
                        : stop.copyWith(type: StopType.nextStop);
                  } else {
                    return stop.type == StopType.skippedStop
                        ? stop
                        : stop.copyWith(type: StopType.futureStop);
                  }
                }
                final isTripCompleted = busRoute.tripStatus == 'COMPLETED';
                if (isTripCompleted) {
                  if (i == baseStops.length - 1) {
                    return stop.copyWith(type: StopType.currentLocation);
                  }
                  return stop.copyWith(type: StopType.passedStop);
                }
                if (!isRouteActive) {
                  return stop.copyWith(type: StopType.futureStop);
                }
                return stop;
              }).toList();
            })(),
            routePath: needsFlip
                ? (busRoute.reverseRoutePath ??
                      busRoute.routePath.reversed.toList())
                : busRoute.routePath,
          );

          // ── GPS VALIDATION OF INITIAL STOP TYPES ─────────────────────────────
          // The server's passedStops list can be stale (e.g., a brief GPS jitter
          // caused a stop to be marked as passed before the bus physically reached it).
          // Before setting the initial state, validate the furthest passed stop
          // against the bus's last known GPS position from the server response.
          //
          // Key invariant: if the bus is physically CLOSER to a stop that is BEFORE
          // the furthest passed stop than to the furthest passed stop itself,
          // the bus cannot have actually reached that stop → roll back.
          BusRoute correctedRoute = mergedRoute;
          if (isRouteActive && existingTransitIdx == null) {
            // Only correct on initial load (existingTransitIdx == null means no live
            // GPS state preserved from memory yet).
            final List<RouteStop> loadedStops = mergedRoute.stops;
            final busLat = mergedRoute.busPosition.latitude;
            final busLng = mergedRoute.busPosition.longitude;

            // Find furthest passed stop
            int furthestPassedIdx = -1;
            for (int i = 0; i < loadedStops.length; i++) {
              if (loadedStops[i].type == StopType.passedStop) {
                furthestPassedIdx = i;
              }
            }

            if (furthestPassedIdx > 0) {
              // Compute straight-line distances from bus to the furthest passed
              // stop and to each stop before it.
              double distToFurthest = Geolocator.distanceBetween(
                busLat,
                busLng,
                loadedStops[furthestPassedIdx].latitude,
                loadedStops[furthestPassedIdx].longitude,
              );

              double minEarlierDist = double.infinity;
              int correctStopIdx = furthestPassedIdx;
              for (int i = 0; i < furthestPassedIdx; i++) {
                final d = Geolocator.distanceBetween(
                  busLat,
                  busLng,
                  loadedStops[i].latitude,
                  loadedStops[i].longitude,
                );
                if (d < minEarlierDist) {
                  minEarlierDist = d;
                  correctStopIdx = i;
                }
              }

              if (minEarlierDist < distToFurthest &&
                  correctStopIdx < furthestPassedIdx) {
                // Server had stale passedStop data — correct the stop types.
                print(
                  'DEBUG [loadBusRoute GPS validation] Stale passedStop corrected. '
                  'Furthest passed stop was index $furthestPassedIdx '
                  '(${distToFurthest.round()}m from bus), but bus is '
                  '${minEarlierDist.round()}m from stop[$correctStopIdx]. '
                  'Rolling back passed stops.',
                );
                final correctedStops = loadedStops.asMap().entries.map((e) {
                  final i = e.key;
                  final stop = e.value;
                  if (stop.type == StopType.skippedStop) return stop;
                  if (i < correctStopIdx)
                    return stop.copyWith(type: StopType.passedStop);
                  if (i == correctStopIdx)
                    return stop.copyWith(type: StopType.currentLocation);
                  return stop.copyWith(type: StopType.futureStop);
                }).toList();
                correctedRoute = mergedRoute.copyWith(stops: correctedStops);
              }
            }
          }

          state = BusTrackingState.loaded(correctedRoute);

          // Lock the direction to prevent socket updates from flipping the route
          _lockedDirection ??= currentDirection;

          // If route path is missing or just basic points, or if the direction changed,
          // fetch better road-mapped directions (two-way aware)
          final bool directionChanged =
              _lastFetchedDirection != currentDirection;
          if (((mergedRoute.routePath.length <= mergedRoute.stops.length) ||
                  directionChanged) &&
              mergedRoute.stops.length >= 2) {
            print(
              'DEBUG: [loadBusRoute] Path is basic or direction changed, fetching road directions for ${mergedRoute.stops.length} stops...',
            );

            // IMPORTANT: Always use the plain (forward) lat/lng for the routing API origin/destination.
            // The reverse lat/lng coordinates are on the other side of the road — using them
            // as routing endpoints forces U-turns on divided highways.
            // Reverse coords are ONLY used for map markers (showing the physical pickup side).
            final origin = LatLng(
              mergedRoute.stops.first.latitude,
              mergedRoute.stops.first.longitude,
            );
            final destination = LatLng(
              mergedRoute.stops.last.latitude,
              mergedRoute.stops.last.longitude,
            );
            // Include all intermediate stops as waypoints so the routing engine
            // traces the exact bus path instead of the fastest generic highway.
            final List<LatLng> waypoints = mergedRoute.stops
                .skip(1)
                .take(mergedRoute.stops.length > 2 ? mergedRoute.stops.length - 2 : 0)
                .map((s) => LatLng(s.latitude, s.longitude))
                .toList();
            final bool shouldFetchNewPath = true;

            List<LatLng> path = [];
            if (shouldFetchNewPath) {
              path = await mapsService.getDirections(
                origin: origin,
                destination: destination,
                waypoints: waypoints,
              );
            } else {
              print(
                'DEBUG: [loadBusRoute] Skipping new path fetch because no reverse coordinates exist. Using reversed forward path.',
              );
            }

            if (!mounted) return;

            if (path.isNotEmpty) {
              print('DEBUG: Success! Received ${path.length} road points');
              final routePoints = path
                  .map(
                    (p) => RoutePoint(
                      latitude: p.latitude,
                      longitude: p.longitude,
                    ),
                  )
                  .toList();

              // Use latest state as base to preserve everything
              state.maybeWhen(
                loaded: (current) {
                  _lastFetchedDirection = currentDirection;
                  state = BusTrackingState.loaded(
                    current.copyWith(routePath: routePoints),
                  );
                },
                orElse: () {},
              );
            } else {
              print('DEBUG: Failed to fetch road directions from API');
            }
          }
        } catch (e, stack) {
          print('ERROR in loadBusRoute: $e\n$stack');
          if (mounted &&
              state.maybeWhen(loading: () => true, orElse: () => false)) {
            state = BusTrackingState.error(e.toString());
          }
        } finally {
          _isReloading = false;
        }
      },
    );
  }

  void reset() {
    _trackingSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    _lockedDirection = null;
    _isReloading = false;
    _lastFetchedDirection = null;
    _isOffRoute = false;
    _offRouteNotifiedAt = null;
    state = const BusTrackingState.initial();
  }

  void updateLocalPosition(BusPosition position, {bool force = false, bool broadcast = true}) {
    state.maybeWhen(
      loaded: (currentRoute) {
        List<RouteStop> stops = currentRoute.stops.toList();
        final path = currentRoute.routePath;
        if (stops.isEmpty) return;
        // Ignore micro-movements (less than 5 meters) to prevent the "ratchet"
        // effect where GPS jitter makes the stationary bus crawl forward.
        final double distFromLast = Geolocator.distanceBetween(
          currentRoute.busPosition.latitude,
          currentRoute.busPosition.longitude,
          position.latitude,
          position.longitude,
        );
        if (!force && distFromLast < 1.0 && currentRoute.transitProgress > 0) {
          return;
        }

        // Start checking stops and segments from the last passed stop to prevent
        // The fast path based on transitFromStopIndex has been removed.
        // It bypassed the physical geofence state machine and caused stops to be marked as passed
        // prematurely based purely on sequence index, breaking the app for both drivers and students.
        // The robust physical state machine below will be used instead to ensure 100% accuracy.
        int startSegment = 0;
        for (int i = 0; i < stops.length; i++) {
          if (stops[i].type == StopType.passedStop ||
              stops[i].type == StopType.currentLocation) {
            startSegment = i;
          }
        }
        if (startSegment >= stops.length - 1) {
          startSegment = stops.length - 2;
        }

        // ── STEP 1: SNAP BUS POSITION TO ROAD (if path/stops available) ────
        BusPosition snappedPosition = position;
        int? closestPathSegmentIndex;
        final List<dynamic> points = path.isNotEmpty ? path : stops;
        if (points.isNotEmpty) {
          int pathStartIdx = 0;
          if (path.isNotEmpty &&
              startSegment > 0 &&
              startSegment < stops.length) {
            final startStop = stops[startSegment];
            double minStopDist = double.infinity;
            for (int i = 0; i < path.length; i++) {
              final dist = Geolocator.distanceBetween(
                startStop.latitude,
                startStop.longitude,
                path[i].latitude,
                path[i].longitude,
              );
              if (dist < minStopDist) {
                minStopDist = dist;
                pathStartIdx = i;
              }
            }
          }

          double minPathDist = double.infinity;
          RoutePoint? closestPoint;
          double segmentBearing = position.bearing;

          final int searchStart = path.isNotEmpty ? pathStartIdx : startSegment;
          for (int i = searchStart; i < points.length - 1; i++) {
            final p1 = points[i];
            final p2 = points[i + 1];

            final double p1Lat = p1.latitude;
            final double p1Lng = p1.longitude;
            final double p2Lat = p2.latitude;
            final double p2Lng = p2.longitude;

            // Find closest point on segment p1-p2
            final projected = _findClosestPointOnSegment(
              position.latitude,
              position.longitude,
              p1Lat,
              p1Lng,
              p2Lat,
              p2Lng,
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
              closestPathSegmentIndex = i;
              segmentBearing = Geolocator.bearingBetween(
                p1Lat,
                p1Lng,
                p2Lat,
                p2Lng,
              );
            }
          }

          // We calculate the closest point on the path to calculate progress,
          // but we DO NOT snap the visual bus position to it.
          // Snapping the bus position to a predefined route path (especially a fallback path)
          // forces the bus marker onto the wrong side of divided highways,
          // causing the driver's blue dot and the bus marker to diverge significantly.
          // snappedPosition = position; // Remains exactly the raw GPS location

          // ── ROUTE DEVIATION DETECTION ──────────────────────────────────────
          // Only fire if the trip is active and we have a real road path (not just stops).
          if (currentRoute.isTripActive &&
              path.isNotEmpty &&
              minPathDist.isFinite) {
            final String busNumber = currentRoute.busNumber;

            if (!_isOffRoute && minPathDist > _deviationThresholdM) {
              // Bus has just gone off-route
              _isOffRoute = true;
              final now = DateTime.now();
              final bool cooldownExpired =
                  _offRouteNotifiedAt == null ||
                  now.difference(_offRouteNotifiedAt!) >
                      _deviationNotificationCooldown;
              if (cooldownExpired) {
                _offRouteNotifiedAt = now;
                showRouteDeviationNotification(
                  busNumber: busNumber,
                  deviationMeters: minPathDist,
                );
              }
            } else if (_isOffRoute && minPathDist <= _onRouteHysteresisM) {
              // Bus has returned to the route
              _isOffRoute = false;
            }
          }
        } // end if (points.isNotEmpty)

        const double atStopRadiusM =
            10.0; // Reduced from 15.0 to prevent premature 'Reached' status

        // Precompute distances from bus to every stop (in meters)
        final List<double> distancesToStops = stops.map((stop) {
          double targetLat = stop.latitude;
          double targetLng = stop.longitude;
          if (currentRoute.isReverse &&
              stop.reverseLatitude != null &&
              stop.reverseLongitude != null) {
            targetLat = stop.reverseLatitude!;
            targetLng = stop.reverseLongitude!;
          }

          return Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            targetLat,
            targetLng,
          );
        }).toList();

        // ── STRICT PHYSICAL GEOFENCE STATE MACHINE ─────────────────────────
        // We do not force stops to be 'passed' based on their index.
        // A stop ONLY becomes 'currentLocation' when physically entered.
        // A stop ONLY becomes 'passedStop' when physically exited.
        // A stop becomes 'skippedStop' if we enter a later stop's geofence.

        List<RouteStop> newStops = List.from(stops);

        // Find the active target stop (first stop not passed or skipped)
        int targetIdx = -1;
        for (int i = 0; i < newStops.length; i++) {
          if (newStops[i].type != StopType.passedStop &&
              newStops[i].type != StopType.skippedStop) {
            targetIdx = i;
            break;
          }
        }

        bool isAtStop = false;
        int activeStopIdx = -1;

        if (targetIdx != -1) {
          if (newStops[targetIdx].type == StopType.currentLocation) {
            // Bus is currently AT a stop. Check if it left the geofence.
            // Use a slightly larger exit radius (60m) to prevent bouncing (hysteresis)
            if (distancesToStops[targetIdx] > 60.0) {
              newStops[targetIdx] = newStops[targetIdx].copyWith(
                type: StopType.passedStop,
              );
              if (targetIdx + 1 < newStops.length) {
                newStops[targetIdx + 1] = newStops[targetIdx + 1].copyWith(
                  type: StopType.nextStop,
                );
              }
              // Bus has left, so it is now IN TRANSIT to the next stop
              isAtStop = false;
            } else {
              isAtStop = true;
              activeStopIdx = targetIdx;
            }
          }

          if (!isAtStop) {
            // Bus is IN TRANSIT. Check if it enters the NEXT geofence.
            // We restrict the lookahead to exactly 1 stop (searchStart + 1)
            // to prevent overlapping routes from prematurely triggering future stops
            // and incorrectly marking them as 'Reached' or 'Passed'.
            int searchStart =
                (newStops[targetIdx].type == StopType.currentLocation)
                ? targetIdx + 1
                : targetIdx;
            int lookaheadEnd = searchStart + 1; // Strict sequential checking
            if (lookaheadEnd > newStops.length) lookaheadEnd = newStops.length;

            for (int i = searchStart; i < lookaheadEnd; i++) {
              if (distancesToStops[i] <= 40.0) {
                // 40m entry radius
                // Arrived at stop i!
                isAtStop = true;
                activeStopIdx = i;

                // Mark any skipped stops
                for (int skip = searchStart; skip < i; skip++) {
                  newStops[skip] = newStops[skip].copyWith(
                    type: StopType.skippedStop,
                  );
                }

                // Mark arrived stop
                newStops[i] = newStops[i].copyWith(
                  type: StopType.currentLocation,
                );
                break; // Stop checking
              }
            }
          }
        }

        // Ensure UI styling consistency for stops
        for (int i = 0; i < newStops.length; i++) {
          if (newStops[i].type == StopType.passedStop ||
              newStops[i].type == StopType.skippedStop ||
              newStops[i].type == StopType.currentLocation)
            continue;
          if (targetIdx != -1 && i == targetIdx && !isAtStop) {
            newStops[i] = newStops[i].copyWith(type: StopType.nextStop);
          } else {
            newStops[i] = newStops[i].copyWith(type: StopType.futureStop);
          }
        }

        if (isAtStop && activeStopIdx != -1) {
          // ── Bus is AT a stop ───────────────────────────────────────────────
          snappedPosition = position;

          state = BusTrackingState.loaded(
            currentRoute.copyWith(
              busPosition: snappedPosition,
              currentLocation: newStops[activeStopIdx].name,
              stops: newStops,
              transitProgress: -1.0,
              transitFromStopIndex: -1,
            ),
          );

          if (broadcast) {
            getIt<SocketService>().updateLocation(
              busId: currentRoute.busNumber,
              latitude: position.latitude,
              longitude: position.longitude,
              bearing: position.bearing,
              transitFromStopIndex: -1,
              transitProgress: -1.0,
            );
          }
        } else {
          // ── Bus is IN TRANSIT ─────────────────────────────────────────────
          // Calculate progress simply for the timeline UI animation
          int fromIdx = targetIdx > 0 ? targetIdx - 1 : -1;
          int toIdx = targetIdx != -1 ? targetIdx : newStops.length - 1;

          double getLat(RouteStop s) =>
              (currentRoute.isReverse && s.reverseLatitude != null)
              ? s.reverseLatitude!
              : s.latitude;
          double getLng(RouteStop s) =>
              (currentRoute.isReverse && s.reverseLongitude != null)
              ? s.reverseLongitude!
              : s.longitude;

          // Use a dummy start coordinate if fromIdx is -1 (e.g. 5km before the first stop)
          final ax = fromIdx >= 0
              ? getLng(stops[fromIdx])
              : getLng(stops[toIdx]) - 0.01;
          final ay = fromIdx >= 0
              ? getLat(stops[fromIdx])
              : getLat(stops[toIdx]) - 0.01;
          final bx = getLng(stops[toIdx]);
          final by = getLat(stops[toIdx]);
          final px = position.longitude;
          final py = position.latitude;

          // ── Robust Vector Projection for Timeline Progress ──
          // Project the bus position (P) onto the segment (A -> B).
          // This mathematically guarantees that driving past B does not cause progress to invert.
          final double dLatAB = by - ay;
          final double dLngAB = bx - ax;
          final double dLatAP = py - ay;
          final double dLngAP = px - ax;

          final double dotProduct = dLatAP * dLatAB + dLngAP * dLngAB;
          final double lengthSquared = dLatAB * dLatAB + dLngAB * dLngAB;

          double bestT = 0.5;
          if (lengthSquared > 0.00000001) {
            bestT = (dotProduct / lengthSquared).clamp(0.0, 1.0);
          }
          
          // Failsafe: Ensure timeline progress never visually moves backward during the same segment
          if (currentRoute.transitFromStopIndex == fromIdx && currentRoute.transitProgress > 0) {
            if (bestT < currentRoute.transitProgress) {
              bestT = currentRoute.transitProgress;
            }
          }

          final transitProg = bestT.clamp(0.02, 0.98);

          snappedPosition = position;

          state = BusTrackingState.loaded(
            currentRoute.copyWith(
              busPosition: snappedPosition,
              currentLocation: 'In Transit (to ${newStops[toIdx].name})',
              stops: newStops,
              transitProgress: transitProg,
              transitFromStopIndex: fromIdx,
            ),
          );

          if (broadcast) {
            getIt<SocketService>().updateLocation(
              busId: currentRoute.busNumber,
              latitude: position.latitude,
              longitude: position.longitude,
              bearing: position.bearing,
              transitFromStopIndex: fromIdx,
              transitProgress: transitProg,
            );
          }
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

  BusPosition _interpolatePosition(
    List<RouteStop> stops,
    List<RoutePoint> path,
    int segmentIdx,
    double progress,
    double fallbackBearing,
  ) {
    if (stops.isEmpty || segmentIdx < 0 || segmentIdx >= stops.length - 1) {
      return BusPosition(
        latitude: stops.isNotEmpty ? stops.last.latitude : 0.0,
        longitude: stops.isNotEmpty ? stops.last.longitude : 0.0,
        bearing: fallbackBearing,
      );
    }

    final stopA = stops[segmentIdx];
    final stopB = stops[segmentIdx + 1];

    if (path.isNotEmpty) {
      int idxA = -1;
      int idxB = -1;
      double minDistA = double.infinity;
      double minDistB = double.infinity;

      for (int i = 0; i < path.length; i++) {
        final distA = Geolocator.distanceBetween(
          stopA.latitude,
          stopA.longitude,
          path[i].latitude,
          path[i].longitude,
        );
        if (distA < minDistA) {
          minDistA = distA;
          idxA = i;
        }
        final distB = Geolocator.distanceBetween(
          stopB.latitude,
          stopB.longitude,
          path[i].latitude,
          path[i].longitude,
        );
        if (distB < minDistB) {
          minDistB = distB;
          idxB = i;
        }
      }

      if (idxA != -1 && idxB != -1 && idxA < idxB) {
        final List<double> segmentDists = [];
        double totalPathDist = 0.0;
        for (int i = idxA; i < idxB; i++) {
          final d = Geolocator.distanceBetween(
            path[i].latitude,
            path[i].longitude,
            path[i + 1].latitude,
            path[i + 1].longitude,
          );
          segmentDists.add(d);
          totalPathDist += d;
        }

        if (totalPathDist > 0) {
          final targetDist = progress * totalPathDist;
          double accumulated = 0.0;
          for (int i = idxA; i < idxB; i++) {
            final d = segmentDists[i - idxA];
            if (accumulated + d >= targetDist) {
              final double segmentProgress = (d > 0)
                  ? (targetDist - accumulated) / d
                  : 0.0;
              final pA = path[i];
              final pB = path[i + 1];
              final lat =
                  pA.latitude + (pB.latitude - pA.latitude) * segmentProgress;
              final lng =
                  pA.longitude +
                  (pB.longitude - pA.longitude) * segmentProgress;
              final bearing = Geolocator.bearingBetween(
                pA.latitude,
                pA.longitude,
                pB.latitude,
                pB.longitude,
              );
              return BusPosition(
                latitude: lat,
                longitude: lng,
                bearing: bearing,
              );
            }
            accumulated += d;
          }
        }
      }
    }

    final lat = stopA.latitude + (stopB.latitude - stopA.latitude) * progress;
    final lng =
        stopA.longitude + (stopB.longitude - stopA.longitude) * progress;
    final bearing = Geolocator.bearingBetween(
      stopA.latitude,
      stopA.longitude,
      stopB.latitude,
      stopB.longitude,
    );
    return BusPosition(latitude: lat, longitude: lng, bearing: bearing);
  }

  Future<void> startTracking(
    String busNumber, {
    TripDirection? initialDirection,
    String? routeId,
  }) async {
    _trackingSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    _lockedDirection = initialDirection;

    // Ensure the socket is connected with the current/fresh ID token on the student's end
    final token = ref.read(authProvider).lastIdToken;
    final socketService = getIt<SocketService>();
    if (!socketService.isConnected && token != null && token.isNotEmpty) {
      socketService.connect(token: token);
    }

    // Reset state to loading when switching buses or direction to prevent showing stale route/map data
    final bool isDifferentBus = state.maybeWhen(
      loaded: (r) => r.busNumber != busNumber,
      orElse: () => false,
    );
    final bool directionChanged = state.maybeWhen(
      loaded: (r) =>
          initialDirection != null && r.tripDirection != initialDirection,
      orElse: () => false,
    );
    if (isDifferentBus || directionChanged) {
      state = const BusTrackingState.loading();
      _lastFetchedDirection = null;
    }

    // Proactively update state with direction if provided.
    // NOTE: Do NOT set isTripActive=true here — that must only come from the server
    // (socket or REST). Setting it prematurely causes a false active→inactive transition
    // when the real response arrives with isTripActive=false, triggering a bogus
    // "Trip Completed" dialog on the student screen.
    if (initialDirection != null) {
      state.maybeWhen(
        loaded: (busRoute) {
          final TripDirection targetDirection = initialDirection;
          final TripDirection wasAlreadyReversed = busRoute.tripDirection;
          final bool needsFlip = targetDirection != wasAlreadyReversed;
          final bool resetTransit =
              needsFlip ||
              !busRoute.isTripActive ||
              busRoute.tripStatus == 'COMPLETED';

          state = BusTrackingState.loaded(
            busRoute.copyWith(
              tripDirection: targetDirection,
              // ⚠️ Do NOT override isTripActive or tripStatus here.
              // Wait for the server confirmation via socket/REST.
              transitFromStopIndex: resetTransit
                  ? -1
                  : busRoute.transitFromStopIndex,
              transitProgress: resetTransit ? -1.0 : busRoute.transitProgress,
              stops: (() {
                final baseStops = needsFlip
                    ? busRoute.stops.reversed.toList()
                    : busRoute.stops;
                if (resetTransit) {
                  return baseStops.asMap().entries.map((entry) {
                    if (entry.key == 0)
                      return entry.value.copyWith(
                        type: StopType.currentLocation,
                      );
                    return entry.value.copyWith(type: StopType.futureStop);
                  }).toList();
                }
                return baseStops;
              })(),
              routePath: needsFlip
                  ? (busRoute.reverseRoutePath ??
                        busRoute.routePath.reversed.toList())
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
        if (skippedStop != null) {
          markStopSkipped(skippedStop);
          showStopSkippedNotification(
            busNumber: busNumber,
            stopName: skippedStop,
            reason: event['reason'] as String?,
          );
        }
        return;
      }

      if (type == 'stop_reached') {
        final stopName = event['stopName'] as String?;
        if (stopName != null) {
          markStopReached(stopName);
        }
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
        final TripDirection? tripDirection = () {
          final dirStr = event['direction']?.toString().toUpperCase();
          if (dirStr == 'REVERSE' || dirStr == 'RETURN')
            return TripDirection.reverse;
          if (dirStr == 'FORWARD') return TripDirection.forward;
          final isRev =
              (event['isReverse'] as bool?) ?? (event['is_reverse'] as bool?);
          if (isRev != null)
            return isRev ? TripDirection.reverse : TripDirection.forward;
          return null;
        }();
        final status = event['status'] as String?;
        final reason = event['reason'] as String? ?? 'No reason provided';

        // If a new trip has started on the server, synchronize our direction lock with it
        if (isTripActive && tripDirection != null) {
          _lockedDirection = tripDirection;
        }

        // STRICTURE DIRECTION LOCK: If this event is for the opposite trip, ignore it completely.
        // But if a trip is active on the server, we should never ignore it.
        if (!isTripActive &&
            tripDirection != null &&
            _lockedDirection != null &&
            tripDirection != _lockedDirection) {
          return;
        }

        state.maybeWhen(
          loaded: (busRoute) {
            final bool directionChanged =
                tripDirection != null &&
                tripDirection != busRoute.tripDirection;
            final bool tripStarted =
                isTripActive && (!busRoute.isTripActive || directionChanged);
            final bool tripEnded = !isTripActive && busRoute.isTripActive;

            if (tripStarted) {
              // ── A new trip started for our specific direction ──
              final bool needsFlip =
                  tripDirection != null &&
                  tripDirection != busRoute.tripDirection;
              final baseStops = needsFlip
                  ? busRoute.stops.reversed.toList()
                  : busRoute.stops;
              final resetStops = baseStops.asMap().entries.map((entry) {
                final idx = entry.key;
                final stop = entry.value;
                if (idx == 0) {
                  return stop.copyWith(type: StopType.currentLocation);
                } else if (idx == baseStops.length - 1) {
                  return stop.copyWith(type: StopType.futureStop);
                } else {
                  return stop.type == StopType.skippedStop
                      ? stop
                      : stop.copyWith(type: StopType.futureStop);
                }
              }).toList();

              state = BusTrackingState.loaded(
                busRoute.copyWith(
                  isTripActive: true,
                  tripDirection: tripDirection ?? busRoute.tripDirection,
                  tripStatus: 'STARTED',
                  cancelReason: null,
                  transitFromStopIndex: -1,
                  transitProgress: -1.0,
                  stops: resetStops,
                  routePath: needsFlip
                      ? (busRoute.reverseRoutePath ??
                            busRoute.routePath.reversed.toList())
                      : busRoute.routePath,
                ),
              );

              // Restart location tracking for the new active trip
              Future.microtask(() {
                if (mounted) {
                  startTracking(
                    busNumber,
                    initialDirection: tripDirection,
                    routeId: routeId,
                  );
                }
              });

              showTripStartedNotification(
                busNumber: busNumber,
                isReverse: tripDirection == TripDirection.reverse,
              );
            } else if (tripEnded) {
              // ── Trip just ended ──
              stopTrackingOnly();

              if (status == 'CANCELLED') {
                showTripCancelledNotification(
                  busNumber: busNumber,
                  reason: reason,
                );
                state = BusTrackingState.loaded(
                  busRoute.copyWith(
                    isTripActive: false,
                    tripStatus: 'CANCELLED',
                    cancelReason: reason,
                    transitFromStopIndex: -1,
                    transitProgress: -1.0,
                  ),
                );
              } else {
                showTripCompletedNotification(
                  busNumber: busNumber,
                  isReverse: busRoute.isReverse,
                );
                state = BusTrackingState.loaded(
                  busRoute.copyWith(
                    isTripActive: false,
                    tripStatus: 'COMPLETED',
                    cancelReason: null,
                    transitFromStopIndex: -1,
                    transitProgress: -1.0,
                  ),
                );
              }
            }
          },
          orElse: () {
            if (isTripActive == true) {
              state = const BusTrackingState.loading();
              loadBusRoute(
                busNumber,
                routeId: routeId,
                initialDirection: tripDirection ?? TripDirection.forward,
              ).then((_) {
                if (!mounted) return;
                startTracking(
                  busNumber,
                  initialDirection: tripDirection ?? TripDirection.forward,
                  routeId: routeId,
                );
              });
            }
          },
        );
      }
    });

    _trackingSubscription =
        trackBusLocation(
          TrackBusLocationParams(
            busNumber: busNumber,
            initialDirection: _lockedDirection,
            routeId: routeId,
          ),
        ).listen((result) {
          result.fold((failure) => state = BusTrackingState.error(failure.message), (
            busRoute,
          ) async {
            // If the server indicates a trip is active, synchronize our direction lock with it
            if (busRoute.isTripActive &&
                _lockedDirection != busRoute.tripDirection) {
              _lockedDirection = busRoute.tripDirection;
            }

            // ── Direction Filter ────────────────────────────────────────────────
            // Ignore updates if they belong to an ACTIVE opposite trip.
            if (busRoute.isTripActive &&
                _lockedDirection != null &&
                busRoute.tripDirection != _lockedDirection) {
              return;
            }

            // If the trip is inactive, the server might send noisy isReverse flags.
            // Accept the GPS update to keep the bus moving on the map, but FORCE
            // the direction to stay locked so our UI doesn't flicker.
            if (!busRoute.isTripActive &&
                _lockedDirection != null &&
                busRoute.tripDirection != _lockedDirection) {
              busRoute = busRoute.copyWith(tripDirection: _lockedDirection);
            }
            // ── Step 0: Remember isNewTripOrDirectionChange ──────────────────────
            bool isNewTripOrDirectionChange = false;
            state.maybeWhen(
              loaded: (snap) {
                if (busRoute.tripDirection != snap.tripDirection ||
                    busRoute.isTripActive != snap.isTripActive) {
                  isNewTripOrDirectionChange = true;
                }
              },
              orElse: () {
                isNewTripOrDirectionChange = true;
              },
            );

            // ── Step 1: Merge server update stops/status first ───────────────────
            state.maybeWhen(
              loaded: (currentRoute) {
                final updatedIsTripActive = busRoute.isTripActive
                    ? true
                    : currentRoute.isTripActive;
                final bool directionChanged =
                    busRoute.tripDirection != currentRoute.tripDirection;
                final bool isNewTrip =
                    busRoute.isTripActive && !currentRoute.isTripActive;
                final bool isNewTripOrDirectionChangeLocal =
                    directionChanged || isNewTrip;

                final stopsToUse =
                    (currentRoute.stops.isEmpty ||
                        isNewTripOrDirectionChangeLocal)
                    ? busRoute.stops
                    : currentRoute.stops.asMap().entries.map((entry) {
                        final i = entry.key;
                        final stop = entry.value;
                        final serverStop = i < busRoute.stops.length
                            ? busRoute.stops[i]
                            : null;

                        StopType resolvedType = stop.type;
                        if (serverStop != null) {
                          if (serverStop.type == StopType.passedStop) {
                            resolvedType = StopType.passedStop;
                          } else if (serverStop.type == StopType.skippedStop) {
                            resolvedType = StopType.skippedStop;
                          } else if (serverStop.type ==
                              StopType.currentLocation) {
                            resolvedType = StopType.currentLocation;
                          }
                        }

                        return stop.copyWith(
                          estimatedArrivalMinutes:
                              serverStop?.estimatedArrivalMinutes,
                          type: resolvedType,
                        );
                      }).toList();

                final routePathToUse =
                    (currentRoute.routePath.isEmpty ||
                        isNewTripOrDirectionChangeLocal)
                    ? busRoute.routePath
                    : currentRoute.routePath;

                // ── Authority fast path: when driver sends index+progress, interpolate
                // the bus position ON the route polyline before writing state, so the map
                // marker never jumps to raw off-road GPS coordinates.
                final int? authIdx = busRoute.transitFromStopIndex;
                final double? authProg = busRoute.transitProgress;
                final bool hasAuthority =
                    authIdx != null && authProg != null && authIdx >= 0;
                final bool isDriver =
                    currentUser?.type?.toLowerCase() == 'driver';

                // We do NOT snap to the route if the user is a driver.
                // The driver needs to see their real, exact GPS location on the map.
                if (hasAuthority && !isDriver) {
                  final int fromIdx = authIdx.clamp(0, stopsToUse.length - 2);
                  final authorityStops = stopsToUse.asMap().entries.map((
                    entry,
                  ) {
                    final i = entry.key;
                    final stop = entry.value;
                    if (stop.type == StopType.passedStop ||
                        stop.type == StopType.skippedStop)
                      return stop;
                    if (i <= fromIdx)
                      return stop.copyWith(type: StopType.passedStop);
                    if (i == fromIdx + 1)
                      return stop.copyWith(type: StopType.nextStop);
                    return stop.copyWith(type: StopType.futureStop);
                  }).toList();

                  // Interpolate along the known route path — no raw GPS used for position
                  final interpolated = _interpolatePosition(
                    stopsToUse,
                    routePathToUse,
                    fromIdx,
                    authProg,
                    busRoute.busPosition.bearing,
                  );
                  final routeSnappedPos = busRoute.busPosition.copyWith(
                    latitude: interpolated.latitude,
                    longitude: interpolated.longitude,
                    bearing: interpolated.bearing,
                  );
                  final nextStopName =
                      stopsToUse[(fromIdx + 1).clamp(0, stopsToUse.length - 1)]
                          .name;

                  state = BusTrackingState.loaded(
                    currentRoute.copyWith(
                      busPosition: routeSnappedPos,
                      currentLocation: 'In Transit (to $nextStopName)',
                      nextStop: nextStopName,
                      isOnTime: busRoute.isOnTime,
                      arrivalTimeMinutes: busRoute.arrivalTimeMinutes,
                      stops: authorityStops,
                      routePath: routePathToUse,
                      isTripActive: updatedIsTripActive,
                      tripDirection: busRoute.tripDirection,
                      transitFromStopIndex: fromIdx,
                      transitProgress: authProg,
                    ),
                  );
                  // State is already fully correct — skip updateLocalPosition to avoid overwrite
                  return;
                }

                // Update local state with merged stops, preserving existing transit values temporarily
                state = BusTrackingState.loaded(
                  currentRoute.copyWith(
                    busPosition: busRoute.busPosition,
                    currentLocation: busRoute.currentLocation,
                    nextStop: busRoute.nextStop,
                    isOnTime: busRoute.isOnTime,
                    arrivalTimeMinutes: busRoute.arrivalTimeMinutes,
                    stops: stopsToUse,
                    routePath: routePathToUse,
                    isTripActive: updatedIsTripActive,
                    tripDirection: busRoute.tripDirection,
                  ),
                );

                // Compute snapped bus position and updated progress using the newly merged stops
                updateLocalPosition(busRoute.busPosition, force: true, broadcast: false);
              },
              orElse: () {
                state = BusTrackingState.loaded(busRoute);
                updateLocalPosition(busRoute.busPosition, force: true, broadcast: false);
              },
            );

            // Only fetch better road route once if it's missing or basic
            if (_isFetchingRoadRoute) return;

            final currentState = state;
            bool isMissingPath = false;
            LatLng? origin;
            LatLng? destination;
            List<LatLng>? waypoints;

            currentState.maybeMap(
              loaded: (s) {
                final route = s.busRoute;
                final bool directionChanged =
                    _lastFetchedDirection != route.tripDirection;
                if ((route.routePath.length <= route.stops.length + 5 ||
                        directionChanged) &&
                    route.stops.length >= 2) {
                  isMissingPath = true;
                  // Always use plain lat/lng for routing — reverse coords cause U-turns
                  origin = LatLng(
                    route.stops.first.latitude,
                    route.stops.first.longitude,
                  );
                  destination = LatLng(
                    route.stops.last.latitude,
                    route.stops.last.longitude,
                  );
                  // Include all intermediate stops as waypoints so the routing engine
                  // traces the exact bus path instead of the fastest generic highway.
                  waypoints = route.stops
                      .skip(1)
                      .take(route.stops.length > 2 ? route.stops.length - 2 : 0)
                      .map((s) => LatLng(s.latitude, s.longitude))
                      .toList();
                }
              },
              orElse: () {},
            );

            if (isMissingPath && origin != null && destination != null) {
              _isFetchingRoadRoute = true;
              print(
                'DEBUG: Tracking path is basic or direction changed, fetching directions for current direction...',
              );
              final path = await mapsService.getDirections(
                origin: origin!,
                destination: destination!,
                waypoints: waypoints,
              );

              if (path.isNotEmpty) {
                final routePoints = path
                    .map(
                      (p) => RoutePoint(
                        latitude: p.latitude,
                        longitude: p.longitude,
                      ),
                    )
                    .toList();
                state.maybeWhen(
                  loaded: (current) {
                    _lastFetchedDirection = current.tripDirection;
                    state = BusTrackingState.loaded(
                      current.copyWith(routePath: routePoints),
                    );
                  },
                  orElse: () {},
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
        final newStops = busRoute.stops.map((stop) {
          if (stop.name == stopName) {
            return stop.copyWith(boardedStudentCount: boardedCount);
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

        final updatedRoute = busRoute.copyWith(
          stops: newStops,
          students: newStudents,
        );

        state = BusTrackingState.loaded(updatedRoute);
      },
      orElse: () {},
    );
  }

  void updateDriverLocation(BusPosition pos) {
    state.maybeWhen(
      loaded: (busRoute) {
        // Use updateLocalPosition to automatically progress the bus along the route
        // and mark stops as passedStop based entirely on GPS position.
        updateLocalPosition(pos, force: true);
      },
      orElse: () {},
    );
  }

  void markStopSkipped(String stopName) {
    state.maybeWhen(
      loaded: (busRoute) {
        int skippedIdx = -1;
        final newStops = busRoute.stops.asMap().entries.map((entry) {
          final idx = entry.key;
          final stop = entry.value;
          if (stop.name == stopName) {
            skippedIdx = idx;
            return stop.copyWith(type: StopType.skippedStop);
          }
          return stop;
        }).toList();

        if (skippedIdx >= 0) {
          for (int i = 0; i < skippedIdx; i++) {
            if (newStops[i].type != StopType.passedStop &&
                newStops[i].type != StopType.skippedStop) {
              newStops[i] = newStops[i].copyWith(type: StopType.passedStop);
            }
          }
        }

        final updatedRoute = busRoute.copyWith(
          stops: newStops,
          transitFromStopIndex:
              (skippedIdx >= 0 && skippedIdx > busRoute.transitFromStopIndex)
              ? skippedIdx
              : busRoute.transitFromStopIndex,
          transitProgress:
              (skippedIdx >= 0 && skippedIdx > busRoute.transitFromStopIndex)
              ? 0.0
              : busRoute.transitProgress,
          // Do NOT override busPosition here either.
        );

        state = BusTrackingState.loaded(updatedRoute);
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

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        studentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      // Proceed without sorting if location fails
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

final tripEventStreamProvider = StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, String busNumber) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return repository.streamTripStatus(busNumber);
});
final getBusRouteUseCaseProvider = Provider<GetBusRoute>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return GetBusRoute(repository);
});

final trackBusLocationUseCaseProvider = Provider<TrackBusLocation>((ref) {
  final repository = ref.watch(busTrackingRepositoryProvider);
  return TrackBusLocation(repository);
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
        ref: ref,
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
