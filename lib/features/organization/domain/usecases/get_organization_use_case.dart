import '../entities/organization_entity.dart';
import '../repositories/organization_repository.dart';

class GetOrganizationUseCase {
  final OrganizationRepository repository;

  GetOrganizationUseCase(this.repository);

  Future<OrganizationEntity> execute(String orgId) async {
    if (orgId.trim().isEmpty) {
      throw Exception('Organization ID cannot be empty');
    }
    return await repository.getOrganization(orgId);
  }
}
