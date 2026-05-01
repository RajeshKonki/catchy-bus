import '../../domain/entities/bus_route.dart';

class BusRouteModel {
  final String id;
  final String busNumber;
  final String currentLocation;
  final String nextStop;
  final String? startPoint;
  final String? endPoint;
  final int arrivalTimeMinutes;
  final double distanceKm;
  final bool isOnTime;
  final String driverPhone;
  final String? driverName;
  final String? driverPhoto;
  final int? capacity;
  final String? collegeName;
  final BusPositionModel busPosition;
  final List<RouteStopModel> stops;
  final List<RoutePointModel> routePath;
  final String? routeName;
  final bool isTripActive;
  final bool isReverse;
  final List<Map<String, dynamic>> students;

  const BusRouteModel({
    required this.id,
    required this.busNumber,
    required this.currentLocation,
    required this.nextStop,
    this.startPoint,
    this.endPoint,
    required this.arrivalTimeMinutes,
    required this.distanceKm,
    required this.isOnTime,
    required this.driverPhone,
    this.driverName,
    this.driverPhoto,
    this.capacity,
    this.collegeName,
    required this.busPosition,
    required this.stops,
    required this.routePath,
    this.routeName,
    this.isTripActive = false,
    this.isReverse = false,
    this.students = const [],
  });

  factory BusRouteModel.fromJson(Map<String, dynamic> json, {String? preferredRouteId}) {
    final trips = (json['trips'] as List? ?? []);
    final activeTripRouteId = trips.isNotEmpty ? trips[0]['routeId']?.toString() : null;
    final targetRouteId = activeTripRouteId ?? preferredRouteId;

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

    final Map<String, int> stopStudentCounts = {};
    for (var item in studentsList) {
      final student = Map<String, dynamic>.from(item as Map);
      final stopName = student['pickupStop'] ?? student['pickup_stop'];
      if (stopName != null) {
        stopStudentCounts[stopName] = (stopStudentCounts[stopName] ?? 0) + 1;
      }
    }

    if (routeData['startPoint'] != null) {
      final name = routeData['startPoint'];
      allStops.add(
        RouteStopModel(
          name: name,
          latitude: (routeData['startLat'] ?? 0.0).toDouble(),
          longitude: (routeData['startLng'] ?? 0.0).toDouble(),
          type: 'passed',
          studentCount: stopStudentCounts[name],
        ),
      );
    }

    final Map<String, Map<String, dynamic>> passedStopsMap = {};
    final Set<String> allBoardedStudentIds = {};
    if (trips.isNotEmpty) {
      final activeTrip = trips[0];
      final passedList = (activeTrip['passedStops'] as List? ?? []);
      for (var s in passedList) {
        final sMap = Map<String, dynamic>.from(s as Map);
        if (sMap['name'] != null) {
          passedStopsMap[sMap['name']] = sMap;
          final studentIds = sMap['studentIds'] as List? ?? [];
          for (var id in studentIds) {
            if (id != null) allBoardedStudentIds.add(id.toString());
          }
        }
      }
    }

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
      routeName: routeData['name'] ?? routeData['title'],
      isTripActive: json['isTripActive'] ?? trips.isNotEmpty,
      isReverse: () {
        if (json['isReverse'] != null) return json['isReverse'] as bool;
        if (json['is_reverse'] != null) return json['is_reverse'] as bool;
        
        if (trips.isNotEmpty) {
          // If a preferred route is specified, use its direction
          if (preferredRouteId != null) {
            final prefTrip = trips.firstWhere(
              (t) => t['routeId']?.toString() == preferredRouteId,
              orElse: () => null,
            );
            if (prefTrip != null) return prefTrip['isReverse'] == true || prefTrip['is_reverse'] == true;
          }
          
          // Fallback to the first active trip
          final activeTrip = trips.firstWhere(
            (t) => t['status'] == 'STARTED',
            orElse: () => trips[0],
          );
          return activeTrip['isReverse'] == true || activeTrip['is_reverse'] == true;
        }
        return false;
      }(),
      id: json['id']?.toString() ?? '',
      busNumber: json['busNumber'] ?? json['bus_number'] ?? '',
      currentLocation: json['currentLocation'] ?? json['current_location'] ?? 'Unknown',
      nextStop: json['nextStop'] ?? json['next_stop'] ?? (stopsList.isNotEmpty ? stopsList[0]['name'] ?? '' : 'No stops'),
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
              latitude: (json['currentLat'] ?? routeData['startLat'] ?? (allStops.isNotEmpty ? allStops[0].latitude : 0.0)).toDouble(),
              longitude: (json['currentLng'] ?? routeData['startLng'] ?? (allStops.isNotEmpty ? allStops[0].longitude : 0.0)).toDouble(),
              bearing: 0,
            ),
      stops: allStops,
      routePath: _parseRoutePath(json, routeData),
      students: studentsList.map((e) {
        final student = Map<String, dynamic>.from(e as Map);
        final id = student['id']?.toString();
        if (id != null && allBoardedStudentIds.contains(id)) {
          return {...student, 'isBoarded': true};
        }
        return student;
      }).toList(),
    );
  }

  static List<RoutePointModel> _parseRoutePath(Map<String, dynamic> json, Map<String, dynamic> routeData) {
    final pathData = routeData['path'] ?? routeData['routePath'] ?? routeData['geometry'] ?? json['routePath'] ?? json['path'];
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
      routeName: routeName,
      isTripActive: isTripActive,
      isReverse: isReverse,
      students: students,
    );
  }
}

class BusPositionModel {
  final double latitude;
  final double longitude;
  final double bearing;
  final String? currentLocation;
  final String? nextStop;
  final bool? isOnTime;
  final int? delayMinutes;
  final bool? isTripActive;
  final bool? isReverse;
  final List<Map<String, dynamic>>? students;

  const BusPositionModel({
    required this.latitude,
    required this.longitude,
    required this.bearing,
    this.currentLocation,
    this.nextStop,
    this.isOnTime,
    this.delayMinutes,
    this.isTripActive,
    this.isReverse,
    this.students,
  });

  factory BusPositionModel.fromJson(Map<String, dynamic> json) {
    return BusPositionModel(
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      bearing: (json['bearing'] ?? 0.0).toDouble(),
      currentLocation: json['currentLocation'] ?? json['current_location'],
      nextStop: json['nextStop'] ?? json['next_stop'],
      isOnTime: json['isOnTime'] ?? json['is_on_time'],
      delayMinutes: json['delayMinutes'] ?? json['delay_minutes'],
      isTripActive: json['isTripActive'] ?? json['is_trip_active'],
      isReverse: json['isReverse'] ?? json['is_reverse'],
      students: json['students'] != null 
          ? (json['students'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : null,
    );
  }

  BusPosition toEntity() {
    return BusPosition(
      latitude: latitude,
      longitude: longitude,
      bearing: bearing,
      currentLocation: currentLocation,
      nextStop: nextStop,
      isOnTime: isOnTime,
      delayMinutes: delayMinutes,
      isTripActive: isTripActive,
      isReverse: isReverse,
      students: students,
    );
  }
}

class RouteStopModel {
  final String name;
  final double latitude;
  final double longitude;
  final String type;
  final int? estimatedArrivalMinutes;
  final int? studentCount;
  final int? boardedStudentCount;
  final String? scheduledTime;

  const RouteStopModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.estimatedArrivalMinutes,
    this.studentCount,
    this.boardedStudentCount,
    this.scheduledTime,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      name: json['name'] ?? '',
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'future',
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'],
      studentCount: json['studentCount'],
      boardedStudentCount: json['boardedStudentCount'],
      scheduledTime: json['scheduledTime'],
    );
  }

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
      case 'current': return StopType.currentLocation;
      case 'next': return StopType.nextStop;
      case 'future': return StopType.futureStop;
      case 'passed': return StopType.passedStop;
      case 'skipped': return StopType.skippedStop;
      default: return StopType.futureStop;
    }
  }
}

class RoutePointModel {
  final double latitude;
  final double longitude;

  const RoutePointModel({
    required this.latitude,
    required this.longitude,
  });

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

class BusSummaryModel {
  final String id;
  final String busNumber;
  final double latitude;
  final double longitude;
  final String status;
  final bool isDelayed;
  final List<RouteStopModel>? routeStops;

  const BusSummaryModel({
    required this.id,
    required this.busNumber,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.isDelayed,
    this.routeStops,
  });

  factory BusSummaryModel.fromJson(Map<String, dynamic> json) {
    List<RouteStopModel>? stops;
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
      id: json['id']?.toString() ?? '',
      busNumber: json['busNumber'] ?? json['bus_number'] ?? json['number'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Unknown',
      isDelayed: json['isDelayed'] ?? false,
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
    );
  }
}
