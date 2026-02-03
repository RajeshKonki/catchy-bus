import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Base class for all use cases
/// T: Return type
/// Params: Parameters required for the use case
abstract class UseCase<T, Params> {
  /// Execute the use case
  /// Returns Either with Failure or T
  /// Left: Failure
  /// Right: Success with T
  Future<Either<Failure, T>> call(Params params);
}

/// Use case with no parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
