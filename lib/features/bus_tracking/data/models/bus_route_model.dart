import '../../domain/entities/bus_route.dart';
import '../../domain/entities/trip_direction.dart';

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
  final List<RoutePointModel>? reverseRoutePath;
  final String? routeName;
  final bool isTripActive;
  final TripDirection tripDirection;
  final bool isReverse;
  final List<Map<String, dynamic>> students;
  final String? tripStatus;
  final String? cancelReason;

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
    this.reverseRoutePath,
    this.routeName,
    this.isTripActive = false,
    this.tripDirection = TripDirection.forward,
    this.isReverse = false,
    this.students = const [],
    this.tripStatus,
    this.cancelReason,
  });

  factory BusRouteModel.fromJson(
    Map<String, dynamic> json, {
    String? preferredRouteId,
  }) {
    final trips = (json['trips'] as List? ?? []);

    // Find the most recently active trip
    final activeTrip = () {
      final startedTrips = trips
          .where((t) => t['status']?.toString().toUpperCase() == 'STARTED')
          .toList();
      if (startedTrips.isEmpty) return null;

      startedTrips.sort((a, b) {
        final aTime =
            DateTime.tryParse(
              a['updated_at']?.toString() ?? a['created_at']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            DateTime.tryParse(
              b['updated_at']?.toString() ?? b['created_at']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return startedTrips.first;
    }();

    final TripDirection tripDirection = () {
      // 1. If there is an active trip, we MUST trust the active trip's direction!
      if (activeTrip != null) {
        final dir = activeTrip['direction']?.toString().toUpperCase();
        final type = activeTrip['type']?.toString().toUpperCase();
        if (dir == 'REVERSE' ||
            dir == 'RETURN' ||
            dir == 'BACKWARD' ||
            type == 'REVERSE' ||
            type == 'RETURN' ||
            activeTrip['isReverse'] == true ||
            activeTrip['is_reverse'] == true) {
          return TripDirection.reverse;
        }
        return TripDirection.forward;
      }

      // 2. If a preferred route is specified, use its direction from trips
      if (preferredRouteId != null && trips.isNotEmpty) {
        final prefTrip = trips.firstWhere(
          (t) => t['routeId']?.toString() == preferredRouteId,
          orElse: () => null,
        );
        if (prefTrip != null) {
          if (prefTrip['direction']?.toString().toUpperCase() == 'REVERSE' ||
              prefTrip['isReverse'] == true ||
              prefTrip['is_reverse'] == true) {
            return TripDirection.reverse;
          }
        }
      }

      // 3. Fallback to main JSON direction field
      final mainDir = json['direction']?.toString().toUpperCase();
      if (mainDir == 'REVERSE' || mainDir == 'RETURN')
        return TripDirection.reverse;
      if (mainDir == 'FORWARD') return TripDirection.forward;

      if (json['isReverse'] != null)
        return json['isReverse'] == true
            ? TripDirection.reverse
            : TripDirection.forward;
      if (json['is_reverse'] != null)
        return json['is_reverse'] == true
            ? TripDirection.reverse
            : TripDirection.forward;

      // 4. Fallback to first trip direction
      if (trips.isNotEmpty) {
        final firstDir = trips[0]['direction']?.toString().toUpperCase();
        if (firstDir == 'REVERSE' ||
            trips[0]['isReverse'] == true ||
            trips[0]['is_reverse'] == true) {
          return TripDirection.reverse;
        }
      }
      return TripDirection.forward;
    }();

    final bool isReverse = tripDirection.isReverse;

    // Find target trip (active or fallback to the first one that matches the determined direction)
    final targetTrip = () {
      if (trips.isNotEmpty) {
        // First try to find a STARTED trip that matches our direction
        final matchingActive = trips.where((t) {
          final String? dir = t['direction']?.toString().toUpperCase();
          final String? type = t['type']?.toString().toUpperCase();
          final bool tIsReverse =
              t['isReverse'] == true ||
              t['is_reverse'] == true ||
              dir == 'REVERSE' ||
              dir == 'RETURN' ||
              dir == 'BACKWARD' ||
              type == 'REVERSE' ||
              type == 'RETURN';
          return t['status']?.toString().toUpperCase() == 'STARTED' && tIsReverse == isReverse;
        }).toList();
        if (matchingActive.isNotEmpty) return matchingActive[0];
      }
      return null;
    }();

    final activeTripRouteId = activeTrip != null
        ? activeTrip['routeId']?.toString()
        : null;
    final targetRouteId = activeTripRouteId ?? preferredRouteId;

    Map<String, dynamic> routeData = <String, dynamic>{};
    if (json['route'] is Map) {
      routeData = Map<String, dynamic>.from(json['route'] as Map);
    } else if (json['busRoutes'] is List &&
        (json['busRoutes'] as List).isNotEmpty) {
      final busRoutes = json['busRoutes'] as List;
      var selectedBusRoute = busRoutes.first;
      if (targetRouteId != null) {
        try {
          selectedBusRoute = busRoutes.firstWhere(
            (br) => br is Map && br['routeId']?.toString() == targetRouteId,
          );
        } catch (_) {}
      }
      if (selectedBusRoute is Map && selectedBusRoute['route'] is Map) {
        routeData = Map<String, dynamic>.from(selectedBusRoute['route'] as Map);
      }
    }
    final stopsList = (routeData['stops'] as List? ?? []);
    final studentsList = (json['students'] as List? ?? []);
    List<RouteStopModel> allStops = [];

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
          type: isReverse ? 'future' : 'passed',
          studentCount: stopStudentCounts[name],
        ),
      );
    }

    final Map<String, Map<String, dynamic>> passedStopsMap = {};
    final Set<String> allBoardedStudentIds = {};
    if (targetTrip != null) {
      final passedList = (targetTrip['passedStops'] as List? ?? []);
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
      stopsList.map((s) {
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
          reverseLatitude: s['reverseLat'] != null
              ? (s['reverseLat'] as num).toDouble()
              : null,
          reverseLongitude: s['reverseLng'] != null
              ? (s['reverseLng'] as num).toDouble()
              : null,
          type: (tripData?['isSkipped'] == true)
              ? 'skipped'
              : (isPassedInTrip ? 'passed' : (s['type'] ?? 'future')),
          studentCount:
              stopStudentCounts[name] ??
              s['studentCount'] ??
              s['students_count'],
          boardedStudentCount: boardedCount,
          scheduledTime:
              s['expectedTime'] ??
              s['scheduledTime'] ??
              s['arrival_time'] ??
              s['arrivalTime'],
        );
      }),
    );

    if (routeData['endPoint'] != null) {
      final name = routeData['endPoint'];
      allStops.add(
        RouteStopModel(
          name: name,
          latitude: (routeData['endLat'] ?? 0.0).toDouble(),
          longitude: (routeData['endLng'] ?? 0.0).toDouble(),
          type: isReverse ? 'passed' : 'future',
          studentCount: stopStudentCounts[name],
        ),
      );
    }

    // Ensure sequential coherence of passed stops:
    // If a stop has been passed/skipped, then in travel order, all stops before it must also be passed.
    // NOTE: We intentionally check only stop.type here (NOT passedStopsMap directly) because
    // each stop's type is already resolved to 'passed' earlier (line ~221). Using the map again
    // as a fallback caused stops to be incorrectly swept as 'passed' on page refresh.
    int furthestPassedIdx = -1;
    if (!isReverse) {
      // Travel order: index 0 to allStops.length - 1
      for (int i = 0; i < allStops.length; i++) {
        final stop = allStops[i];
        final isPassedOrSkipped =
            stop.type == 'passed' || stop.type == 'skipped';
        if (isPassedOrSkipped) {
          furthestPassedIdx = i;
        }
      }
      if (furthestPassedIdx != -1) {
        for (int i = 0; i < furthestPassedIdx; i++) {
          if (allStops[i].type != 'skipped' && allStops[i].type != 'passed') {
            allStops[i] = allStops[i].copyWith(type: 'passed');
          }
        }
      }
    } else {
      // Travel order: index allStops.length - 1 down to 0
      for (int i = allStops.length - 1; i >= 0; i--) {
        final stop = allStops[i];
        final isPassedOrSkipped =
            stop.type == 'passed' || stop.type == 'skipped';
        if (isPassedOrSkipped) {
          furthestPassedIdx = i;
        }
      }
      if (furthestPassedIdx != -1) {
        for (int i = allStops.length - 1; i > furthestPassedIdx; i--) {
          if (allStops[i].type != 'skipped' && allStops[i].type != 'passed') {
            allStops[i] = allStops[i].copyWith(type: 'passed');
          }
        }
      }
    }

    if (isReverse) {
      allStops = allStops.reversed.toList();
    }

    return BusRouteModel(
      routeName: routeData['name'] ?? routeData['title'],
      isTripActive: (json['isTripActive'] == true || json['isTripActive']?.toString().toLowerCase() == 'true' || json['is_trip_active'] == true || json['is_trip_active']?.toString().toLowerCase() == 'true') || (activeTrip != null),
      tripDirection: tripDirection,
      isReverse: isReverse,
      id:
          json['id']?.toString() ??
          routeData['id']?.toString() ??
          targetRouteId ??
          '',
      busNumber: json['busNumber'] ?? json['bus_number'] ?? '',
      currentLocation:
          json['currentLocation'] ?? json['current_location'] ?? 'Unknown',
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
          ? BusPositionModel.fromJson(
              Map<String, dynamic>.from(json['busPosition'] as Map),
            )
          : json['bus_position'] != null
          ? BusPositionModel.fromJson(
              Map<String, dynamic>.from(json['bus_position'] as Map),
            )
          : BusPositionModel(
              latitude:
                  (json['latitude'] ??
                          json['lat'] ??
                          json['currentLat'] ??
                          routeData['startLat'] ??
                          (allStops.isNotEmpty ? allStops[0].latitude : 0.0))
                      .toDouble(),
              longitude:
                  (json['longitude'] ??
                          json['lng'] ??
                          json['currentLng'] ??
                          routeData['startLng'] ??
                          (allStops.isNotEmpty ? allStops[0].longitude : 0.0))
                      .toDouble(),
              bearing: (json['bearing'] ?? 0.0).toDouble(),
              currentLocation:
                  json['currentLocation'] ?? json['current_location'],
              nextStop: json['nextStop'] ?? json['next_stop'],
              isOnTime: json['isOnTime'] ?? json['is_on_time'],
              delayMinutes: json['delayMinutes'] ?? json['delay_minutes'],
              isTripActive: (json['isTripActive'] == true || json['isTripActive']?.toString().toLowerCase() == 'true' || json['is_trip_active'] == true || json['is_trip_active']?.toString().toLowerCase() == 'true') || (activeTrip != null),
              isReverse: isReverse,
            ),
      stops: allStops,
      routePath: isReverse
          ? (_parseReverseRoutePath(json, routeData) ??
                _parseRoutePath(json, routeData).reversed.toList())
          : _parseRoutePath(json, routeData),
      reverseRoutePath: _parseReverseRoutePath(json, routeData),
      students: studentsList.map((e) {
        final student = Map<String, dynamic>.from(e as Map);
        final id = student['id']?.toString();
        if (id != null && allBoardedStudentIds.contains(id)) {
          return {...student, 'isBoarded': true};
        }
        return student;
      }).toList(),
      tripStatus: targetTrip != null 
          ? targetTrip['status']?.toString() 
          : (activeTrip != null 
              ? activeTrip['status']?.toString() 
              : ((json['isTripActive'] == true || json['isTripActive']?.toString().toLowerCase() == 'true' || json['is_trip_active'] == true || json['is_trip_active']?.toString().toLowerCase() == 'true') ? 'STARTED' : null)),
      cancelReason: targetTrip != null
          ? (targetTrip['cancelReason'] ??
                    targetTrip['reason'] ??
                    targetTrip['cancel_reason'])
                ?.toString()
          : null,
    );
  }

  static List<RoutePointModel> _parseRoutePath(
    Map<String, dynamic> json,
    Map<String, dynamic> routeData,
  ) {
    final pathData =
        routeData['path'] ??
        routeData['routePath'] ??
        routeData['geometry'] ??
        json['routePath'] ??
        json['path'];
    if (pathData is List && pathData.isNotEmpty) {
      return pathData
          .map(
            (p) =>
                RoutePointModel.fromJson(Map<String, dynamic>.from(p as Map)),
          )
          .toList();
    }
    return [];
  }

  static List<RoutePointModel>? _parseReverseRoutePath(
    Map<String, dynamic> json,
    Map<String, dynamic> routeData,
  ) {
    final pathData =
        routeData['reversePath'] ??
        routeData['reverseRoutePath'] ??
        json['reversePath'] ??
        json['reverseRoutePath'];
    if (pathData is List && pathData.isNotEmpty) {
      return pathData
          .map(
            (p) =>
                RoutePointModel.fromJson(Map<String, dynamic>.from(p as Map)),
          )
          .toList();
    }
    return null;
  }

  BusRoute toEntity() {
    final mappedStops = stops.map((s) => s.toEntity(currentLocation)).toList();
    final mappedPath = routePath.map((p) => p.toEntity()).toList();
    final mappedReversePath = reverseRoutePath
        ?.map((p) => p.toEntity())
        .toList();

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
      stops: mappedStops,
      routePath: mappedPath,
      reverseRoutePath: mappedReversePath,
      routeName: routeName,
      isTripActive: isTripActive,
      tripDirection: tripDirection,
      students: students,
      tripStatus: tripStatus,
      cancelReason: cancelReason,
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
  final TripDirection? tripDirection;
  final bool? isReverse;
  final List<Map<String, dynamic>>? students;
  final double? transitProgress;
  final int? transitFromStopIndex;

  const BusPositionModel({
    required this.latitude,
    required this.longitude,
    required this.bearing,
    this.currentLocation,
    this.nextStop,
    this.isOnTime,
    this.delayMinutes,
    this.isTripActive,
    this.tripDirection,
    this.isReverse,
    this.students,
    this.transitProgress,
    this.transitFromStopIndex,
  });

  factory BusPositionModel.fromJson(Map<String, dynamic> json) {
    final String? dirStr =
        json['direction']?.toString().toUpperCase() ??
        json['tripDirection']?.toString().toUpperCase();
    TripDirection? tripDir;
    if (dirStr == 'REVERSE' || dirStr == 'RETURN' || dirStr == 'BACKWARD') {
      tripDir = TripDirection.reverse;
    } else if (dirStr == 'FORWARD') {
      tripDir = TripDirection.forward;
    }

    return BusPositionModel(
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      bearing: (json['bearing'] ?? 0.0).toDouble(),
      currentLocation: json['currentLocation'] ?? json['current_location'],
      nextStop: json['nextStop'] ?? json['next_stop'],
      isOnTime: json['isOnTime'] ?? json['is_on_time'],
      delayMinutes: json['delayMinutes'] ?? json['delay_minutes'],
      isTripActive: json['isTripActive'] ?? json['is_trip_active'],
      tripDirection: tripDir,
      isReverse: json['isReverse'] ?? json['is_reverse'],
      students: json['students'] != null
          ? (json['students'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
          : null,
      transitProgress: (json['transitProgress'] ?? json['transit_progress'])
          ?.toDouble(),
      transitFromStopIndex:
          json['transitFromStopIndex'] ?? json['transit_from_stop_index'],
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
      tripDirection: tripDirection,
      students: students,
      transitProgress: transitProgress,
      transitFromStopIndex: transitFromStopIndex,
    );
  }
}

class RouteStopModel {
  final String name;
  final double latitude;
  final double longitude;
  final double? reverseLatitude;
  final double? reverseLongitude;
  final String type;
  final int? estimatedArrivalMinutes;
  final int? studentCount;
  final int? boardedStudentCount;
  final String? scheduledTime;
  final int? logicalStopId;
  final int? forwardStopId;
  final int? reverseStopId;

  const RouteStopModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.reverseLatitude,
    this.reverseLongitude,
    required this.type,
    this.estimatedArrivalMinutes,
    this.studentCount,
    this.boardedStudentCount,
    this.scheduledTime,
    this.logicalStopId,
    this.forwardStopId,
    this.reverseStopId,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      name: json['name'] ?? '',
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      reverseLatitude: json['reverseLat'] != null
          ? (json['reverseLat'] as num).toDouble()
          : null,
      reverseLongitude: json['reverseLng'] != null
          ? (json['reverseLng'] as num).toDouble()
          : null,
      type: json['type'] ?? 'future',
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'],
      studentCount: json['studentCount'],
      boardedStudentCount: json['boardedStudentCount'],
      scheduledTime: json['scheduledTime'],
      logicalStopId: json['logicalStopId'],
      forwardStopId: json['forwardStopId'],
      reverseStopId: json['reverseStopId'],
    );
  }

  RouteStopModel copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? reverseLatitude,
    double? reverseLongitude,
    String? type,
    int? estimatedArrivalMinutes,
    int? studentCount,
    int? boardedStudentCount,
    String? scheduledTime,
    int? logicalStopId,
    int? forwardStopId,
    int? reverseStopId,
  }) {
    return RouteStopModel(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reverseLatitude: reverseLatitude ?? this.reverseLatitude,
      reverseLongitude: reverseLongitude ?? this.reverseLongitude,
      type: type ?? this.type,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      studentCount: studentCount ?? this.studentCount,
      boardedStudentCount: boardedStudentCount ?? this.boardedStudentCount,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      logicalStopId: logicalStopId ?? this.logicalStopId,
      forwardStopId: forwardStopId ?? this.forwardStopId,
      reverseStopId: reverseStopId ?? this.reverseStopId,
    );
  }

  RouteStop toEntity(String busCurrentLocation) {
    return RouteStop(
      name: name,
      latitude: latitude,
      longitude: longitude,
      reverseLatitude: reverseLatitude,
      reverseLongitude: reverseLongitude,
      type: name == busCurrentLocation
          ? StopType.currentLocation
          : _parseStopType(type),
      estimatedArrivalMinutes: estimatedArrivalMinutes,
      studentCount: studentCount,
      boardedStudentCount: boardedStudentCount,
      scheduledTime: scheduledTime,
      logicalStopId: logicalStopId,
      forwardStopId: forwardStopId,
      reverseStopId: reverseStopId,
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

class RoutePointModel {
  final double latitude;
  final double longitude;

  const RoutePointModel({required this.latitude, required this.longitude});

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
    } else if (json['busRoutes'] is List &&
        (json['busRoutes'] as List).isNotEmpty) {
      final firstBusRoute = (json['busRoutes'] as List).first;
      if (firstBusRoute is Map && firstBusRoute['route'] is Map) {
        routeObj = Map<String, dynamic>.from(firstBusRoute['route'] as Map);
      }
    }

    if (routeObj != null && routeObj['stops'] != null) {
      final stopsList = routeObj['stops'] as List? ?? [];
      stops = stopsList
          .map(
            (s) => RouteStopModel(
              name: s['name'] ?? '',
              latitude: (s['lat'] ?? s['latitude'] ?? 0.0).toDouble(),
              longitude: (s['lng'] ?? s['longitude'] ?? 0.0).toDouble(),
              type: s['type'] ?? 'future',
            ),
          )
          .toList();
    }

    return BusSummaryModel(
      id: json['id']?.toString() ?? '',
      busNumber:
          json['busNumber'] ?? json['bus_number'] ?? json['number'] ?? '',
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
      routeStops: routeStops?.map((s) => s.toEntity('')).toList(),
    );
  }
}
