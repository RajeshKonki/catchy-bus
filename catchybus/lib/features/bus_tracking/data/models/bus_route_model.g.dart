// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_route_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusRouteModelImpl _$$BusRouteModelImplFromJson(
  Map json,
) => _$BusRouteModelImpl(
  busNumber: json['bus_number'] as String,
  currentLocation: json['current_location'] as String,
  nextStop: json['next_stop'] as String,
  arrivalTimeMinutes: (json['arrival_time_minutes'] as num).toInt(),
  distanceKm: (json['distance_km'] as num).toDouble(),
  isOnTime: json['is_on_time'] as bool,
  driverPhone: json['driver_phone'] as String,
  busPosition: BusPositionModel.fromJson(
    Map<String, dynamic>.from(json['bus_position'] as Map),
  ),
  stops: (json['stops'] as List<dynamic>)
      .map((e) => RouteStopModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  routePath: (json['route_path'] as List<dynamic>)
      .map((e) => RoutePointModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
);

Map<String, dynamic> _$$BusRouteModelImplToJson(_$BusRouteModelImpl instance) =>
    <String, dynamic>{
      'bus_number': instance.busNumber,
      'current_location': instance.currentLocation,
      'next_stop': instance.nextStop,
      'arrival_time_minutes': instance.arrivalTimeMinutes,
      'distance_km': instance.distanceKm,
      'is_on_time': instance.isOnTime,
      'driver_phone': instance.driverPhone,
      'bus_position': instance.busPosition.toJson(),
      'stops': instance.stops.map((e) => e.toJson()).toList(),
      'route_path': instance.routePath.map((e) => e.toJson()).toList(),
    };

_$BusPositionModelImpl _$$BusPositionModelImplFromJson(Map json) =>
    _$BusPositionModelImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      bearing: (json['bearing'] as num).toDouble(),
    );

Map<String, dynamic> _$$BusPositionModelImplToJson(
  _$BusPositionModelImpl instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'bearing': instance.bearing,
};

_$RouteStopModelImpl _$$RouteStopModelImplFromJson(Map json) =>
    _$RouteStopModelImpl(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String,
      estimatedArrivalMinutes: (json['estimated_arrival_minutes'] as num?)
          ?.toInt(),
    );

Map<String, dynamic> _$$RouteStopModelImplToJson(
  _$RouteStopModelImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'type': instance.type,
  'estimated_arrival_minutes': instance.estimatedArrivalMinutes,
};

_$RoutePointModelImpl _$$RoutePointModelImplFromJson(Map json) =>
    _$RoutePointModelImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$RoutePointModelImplToJson(
  _$RoutePointModelImpl instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
