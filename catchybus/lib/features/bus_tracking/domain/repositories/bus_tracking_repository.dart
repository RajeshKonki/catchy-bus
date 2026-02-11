import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/bus_route.dart';

/// Repository interface for bus tracking operations
abstract class BusTrackingRepository {
  /// Get the current bus route information
  Future<Either<Failure, BusRoute>> getBusRoute(String busNumber);

  /// Get list of available buses
  Future<Either<Failure, List<String>>> getAvailableBuses();

  /// Update bus location (for real-time tracking)
  Stream<Either<Failure, BusRoute>> trackBusLocation(String busNumber);
}
