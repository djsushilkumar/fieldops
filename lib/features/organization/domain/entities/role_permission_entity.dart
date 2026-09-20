import '../../../auth/domain/entities/user_role.dart';

class RolePermissionEntity {
  final UserRole role;
  final bool canCreateTasks;
  final bool canManageCustomers;
  final bool canViewAllTeams;
  final bool canExportReports;
  final bool canManageForms;
  final bool canManageUsers;

  const RolePermissionEntity({
    required this.role,
    this.canCreateTasks = true,
    this.canManageCustomers = true,
    this.canViewAllTeams = true,
    this.canExportReports = true,
    this.canManageForms = false,
    this.canManageUsers = false,
  });

  static RolePermissionEntity defaultForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
      case UserRole.admin:
        return RolePermissionEntity(
          role: role,
          canCreateTasks: true,
          canManageCustomers: true,
          canViewAllTeams: true,
          canExportReports: true,
          canManageForms: true,
          canManageUsers: true,
        );
      case UserRole.manager:
        return RolePermissionEntity(
          role: role,
          canCreateTasks: true,
          canManageCustomers: true,
          canViewAllTeams: true,
          canExportReports: true,
          canManageForms: false,
          canManageUsers: false,
        );
      case UserRole.employee:
        return RolePermissionEntity(
          role: role,
          canCreateTasks: false,
          canManageCustomers: false,
          canViewAllTeams: false,
          canExportReports: false,
          canManageForms: false,
          canManageUsers: false,
        );
    }
  }

  RolePermissionEntity copyWith({
    UserRole? role,
    bool? canCreateTasks,
    bool? canManageCustomers,
    bool? canViewAllTeams,
    bool? canExportReports,
    bool? canManageForms,
    bool? canManageUsers,
  }) {
    return RolePermissionEntity(
      role: role ?? this.role,
      canCreateTasks: canCreateTasks ?? this.canCreateTasks,
      canManageCustomers: canManageCustomers ?? this.canManageCustomers,
      canViewAllTeams: canViewAllTeams ?? this.canViewAllTeams,
      canExportReports: canExportReports ?? this.canExportReports,
      canManageForms: canManageForms ?? this.canManageForms,
      canManageUsers: canManageUsers ?? this.canManageUsers,
    );
  }
}
