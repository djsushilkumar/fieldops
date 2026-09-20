import '../entities/organization_entity.dart';
import '../repositories/organization_repository.dart';

class UpdateOrganizationSettingsUseCase {
  final OrganizationRepository repository;

  UpdateOrganizationSettingsUseCase(this.repository);

  Future<OrganizationEntity> call({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
    String? industry,
    int? geofenceDefaultRadius,
    int? autoCheckoutHours,
    bool? requirePhotoOnCompletion,
    bool? requireGpsOnCheckin,
  }) {
    return repository.updateOrganization(
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
  }
}
