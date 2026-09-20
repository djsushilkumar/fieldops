import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/entities/role_permission_entity.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/entities/team_member_entity.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';
import '../models/role_permission_model.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationRemoteDataSource remoteDataSource;

  OrganizationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<OrganizationEntity> getOrganization(String orgId) async {
    try {
      final model = await remoteDataSource.getOrganization(orgId);
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
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
  }) async {
    try {
      final model = await remoteDataSource.updateOrganization(
        orgId: orgId,
        name: name,
        timezone: timezone,
        currency: currency,
        industry: industry,
        geofenceDefaultRadius: geofenceDefaultRadius,
        autoCheckoutHours: autoCheckoutHours,
        requirePhotoOnCompletion: requirePhotoOnCompletion,
        requireGpsOnCheckin: requireGpsOnCheckin,
      );
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<TeamEntity>> getTeams(String orgId) async {
    try {
      final models = await remoteDataSource.getTeams(orgId);
      return models;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TeamEntity> createTeam({
    required String orgId,
    required String name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    try {
      final model = await remoteDataSource.createTeam(
        orgId: orgId,
        name: name,
        description: description,
        leadManagerId: leadManagerId,
        colorHex: colorHex,
      );
      return model;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TeamEntity> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    try {
      final model = await remoteDataSource.updateTeam(
        teamId: teamId,
        name: name,
        description: description,
        leadManagerId: leadManagerId,
        colorHex: colorHex,
      );
      return model;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    try {
      await remoteDataSource.deleteTeam(teamId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<TeamMemberEntity>> getMembers(String orgId) async {
    try {
      final models = await remoteDataSource.getMembers(orgId);
      return models;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TeamMemberEntity> inviteMember({
    required String orgId,
    required String name,
    required String email,
    required UserRole role,
    String? teamId,
  }) async {
    try {
      final model = await remoteDataSource.inviteMember(
        orgId: orgId,
        name: name,
        email: email,
        role: role,
        teamId: teamId,
      );
      return model;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TeamMemberEntity> updateMemberRole({
    required String memberId,
    required UserRole role,
    String? teamId,
    MemberStatus? status,
  }) async {
    try {
      final model = await remoteDataSource.updateMemberRole(
        memberId: memberId,
        role: role,
        teamId: teamId,
        status: status,
      );
      return model;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<RolePermissionEntity>> getRolePermissions(String orgId) async {
    try {
      final models = await remoteDataSource.getRolePermissions(orgId);
      return models;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<RolePermissionEntity> updateRolePermission({
    required String orgId,
    required RolePermissionEntity permission,
  }) async {
    try {
      final model = await remoteDataSource.updateRolePermission(
        orgId: orgId,
        permission: RolePermissionModel.fromEntity(permission),
      );
      return model;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
