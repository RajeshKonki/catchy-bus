import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bus_tracking_repository.dart';

class SubmitSupportQuery implements UseCase<bool, SubmitSupportQueryParams> {
  final BusTrackingRepository repository;

  SubmitSupportQuery(this.repository);

  @override
  Future<Either<Failure, bool>> call(SubmitSupportQueryParams params) {
    return repository.submitSupportQuery(
      query: params.query,
      subject: params.subject,
      email: params.email,
    );
  }
}

class SubmitSupportQueryParams {
  final String query;
  final String subject;
  final String? email;

  SubmitSupportQueryParams({
    required this.query,
    required this.subject,
    this.email,
  });
}
