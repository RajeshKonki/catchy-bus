import 'package:equatable/equatable.dart';

/// User entity - Domain layer
/// This represents the business model
class UserEntity extends Equatable {
  final String id;
  final String? email;
  final String name;
  final String? avatar;
  final String? phone;
  final String? type;
  final String? college;
  final String? collegeImageUrl;
  final String? busId;
  final String? busNumber;
  final String? fcmToken;
  final String? studentId;

  final bool? isMultiAccount;
  final List<UserEntity>? accounts;

  const UserEntity({
    required this.id,
    this.email,
    required this.name,
    this.avatar,
    this.phone,
    this.type,
    this.college,
    this.collegeImageUrl,
    this.busId,
    this.busNumber,
    this.fcmToken,
    this.studentId,
    this.isMultiAccount,
    this.accounts,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    avatar,
    phone,
    type,
    college,
    collegeImageUrl,
    busId,
    busNumber,
    fcmToken,
    studentId,
    isMultiAccount,
    accounts,
  ];
}
