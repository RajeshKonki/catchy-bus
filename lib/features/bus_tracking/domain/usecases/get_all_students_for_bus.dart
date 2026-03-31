import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bus_tracking_repository.dart';

class GetAllStudentsForBus implements UseCase<List<Map<String, dynamic>>, String> {
  final BusTrackingRepository repository;

  GetAllStudentsForBus(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(String busNumber) async {
    return await repository.getAllStudentsForBus(busNumber);
  }
}
