import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bus_route.dart';
import '../repositories/bus_tracking_repository.dart';
import '../entities/trip_direction.dart';

class TrackBusLocation
    implements StreamUseCase<BusRoute, TrackBusLocationParams> {
  final BusTrackingRepository repository;

  TrackBusLocation(this.repository);

  @override
  Stream<Either<Failure, BusRoute>> call(TrackBusLocationParams params) {
    return repository.trackBusLocation(
      params.busNumber,
      initialDirection: params.initialDirection,
      routeId: params.routeId,
    );
  }
}

class TrackBusLocationParams {
  final String busNumber;
  final TripDirection? initialDirection;
  final String? routeId;

  TrackBusLocationParams({
    required this.busNumber,
    this.initialDirection,
    this.routeId,
  });
}
