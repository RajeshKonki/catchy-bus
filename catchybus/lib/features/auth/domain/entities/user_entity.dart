import 'package:equatable/equatable.dart';

/// User entity - Domain layer
/// This represents the business model
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatar;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
  });

  @override
  List<Object?> get props => [id, email, name, avatar];
}
