import '../entities/field_technician_location.dart';
import '../repositories/dashboard_repository.dart';

class GetLiveTechniciansUseCase {
  final DashboardRepository repository;

  GetLiveTechniciansUseCase(this.repository);

  Future<List<FieldTechnicianLocation>> call(String organizationId) {
    return repository.getLiveTechnicianLocations(organizationId);
  }
}
