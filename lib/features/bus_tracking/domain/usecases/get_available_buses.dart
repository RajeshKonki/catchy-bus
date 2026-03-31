import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bus_route.dart';
import '../repositories/bus_tracking_repository.dart';

/// Use case for getting list of available buses
class GetAvailableBuses implements UseCase<List<BusSummary>, NoParams> {
  final BusTrackingRepository repository;

  GetAvailableBuses(this.repository);

  @override
  Future<Either<Failure, List<BusSummary>>> call(NoParams params) async {
    return await repository.getAvailableBuses();
  }
}
