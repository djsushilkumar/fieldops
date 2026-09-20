import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomerDetailUseCase {
  final CustomerRepository repository;

  GetCustomerDetailUseCase(this.repository);

  Future<CustomerEntity> call(String customerId) async {
    return repository.getCustomerDetail(customerId);
  }
}
