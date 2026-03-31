import '../config/env.dart';

/// API related constants
class ApiConstants {
  // Base URLs
  static String get baseUrl =>
      Env.baseUrl.endsWith('/') ? Env.baseUrl : '${Env.baseUrl}/';
  static String get socketUrl {
    final uri = Uri.parse(Env.baseUrl);
    // Strip the path (e.g. /api) — keep scheme + host + port only
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
  static const String apiVersion = '/v1';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints
  static const String login = 'auth/login';
  static const String studentLogin = 'auth/student/login';
  static const String parentLogin = 'auth/parent/login';
  static const String driverLogin = 'auth/driver/login';
  static const String register = 'auth/register';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';
  static const String me = 'auth/me';
  static const String checkPhone = 'auth/check-phone';

  static const String availableBuses = 'buses';
  static String busRoute(String busNumber) => 'buses/number/$busNumber';
  static const String banners = 'banners/active';

  static const String colleges = 'colleges';
  static const String students = 'students';
  static const String routes = 'routes';
  static const String allStops = 'routes/stops';
  static const String drivers = 'drivers';
  static const String support = 'support/query';

  static const String bulkColleges = 'bulk/colleges';
  static const String bulkDrivers = 'bulk/drivers';
  static const String bulkStudents = 'bulk/students';

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
}
