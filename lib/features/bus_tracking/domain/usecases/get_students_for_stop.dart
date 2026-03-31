import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bus_tracking_repository.dart';

class GetStudentsForStop implements UseCase<List<Map<String, dynamic>>, GetStudentsForStopParams> {
  final BusTrackingRepository repository;

  GetStudentsForStop(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetStudentsForStopParams params) async {
    return await repository.getStudentsForStop(params.busNumber, params.stopName);
  }
}

class GetStudentsForStopParams {
  final String busNumber;
  final String stopName;

  GetStudentsForStopParams({required this.busNumber, required this.stopName});
}
