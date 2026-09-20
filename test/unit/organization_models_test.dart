import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/organization/data/models/organization_model.dart';
import 'package:field_ops/features/organization/data/models/role_permission_model.dart';
import 'package:field_ops/features/organization/data/models/team_member_model.dart';
import 'package:field_ops/features/organization/data/models/team_model.dart';
import 'package:field_ops/features/organization/domain/entities/role_permission_entity.dart';
import 'package:field_ops/features/organization/domain/entities/team_member_entity.dart';

void main() {
  group('OrganizationModel Unit Tests', () {
    test('fromJson and toJson maintain all settings including geofencing and policies', () {
      final now = DateTime(2026, 9, 20);
      final json = {
        'id': 'org-123',
        'name': 'Apex Mechanical Operations',
        'timezone': 'America/New_York',
        'currency': 'USD',
        'industry': 'HVAC & Plumbing',
        'geofence_default_radius': 250,
        'auto_checkout_hours': 8,
        'require_photo_on_completion': true,
        'require_gps_on_checkin': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = OrganizationModel.fromJson(json);
      expect(model.id, 'org-123');
      expect(model.name, 'Apex Mechanical Operations');
      expect(model.industry, 'HVAC & Plumbing');
      expect(model.geofenceDefaultRadius, 250);
      expect(model.requirePhotoOnCompletion, true);
      expect(model.requireGpsOnCheckin, true);

      final entity = model.toEntity();
      expect(entity.geofenceDefaultRadius, 250);
      expect(entity.industry, 'HVAC & Plumbing');

      final serialized = model.toJson();
      expect(serialized['id'], 'org-123');
      expect(serialized['geofence_default_radius'], 250);
      expect(serialized['require_photo_on_completion'], true);
    });
  });

  group('TeamModel Unit Tests', () {
    test('fromJson and toJson serialize dispatch teams accurately', () {
      final now = DateTime(2026, 9, 20);
      final json = {
        'id': 'team-99',
        'organization_id': 'org-123',
        'name': 'East Bay Electrical',
        'description': 'Solar and high voltage maintenance',
        'lead_manager_id': 'user-1',
        'lead_manager_name': 'Marcus Vance',
        'color_hex': '#00A86B',
        'member_count': 4,
        'member_ids': ['user-1', 'user-2', 'user-3', 'user-4'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = TeamModel.fromJson(json);
      expect(model.id, 'team-99');
      expect(model.name, 'East Bay Electrical');
      expect(model.leadManagerName, 'Marcus Vance');
      expect(model.colorHex, '#00A86B');
      expect(model.memberCount, 4);

      final serialized = model.toJson();
      expect(serialized['lead_manager_id'], 'user-1');
      expect(serialized['member_count'], 4);
    });
  });

  group('TeamMemberModel Unit Tests', () {
    test('fromJson and toJson serialize staff with roles and status', () {
      final now = DateTime(2026, 9, 20);
      final json = {
        'id': 'mem-1',
        'user_id': 'user-10',
        'team_id': 'team-99',
        'team_name': 'East Bay Electrical',
        'full_name': 'Alex Rivera',
        'email': 'alex@fieldops.com',
        'role': 'admin',
        'status': 'ACTIVE',
        'created_at': now.toIso8601String(),
      };

      final model = TeamMemberModel.fromJson(json);
      expect(model.userId, 'user-10');
      expect(model.name, 'Alex Rivera');
      expect(model.role, UserRole.admin);
      expect(model.status, MemberStatus.active);
      expect(model.teamName, 'East Bay Electrical');

      final serialized = model.toJson();
      expect(serialized['role'], 'admin');
      expect(serialized['status'], 'ACTIVE');
    });
  });

  group('RolePermissionModel Unit Tests', () {
    test('defaultForRole produces strict and progressive permission levels', () {
      final owner = RolePermissionEntity.defaultForRole(UserRole.owner);
      expect(owner.canManageUsers, true);
      expect(owner.canManageForms, true);
      expect(owner.canCreateTasks, true);

      final manager = RolePermissionEntity.defaultForRole(UserRole.manager);
      expect(manager.canCreateTasks, true);
      expect(manager.canManageCustomers, true);
      expect(manager.canManageUsers, false);

      final employee = RolePermissionEntity.defaultForRole(UserRole.employee);
      expect(employee.canCreateTasks, false);
      expect(employee.canManageCustomers, false);
      expect(employee.canExportReports, false);
    });

    test('RolePermissionModel serialization retains permission switches', () {
      final json = {
        'role': 'manager',
        'can_create_tasks': true,
        'can_manage_customers': true,
        'can_view_all_teams': false,
        'can_export_reports': true,
        'can_manage_forms': false,
        'can_manage_users': false,
      };

      final model = RolePermissionModel.fromJson(json);
      expect(model.role, UserRole.manager);
      expect(model.canViewAllTeams, false);
      expect(model.canExportReports, true);

      final serialized = model.toJson();
      expect(serialized['can_view_all_teams'], false);
      expect(serialized['role'], 'manager');
    });
  });
}
