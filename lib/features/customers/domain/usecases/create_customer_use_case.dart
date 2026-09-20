import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class CreateCustomerUseCase {
  final CustomerRepository repository;

  CreateCustomerUseCase(this.repository);

  Future<CustomerEntity> call(CustomerEntity customer) async {
    return repository.createCustomer(customer);
  }
}
