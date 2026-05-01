// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String?,
  name: json['name'] as String,
  avatar: json['profilePictureUrl'] as String?,
  phone: json['phone'] as String?,
  type: json['type'] as String?,
  college: json['college'] as String?,
  busId: json['busId'] as String?,
  busNumber: json['busNumber'] as String?,
  collegeImageUrl: json['collegeImageUrl'] as String?,
  fcmToken: json['fcm_token'] as String?,
  studentId: json['studentId'] as String?,
  collegeId: json['collegeId'] as String?,
  department: json['department'] as String?,
  year: json['year'] as String?,
  isMultiAccount: json['is_multi_account'] as bool?,
  accounts: (json['accounts'] as List<dynamic>?)
      ?.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'profilePictureUrl': instance.avatar,
  'phone': instance.phone,
  'type': instance.type,
  'college': instance.college,
  'busId': instance.busId,
  'busNumber': instance.busNumber,
  'collegeImageUrl': instance.collegeImageUrl,
  'fcm_token': instance.fcmToken,
  'studentId': instance.studentId,
  'collegeId': instance.collegeId,
  'department': instance.department,
  'year': instance.year,
  'is_multi_account': instance.isMultiAccount,
  'accounts': instance.accounts?.map((e) => e.toJson()).toList(),
};
