import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

/// User model - Data layer
/// This is the data transfer object (DTO) for API responses
@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.avatar,
  });

  /// Factory constructor for creating a new UserModel instance from a map
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Method to convert UserModel to a map
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convert UserModel to UserEntity
  UserEntity toEntity() {
    return UserEntity(id: id, email: email, name: name, avatar: avatar);
  }

  /// Create UserModel from UserEntity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      avatar: entity.avatar,
    );
  }
}
