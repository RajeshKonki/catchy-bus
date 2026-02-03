import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/di/injection.dart';

/// Implementation of AuthRepository - Data layer
/// Implements the repository interface defined in domain layer
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    // Check network connectivity
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save tokens to local storage
      final prefs = getIt<SharedPreferences>();
      await prefs.setString(AppConstants.keyAccessToken, result.accessToken);
      if (result.refreshToken != null) {
        await prefs.setString(
          AppConstants.keyRefreshToken,
          result.refreshToken!,
        );
      }
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyUserId, result.user.id);

      return Right(result.user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );

      // Save tokens to local storage
      final prefs = getIt<SharedPreferences>();
      await prefs.setString(AppConstants.keyAccessToken, result.accessToken);
      if (result.refreshToken != null) {
        await prefs.setString(
          AppConstants.keyRefreshToken,
          result.refreshToken!,
        );
      }
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyUserId, result.user.id);

      return Right(result.user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();

      // Clear local storage
      final prefs = getIt<SharedPreferences>();
      await prefs.remove(AppConstants.keyAccessToken);
      await prefs.remove(AppConstants.keyRefreshToken);
      await prefs.setBool(AppConstants.keyIsLoggedIn, false);
      await prefs.remove(AppConstants.keyUserId);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    // TODO: Implement get current user from API or local storage
    return const Left(UnknownFailure(message: 'Not implemented'));
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = getIt<SharedPreferences>();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }
}
