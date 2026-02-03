// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponseModel _$AuthResponseModelFromJson(Map json) => AuthResponseModel(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String?,
  user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  tokenType: json['token_type'] as String?,
);

Map<String, dynamic> _$AuthResponseModelToJson(AuthResponseModel instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user.toJson(),
      'token_type': instance.tokenType,
    };
