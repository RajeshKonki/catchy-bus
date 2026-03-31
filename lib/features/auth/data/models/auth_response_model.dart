import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

/// Authentication response model - Data layer
/// Represents the API response for login/register
@JsonSerializable()
class AuthResponseModel {
  @JsonKey(name: 'token')
  final String? accessToken;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  @JsonKey(name: 'user')
  final UserModel? user;

  @JsonKey(name: 'token_type')
  final String? tokenType;

  @JsonKey(name: 'multipleUsers')
  final bool? multipleUsers;

  @JsonKey(name: 'users')
  final List<UserModel>? users;

  const AuthResponseModel({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.tokenType,
    this.multipleUsers,
    this.users,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) => 
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}
