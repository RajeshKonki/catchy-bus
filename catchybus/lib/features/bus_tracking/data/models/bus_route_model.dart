import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/bus_route.dart';

part 'bus_route_model.freezed.dart';
part 'bus_route_model.g.dart';

@freezed
class BusRouteModel with _$BusRouteModel {
  const BusRouteModel._();

  const factory BusRouteModel({
    required String busNumber,
    required String currentLocation,
    required String nextStop,
    required int arrivalTimeMinutes,
    required double distanceKm,
    required bool isOnTime,
    required String driverPhone,
    required BusPositionModel busPosition,
    required List<RouteStopModel> stops,
    required List<RoutePointModel> routePath,
  }) = _BusRouteModel;

  factory BusRouteModel.fromJson(Map<String, dynamic> json) =>
      _$BusRouteModelFromJson(json);

  BusRoute toEntity() {
    return BusRoute(
      busNumber: busNumber,
      currentLocation: currentLocation,
      nextStop: nextStop,
      arrivalTimeMinutes: arrivalTimeMinutes,
      distanceKm: distanceKm,
      isOnTime: isOnTime,
      driverPhone: driverPhone,
      busPosition: busPosition.toEntity(),
      stops: stops.map((s) => s.toEntity()).toList(),
      routePath: routePath.map((p) => p.toEntity()).toList(),
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
  }) = _BusPositionModel;

  factory BusPositionModel.fromJson(Map<String, dynamic> json) =>
      _$BusPositionModelFromJson(json);

  BusPosition toEntity() {
    return BusPosition(
      latitude: latitude,
      longitude: longitude,
      bearing: bearing,
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
  }) = _RouteStopModel;

  factory RouteStopModel.fromJson(Map<String, dynamic> json) =>
      _$RouteStopModelFromJson(json);

  RouteStop toEntity() {
    return RouteStop(
      name: name,
      latitude: latitude,
      longitude: longitude,
      type: _parseStopType(type),
      estimatedArrivalMinutes: estimatedArrivalMinutes,
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

  factory RoutePointModel.fromJson(Map<String, dynamic> json) =>
      _$RoutePointModelFromJson(json);

  RoutePoint toEntity() {
    return RoutePoint(latitude: latitude, longitude: longitude);
  }
}
