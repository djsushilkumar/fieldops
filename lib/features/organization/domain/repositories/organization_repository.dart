import '../../../auth/domain/entities/user_role.dart';
import '../entities/organization_entity.dart';
import '../entities/role_permission_entity.dart';
import '../entities/team_entity.dart';
import '../entities/team_member_entity.dart';

abstract class OrganizationRepository {
  Future<OrganizationEntity> getOrganization(String orgId);

  Future<OrganizationEntity> updateOrganization({
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

  // Teams
  Future<List<TeamEntity>> getTeams(String orgId);

  Future<TeamEntity> createTeam({
    required String orgId,
    required String name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  });

  Future<TeamEntity> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  });

  Future<void> deleteTeam(String teamId);

  // Members
  Future<List<TeamMemberEntity>> getMembers(String orgId);

  Future<TeamMemberEntity> inviteMember({
    required String orgId,
    required String name,
    required String email,
    required UserRole role,
    String? teamId,
  });

  Future<TeamMemberEntity> updateMemberRole({
    required String memberId,
    required UserRole role,
    String? teamId,
    MemberStatus? status,
  });

  // Permissions
  Future<List<RolePermissionEntity>> getRolePermissions(String orgId);

  Future<RolePermissionEntity> updateRolePermission({
    required String orgId,
    required RolePermissionEntity permission,
  });
}
