import 'dart:async';

/// A simple manager to handle global session events like token expiry
class SessionManager {
  final _sessionExpiryController = StreamController<void>.broadcast();

  /// Stream of session expiry events
  Stream<void> get onSessionExpired => _sessionExpiryController.stream;

  /// Trigger a session expiry event
  void logout() {
    _sessionExpiryController.add(null);
  }

  void dispose() {
    _sessionExpiryController.close();
  }
}
