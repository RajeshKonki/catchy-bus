import 'package:equatable/equatable.dart';
import 'trip_direction.dart';

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
  final List<RoutePoint>? reverseRoutePath;
  final String? routeName;
  final bool isTripActive;
  final TripDirection tripDirection;
  final List<Map<String, dynamic>> students;
  /// 0.0 = at fromStop, 1.0 = at nextStop. -1 = at a stop (not in transit)
  final double transitProgress;
  /// Index of the stop the bus just left. -1 if not in transit.
  final int transitFromStopIndex;
  final String? tripStatus;
  final String? cancelReason;

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
    this.reverseRoutePath,
    this.routeName,
    this.isTripActive = false,
    this.tripDirection = TripDirection.forward,
    this.students = const [],
    this.transitProgress = -1.0,
    this.transitFromStopIndex = -1,
    this.tripStatus,
    this.cancelReason,
  });

  bool get isReverse => tripDirection.isReverse;

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
    reverseRoutePath,
    routeName,
    isTripActive,
    tripDirection,
    students,
    transitProgress,
    transitFromStopIndex,
    tripStatus,
    cancelReason,
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
    List<RoutePoint>? reverseRoutePath,
    String? routeName,
    bool? isTripActive,
    TripDirection? tripDirection,
    bool? isReverse, // Helper for backwards compatibility
    List<Map<String, dynamic>>? students,
    double? transitProgress,
    int? transitFromStopIndex,
    String? tripStatus,
    String? cancelReason,
  }) {
    final newDirection = tripDirection ?? 
                         (isReverse != null ? (isReverse ? TripDirection.reverse : TripDirection.forward) : this.tripDirection);
    
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
      reverseRoutePath: reverseRoutePath ?? this.reverseRoutePath,
      routeName: routeName ?? this.routeName,
      isTripActive: isTripActive ?? this.isTripActive,
      tripDirection: newDirection,
      students: students ?? this.students,
      transitProgress: transitProgress ?? this.transitProgress,
      transitFromStopIndex: transitFromStopIndex ?? this.transitFromStopIndex,
      tripStatus: tripStatus ?? this.tripStatus,
      cancelReason: cancelReason ?? this.cancelReason,
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
  final TripDirection? tripDirection;
  final List<Map<String, dynamic>>? students;
  final double? transitProgress;
  final int? transitFromStopIndex;

  const BusPosition({
    required this.latitude,
    required this.longitude,
    required this.bearing,
    this.currentLocation,
    this.nextStop,
    this.isOnTime,
    this.delayMinutes,
    this.isTripActive,
    this.tripDirection,
    this.students,
    this.transitProgress,
    this.transitFromStopIndex,
  });

  bool get isReverse => tripDirection?.isReverse ?? false;

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
    tripDirection,
    students,
    transitProgress,
    transitFromStopIndex,
  ];

  BusPosition copyWith({
    double? latitude,
    double? longitude,
    double? bearing,
    String? currentLocation,
    String? nextStop,
    bool? isOnTime,
    int? delayMinutes,
    bool? isTripActive,
    TripDirection? tripDirection,
    bool? isReverse, // Helper
    List<Map<String, dynamic>>? students,
    double? transitProgress,
    int? transitFromStopIndex,
  }) {
    final newDirection = tripDirection ?? 
                         (isReverse != null ? (isReverse ? TripDirection.reverse : TripDirection.forward) : this.tripDirection);

    return BusPosition(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bearing: bearing ?? this.bearing,
      currentLocation: currentLocation ?? this.currentLocation,
      nextStop: nextStop ?? this.nextStop,
      isOnTime: isOnTime ?? this.isOnTime,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      isTripActive: isTripActive ?? this.isTripActive,
      tripDirection: newDirection,
      students: students ?? this.students,
      transitProgress: transitProgress ?? this.transitProgress,
      transitFromStopIndex: transitFromStopIndex ?? this.transitFromStopIndex,
    );
  }
}

/// Entity representing a stop on the route
class RouteStop extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final double? reverseLatitude;
  final double? reverseLongitude;
  final StopType type;
  final int? estimatedArrivalMinutes;
  final int? studentCount;
  final DateTime? actualArrivalTime;
  final DateTime? actualDepartureTime;
  final int? boardedStudentCount;
  final String? scheduledTime; // Planned time, e.g., "08:30 AM"
  final int? logicalStopId;
  final int? forwardStopId;
  final int? reverseStopId;


  const RouteStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.reverseLatitude,
    this.reverseLongitude,
    required this.type,
    this.estimatedArrivalMinutes,
    this.studentCount,
    this.actualArrivalTime,
    this.actualDepartureTime,
    this.boardedStudentCount,
    this.scheduledTime,
    this.logicalStopId,
    this.forwardStopId,
    this.reverseStopId,
  });

  @override
  List<Object?> get props => [
    name,
    latitude,
    longitude,
    reverseLatitude,
    reverseLongitude,
    type,
    estimatedArrivalMinutes,
    studentCount,
    actualArrivalTime,
    actualDepartureTime,
    boardedStudentCount,
    scheduledTime,
    logicalStopId,
    forwardStopId,
    reverseStopId,
  ];

  RouteStop copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? reverseLatitude,
    double? reverseLongitude,
    StopType? type,
    int? estimatedArrivalMinutes,
    int? studentCount,
    DateTime? actualArrivalTime,
    DateTime? actualDepartureTime,
    int? boardedStudentCount,
    String? scheduledTime,
    int? logicalStopId,
    int? forwardStopId,
    int? reverseStopId,
  }) {
    return RouteStop(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reverseLatitude: reverseLatitude ?? this.reverseLatitude,
      reverseLongitude: reverseLongitude ?? this.reverseLongitude,
      type: type ?? this.type,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      studentCount: studentCount ?? this.studentCount,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      actualDepartureTime: actualDepartureTime ?? this.actualDepartureTime,
      boardedStudentCount: boardedStudentCount ?? this.boardedStudentCount,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      logicalStopId: logicalStopId ?? this.logicalStopId,
      forwardStopId: forwardStopId ?? this.forwardStopId,
      reverseStopId: reverseStopId ?? this.reverseStopId,
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
