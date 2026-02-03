/// API related constants
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = '/v1';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
}
