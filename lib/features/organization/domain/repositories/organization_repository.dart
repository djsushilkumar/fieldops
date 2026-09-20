import '../entities/organization_entity.dart';

abstract class OrganizationRepository {
  Future<OrganizationEntity> getOrganization(String orgId);
  Future<OrganizationEntity> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
  });
}
