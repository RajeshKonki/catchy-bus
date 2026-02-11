import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bus_tracking_repository.dart';

/// Use case for getting list of available buses
class GetAvailableBuses implements UseCase<List<String>, NoParams> {
  final BusTrackingRepository repository;

  GetAvailableBuses(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getAvailableBuses();
  }
}
