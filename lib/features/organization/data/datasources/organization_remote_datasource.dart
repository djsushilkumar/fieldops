import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/role_permission_entity.dart';
import '../../domain/entities/team_member_entity.dart';
import '../models/organization_model.dart';
import '../models/role_permission_model.dart';
import '../models/team_member_model.dart';
import '../models/team_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<OrganizationModel> getOrganization(String orgId);

  Future<OrganizationModel> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
    String? industry,
    int? geofenceDefaultRadius,
    int? autoCheckoutHours,
    bool? requirePhotoOnCompletion,
    bool? requireGpsOnCheckin,
  });

  Future<List<TeamModel>> getTeams(String orgId);

  Future<TeamModel> createTeam({
    required String orgId,
    required String name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  });

  Future<TeamModel> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  });

  Future<void> deleteTeam(String teamId);

  Future<List<TeamMemberModel>> getMembers(String orgId);

  Future<TeamMemberModel> inviteMember({
    required String orgId,
    required String name,
    required String email,
    required UserRole role,
    String? teamId,
  });

  Future<TeamMemberModel> updateMemberRole({
    required String memberId,
    required UserRole role,
    String? teamId,
    MemberStatus? status,
  });

  Future<List<RolePermissionModel>> getRolePermissions(String orgId);

  Future<RolePermissionModel> updateRolePermission({
    required String orgId,
    required RolePermissionModel permission,
  });
}

class SupabaseOrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  final supa.SupabaseClient client;

  SupabaseOrganizationRemoteDataSourceImpl(this.client);

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    try {
      final data = await client
          .from('organizations')
          .select()
          .eq('id', orgId)
          .single();
      return OrganizationModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to get organization: $e');
    }
  }

  @override
  Future<OrganizationModel> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
    String? industry,
    int? geofenceDefaultRadius,
    int? autoCheckoutHours,
    bool? requirePhotoOnCompletion,
    bool? requireGpsOnCheckin,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (timezone != null) updates['timezone'] = timezone;
      if (currency != null) updates['currency'] = currency;
      if (industry != null) updates['industry'] = industry;
      if (geofenceDefaultRadius != null) updates['geofence_default_radius'] = geofenceDefaultRadius;
      if (autoCheckoutHours != null) updates['auto_checkout_hours'] = autoCheckoutHours;
      if (requirePhotoOnCompletion != null) updates['require_photo_on_completion'] = requirePhotoOnCompletion;
      if (requireGpsOnCheckin != null) updates['require_gps_on_checkin'] = requireGpsOnCheckin;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final data = await client
          .from('organizations')
          .update(updates)
          .eq('id', orgId)
          .select()
          .single();
      return OrganizationModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to update organization: $e');
    }
  }

  @override
  Future<List<TeamModel>> getTeams(String orgId) async {
    try {
      final data = await client
          .from('teams')
          .select('*, lead_manager:profiles!lead_manager_id(full_name), team_members(user_id)')
          .eq('organization_id', orgId)
          .order('name');
      return (data as List).map((t) => TeamModel.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<TeamModel> createTeam({
    required String orgId,
    required String name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    try {
      final data = await client
          .from('teams')
          .insert({
            'organization_id': orgId,
            'name': name,
            'description': description,
            'lead_manager_id': leadManagerId,
            'color_hex': colorHex ?? '#0288D1',
          })
          .select()
          .single();
      return TeamModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to create team: $e');
    }
  }

  @override
  Future<TeamModel> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (leadManagerId != null) updates['lead_manager_id'] = leadManagerId;
      if (colorHex != null) updates['color_hex'] = colorHex;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final data = await client
          .from('teams')
          .update(updates)
          .eq('id', teamId)
          .select()
          .single();
      return TeamModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to update team: $e');
    }
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    try {
      await client.from('teams').delete().eq('id', teamId);
    } catch (e) {
      throw ServerException('Failed to delete team: $e');
    }
  }

  @override
  Future<List<TeamMemberModel>> getMembers(String orgId) async {
    try {
      final data = await client
          .from('profiles')
          .select('*, team_members(team_id, teams(name))')
          .eq('organization_id', orgId)
          .order('full_name');
      return (data as List).map((m) => TeamMemberModel.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<TeamMemberModel> inviteMember({
    required String orgId,
    required String name,
    required String email,
    required UserRole role,
    String? teamId,
  }) async {
    // In production, triggers Supabase auth invite
    return TeamMemberModel(
      id: const Uuid().v4(),
      userId: const Uuid().v4(),
      name: name,
      email: email,
      role: role,
      teamId: teamId,
      status: MemberStatus.pending,
      joinedAt: DateTime.now(),
    );
  }

  @override
  Future<TeamMemberModel> updateMemberRole({
    required String memberId,
    required UserRole role,
    String? teamId,
    MemberStatus? status,
  }) async {
    try {
      final updates = <String, dynamic>{'role': role.value};
      final data = await client
          .from('profiles')
          .update(updates)
          .eq('id', memberId)
          .select()
          .single();
      return TeamMemberModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to update member role: $e');
    }
  }

  @override
  Future<List<RolePermissionModel>> getRolePermissions(String orgId) async {
    try {
      final data = await client
          .from('role_permissions')
          .select()
          .eq('organization_id', orgId);
      final list = (data as List).map((p) => RolePermissionModel.fromJson(p as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    return [
      RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.owner)),
      RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.admin)),
      RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.manager)),
      RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.employee)),
    ];
  }

  @override
  Future<RolePermissionModel> updateRolePermission({
    required String orgId,
    required RolePermissionModel permission,
  }) async {
    try {
      final data = await client
          .from('role_permissions')
          .upsert({
            'organization_id': orgId,
            'role': permission.role.value,
            'can_create_tasks': permission.canCreateTasks,
            'can_manage_customers': permission.canManageCustomers,
            'can_view_all_teams': permission.canViewAllTeams,
            'can_export_reports': permission.canExportReports,
            'can_manage_forms': permission.canManageForms,
            'can_manage_users': permission.canManageUsers,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'organization_id, role')
          .select()
          .single();
      return RolePermissionModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to update role permissions: $e');
    }
  }
}

class MockOrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  OrganizationModel _org = OrganizationModel(
    id: 'org-acme-ops-001',
    name: 'Apex Field Operations Inc.',
    timezone: 'America/New_York',
    currency: 'USD',
    industry: 'Commercial HVAC & Mechanical',
    geofenceDefaultRadius: 100,
    autoCheckoutHours: 10,
    requirePhotoOnCompletion: true,
    requireGpsOnCheckin: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime.now(),
  );

  final List<TeamModel> _teams = [
    TeamModel(
      id: 'team-001',
      organizationId: 'org-acme-ops-001',
      name: 'North Bay HVAC Fleet',
      description: 'Commercial chilling and air purification servicing Marin and Sonoma counties.',
      leadManagerId: 'user-002',
      leadManagerName: 'Elena Rostova',
      colorHex: '#0288D1',
      memberCount: 5,
      memberIds: const ['user-001', 'user-002', 'user-004'],
      createdAt: DateTime(2025, 2, 1),
      updatedAt: DateTime(2025, 2, 1),
    ),
    TeamModel(
      id: 'team-002',
      organizationId: 'org-acme-ops-001',
      name: 'SF Metro Rapid Response',
      description: 'Emergency refrigeration repairs, sensor calibration, and critical hospital cooling.',
      leadManagerId: 'user-003',
      leadManagerName: 'Marcus Vance',
      colorHex: '#7B1FA2',
      memberCount: 4,
      memberIds: const ['user-003', 'user-005'],
      createdAt: DateTime(2025, 2, 15),
      updatedAt: DateTime(2025, 2, 15),
    ),
    TeamModel(
      id: 'team-003',
      organizationId: 'org-acme-ops-001',
      name: 'East Bay Electrical & Solar',
      description: 'Solar inverters, high-voltage battery banks, and transfer switch commissioning.',
      leadManagerId: 'user-001',
      leadManagerName: 'Alex Rivera',
      colorHex: '#00A86B',
      memberCount: 3,
      memberIds: const ['user-001', 'user-004'],
      createdAt: DateTime(2025, 3, 1),
      updatedAt: DateTime(2025, 3, 1),
    ),
  ];

  final List<TeamMemberModel> _members = [
    TeamMemberModel(
      id: 'member-001',
      userId: 'user-001',
      name: 'Alex Rivera',
      email: 'alex.rivera@fieldops.com',
      role: UserRole.admin,
      teamId: 'team-003',
      teamName: 'East Bay Electrical & Solar',
      status: MemberStatus.active,
      joinedAt: DateTime(2025, 1, 1),
    ),
    TeamMemberModel(
      id: 'member-002',
      userId: 'user-002',
      name: 'Elena Rostova',
      email: 'elena.rostova@fieldops.com',
      role: UserRole.manager,
      teamId: 'team-001',
      teamName: 'North Bay HVAC Fleet',
      status: MemberStatus.active,
      joinedAt: DateTime(2025, 1, 15),
    ),
    TeamMemberModel(
      id: 'member-003',
      userId: 'user-003',
      name: 'Marcus Vance',
      email: 'marcus.vance@fieldops.com',
      role: UserRole.manager,
      teamId: 'team-002',
      teamName: 'SF Metro Rapid Response',
      status: MemberStatus.active,
      joinedAt: DateTime(2025, 2, 1),
    ),
    TeamMemberModel(
      id: 'member-004',
      userId: 'user-004',
      name: 'Chloe Bennett',
      email: 'chloe.bennett@fieldops.com',
      role: UserRole.employee,
      teamId: 'team-001',
      teamName: 'North Bay HVAC Fleet',
      status: MemberStatus.active,
      joinedAt: DateTime(2025, 2, 10),
    ),
    TeamMemberModel(
      id: 'member-005',
      userId: 'user-005',
      name: 'Samira Khan',
      email: 'samira.khan@fieldops.com',
      role: UserRole.employee,
      teamId: 'team-002',
      teamName: 'SF Metro Rapid Response',
      status: MemberStatus.active,
      joinedAt: DateTime(2025, 3, 1),
    ),
  ];

  final Map<UserRole, RolePermissionModel> _permissions = {
    UserRole.owner: RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.owner)),
    UserRole.admin: RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.admin)),
    UserRole.manager: RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.manager)),
    UserRole.employee: RolePermissionModel.fromEntity(RolePermissionEntity.defaultForRole(UserRole.employee)),
  };

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _org;
  }

  @override
  Future<OrganizationModel> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
    String? industry,
    int? geofenceDefaultRadius,
    int? autoCheckoutHours,
    bool? requirePhotoOnCompletion,
    bool? requireGpsOnCheckin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _org = OrganizationModel(
      id: orgId,
      name: name ?? _org.name,
      timezone: timezone ?? _org.timezone,
      currency: currency ?? _org.currency,
      industry: industry ?? _org.industry,
      geofenceDefaultRadius: geofenceDefaultRadius ?? _org.geofenceDefaultRadius,
      autoCheckoutHours: autoCheckoutHours ?? _org.autoCheckoutHours,
      requirePhotoOnCompletion: requirePhotoOnCompletion ?? _org.requirePhotoOnCompletion,
      requireGpsOnCheckin: requireGpsOnCheckin ?? _org.requireGpsOnCheckin,
      createdAt: _org.createdAt,
      updatedAt: DateTime.now(),
    );
    return _org;
  }

  @override
  Future<List<TeamModel>> getTeams(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_teams);
  }

  @override
  Future<TeamModel> createTeam({
    required String orgId,
    required String name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newTeam = TeamModel(
      id: const Uuid().v4(),
      organizationId: orgId,
      name: name,
      description: description,
      leadManagerId: leadManagerId,
      leadManagerName: leadManagerId != null ? _members.firstWhere((m) => m.userId == leadManagerId, orElse: () => _members.first).name : null,
      colorHex: colorHex ?? '#0288D1',
      memberCount: 0,
      memberIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _teams.add(newTeam);
    return newTeam;
  }

  @override
  Future<TeamModel> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index == -1) throw const ServerException('Team not found');

    final existing = _teams[index];
    final updated = existing.copyWith(
      name: name,
      description: description,
      leadManagerId: leadManagerId,
      colorHex: colorHex,
      updatedAt: DateTime.now(),
    );
    final model = TeamModel.fromEntity(updated);
    _teams[index] = model;
    return model;
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _teams.removeWhere((t) => t.id == teamId);
  }

  @override
  Future<List<TeamMemberModel>> getMembers(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_members);
  }

  @override
  Future<TeamMemberModel> inviteMember({
    required String orgId,
    required String name,
    required String email,
    required UserRole role,
    String? teamId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final team = teamId != null ? _teams.firstWhere((t) => t.id == teamId, orElse: () => _teams.first) : null;
    final newMember = TeamMemberModel(
      id: const Uuid().v4(),
      userId: const Uuid().v4(),
      name: name,
      email: email,
      role: role,
      teamId: teamId,
      teamName: team?.name,
      status: MemberStatus.pending,
      joinedAt: DateTime.now(),
    );
    _members.add(newMember);
    return newMember;
  }

  @override
  Future<TeamMemberModel> updateMemberRole({
    required String memberId,
    required UserRole role,
    String? teamId,
    MemberStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _members.indexWhere((m) => m.id == memberId || m.userId == memberId);
    if (index == -1) throw const ServerException('Member not found');

    final existing = _members[index];
    final updated = existing.copyWith(
      role: role,
      teamId: teamId ?? existing.teamId,
      status: status ?? existing.status,
    );
    final model = TeamMemberModel.fromEntity(updated);
    _members[index] = model;
    return model;
  }

  @override
  Future<List<RolePermissionModel>> getRolePermissions(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _permissions.values.toList();
  }

  @override
  Future<RolePermissionModel> updateRolePermission({
    required String orgId,
    required RolePermissionModel permission,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _permissions[permission.role] = permission;
    return permission;
  }
}
