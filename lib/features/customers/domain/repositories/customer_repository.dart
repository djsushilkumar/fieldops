import '../entities/customer_entity.dart';
import '../entities/location_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getCustomers({String? searchQuery});
  Future<CustomerEntity> getCustomerDetail(String customerId);
  Future<CustomerEntity> createCustomer(CustomerEntity customer);
  Future<CustomerEntity> updateCustomer(CustomerEntity customer);
  Future<List<LocationEntity>> getLocations({String? customerId});
  Future<LocationEntity> getLocationDetail(String locationId);
  Future<LocationEntity> createLocation(LocationEntity location);
}
