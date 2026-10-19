import 'dart:io';
import '../config/env.dart';

/// API related constants
class ApiConstants {
  // Base URLs
  static String get baseUrl {
    String url = Env.baseUrl;
    if (Platform.isAndroid) {
      url = url.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url.endsWith('/') ? url : '$url/';
  }

  static String get socketUrl {
    String url = Env.baseUrl;
    if (Platform.isAndroid) {
      url = url.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }
    final uri = Uri.parse(url);
    int port = uri.port;
    if (!uri.hasPort) {
      port = uri.scheme == 'https' ? 443 : 80;
    }
    return '${uri.scheme}://${uri.host}:$port';
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
