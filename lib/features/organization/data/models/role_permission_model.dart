import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/role_permission_entity.dart';

class RolePermissionModel extends RolePermissionEntity {
  const RolePermissionModel({
    required super.role,
    super.canCreateTasks = true,
    super.canManageCustomers = true,
    super.canViewAllTeams = true,
    super.canExportReports = true,
    super.canManageForms = false,
    super.canManageUsers = false,
  });

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionModel(
      role: UserRole.fromString(json['role'] as String?),
      canCreateTasks: (json['can_create_tasks'] ?? true) as bool,
      canManageCustomers: (json['can_manage_customers'] ?? true) as bool,
      canViewAllTeams: (json['can_view_all_teams'] ?? true) as bool,
      canExportReports: (json['can_export_reports'] ?? true) as bool,
      canManageForms: (json['can_manage_forms'] ?? false) as bool,
      canManageUsers: (json['can_manage_users'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.value,
      'can_create_tasks': canCreateTasks,
      'can_manage_customers': canManageCustomers,
      'can_view_all_teams': canViewAllTeams,
      'can_export_reports': canExportReports,
      'can_manage_forms': canManageForms,
      'can_manage_users': canManageUsers,
    };
  }

  factory RolePermissionModel.fromEntity(RolePermissionEntity entity) {
    return RolePermissionModel(
      role: entity.role,
      canCreateTasks: entity.canCreateTasks,
      canManageCustomers: entity.canManageCustomers,
      canViewAllTeams: entity.canViewAllTeams,
      canExportReports: entity.canExportReports,
      canManageForms: entity.canManageForms,
      canManageUsers: entity.canManageUsers,
    );
  }
}
