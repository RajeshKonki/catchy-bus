import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/bus_route.dart';

/// Repository interface for bus tracking operations
abstract class BusTrackingRepository {
  /// Get the current bus route information
  Future<Either<Failure, BusRoute>> getBusRoute(String busNumber);

  /// Get list of available buses
  Future<Either<Failure, List<BusSummary>>> getAvailableBuses();

  /// Get all unique stops for the college
  Future<Either<Failure, List<RouteStop>>> getAllCollegeStops();

  /// Submit a support query to the help desk
  Future<Either<Failure, bool>> submitSupportQuery({
    required String query,
    required String subject,
    String? email,
  });

  /// Get students for a specific stop on a bus
  Future<Either<Failure, List<Map<String, dynamic>>>> getStudentsForStop(String busNumber, String stopName);

  /// Update bus location (for real-time tracking)
  Stream<Either<Failure, BusRoute>> trackBusLocation(String busNumber);

  /// Stream real-time trip status updates (start/end/cancel/stop_skipped)
  Stream<Map<String, dynamic>> streamTripStatus(String busNumber);
}
