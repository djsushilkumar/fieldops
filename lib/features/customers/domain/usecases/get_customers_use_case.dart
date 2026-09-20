import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  Future<List<CustomerEntity>> call({String? searchQuery}) async {
    return repository.getCustomers(searchQuery: searchQuery);
  }
}
