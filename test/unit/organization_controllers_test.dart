import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/organization/data/datasources/organization_remote_datasource.dart';
import 'package:field_ops/features/organization/domain/entities/team_member_entity.dart';
import 'package:field_ops/features/organization/presentation/controllers/organization_settings_controller.dart';
import 'package:field_ops/features/organization/presentation/controllers/role_permissions_controller.dart';
import 'package:field_ops/features/organization/presentation/controllers/teams_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockOrganizationRemoteDataSourceImpl mockDataSource;

  setUp(() {
    mockDataSource = MockOrganizationRemoteDataSourceImpl();
    container = ProviderContainer(
      overrides: [
        organizationRemoteDataSourceProvider.overrideWithValue(mockDataSource),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OrganizationSettingsController Unit Tests', () {
    test('loads organization settings on initialization', () async {
      container.read(organizationSettingsControllerProvider.notifier);

      // Wait for async loadOrganization
      await Future.delayed(const Duration(milliseconds: 150));

      final state = container.read(organizationSettingsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.organization, isNotNull);
      expect(state.organization!.name, equals('Apex Field Operations Inc.'));
      expect(state.organization!.industry, equals('Commercial HVAC & Mechanical'));
      expect(state.organization!.geofenceDefaultRadius, equals(100));
      expect(state.organization!.autoCheckoutHours, equals(10));
      expect(state.organization!.requirePhotoOnCompletion, isTrue);
      expect(state.organization!.requireGpsOnCheckin, isTrue);
    });

    test('saveSettings updates organization properties and sets success message', () async {
      final controller = container.read(organizationSettingsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      final result = await controller.saveSettings(
        name: 'Apex Field Services Global',
        industry: 'Solar & Renewable Energy',
        geofenceRadius: 250,
        autoCheckoutHours: 10,
        requirePhoto: false,
        requireGps: true,
      );

      expect(result, isTrue);
      final state = container.read(organizationSettingsControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.organization!.name, equals('Apex Field Services Global'));
      expect(state.organization!.industry, equals('Solar & Renewable Energy'));
      expect(state.organization!.geofenceDefaultRadius, equals(250));
      expect(state.organization!.autoCheckoutHours, equals(10));
      expect(state.organization!.requirePhotoOnCompletion, isFalse);
      expect(state.successMessage, contains('updated successfully'));

      // Test clearMessages
      controller.clearMessages();
      expect(container.read(organizationSettingsControllerProvider).successMessage, isNull);
    });
  });

  group('TeamsController Unit Tests', () {
    test('loads teams and members on initialization', () async {
      container.read(teamsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(teamsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.teams.length, equals(3));
      expect(state.members.length, equals(5));
      expect(state.teams.any((t) => t.name.contains('North Bay HVAC')), isTrue);
      expect(state.members.any((m) => m.name == 'Elena Rostova'), isTrue);
    });

    test('createTeam adds a new dispatch team to state', () async {
      final controller = container.read(teamsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 200));

      final result = await controller.createTeam(
        name: 'South Bay Emergency Response',
        description: 'Covers San Jose, Santa Clara, and Silicon Valley',
        colorHex: '#0D9488',
      );

      expect(result, isTrue);
      final state = container.read(teamsControllerProvider);
      expect(state.teams.length, equals(4));
      final created = state.teams.firstWhere((t) => t.name == 'South Bay Emergency Response');
      expect(created.colorHex, equals('#0D9488'));
      expect(state.successMessage, contains('created successfully'));
    });

    test('updateTeam modifies existing team attributes in state', () async {
      final controller = container.read(teamsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 200));

      final existingTeam = container.read(teamsControllerProvider).teams.first;
      final result = await controller.updateTeam(
        teamId: existingTeam.id,
        name: 'North Bay Climate Specialists',
        description: 'Expanded commercial cooling operations',
      );

      expect(result, isTrue);
      final updated = container.read(teamsControllerProvider).teams.firstWhere((t) => t.id == existingTeam.id);
      expect(updated.name, equals('North Bay Climate Specialists'));
      expect(updated.description, equals('Expanded commercial cooling operations'));
    });

    test('deleteTeam removes team from state list', () async {
      final controller = container.read(teamsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 200));

      final targetId = container.read(teamsControllerProvider).teams.first.id;
      final result = await controller.deleteTeam(targetId);

      expect(result, isTrue);
      final state = container.read(teamsControllerProvider);
      expect(state.teams.any((t) => t.id == targetId), isFalse);
      expect(state.successMessage, contains('removed successfully'));
    });

    test('inviteMember adds new pending technician or staff to roster', () async {
      final controller = container.read(teamsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 200));

      final result = await controller.inviteMember(
        name: 'Johnathan Archer',
        email: 'jarcher@starfleet.org',
        role: UserRole.employee,
        teamId: 'team-north-01',
      );

      expect(result, isTrue);
      final state = container.read(teamsControllerProvider);
      expect(state.members.length, equals(6));
      final invited = state.members.firstWhere((m) => m.email == 'jarcher@starfleet.org');
      expect(invited.name, equals('Johnathan Archer'));
      expect(invited.role, equals(UserRole.employee));
      expect(invited.status, equals(MemberStatus.pending));
    });

    test('updateMemberRole modifies staff role and team assignment', () async {
      final controller = container.read(teamsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 200));

      final member = container.read(teamsControllerProvider).members.firstWhere((m) => m.role == UserRole.employee);
      final result = await controller.updateMemberRole(
        memberId: member.id,
        role: UserRole.manager,
        status: MemberStatus.active,
      );

      expect(result, isTrue);
      final updated = container.read(teamsControllerProvider).members.firstWhere((m) => m.id == member.id);
      expect(updated.role, equals(UserRole.manager));
      expect(updated.status, equals(MemberStatus.active));
    });
  });

  group('RolePermissionsController Unit Tests', () {
    test('loads role permissions and exposes helper forRole', () async {
      container.read(rolePermissionsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      final state = container.read(rolePermissionsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.permissions.length, equals(4));

      final ownerPerm = state.forRole(UserRole.owner);
      expect(ownerPerm, isNotNull);
      expect(ownerPerm!.canManageUsers, isTrue);
      expect(ownerPerm.canExportReports, isTrue);

      final employeePerm = state.forRole(UserRole.employee);
      expect(employeePerm, isNotNull);
      expect(employeePerm!.canManageUsers, isFalse);
    });

    test('togglePermission updates specific permission for role', () async {
      final controller = container.read(rolePermissionsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      // Enable export reports for employee
      controller.togglePermission(
        role: UserRole.employee,
        permissionKey: 'canExportReports',
        value: true,
      );

      var state = container.read(rolePermissionsControllerProvider);
      expect(state.forRole(UserRole.employee)!.canExportReports, isTrue);

      // Disable it back
      controller.togglePermission(
        role: UserRole.employee,
        permissionKey: 'canExportReports',
        value: false,
      );

      state = container.read(rolePermissionsControllerProvider);
      expect(state.forRole(UserRole.employee)!.canExportReports, isFalse);
    });

    test('resetToDefaults resets all permissions to baseline policy', () async {
      final controller = container.read(rolePermissionsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      // Modify manager permissions
      controller.togglePermission(
        role: UserRole.manager,
        permissionKey: 'canManageUsers',
        value: true,
      );
      expect(container.read(rolePermissionsControllerProvider).forRole(UserRole.manager)!.canManageUsers, isTrue);

      // Reset
      controller.resetToDefaults();
      final state = container.read(rolePermissionsControllerProvider);
      expect(state.forRole(UserRole.manager)!.canManageUsers, isFalse);
      expect(state.successMessage, contains('Reset to default'));
    });

    test('savePermissions persists permissions and clears loading state', () async {
      final controller = container.read(rolePermissionsControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      final result = await controller.savePermissions();
      expect(result, isTrue);

      final state = container.read(rolePermissionsControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.successMessage, contains('saved successfully'));
    });
  });
}
