import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';

/// Remote data source for authentication
/// Handles all API calls related to authentication
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String emailOrPhone,
    String? password,
    String? idToken,
    required String role,
    String? selectedUserId,
  });

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String name,
  });

  Future<void> logout();
  Future<void> updateFcmToken(String fcmToken);
  Future<void> updateNotificationSettings(Map<String, bool> settings);
}

/// Implementation of AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<AuthResponseModel> login({
    required String emailOrPhone,
    String? password,
    String? idToken,
    required String role,
    String? selectedUserId,
  }) async {
    try {
      String endpoint = ApiConstants.login; // Default
      if (role.toLowerCase() == 'student') {
        endpoint = ApiConstants.studentLogin;
      } else if (role.toLowerCase() == 'parent') {
        endpoint = ApiConstants.parentLogin;
      } else if (role.toLowerCase() == 'driver') {
        endpoint = ApiConstants.driverLogin;
      }

      final data = {
        'emailOrPhone': emailOrPhone,
        'email': emailOrPhone,
        'phone': emailOrPhone,
        'role': role.toLowerCase(),
      };

      if (idToken != null) {
        data['idToken'] = idToken;
      } else if (password != null) {
        data['password'] = password;
      }

      if (selectedUserId != null) {
        data['selectedUserId'] = selectedUserId;
      }

      final response = await dioClient.post(
        endpoint,
        data: data, 
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to login',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map 
        ? (e.response?.data['message'] ?? e.message)
        : e.message;
      throw ServerException(
        message: message ?? 'Connection error', 
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: e.toString(), statusCode: null);
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.register,
        data: {'email': email, 'password': password, 'name': name},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to register',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: e.toString(), statusCode: null);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final response = await dioClient.post(ApiConstants.logout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to logout',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: e.toString(), statusCode: null);
    }
  }

  @override
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final response = await dioClient.post(
        '/auth/fcm-token',
        data: {'fcmToken': fcmToken},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to update FCM token',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: e.toString(), statusCode: null);
    }
  }

  @override
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final response = await dioClient.post(
        '/student/notification-settings',
        data: {'notificationSettings': settings},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to update notification settings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: e.toString(), statusCode: null);
    }
  }
}
