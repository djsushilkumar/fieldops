import 'user_role.dart';

class UserEntity {
  final String id;
  final String organizationId;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
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

  bool get isActive => status == 'active';

  UserEntity copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          organizationId == other.organizationId &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ organizationId.hashCode ^ email.hashCode ^ role.hashCode;

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email, role: ${role.value}, org: $organizationId)';
  }
}
