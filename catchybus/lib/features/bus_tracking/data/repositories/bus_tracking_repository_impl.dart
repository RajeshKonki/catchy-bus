import 'package:dartz/dartz.dart';
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
  Future<Either<Failure, List<String>>> getAvailableBuses() async {
    try {
      final result = await remoteDataSource.getAvailableBuses();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, BusRoute>> trackBusLocation(String busNumber) async* {
    // Simulate real-time updates every 5 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final result = await remoteDataSource.getBusRoute(busNumber);
        yield Right(result.toEntity());
      } catch (e) {
        yield Left(ServerFailure(message: e.toString()));
      }
    }
  }
}
