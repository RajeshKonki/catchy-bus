import 'package:equatable/equatable.dart';

/// Entity representing a bus route with tracking information
class BusRoute extends Equatable {
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
  final BusPosition busPosition;
  final List<RouteStop> stops;
  final List<RoutePoint> routePath;
  final String? routeName;
  final bool isTripActive;
  final bool isReverse;
  final List<Map<String, dynamic>> students;
  /// 0.0 = at fromStop, 1.0 = at nextStop. -1 = at a stop (not in transit)
  final double transitProgress;
  /// Index of the stop the bus just left. -1 if not in transit.
  final int transitFromStopIndex;

  const BusRoute({
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
    this.transitProgress = -1.0,
    this.transitFromStopIndex = -1,
  });

  @override
  List<Object?> get props => [
    id,
    busNumber,
    currentLocation,
    nextStop,
    startPoint,
    endPoint,
    arrivalTimeMinutes,
    distanceKm,
    isOnTime,
    driverPhone,
    driverName,
    driverPhoto,
    capacity,
    collegeName,
    busPosition,
    stops,
    routePath,
    routeName,
    isTripActive,
    isReverse,
    students,
    transitProgress,
    transitFromStopIndex,
  ];

  BusRoute copyWith({
    String? id,
    String? busNumber,
    String? currentLocation,
    String? nextStop,
    String? startPoint,
    String? endPoint,
    int? arrivalTimeMinutes,
    double? distanceKm,
    bool? isOnTime,
    String? driverPhone,
    String? driverName,
    String? driverPhoto,
    int? capacity,
    String? collegeName,
    BusPosition? busPosition,
    List<RouteStop>? stops,
    List<RoutePoint>? routePath,
    String? routeName,
    bool? isTripActive,
    bool? isReverse,
    List<Map<String, dynamic>>? students,
    double? transitProgress,
    int? transitFromStopIndex,
  }) {
    return BusRoute(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      currentLocation: currentLocation ?? this.currentLocation,
      nextStop: nextStop ?? this.nextStop,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      arrivalTimeMinutes: arrivalTimeMinutes ?? this.arrivalTimeMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      isOnTime: isOnTime ?? this.isOnTime,
      driverPhone: driverPhone ?? this.driverPhone,
      driverName: driverName ?? this.driverName,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      capacity: capacity ?? this.capacity,
      collegeName: collegeName ?? this.collegeName,
      busPosition: busPosition ?? this.busPosition,
      stops: stops ?? this.stops,
      routePath: routePath ?? this.routePath,
      routeName: routeName ?? this.routeName,
      isTripActive: isTripActive ?? this.isTripActive,
      isReverse: isReverse ?? this.isReverse,
      students: students ?? this.students,
      transitProgress: transitProgress ?? this.transitProgress,
      transitFromStopIndex: transitFromStopIndex ?? this.transitFromStopIndex,
    );
  }
}

/// Entity representing a bus position on the map
class BusPosition extends Equatable {
  final double latitude;
  final double longitude;
  final double bearing; // Direction the bus is facing
  final String? currentLocation;
  final String? nextStop;
  final bool? isOnTime;
  final int? delayMinutes;
  final bool? isTripActive;
  final bool? isReverse;
  final List<Map<String, dynamic>>? students;
  
  const BusPosition({
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

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    bearing,
    currentLocation,
    nextStop,
    isOnTime,
    delayMinutes,
    isTripActive,
    isReverse,
    students,
  ];

  BusPosition copyWith({
    double? latitude,
    double? longitude,
    double? bearing,
    String? currentLocation,
    String? nextStop,
    bool? isOnTime,
    int? delayMinutes,
    List<Map<String, dynamic>>? students,
  }) {
    return BusPosition(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bearing: bearing ?? this.bearing,
      currentLocation: currentLocation ?? this.currentLocation,
      nextStop: nextStop ?? this.nextStop,
      isOnTime: isOnTime ?? this.isOnTime,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      students: students ?? this.students,
    );
  }
}

/// Entity representing a stop on the route
class RouteStop extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final StopType type;
  final int? estimatedArrivalMinutes;
  final int? studentCount;
  final DateTime? actualArrivalTime;
  final DateTime? actualDepartureTime;
  final int? boardedStudentCount;
  final String? scheduledTime; // Planned time, e.g., "08:30 AM"


  const RouteStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.estimatedArrivalMinutes,
    this.studentCount,
    this.actualArrivalTime,
    this.actualDepartureTime,
    this.boardedStudentCount,
    this.scheduledTime,
  });

  @override
  List<Object?> get props => [
    name,
    latitude,
    longitude,
    type,
    estimatedArrivalMinutes,
    studentCount,
    actualArrivalTime,
    actualDepartureTime,
    boardedStudentCount,
    scheduledTime,
  ];

  RouteStop copyWith({
    String? name,
    double? latitude,
    double? longitude,
    StopType? type,
    int? estimatedArrivalMinutes,
    int? studentCount,
    DateTime? actualArrivalTime,
    DateTime? actualDepartureTime,
    int? boardedStudentCount,
    String? scheduledTime,
  }) {
    return RouteStop(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      studentCount: studentCount ?? this.studentCount,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      actualDepartureTime: actualDepartureTime ?? this.actualDepartureTime,
      boardedStudentCount: boardedStudentCount ?? this.boardedStudentCount,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  /// Calculates the delay in minutes compared to scheduled time
  int get delayMinutes {
    if (scheduledTime == null || estimatedArrivalMinutes == null) return 0;
    
    try {
      // Parse scheduled time (assuming "HH:mm AM/PM" format)
      final now = DateTime.now();
      final parts = scheduledTime!.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      
      final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      final estimatedDateTime = now.add(Duration(minutes: estimatedArrivalMinutes!));
      
      final diff = estimatedDateTime.difference(scheduledDateTime).inMinutes;
      return diff > 0 ? diff : 0;
    } catch (e) {
      return 0;
    }
  }
}


/// Entity representing a point on the route path
class RoutePoint extends Equatable {
  final double latitude;
  final double longitude;

  const RoutePoint({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Enum for stop types
enum StopType { currentLocation, nextStop, futureStop, passedStop, skippedStop }

/// Summary of a bus for the selection list
class BusSummary extends Equatable {
  final String id;
  final String busNumber;
  final double latitude;
  final double longitude;
  final String status;
  final bool isDelayed;
  final double? distance; // Distance from student in km
  final List<RouteStop>? routeStops;

  const BusSummary({
    required this.id,
    required this.busNumber,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.isDelayed,
    this.distance,
    this.routeStops,
  });

  @override
  List<Object?> get props => [
    id,
    busNumber,
    latitude,
    longitude,
    status,
    isDelayed,
    distance,
    routeStops,
  ];

  BusSummary copyWith({
    String? id,
    String? busNumber,
    double? latitude,
    double? longitude,
    String? status,
    bool? isDelayed,
    double? distance,
    List<RouteStop>? routeStops,
  }) {
    return BusSummary(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      isDelayed: isDelayed ?? this.isDelayed,
      distance: distance ?? this.distance,
      routeStops: routeStops ?? this.routeStops,
    );
  }
}
