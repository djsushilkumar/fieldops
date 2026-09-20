import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:field_ops/features/customers/data/datasources/mock_customer_remote_datasource.dart';
import 'package:field_ops/features/customers/data/models/customer_model.dart';
import 'package:field_ops/features/customers/data/models/location_model.dart';
import 'package:field_ops/features/customers/data/repositories/customer_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCustomerRemoteDataSource remoteDataSource;
  late CustomerLocalDataSource localDataSource;
  late CustomerRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockCustomerRemoteDataSource();
    localDataSource = CustomerLocalDataSourceImpl();
    repository = CustomerRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  group('CustomerRepository Unit Tests', () {
    test('getCustomers returns list and caches them locally', () async {
      final customers = await repository.getCustomers();

      expect(customers.isNotEmpty, isTrue);
      expect(customers.first.name, isNotEmpty);

      // Verify cached locally
      final cached = await localDataSource.getCachedCustomers();
      expect(cached.length, equals(customers.length));
    });

    test('getCustomers with search query filters results', () async {
      final customers = await repository.getCustomers(searchQuery: 'Apex');

      expect(customers.isNotEmpty, isTrue);
      for (final c in customers) {
        expect(c.name.toLowerCase().contains('apex'), isTrue);
      }
    });

    test('getCustomerDetail returns customer by id', () async {
      final customers = await repository.getCustomers();
      final target = customers.first;

      final detail = await repository.getCustomerDetail(target.id);
      expect(detail.id, equals(target.id));
      expect(detail.name, equals(target.name));
    });

    test('createCustomer adds customer to remote and local cache', () async {
      final now = DateTime.now();
      final newCustomer = CustomerModel(
        id: 'cust-new-999',
        organizationId: 'org-001',
        name: 'Horizon Tech Corp',
        email: 'info@horizon.com',
        createdAt: now,
        updatedAt: now,
      );

      final created = await repository.createCustomer(newCustomer);
      expect(created.name, equals('Horizon Tech Corp'));

      final fetched = await repository.getCustomerDetail(created.id);
      expect(fetched.name, equals('Horizon Tech Corp'));
    });

    test('createLocation adds location under customer', () async {
      final now = DateTime.now();
      final customers = await repository.getCustomers();
      final customerId = customers.first.id;

      final newLocation = LocationModel(
        id: 'loc-new-888',
        organizationId: 'org-001',
        customerId: customerId,
        name: 'Annex North',
        latitude: 37.781,
        longitude: -122.411,
        radiusMeters: 120,
        createdAt: now,
        updatedAt: now,
      );

      final created = await repository.createLocation(newLocation);
      expect(created.name, equals('Annex North'));
      expect(created.radiusMeters, equals(120));

      final locations = await repository.getLocations(customerId: customerId);
      expect(locations.any((l) => l.name == 'Annex North'), isTrue);
    });

    test('falls back to local cache when remote datasource fails', () async {
      // 1. First populate cache
      final initial = await repository.getCustomers();
      expect(initial.isNotEmpty, isTrue);

      // 2. Simulate remote failure by throwing error
      remoteDataSource.shouldThrowError = true;

      // 3. getCustomers fallback should return from local cache
      final fallbackCustomers = await repository.getCustomers();
      expect(fallbackCustomers.isNotEmpty, isTrue);
      expect(fallbackCustomers.length, equals(initial.length));
    });
  });
}
