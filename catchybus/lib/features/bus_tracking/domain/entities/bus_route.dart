import 'package:equatable/equatable.dart';

/// Entity representing a bus route with tracking information
class BusRoute extends Equatable {
  final String busNumber;
  final String currentLocation;
  final String nextStop;
  final int arrivalTimeMinutes;
  final double distanceKm;
  final bool isOnTime;
  final String driverPhone;
  final BusPosition busPosition;
  final List<RouteStop> stops;
  final List<RoutePoint> routePath;

  const BusRoute({
    required this.busNumber,
    required this.currentLocation,
    required this.nextStop,
    required this.arrivalTimeMinutes,
    required this.distanceKm,
    required this.isOnTime,
    required this.driverPhone,
    required this.busPosition,
    required this.stops,
    required this.routePath,
  });

  @override
  List<Object?> get props => [
    busNumber,
    currentLocation,
    nextStop,
    arrivalTimeMinutes,
    distanceKm,
    isOnTime,
    driverPhone,
    busPosition,
    stops,
    routePath,
  ];
}

/// Entity representing a bus position on the map
class BusPosition extends Equatable {
  final double latitude;
  final double longitude;
  final double bearing; // Direction the bus is facing

  const BusPosition({
    required this.latitude,
    required this.longitude,
    required this.bearing,
  });

  @override
  List<Object?> get props => [latitude, longitude, bearing];
}

/// Entity representing a stop on the route
class RouteStop extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final StopType type;
  final int? estimatedArrivalMinutes;

  const RouteStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.estimatedArrivalMinutes,
  });

  @override
  List<Object?> get props => [
    name,
    latitude,
    longitude,
    type,
    estimatedArrivalMinutes,
  ];
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
enum StopType { currentLocation, nextStop, futureStop, passedStop }
