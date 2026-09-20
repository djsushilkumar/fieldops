import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:field_ops/features/customers/data/datasources/mock_customer_remote_datasource.dart';
import 'package:field_ops/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:field_ops/features/customers/domain/entities/location_entity.dart';
import 'package:field_ops/features/customers/domain/usecases/create_customer_use_case.dart';
import 'package:field_ops/features/customers/domain/usecases/create_location_use_case.dart';
import 'package:field_ops/features/customers/domain/usecases/get_customer_detail_use_case.dart';
import 'package:field_ops/features/customers/domain/usecases/get_customers_use_case.dart';
import 'package:field_ops/features/customers/presentation/controllers/customer_controller.dart';
import 'package:field_ops/features/visits/data/datasources/mock_visit_remote_datasource.dart';
import 'package:field_ops/features/visits/data/datasources/visit_local_datasource.dart';
import 'package:field_ops/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:field_ops/features/visits/domain/usecases/get_active_visit_use_case.dart';
import 'package:field_ops/features/visits/domain/usecases/get_visits_use_case.dart';
import 'package:field_ops/features/visits/domain/usecases/visit_check_in_use_case.dart';
import 'package:field_ops/features/visits/domain/usecases/visit_check_out_use_case.dart';
import 'package:field_ops/features/visits/presentation/controllers/visit_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Controllers Unit Tests', () {
    late CustomerRepositoryImpl customerRepository;
    late GetCustomersUseCase getCustomersUseCase;
    late CreateCustomerUseCase createCustomerUseCase;
    late GetCustomerDetailUseCase getCustomerDetailUseCase;
    late CreateLocationUseCase createLocationUseCase;

    setUp(() {
      final remote = MockCustomerRemoteDataSource();
      final local = CustomerLocalDataSourceImpl();
      customerRepository = CustomerRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );
      getCustomersUseCase = GetCustomersUseCase(customerRepository);
      createCustomerUseCase = CreateCustomerUseCase(customerRepository);
      getCustomerDetailUseCase = GetCustomerDetailUseCase(customerRepository);
      createLocationUseCase = CreateLocationUseCase(customerRepository);
    });

    test('CustomerListNotifier loads customers on initialization', () async {
      final notifier = CustomerListNotifier(
        getCustomersUseCase: getCustomersUseCase,
        createCustomerUseCase: createCustomerUseCase,
      );

      // Await async loading
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.status, equals(CustomerListStatus.success));
      expect(notifier.state.customers.isNotEmpty, isTrue);
    });

    test('CustomerListNotifier setSearchQuery updates filtered list', () async {
      final notifier = CustomerListNotifier(
        getCustomersUseCase: getCustomersUseCase,
        createCustomerUseCase: createCustomerUseCase,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      await notifier.setSearchQuery('Apex');

      expect(notifier.state.searchQuery, equals('Apex'));
      expect(notifier.state.customers.every((c) => c.name.contains('Apex')), isTrue);
    });

    test('CustomerDetailNotifier loads customer and sites', () async {
      final notifier = CustomerDetailNotifier(
        customerId: 'cust-001',
        getCustomerDetailUseCase: getCustomerDetailUseCase,
        createLocationUseCase: createLocationUseCase,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.status, equals(CustomerDetailStatus.success));
      expect(notifier.state.customer, isNotNull);
      expect(notifier.state.customer?.id, equals('cust-001'));
      expect(notifier.state.customer?.locations.isNotEmpty, isTrue);
    });
  });

  group('Visit Controllers Unit Tests', () {
    late VisitRepositoryImpl visitRepository;
    late GetVisitsUseCase getVisitsUseCase;
    late GetActiveVisitUseCase getActiveVisitUseCase;
    late VisitCheckInUseCase checkInUseCase;
    late VisitCheckOutUseCase checkOutUseCase;
    late MockLocationService locationService;

    final targetLocation = LocationEntity(
      id: 'loc-001',
      organizationId: 'org-001',
      name: 'Main HQ',
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: 200,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      final remote = MockVisitRemoteDataSource();
      final local = VisitLocalDataSourceImpl();
      visitRepository = VisitRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );
      getVisitsUseCase = GetVisitsUseCase(visitRepository);
      getActiveVisitUseCase = GetActiveVisitUseCase(visitRepository);
      checkInUseCase = VisitCheckInUseCase(visitRepository);
      checkOutUseCase = VisitCheckOutUseCase(visitRepository);
      locationService = MockLocationService(
        initialCoordinates: const LocationCoordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
        ),
      );
    });

    test('VisitListNotifier loads visits on init', () async {
      final notifier = VisitListNotifier(
        getVisitsUseCase: getVisitsUseCase,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.status, equals(VisitListStatus.success));
      expect(notifier.state.visits.isNotEmpty, isTrue);
    });

    test('VisitExecutionNotifier handles GPS acquisition and check-in/out cycle', () async {
      final notifier = VisitExecutionNotifier(
        taskId: 'tsk-test-100',
        targetLocation: targetLocation,
        locationService: locationService,
        getActiveVisitUseCase: getActiveVisitUseCase,
        visitCheckInUseCase: checkInUseCase,
        visitCheckOutUseCase: checkOutUseCase,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // 1. Verify GPS coordinates acquired
      await notifier.refreshGps();
      expect(notifier.state.currentCoordinates, isNotNull);
      expect(notifier.state.radiusResult?.isWithinRadius, isTrue);

      // 2. Perform GPS check in
      final visit = await notifier.checkIn(notes: 'Starting test visit');
      expect(visit.id, isNotEmpty);
      expect(notifier.state.activeVisit, isNotNull);
      expect(notifier.state.activeVisit?.id, equals(visit.id));

      // 3. Perform GPS check out
      final completed = await notifier.checkOut(notes: 'Completed test visit');
      expect(completed.isCompleted, isTrue);
      expect(notifier.state.activeVisit, isNull);
    });
  });
}
