import 'package:catchybus/core/network/dio_client.dart';
import 'package:catchybus/core/network/socket_service.dart';
import 'package:catchybus/core/constants/api_constants.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_route_model.dart';
import 'bus_tracking_remote_data_source.dart';

/// Student-side data source.
/// Reuses the singleton [SocketService] so driver and student share one
/// stable socket connection + bus room membership.
class BusTrackingSocketDataSourceImpl implements BusTrackingRemoteDataSource {
  final SocketService socketService;
  final DioClient dioClient;
  BusTrackingSocketDataSourceImpl({
    required this.socketService,
    required this.dioClient,
    // Kept for signature compatibility – unused (socket managed by SocketService)
    String? serverUrl,
    String? token,
  });
  @override
  Future<BusRouteModel> getBusRoute(String busNumber, {String? routeId}) async {
    try {
      final response = await dioClient.get(
        ApiConstants.busRoute(Uri.encodeComponent(busNumber)),
      );
      final prefs = await SharedPreferences.getInstance();
      return BusRouteModel.fromJson(
        response.data, 
        preferredRouteId: routeId ?? prefs.getString('last_selected_route_id')
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<BusSummaryModel>> getAvailableBuses() async {
    try {
      final response = await dioClient.get(ApiConstants.availableBuses);
      final List<dynamic> data = response.data;
      return data.map((e) {
        if (e is String) {
          return BusSummaryModel(
            id: '',
            busNumber: e,
            latitude: 0.0,
            longitude: 0.0,
            status: 'On Time',
            isDelayed: false,
          );
        }
        return BusSummaryModel.fromJson(e as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<RouteStopModel>> getAllCollegeStops() async {
    try {
      final response = await dioClient.get(ApiConstants.allStops);
      final List<dynamic> data = response.data;
      return data
          .map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> submitSupportQuery({
    required String query,
    required String subject,
    String? email,
  }) async {
    try {
      await dioClient.post(
        ApiConstants.support,
        data: {
          'query': query,
          'subject': subject,
          if (email != null) 'email': email,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsByStop(
      String busNumber, String stopName) async {
    try {
      final response = await dioClient.get(
        'students',
        queryParameters: {
          'busNumber': busNumber,
          'pickupStop': stopName,
        },
      );
      final List<dynamic> data = response.data;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllStudentsForBus(String busNumber) {
    final completer = Completer<List<Map<String, dynamic>>>();
    
    void onList(dynamic data) {
      if (data is Map && data['busNumber'] == busNumber) {
        socketService.offCallback('all_students_list', onList);
        final students = data['students'] as List?;
        completer.complete(students?.map((s) => Map<String, dynamic>.from(s as Map)).toList() ?? []);
      }
    }

    socketService.on('all_students_list', onList);
    socketService.emit('get_all_students_for_bus', busNumber);

    // Timeout after 10 seconds
    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      socketService.offCallback('all_students_list', onList);
      return [];
    });
  }

  @override
  Stream<BusPositionModel> streamBusLocation(String busNumber) {
    final controller = StreamController<BusPositionModel>();
    print('DEBUG: [StudentSocket] streamBusLocation → joining bus room: $busNumber');
    print('DEBUG: [StudentSocket] Socket connected? ${socketService.isConnected}');

    // joinBus handles connect-before-join timing + auto-rejoin after reconnect
    socketService.joinBus(busNumber);

    // Use a named local function so we can remove ONLY this specific callback.
    // Using socketService.off('bus_location_update') would remove ALL listeners
    // for that event (including the one in streamTripStatus), causing updates
    // to stop being delivered until the app restarts.
    void onLocationUpdate(dynamic data) {
      print('DEBUG: [StudentSocket] ✅ bus_location_update received: $data');
      final location = data['location'];
      if (location == null) {
        print('DEBUG: [StudentSocket] ❌ location field is null in update!');
        return;
      }
      final students = data['students'] as List?;
      if (!controller.isClosed) {
        controller.add(
          BusPositionModel(
            latitude:
                (location['latitude'] ?? location['lat'] ?? 0.0).toDouble(),
            longitude:
                (location['longitude'] ?? location['lng'] ?? 0.0).toDouble(),
            bearing: (location['bearing'] ?? 0.0).toDouble(),
            currentLocation: data['currentLocation'],
            nextStop: data['nextStop'],
            isOnTime: data['isOnTime'] as bool?,
            delayMinutes: data['delayMinutes'] as int?,
            isTripActive: data['isTripActive'] as bool?,
            isReverse: data['isReverse'] as bool?,
            students: students?.map((s) => Map<String, dynamic>.from(s)).toList(),
          ),
        );
      }
    }

    // Register listener. SocketService.on() handles the case where _socket
    // is still null (it calls connect() first).
    socketService.on('bus_location_update', onLocationUpdate);

    controller.onCancel = () {
      print('DEBUG: [StudentSocket] streamBusLocation cancelled – removing its bus_location_update listener');
      // Remove ONLY our specific callback, not all listeners for the event.
      socketService.offCallback('bus_location_update', onLocationUpdate);
    };

    return controller.stream;
  }

  @override
  Stream<Map<String, dynamic>> streamTripStatus(String busNumber) {
    final controller = StreamController<Map<String, dynamic>>();

    print('DEBUG: [StudentSocket] streamTripStatus → listening for bus: $busNumber');

    void onTripStatusUpdate(dynamic data) {
      print('DEBUG: [StudentSocket] trip_status_update: $data');
      if (data is Map && !controller.isClosed) {
        controller.add(Map<String, dynamic>.from(data));
      }
    }

    // Also promote isTripActive flag from bus_location_update as a trip signal (both true and false)
    void onLocationUpdateForTripActive(dynamic data) {
      if (data is Map && data.containsKey('isTripActive') && !controller.isClosed) {
        final isActive = data['isTripActive'] == true;
        // ONLY include isReverse if the packet explicitly provides it
        final hasReverse = data.containsKey('isReverse') || data.containsKey('is_reverse');
        final isReverse = (data['isReverse'] ?? data['is_reverse']) == true;
        
        controller.add({
          'busId': busNumber,
          'isTripActive': isActive,
          if (hasReverse) 'isReverse': isReverse,
          'status': isActive ? 'STARTED' : 'ENDED',
        });
      }
    }

    void onStopSkipped(dynamic data) {
      print('DEBUG: [StudentSocket] stop_skipped: $data');
      if (data is Map && !controller.isClosed) {
        controller.add({
          'busId': busNumber,
          'type': 'stop_skipped',
          'stopName': data['stopName'],
        });
      }
    }

    void onAttendanceMarked(dynamic data) {
      print('DEBUG: [StudentSocket] attendance_marked: $data');
      if (data is Map && !controller.isClosed) {
        controller.add({
          'busId': busNumber,
          'type': 'attendance_marked',
          'studentName': data['studentName'],
          'studentId': data['studentId'],
          'pickupStop': data['pickupStop'] ?? data['stopName'],
          'busNumber': data['busNumber'] ?? busNumber,
        });
      }
    }

    socketService.on('trip_status_update', onTripStatusUpdate);
    socketService.on('bus_location_update', onLocationUpdateForTripActive);
    socketService.on('stop_skipped', onStopSkipped);
    socketService.on('attendance_marked', onAttendanceMarked);

    controller.onCancel = () {
      print('DEBUG: [StudentSocket] streamTripStatus cancelled – removing its listeners');
      socketService.offCallback('trip_status_update', onTripStatusUpdate);
      socketService.offCallback('bus_location_update', onLocationUpdateForTripActive);
      socketService.offCallback('stop_skipped', onStopSkipped);
      socketService.offCallback('attendance_marked', onAttendanceMarked);
    };


    return controller.stream;
  }
}
