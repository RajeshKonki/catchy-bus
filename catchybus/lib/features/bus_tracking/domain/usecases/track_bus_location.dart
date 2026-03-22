import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bus_route.dart';
import '../repositories/bus_tracking_repository.dart';

class TrackBusLocation
    implements StreamUseCase<BusRoute, TrackBusLocationParams> {
  final BusTrackingRepository repository;

  TrackBusLocation({required this.repository});

  @override
  Stream<Either<Failure, BusRoute>> call(TrackBusLocationParams params) {
    return repository.trackBusLocation(params.busNumber);
  }
}

class TrackBusLocationParams {
  final String busNumber;

  TrackBusLocationParams({required this.busNumber});
}
