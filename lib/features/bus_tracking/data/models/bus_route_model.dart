import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/bus_route.dart';

part 'bus_route_model.freezed.dart';
part 'bus_route_model.g.dart';

@freezed
class BusRouteModel with _$BusRouteModel {
  const BusRouteModel._();

  const factory BusRouteModel({
    required String id,
    required String busNumber,
    required String currentLocation,
    required String nextStop,
    String? startPoint,
    String? endPoint,
    required int arrivalTimeMinutes,
    required double distanceKm,
    required bool isOnTime,
    required String driverPhone,
    String? driverName,
    String? driverPhoto,
    int? capacity,
    String? collegeName,
    required BusPositionModel busPosition,
    required List<RouteStopModel> stops,
    required List<RoutePointModel> routePath,
    @Default(false) bool isTripActive,
    @Default([]) List<Map<String, dynamic>> students,
  }) = _BusRouteModel;

  factory BusRouteModel.fromJson(Map<String, dynamic> json, {String? preferredRouteId}) {
    // Determine the route to show based on active trip or driver preference
    final trips = (json['trips'] as List? ?? []);
    final activeTripRouteId = trips.isNotEmpty ? trips[0]['routeId']?.toString() : null;
    final targetRouteId = activeTripRouteId ?? preferredRouteId;

    // Handle nested structure if coming from /api/buses/number/:busNumber
    Map<String, dynamic> routeData = <String, dynamic>{};
    if (json['route'] is Map) {
      routeData = Map<String, dynamic>.from(json['route'] as Map);
    } else if (json['busRoutes'] is List && (json['busRoutes'] as List).isNotEmpty) {
      final busRoutes = json['busRoutes'] as List;
      var selectedBusRoute = busRoutes.first;
      if (targetRouteId != null) {
        try {
          selectedBusRoute = busRoutes.firstWhere(
            (br) => br is Map && br['routeId']?.toString() == targetRouteId
          );
        } catch (_) {}
      }
      if (selectedBusRoute is Map && selectedBusRoute['route'] is Map) {
        routeData = Map<String, dynamic>.from(selectedBusRoute['route'] as Map);
      }
    }
    final stopsList = (routeData['stops'] as List? ?? []);
    final studentsList = (json['students'] as List? ?? []);
    final List<RouteStopModel> allStops = [];

    // Map to store counts of students per stop
    final Map<String, int> stopStudentCounts = {};
    for (var item in studentsList) {
      final student = Map<String, dynamic>.from(item as Map);
      final stopName = student['pickupStop'] ?? student['pickup_stop'];
      if (stopName != null) {
        stopStudentCounts[stopName] = (stopStudentCounts[stopName] ?? 0) + 1;
      }
    }

    // Add start point if available
    if (routeData['startPoint'] != null) {
      final name = routeData['startPoint'];
      allStops.add(
        RouteStopModel(
          name: name,
          latitude: (routeData['startLat'] ?? 0.0).toDouble(),
          longitude: (routeData['startLng'] ?? 0.0).toDouble(),
          type: 'passed', // Assuming it's the start
          studentCount: stopStudentCounts[name],
        ),
      );
    }

    // Parse active trip data if available
    final Map<String, Map<String, dynamic>> passedStopsMap = {};
    final Set<String> allBoardedStudentIds = {};
    if (trips.isNotEmpty) {
      final activeTrip = trips[0];
      final passedList = (activeTrip['passedStops'] as List? ?? []);
      for (var s in passedList) {
        final sMap = Map<String, dynamic>.from(s as Map);
        if (sMap['name'] != null) {
          passedStopsMap[sMap['name']] = sMap;
          
          // Collect all student IDs that have boarded during this trip
          final studentIds = sMap['studentIds'] as List? ?? [];
          for (var id in studentIds) {
            if (id != null) allBoardedStudentIds.add(id.toString());
          }
        }
      }
    }

    // Add intermediate stops
    allStops.addAll(
      stopsList.map(
        (s) {
          final name = s['name'] ?? '';
          final isPassedInTrip = passedStopsMap.containsKey(name);
          final tripData = passedStopsMap[name];
          
          int? boardedCount;
          if (isPassedInTrip) {
            boardedCount = tripData?['boarded'] as int?;
          } else {
            boardedCount = s['boardedStudentCount'] ?? s['boarded_count'] as int?;
          }

          return RouteStopModel(
            name: name,
            latitude: (s['lat'] ?? s['latitude'] ?? 0.0).toDouble(),
            longitude: (s['lng'] ?? s['longitude'] ?? 0.0).toDouble(),
            type: (tripData?['isSkipped'] == true) 
                ? 'skipped' 
                : (isPassedInTrip ? 'passed' : (s['type'] ?? 'future')),
            studentCount: stopStudentCounts[name] ?? s['studentCount'] ?? s['students_count'],
            boardedStudentCount: boardedCount,
            scheduledTime: s['expectedTime'] ?? s['scheduledTime'] ?? s['arrival_time'] ?? s['arrivalTime'],
          );
        },
      ),
    );

    // Add end point if available
    if (routeData['endPoint'] != null) {
      final name = routeData['endPoint'];
      allStops.add(
        RouteStopModel(
          name: name,
          latitude: (routeData['endLat'] ?? 0.0).toDouble(),
          longitude: (routeData['endLng'] ?? 0.0).toDouble(),
          type: 'future',
          studentCount: stopStudentCounts[name],
        ),
      );
    }

    return BusRouteModel(
      isTripActive: trips.isNotEmpty,
      id: json['id'] ?? '',
      busNumber: json['busNumber'] ?? json['bus_number'] ?? '',
      currentLocation: json['currentLocation'] ?? json['current_location'] ?? 'Unknown',
      nextStop:
          json['nextStop'] ??
          json['next_stop'] ??
          (stopsList.isNotEmpty ? stopsList[0]['name'] ?? '' : 'No stops'),
      startPoint: routeData['startPoint'] ?? json['startPoint'],
      endPoint: routeData['endPoint'] ?? json['endPoint'],
      arrivalTimeMinutes: json['arrivalTimeMinutes'] ?? 0,
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      isOnTime: json['isOnTime'] ?? true,
      driverPhone: (json['driver']?['phone'] ?? json['driverPhone'] ?? ''),
      driverName: json['driver']?['name'],
      driverPhoto: json['driver']?['photoUrl'] ?? json['driver']?['photo'],
      capacity: json['capacity'],
      collegeName: json['college']?['name'],
      busPosition: json['busPosition'] != null
          ? BusPositionModel.fromJson(Map<String, dynamic>.from(json['busPosition'] as Map))
          : json['bus_position'] != null
          ? BusPositionModel.fromJson(Map<String, dynamic>.from(json['bus_position'] as Map))
          : BusPositionModel(
              latitude:
                  (json['currentLat'] ??
                          routeData['startLat'] ??
                          (allStops.isNotEmpty ? allStops[0].latitude : 0.0))
                      .toDouble(),
              longitude:
                  (json['currentLng'] ??
                          routeData['startLng'] ??
                          (allStops.isNotEmpty ? allStops[0].longitude : 0.0))
                      .toDouble(),
              bearing: 0,
            ),
      stops: allStops,
      routePath: _parseRoutePath(json, routeData),
      students: studentsList.map((e) {
        final student = Map<String, dynamic>.from(e as Map);
        final id = student['id']?.toString();
        if (id != null && allBoardedStudentIds.contains(id)) {
          return {
            ...student,
            'isBoarded': true,
          };
        }
        return student;
      }).toList(),
    );
  }

  static List<RoutePointModel> _parseRoutePath(Map<String, dynamic> json, Map<String, dynamic> routeData) {
    // Try multiple possible field names from different backend versions
    final pathData = routeData['path'] ?? 
                    routeData['routePath'] ?? 
                    routeData['geometry'] ??
                    json['routePath'] ?? 
                    json['path'];
    
    if (pathData is List && pathData.isNotEmpty) {
      return pathData.map((p) => RoutePointModel.fromJson(Map<String, dynamic>.from(p as Map))).toList();
    }
    
    return [];
  }

  BusRoute toEntity() {
    return BusRoute(
      id: id,
      busNumber: busNumber,
      currentLocation: currentLocation,
      nextStop: nextStop,
      startPoint: startPoint,
      endPoint: endPoint,
      arrivalTimeMinutes: arrivalTimeMinutes,
      distanceKm: distanceKm,
      isOnTime: isOnTime,
      driverPhone: driverPhone,
      driverName: driverName,
      driverPhoto: driverPhoto,
      capacity: capacity,
      collegeName: collegeName,
      busPosition: busPosition.toEntity(),
      stops: stops.map((s) => s.toEntity(currentLocation)).toList(),
      routePath: routePath.map((p) => p.toEntity()).toList(),
      isTripActive: isTripActive,
      students: students,
    );
  }
}

@freezed
class BusPositionModel with _$BusPositionModel {
  const BusPositionModel._();

  const factory BusPositionModel({
    required double latitude,
    required double longitude,
    required double bearing,
    String? currentLocation,
    String? nextStop,
    bool? isOnTime,
    int? delayMinutes,
    List<Map<String, dynamic>>? students,
  }) = _BusPositionModel;

  factory BusPositionModel.fromJson(Map<String, dynamic> json) =>
      _$BusPositionModelFromJson(json);

  BusPosition toEntity() {
    return BusPosition(
      latitude: latitude,
      longitude: longitude,
      bearing: bearing,
      currentLocation: currentLocation,
      nextStop: nextStop,
      isOnTime: isOnTime,
      delayMinutes: delayMinutes,
      students: students,
    );
  }
}

@freezed
class RouteStopModel with _$RouteStopModel {
  const RouteStopModel._();

  const factory RouteStopModel({
    required String name,
    required double latitude,
    required double longitude,
    required String type,
    int? estimatedArrivalMinutes,
    int? studentCount,
    int? boardedStudentCount,
    String? scheduledTime,
  }) = _RouteStopModel;

  factory RouteStopModel.fromJson(Map<String, dynamic> json) =>
      _$RouteStopModelFromJson(json);

  RouteStop toEntity(String busCurrentLocation) {
    return RouteStop(
      name: name,
      latitude: latitude,
      longitude: longitude,
      type: name == busCurrentLocation ? StopType.currentLocation : _parseStopType(type),
      estimatedArrivalMinutes: estimatedArrivalMinutes,
      studentCount: studentCount,
      boardedStudentCount: boardedStudentCount,
      scheduledTime: scheduledTime,
    );
  }

  StopType _parseStopType(String type) {
    switch (type.toLowerCase()) {
      case 'current':
        return StopType.currentLocation;
      case 'next':
        return StopType.nextStop;
      case 'future':
        return StopType.futureStop;
      case 'passed':
        return StopType.passedStop;
      case 'skipped':
        return StopType.skippedStop;
      default:
        return StopType.futureStop;
    }
  }
}

@freezed
class RoutePointModel with _$RoutePointModel {
  const RoutePointModel._();

  const factory RoutePointModel({
    required double latitude,
    required double longitude,
  }) = _RoutePointModel;

  factory RoutePointModel.fromJson(Map<String, dynamic> json) {
    return RoutePointModel(
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
    );
  }

  RoutePoint toEntity() {
    return RoutePoint(latitude: latitude, longitude: longitude);
  }
}

@freezed
class BusSummaryModel with _$BusSummaryModel {
  const BusSummaryModel._();

  const factory BusSummaryModel({
    required String id,
    required String busNumber,
    required double latitude,
    required double longitude,
    required String status,
    required bool isDelayed,
    List<RouteStopModel>? routeStops,
  }) = _BusSummaryModel;

  factory BusSummaryModel.fromJson(Map<String, dynamic> json) {
    List<RouteStopModel>? stops;
    
    // Check legacy 'route' first, then 'busRoutes' array
    Map<String, dynamic>? routeObj;
    if (json['route'] is Map) {
      routeObj = Map<String, dynamic>.from(json['route'] as Map);
    } else if (json['busRoutes'] is List && (json['busRoutes'] as List).isNotEmpty) {
      final firstBusRoute = (json['busRoutes'] as List).first;
      if (firstBusRoute is Map && firstBusRoute['route'] is Map) {
        routeObj = Map<String, dynamic>.from(firstBusRoute['route'] as Map);
      }
    }

    if (routeObj != null && routeObj['stops'] != null) {
      final stopsList = routeObj['stops'] as List? ?? [];
      stops = stopsList.map((s) => RouteStopModel(
        name: s['name'] ?? '',
        latitude: (s['lat'] ?? s['latitude'] ?? 0.0).toDouble(),
        longitude: (s['lng'] ?? s['longitude'] ?? 0.0).toDouble(),
        type: s['type'] ?? 'future',
      )).toList();
    }

    return BusSummaryModel(
      id: json['id'] ?? '',
      busNumber:
          json['busNumber'] ??
          json['bus_number'] ??
          json['number'] ??
          'Unknown',
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      status:
          json['status'] ??
          (json['is_delayed'] == true || json['isDelayed'] == true
              ? 'Delayed'
              : 'On Time'),
      isDelayed: json['isDelayed'] ?? json['is_delayed'] ?? false,
      routeStops: stops,
    );
  }

  BusSummary toEntity() {
    return BusSummary(
      id: id,
      busNumber: busNumber,
      latitude: latitude,
      longitude: longitude,
      status: status,
      isDelayed: isDelayed,
      routeStops: routeStops?.map((s) => s.toEntity(status)).toList(),
    );
  }
}
