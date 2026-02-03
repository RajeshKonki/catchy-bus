/// Base exception class for all custom exceptions
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message (Status: $statusCode)';
}

/// Server exception (API errors)
class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Cache exception (local storage errors)
class CacheException extends AppException {
  const CacheException({required super.message, super.statusCode});

  @override
  String toString() => 'CacheException: $message';
}

/// Network exception (connectivity issues)
class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});

  @override
  String toString() => 'NetworkException: $message';
}

/// Authentication exception (unauthorized access)
class AuthenticationException extends AppException {
  const AuthenticationException({required super.message, super.statusCode});

  @override
  String toString() =>
      'AuthenticationException: $message (Status: $statusCode)';
}
