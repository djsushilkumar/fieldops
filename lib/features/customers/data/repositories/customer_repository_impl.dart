import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_datasource.dart';
import '../datasources/customer_remote_datasource.dart';
import '../models/customer_model.dart';
import '../models/location_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<CustomerEntity>> getCustomers({String? searchQuery}) async {
    try {
      final remoteList =
          await remoteDataSource.getCustomers(searchQuery: searchQuery);
      await localDataSource.cacheCustomers(remoteList);
      return remoteList;
    } catch (_) {
      // Fallback to local cache when remote fails
      final cached = await localDataSource.getCachedCustomers();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        return cached
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                (c.address?.toLowerCase().contains(q) ?? false))
            .toList();
      }
      return cached;
    }
  }

  @override
  Future<CustomerEntity> getCustomerDetail(String customerId) async {
    try {
      final remote = await remoteDataSource.getCustomerDetail(customerId);
      await localDataSource.cacheCustomer(remote);
      return remote;
    } catch (_) {
      final cached = await localDataSource.getCachedCustomer(customerId);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    try {
      final created = await remoteDataSource.createCustomer(model);
      await localDataSource.cacheCustomer(created);
      return created;
    } catch (_) {
      // Cache locally for offline resilience
      await localDataSource.cacheCustomer(model);
      return model;
    }
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    try {
      final updated = await remoteDataSource.updateCustomer(model);
      await localDataSource.cacheCustomer(updated);
      return updated;
    } catch (_) {
      await localDataSource.cacheCustomer(model);
      return model;
    }
  }

  @override
  Future<List<LocationEntity>> getLocations({String? customerId}) async {
    try {
      final remote = await remoteDataSource.getLocations(customerId: customerId);
      await localDataSource.cacheLocations(remote);
      return remote;
    } catch (_) {
      return localDataSource.getCachedLocations(customerId: customerId);
    }
  }

  @override
  Future<LocationEntity> getLocationDetail(String locationId) async {
    try {
      final remote = await remoteDataSource.getLocationDetail(locationId);
      await localDataSource.cacheLocation(remote);
      return remote;
    } catch (_) {
      final cached = await localDataSource.getCachedLocations();
      final found = cached.where((l) => l.id == locationId);
      if (found.isNotEmpty) return found.first;
      rethrow;
    }
  }

  @override
  Future<LocationEntity> createLocation(LocationEntity location) async {
    final model = LocationModel.fromEntity(location);
    try {
      final created = await remoteDataSource.createLocation(model);
      await localDataSource.cacheLocation(created);
      return created;
    } catch (_) {
      await localDataSource.cacheLocation(model);
      return model;
    }
  }
}
