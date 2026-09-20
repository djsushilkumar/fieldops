import '../entities/location_entity.dart';
import '../repositories/customer_repository.dart';

class CreateLocationUseCase {
  final CustomerRepository repository;

  CreateLocationUseCase(this.repository);

  Future<LocationEntity> call(LocationEntity location) async {
    return repository.createLocation(location);
  }
}
