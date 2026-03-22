import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/bus_route.dart';
import '../../domain/repositories/bus_tracking_repository.dart';
import '../datasources/bus_tracking_remote_data_source.dart';

class BusTrackingRepositoryImpl implements BusTrackingRepository {
  final BusTrackingRemoteDataSource remoteDataSource;

  BusTrackingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BusRoute>> getBusRoute(String busNumber) async {
    try {
      final result = await remoteDataSource.getBusRoute(busNumber);
      return Right(result.toEntity());
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
  Stream<Either<Failure, BusRoute>> trackBusLocation(String busNumber) async* {
    final routeResult = await getBusRoute(busNumber);

    if (routeResult.isLeft()) {
      yield Left(
        routeResult.fold((l) => l, (r) => throw Exception('Impossible')),
      );
      return;
    }

    BusRoute currentRoute = routeResult.getOrElse(
      () => throw Exception('Impossible'),
    );
    yield Right(currentRoute);

    yield* remoteDataSource.streamBusLocation(busNumber).map((position) {
      final posEntity = position.toEntity();

      final stops = currentRoute.stops;
      if (stops.isEmpty) return Right<Failure, BusRoute>(currentRoute);

      List<RouteStop> updatedStops;
      String newCurrentLocation = currentRoute.currentLocation;
      String newNextStop = currentRoute.nextStop;

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

        if (nextIdx > 0) {
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
              if (i < atIdx) return stop.copyWith(type: StopType.passedStop);
              if (i == atIdx) return stop.copyWith(type: StopType.currentLocation);
              if (i == atIdx + 1) return stop.copyWith(type: StopType.nextStop);
              return stop.copyWith(type: StopType.futureStop);
            }).toList();
          } else {
            // In transit: last passed stop = stops[nextIdx - 1]
            newCurrentLocation = stops[nextIdx - 1].name;
            newNextStop = serverNextStop;
            updatedStops = stops.asMap().entries.map((e) {
              final i = e.key; final stop = e.value;
              if (i < nextIdx) return stop.copyWith(type: StopType.passedStop);
              if (i == nextIdx) return stop.copyWith(type: StopType.nextStop);
              return stop.copyWith(type: StopType.futureStop);
            }).toList();
          }

          currentRoute = currentRoute.copyWith(
            busPosition: posEntity,
            currentLocation: newCurrentLocation,
            nextStop: newNextStop,
            isOnTime: posEntity.isOnTime ?? currentRoute.isOnTime,
            arrivalTimeMinutes: posEntity.delayMinutes ?? currentRoute.arrivalTimeMinutes,
            stops: updatedStops,
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
          currentRoute = currentRoute.copyWith(
            busPosition: posEntity, nextStop: serverNextStop, stops: updatedStops,
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
          if (i < atIdx) return stop.copyWith(type: StopType.passedStop);
          if (i == atIdx) return stop.copyWith(type: StopType.currentLocation);
          if (i == atIdx + 1) return stop.copyWith(type: StopType.nextStop);
          return stop.copyWith(type: StopType.futureStop);
        }).toList();
        currentRoute = currentRoute.copyWith(
          busPosition: posEntity,
          currentLocation: serverCurrent,
          nextStop: posEntity.nextStop ?? currentRoute.nextStop,
          isOnTime: posEntity.isOnTime ?? currentRoute.isOnTime,
          arrivalTimeMinutes: posEntity.delayMinutes ?? currentRoute.arrivalTimeMinutes,
          stops: updatedStops,
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
          final i = e.key; final stop = e.value;
          if (i < closestIdx) return stop.copyWith(type: StopType.passedStop);
          if (i == closestIdx) return stop.copyWith(type: StopType.currentLocation);
          if (i == closestIdx + 1) return stop.copyWith(type: StopType.nextStop);
          return stop.copyWith(type: StopType.futureStop);
        }).toList();
        currentRoute = currentRoute.copyWith(
          busPosition: posEntity,
          currentLocation: stops[closestIdx].name,
          isOnTime: posEntity.isOnTime ?? currentRoute.isOnTime,
          stops: updatedStops,
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
