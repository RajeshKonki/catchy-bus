import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bus_route.dart';
import '../repositories/bus_tracking_repository.dart';

/// Use case for getting bus route information
class GetBusRoute implements UseCase<BusRoute, GetBusRouteParams> {
  final BusTrackingRepository repository;

  GetBusRoute(this.repository);

  @override
  Future<Either<Failure, BusRoute>> call(GetBusRouteParams params) async {
    return await repository.getBusRoute(params.busNumber, routeId: params.routeId);
  }
}

class GetBusRouteParams {
  final String busNumber;
  final String? routeId;

  GetBusRouteParams({required this.busNumber, this.routeId});
}
