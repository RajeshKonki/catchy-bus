import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

/// User model - Data layer
/// This is the data transfer object (DTO) for API responses
@JsonSerializable()
class UserModel {
  final String id;
  final String? email;
  final String name;
  @JsonKey(name: 'profilePictureUrl')
  final String? avatar;
  final String? phone;
  final String? type;
  final String? college;
  @JsonKey(name: 'busId')
  final String? busId;
  @JsonKey(name: 'busNumber')
  final String? busNumber;
  @JsonKey(name: 'collegeImageUrl')
  final String? collegeImageUrl;
  final String? fcmToken;
  @JsonKey(name: 'studentId')
  final String? studentId;
  @JsonKey(name: 'collegeId')
  final String? collegeId;
  final String? department;
  final String? year;
  final bool? isMultiAccount;
  @JsonKey(name: 'accounts')
  final List<UserModel>? accounts;

  const UserModel({
    required this.id,
    this.email,
    required this.name,
    this.avatar,
    this.phone,
    this.type,
    this.college,
    this.busId,
    this.busNumber,
    this.collegeImageUrl,
    this.fcmToken,
    this.studentId,
    this.collegeId,
    this.department,
    this.year,
    this.isMultiAccount,
    this.accounts,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      avatar: json['profilePictureUrl'] as String?,
      phone: json['phone'] as String?,
      type: json['type'] as String?,
      college: json['college'] is Map ? json['college']['name'] : json['college'] as String?,
      busId: (json['busId'] ?? (json['bus'] is Map ? json['bus']['id'] : null)) as String?,
      busNumber: (json['busNumber'] ?? (json['bus'] is Map ? json['bus']['busNumber'] : null)) as String?,
      collegeImageUrl: json['collegeImageUrl'] as String?,
      fcmToken: json['fcmToken'] as String?,
      studentId: json['studentId'] as String?,
      collegeId: (json['collegeId'] ?? (json['college'] is Map ? json['college']['id'] : null)) as String?,
      department: json['department'] as String?,
      year: json['year'] as String?,
      isMultiAccount: json['isMultiAccount'] as bool?,
      accounts: (json['accounts'] as List?)
          ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profilePictureUrl': avatar,
      'phone': phone,
      'type': type,
      'college': college,
      'busId': busId,
      'busNumber': busNumber,
      'collegeImageUrl': collegeImageUrl,
      'fcmToken': fcmToken,
      'studentId': studentId,
      'collegeId': collegeId,
      'department': department,
      'year': year,
      'isMultiAccount': isMultiAccount,
      'accounts': accounts?.map((e) => e.toJson()).toList(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      avatar: avatar,
      phone: phone,
      type: type,
      college: college,
      busId: busId,
      busNumber: busNumber,
      collegeImageUrl: collegeImageUrl,
      fcmToken: fcmToken,
      studentId: studentId,
      collegeId: collegeId,
      department: department,
      year: year,
      isMultiAccount: isMultiAccount,
      accounts: accounts?.map((e) => e.toEntity()).toList(),
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      avatar: entity.avatar,
      phone: entity.phone,
      type: entity.type,
      college: entity.college,
      busId: entity.busId,
      busNumber: entity.busNumber,
      collegeImageUrl: entity.collegeImageUrl,
      fcmToken: entity.fcmToken,
      studentId: entity.studentId,
      collegeId: entity.collegeId,
      department: entity.department,
      year: entity.year,
      isMultiAccount: entity.isMultiAccount,
      accounts: entity.accounts?.map((e) => UserModel.fromEntity(e)).toList(),
    );
  }
}
