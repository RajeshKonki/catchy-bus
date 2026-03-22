// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponseModel _$AuthResponseModelFromJson(Map json) => AuthResponseModel(
  accessToken: json['token'] as String?,
  refreshToken: json['refresh_token'] as String?,
  user: json['user'] == null
      ? null
      : UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  tokenType: json['token_type'] as String?,
  multipleUsers: json['multipleUsers'] as bool?,
  users: (json['users'] as List<dynamic>?)
      ?.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
);

Map<String, dynamic> _$AuthResponseModelToJson(AuthResponseModel instance) =>
    <String, dynamic>{
      'token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user?.toJson(),
      'token_type': instance.tokenType,
      'multipleUsers': instance.multipleUsers,
      'users': instance.users?.map((e) => e.toJson()).toList(),
    };
