import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Authentication repository interface - Domain layer
/// This defines the contract for authentication operations
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, UserEntity>> login({
    required String emailOrPhone,
    String? password,
    String? idToken,
    required String role,
    String? selectedUserId,
  });

  /// Register a new user
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String name,
  });

  /// Logout current user
  Future<Either<Failure, void>> logout();

  /// Get current user
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();
  /// Update FCM token for push notifications
  Future<Either<Failure, void>> updateFcmToken(String fcmToken);
  /// Update notification settings
  Future<Either<Failure, void>> updateNotificationSettings(Map<String, bool> settings);
}
