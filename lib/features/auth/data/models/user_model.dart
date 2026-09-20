import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';

class UserModel {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String? ?? 'Unnamed User',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'employee',
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      organizationId: organizationId,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.fromString(role),
      avatarUrl: avatarUrl,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      role: entity.role.value,
      avatarUrl: entity.avatarUrl,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
