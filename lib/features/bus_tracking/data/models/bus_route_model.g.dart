// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_route_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusPositionModelImpl _$$BusPositionModelImplFromJson(Map json) =>
    _$BusPositionModelImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      bearing: (json['bearing'] as num).toDouble(),
      currentLocation: json['current_location'] as String?,
      nextStop: json['next_stop'] as String?,
      isOnTime: json['is_on_time'] as bool?,
      delayMinutes: (json['delay_minutes'] as num?)?.toInt(),
      students: (json['students'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );

Map<String, dynamic> _$$BusPositionModelImplToJson(
  _$BusPositionModelImpl instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'bearing': instance.bearing,
  'current_location': instance.currentLocation,
  'next_stop': instance.nextStop,
  'is_on_time': instance.isOnTime,
  'delay_minutes': instance.delayMinutes,
  'students': instance.students,
};

_$RouteStopModelImpl _$$RouteStopModelImplFromJson(Map json) =>
    _$RouteStopModelImpl(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String,
      estimatedArrivalMinutes: (json['estimated_arrival_minutes'] as num?)
          ?.toInt(),
      studentCount: (json['student_count'] as num?)?.toInt(),
      boardedStudentCount: (json['boarded_student_count'] as num?)?.toInt(),
      scheduledTime: json['scheduled_time'] as String?,
    );

Map<String, dynamic> _$$RouteStopModelImplToJson(
  _$RouteStopModelImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'type': instance.type,
  'estimated_arrival_minutes': instance.estimatedArrivalMinutes,
  'student_count': instance.studentCount,
  'boarded_student_count': instance.boardedStudentCount,
  'scheduled_time': instance.scheduledTime,
};
