import '../entities/location_entity.dart';
import '../repositories/customer_repository.dart';

class GetLocationsUseCase {
  final CustomerRepository repository;

  GetLocationsUseCase(this.repository);

  Future<List<LocationEntity>> call({String? customerId}) async {
    return repository.getLocations(customerId: customerId);
  }
}
