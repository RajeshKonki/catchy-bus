import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bus_route.dart';
import '../repositories/bus_tracking_repository.dart';

class GetCollegeStops implements UseCase<List<RouteStop>, NoParams> {
  final BusTrackingRepository repository;

  GetCollegeStops(this.repository);

  @override
  Future<Either<Failure, List<RouteStop>>> call(NoParams params) async {
    return await repository.getAllCollegeStops();
  }
}
