import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Login use case - Domain layer
/// Handles the business logic for user login
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return await repository.login(
      emailOrPhone: params.emailOrPhone,
      password: params.password,
      idToken: params.idToken,
      role: params.role,
      selectedUserId: params.selectedUserId,
    );
  }
}

/// Parameters for login use case
class LoginParams extends Equatable {
  final String emailOrPhone;
  final String? password;
  final String? idToken;
  final String role; // 'Student', 'Parent', 'Driver'
  final String? selectedUserId;

  const LoginParams({
    required this.emailOrPhone,
    this.password,
    this.idToken,
    required this.role,
    this.selectedUserId,
  });

  @override
  List<Object?> get props => [emailOrPhone, password, idToken, role, selectedUserId];
}
