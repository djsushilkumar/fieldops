import '../entities/role_permission_entity.dart';
import '../repositories/organization_repository.dart';

class GetRolePermissionsUseCase {
  final OrganizationRepository repository;

  GetRolePermissionsUseCase(this.repository);

  Future<List<RolePermissionEntity>> call(String orgId) {
    return repository.getRolePermissions(orgId);
  }
}

class UpdateRolePermissionUseCase {
  final OrganizationRepository repository;

  UpdateRolePermissionUseCase(this.repository);

  Future<RolePermissionEntity> call({
    required String orgId,
    required RolePermissionEntity permission,
  }) {
    return repository.updateRolePermission(
      orgId: orgId,
      permission: permission,
    );
  }
}
