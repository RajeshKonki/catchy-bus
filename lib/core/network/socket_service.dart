import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../../core/utils/logger.dart';

@lazySingleton
class SocketService {
  io.Socket? _socket;
  final String _baseUrl = ApiConstants.socketUrl;

  /// Tracks which bus rooms this socket has joined, so we can rejoin on reconnect.
  final Set<String> _joinedRooms = {};

  io.Socket? get socket => _socket;

  void connect({String? token}) {
    if (_socket?.connected == true) return;

    _socket = io.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'auth': token != null ? {'token': token} : null,
    });

    _socket?.onConnect((_) {
      Log.i('✅ Connected to socket server at $_baseUrl');
      // Re-join all bus rooms after every (re)connect so we never miss updates.
      for (final busId in _joinedRooms) {
        Log.i('🔄 Rejoining bus room after connect: $busId');
        _socket?.emit('join_bus', busId);
      }
    });

    _socket?.onConnectError((data) {
      Log.e('❌ Socket Connection Error ($data) at $_baseUrl');
    });

    _socket?.onError((data) {
      Log.e('⚠️ Socket Error: $data');
    });

    _socket?.onDisconnect((_) {
      Log.i('Disconnected from socket server');
    });

    _socket?.connect();
  }

  void disconnect() {
    _joinedRooms.clear();
    _socket?.disconnect();
    _socket = null;
  }

  void emit(String event, dynamic data) {
    if (_socket == null || !(_socket!.connected)) {
      // Not connected yet — connect and defer the emit until connected.
      connect();
      _socket?.once('connect', (_) => _socket?.emit(event, data));
      return;
    }
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      // Socket not created yet — connect first, then register listener.
      connect();
    }
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  /// Remove only [callback] from [event], leaving any other listeners intact.
  /// Use this instead of [off] when multiple streams share the same event name,
  /// to avoid accidentally de-registering a different stream's listener.
  void offCallback(String event, Function(dynamic) callback) {
    _socket?.off(event, callback);
  }

  /// Join a socket.io bus room. Remembers the room so it auto-rejoins on reconnect.
  void joinBus(String busId) {
    _joinedRooms.add(busId);
    if (_socket == null || !(_socket!.connected)) {
      // Not connected — emit will be deferred via the onConnect handler above.
      connect();
    } else {
      _socket?.emit('join_bus', busId);
    }
  }

  /// Leave a bus room (stops monitoring that bus).
  void leaveBus(String busId) {
    _joinedRooms.remove(busId);
    _socket?.emit('leave_bus', busId);
  }

  void updateLocation({
    required String busId,
    required double latitude,
    required double longitude,
    double? bearing,
  }) {
    emit('update_location', {
      'busId': busId,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'bearing': bearing,
      },
    });
  }

  void markAttendance({
    required String busId,
    required String stopName,
    required List<String> studentIds,
  }) {
    emit('mark_attendance', {
      'busId': busId,
      'stopName': stopName,
      'studentIds': studentIds,
    });
  }

  void requestStudentsByStop({
    required String busNumber,
    required String stopName,
  }) {
    emit('get_students_by_stop', {
      'busNumber': busNumber,
      'stopName': stopName,
    });
  }

  void startTrip(String busNumber, {String? routeId, double? driverLat, double? driverLng}) {
    if (routeId != null) {
      emit('start_trip', {
        'busNumber': busNumber,
        'routeId': routeId,
        if (driverLat != null) 'driverLat': driverLat,
        if (driverLng != null) 'driverLng': driverLng,
      });
    } else {
      emit('start_trip', busNumber);
    }
  }

  void endTrip(String busNumber, {double? driverLat, double? driverLng}) {
    if (driverLat != null && driverLng != null) {
      emit('end_trip', {
        'busNumber': busNumber,
        'driverLat': driverLat,
        'driverLng': driverLng,
      });
    } else {
      emit('end_trip', busNumber);
    }
  }

  void cancelTrip(String busNumber, String reason) {
    emit('cancel_trip', {
      'busNumber': busNumber,
      'reason': reason,
    });
  }

  void skipStop({
    required String busId,
    required String stopName,
    required String reason,
  }) {
    emit('skip_stop', {
      'busId': busId,
      'stopName': stopName,
      'reason': reason,
    });
  }

  bool get isConnected => _socket?.connected ?? false;
}
