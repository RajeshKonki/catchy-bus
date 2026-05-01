import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/bus_route.dart';
import '../../domain/repositories/bus_tracking_repository.dart';
import '../datasources/bus_tracking_remote_data_source.dart';

class BusTrackingRepositoryImpl implements BusTrackingRepository {
  final BusTrackingRemoteDataSource remoteDataSource;

  BusTrackingRepositoryImpl({required this.remoteDataSource});

  // ── ETA calculation ────────────────────────────────────────────────────────
  // Assumed average bus speed used only when the server doesn't send ETAs.
  static const double _avgSpeedKmh = 30.0;

  /// Given the bus's current position and an ordered list of UPCOMING stops
  /// (not yet passed), returns ETA in minutes for each stop.
  List<int?> _estimateEta(BusRoute route, List<RouteStop> upcomingStops) {
    if (upcomingStops.isEmpty) return [];
    final busLat = route.busPosition.latitude;
    final busLng = route.busPosition.longitude;

    // Cumulative distance from bus → stop[0] → stop[1] → ...
    double cumulativeKm = 0;
    double prevLat = busLat;
    double prevLng = busLng;

    return upcomingStops.map((stop) {
      cumulativeKm += Geolocator.distanceBetween(
        prevLat, prevLng, stop.latitude, stop.longitude,
      ) / 1000.0;
      prevLat = stop.latitude;
      prevLng = stop.longitude;
      // ETA in minutes = distance / speed * 60, minimum 1
      final etaMins = ((cumulativeKm / _avgSpeedKmh) * 60).ceil();
      return etaMins < 1 ? 1 : etaMins;
    }).toList();
  }

  /// Stamps each stop with its estimated ETA (minutes) so _checkAlarms can
  /// compare against the user-selected alarm threshold.
  List<RouteStop> _applyEtas(BusRoute route, List<RouteStop> stops) {
    // Collect upcoming stops (not passed, not current)
    final upcoming = stops
        .where((s) => s.type == StopType.futureStop || s.type == StopType.nextStop)
        .toList();
    final etas = _estimateEta(route, upcoming);
    int etaIdx = 0;
    return stops.map((s) {
      if (s.type == StopType.futureStop || s.type == StopType.nextStop) {
        final eta = etaIdx < etas.length ? etas[etaIdx] : null;
        etaIdx++;
        return s.copyWith(estimatedArrivalMinutes: eta);
      }
      return s;
    }).toList();
  }


  @override
  Future<Either<Failure, BusRoute>> getBusRoute(String busNumber, {String? routeId}) async {
    try {
      final result = await remoteDataSource.getBusRoute(busNumber, routeId: routeId);
      BusRoute route = result.toEntity();
      
      // If the bus is already in a reverse trip, reverse the manifest immediately
      if (route.isReverse) {
        route = route.copyWith(
          stops: route.stops.reversed.toList(),
          routePath: route.routePath.reversed.toList(),
        );
      }
      return Right(route);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BusSummary>>> getAvailableBuses() async {
    try {
      final result = await remoteDataSource.getAvailableBuses();
      return Right(result.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RouteStop>>> getAllCollegeStops() async {
    try {
      final result = await remoteDataSource.getAllCollegeStops();
      return Right(result.map((m) => m.toEntity('')).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitSupportQuery({
    required String query,
    required String subject,
    String? email,
  }) async {
    try {
      await remoteDataSource.submitSupportQuery(
        query: query,
        subject: subject,
        email: email,
      );
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getStudentsForStop(String busNumber, String stopName) async {
    try {
      final result = await remoteDataSource.getStudentsByStop(busNumber, stopName);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllStudentsForBus(String busNumber) async {
    try {
      final result = await remoteDataSource.getAllStudentsForBus(busNumber);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, BusRoute>> trackBusLocation(
    String busNumber, {
    bool? initialIsReverse,
    String? routeId,
  }) async* {
    final routeResult = await getBusRoute(busNumber, routeId: routeId);

    if (routeResult.isLeft()) {
      yield Left(
        routeResult.fold((l) => l, (r) => throw Exception('Impossible')),
      );
      return;
    }

    BusRoute currentRoute = routeResult.getOrElse(
      () => throw Exception('Impossible'),
    );

    // If direction is explicitly provided (e.g. from driver/student selection), 
    // override the REST result and ensure the physical stops/path are flipped if necessary.
    if (initialIsReverse != null) {
      if (currentRoute.isReverse != initialIsReverse) {
        currentRoute = currentRoute.copyWith(
          isReverse: initialIsReverse,
          stops: currentRoute.stops.reversed.toList(),
          routePath: currentRoute.routePath.reversed.toList(),
        );
      } else {
        currentRoute = currentRoute.copyWith(isReverse: initialIsReverse);
      }
    }

    yield Right(currentRoute);

    yield* remoteDataSource.streamBusLocation(busNumber).map((position) {
      final posEntity = position.toEntity();
      final bool isReverse = posEntity.isReverse ?? currentRoute.isReverse;

      final stops = currentRoute.stops;
      if (stops.isEmpty) return Right<Failure, BusRoute>(currentRoute);

      List<RouteStop> updatedStops;
      String newCurrentLocation = currentRoute.currentLocation;
      String newNextStop = currentRoute.nextStop;

      // If trip is NOT active, all stops should be reset to Upcoming
      if (posEntity.isTripActive == false) {
        currentRoute = currentRoute.copyWith(
          busPosition: posEntity,
          isTripActive: false,
          isReverse: posEntity.isReverse ?? currentRoute.isReverse,
          stops: stops.map((s) => s.copyWith(type: StopType.futureStop)).toList(),
          currentLocation: 'Inactive',
          nextStop: 'Trip not started',
        );
        return Right<Failure, BusRoute>(currentRoute);
      }

      // ── STRATEGY 1: nextStop from server = sequence authority ───────────────
      // The server reliably sends nextStop. Everything before nextStop is passed.
      // This correctly handles "In Transit (to X)" without GPS guessing.
      final serverNextStop = posEntity.nextStop;
      if (serverNextStop != null &&
          serverNextStop.isNotEmpty &&
          serverNextStop != 'Calculating...' &&
          serverNextStop != 'Terminus' &&
          serverNextStop != 'Terminus Reached') {

        final nextIdx = stops.indexWhere(
          (s) => s.name.trim().toLowerCase() == serverNextStop.trim().toLowerCase(),
        );

        if (nextIdx != -1) {
          // Check if bus is AT the next stop (server sends plain stop name, not "In Transit")
          final serverCurrent = posEntity.currentLocation;
          final busIsAtStop = serverCurrent != null &&
              !serverCurrent.startsWith('In Transit') &&
              stops.any((s) => s.name.trim().toLowerCase() == serverCurrent.trim().toLowerCase());

          if (busIsAtStop) {
            final atIdx = stops.indexWhere(
              (s) => s.name.trim().toLowerCase() == serverCurrent.trim().toLowerCase(),
            );
            newCurrentLocation = serverCurrent;
            updatedStops = stops.asMap().entries.map((e) {
              final i = e.key; final stop = e.value;
              // Since the list is already in travel order, lower index = passed
              if (i < atIdx) return stop.copyWith(type: StopType.passedStop);
              if (i == atIdx) return stop.copyWith(type: StopType.currentLocation);
              if (i == atIdx + 1) return stop.copyWith(type: StopType.nextStop);
              return stop.copyWith(type: StopType.futureStop);
            }).toList();
          } else {
            // In transit: nextIdx is the upcoming stop. 
            // Since the list is in travel order, anything < nextIdx is passed.
            newCurrentLocation = stops[(nextIdx - 1).clamp(0, stops.length-1)].name;
            newNextStop = serverNextStop;
            updatedStops = stops.asMap().entries.map((e) {
              final i = e.key; final stop = e.value;
              if (i < nextIdx) return stop.copyWith(type: StopType.passedStop);
              if (i == nextIdx) return stop.copyWith(type: StopType.nextStop);
              return stop.copyWith(type: StopType.futureStop);
            }).toList();
          }

          // Stamp ETAs so _checkAlarms can compare against user threshold
          final withEtas = _applyEtas(currentRoute.copyWith(busPosition: posEntity), updatedStops);
          currentRoute = currentRoute.copyWith(
            busPosition: posEntity,
            currentLocation: newCurrentLocation,
            nextStop: newNextStop,
            isOnTime: posEntity.isOnTime ?? currentRoute.isOnTime,
            arrivalTimeMinutes: posEntity.delayMinutes ?? currentRoute.arrivalTimeMinutes,
            stops: withEtas,
            isTripActive: posEntity.isTripActive ?? currentRoute.isTripActive,
            isReverse: isReverse,
            students: posEntity.students ?? currentRoute.students,
          );
          return Right<Failure, BusRoute>(currentRoute);
        }

        if (nextIdx == 0) {
          // Heading to first stop — nothing passed yet
          updatedStops = stops.asMap().entries.map((e) =>
            e.key == 0 ? e.value.copyWith(type: StopType.nextStop)
                       : e.value.copyWith(type: StopType.futureStop)
          ).toList();
          final withEtas = _applyEtas(currentRoute.copyWith(busPosition: posEntity), updatedStops);
          currentRoute = currentRoute.copyWith(
            busPosition: posEntity, 
            nextStop: serverNextStop, 
            stops: withEtas,
            isTripActive: posEntity.isTripActive ?? currentRoute.isTripActive,
            isReverse: posEntity.isReverse ?? currentRoute.isReverse,
          );
          return Right<Failure, BusRoute>(currentRoute);
        }
      }

      // ── STRATEGY 2: currentLocation exactly matches a stop name ─────────────
      final serverCurrent = posEntity.currentLocation;
      if (serverCurrent != null &&
          serverCurrent.isNotEmpty &&
          !serverCurrent.startsWith('In Transit') &&
          stops.any((s) => s.name.trim().toLowerCase() == serverCurrent.trim().toLowerCase())) {
        final atIdx = stops.indexWhere(
          (s) => s.name.trim().toLowerCase() == serverCurrent.trim().toLowerCase(),
        );
        updatedStops = stops.asMap().entries.map((e) {
          final i = e.key; final stop = e.value;
          // Travel order: lower index = passed
          if (i < atIdx) return stop.copyWith(type: StopType.passedStop);
          if (i == atIdx) return stop.copyWith(type: StopType.currentLocation);
          if (i == atIdx + 1) return stop.copyWith(type: StopType.nextStop);
          return stop.copyWith(type: StopType.futureStop);
        }).toList();
        final withEtas2 = _applyEtas(currentRoute.copyWith(busPosition: posEntity), updatedStops);
        currentRoute = currentRoute.copyWith(
          busPosition: posEntity,
          currentLocation: serverCurrent,
          nextStop: posEntity.nextStop ?? currentRoute.nextStop,
          isOnTime: posEntity.isOnTime ?? currentRoute.isOnTime,
          arrivalTimeMinutes: posEntity.delayMinutes ?? currentRoute.arrivalTimeMinutes,
          isTripActive: posEntity.isTripActive ?? currentRoute.isTripActive,
          isReverse: posEntity.isReverse ?? currentRoute.isReverse,
          stops: withEtas2,
          students: posEntity.students ?? currentRoute.students,
        );
        return Right<Failure, BusRoute>(currentRoute);
      }

      // ── STRATEGY 3: GPS proximity fallback ─────────────────────────────────
      double minDist = double.infinity;
      int closestIdx = -1;
      for (int i = 0; i < stops.length; i++) {
        final dist = Geolocator.distanceBetween(
          posEntity.latitude, posEntity.longitude,
          stops[i].latitude, stops[i].longitude,
        ) / 1000;
        if (dist < minDist) { minDist = dist; closestIdx = i; }
      }
      if (closestIdx >= 0 && minDist < 1.0) {
        updatedStops = stops.asMap().entries.map((e) {
          final i = e.key;
          final stop = e.value;
          // Travel order: lower index = passed
          if (i < closestIdx) return stop.copyWith(type: StopType.passedStop);
          if (i == closestIdx) return stop.copyWith(type: StopType.currentLocation);
          if (i == closestIdx + 1) return stop.copyWith(type: StopType.nextStop);
          return stop.copyWith(type: StopType.futureStop);
        }).toList();
        final withEtas3 = _applyEtas(currentRoute.copyWith(busPosition: posEntity), updatedStops);
        currentRoute = currentRoute.copyWith(
          busPosition: posEntity,
          currentLocation: stops[closestIdx].name,
          isOnTime: posEntity.isOnTime ?? currentRoute.isOnTime,
          stops: withEtas3,
          students: posEntity.students ?? currentRoute.students,
        );
        return Right<Failure, BusRoute>(currentRoute);
      }

      // ── STRATEGY 4: Position-only update, keep existing stop sequence ───────
      currentRoute = currentRoute.copyWith(
        busPosition: posEntity,
        students: posEntity.students ?? currentRoute.students,
      );
      return Right<Failure, BusRoute>(currentRoute);
    });
  }

  @override
  Stream<Map<String, dynamic>> streamTripStatus(String busNumber) {
    return remoteDataSource.streamTripStatus(busNumber);
  }
}
