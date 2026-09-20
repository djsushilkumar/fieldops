import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/errors/failures.dart';
import 'package:field_ops/features/customers/domain/entities/location_entity.dart';
import 'package:field_ops/features/visits/data/datasources/mock_visit_remote_datasource.dart';
import 'package:field_ops/features/visits/data/datasources/visit_local_datasource.dart';
import 'package:field_ops/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:field_ops/features/visits/domain/usecases/get_active_visit_use_case.dart';
import 'package:field_ops/features/visits/domain/usecases/get_visits_use_case.dart';
import 'package:field_ops/features/visits/domain/usecases/visit_check_in_use_case.dart';
import 'package:field_ops/features/visits/domain/usecases/visit_check_out_use_case.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVisitRemoteDataSource remoteDataSource;
  late VisitLocalDataSource localDataSource;
  late VisitRepositoryImpl repository;
  late VisitCheckInUseCase checkInUseCase;
  late VisitCheckOutUseCase checkOutUseCase;
  late GetVisitsUseCase getVisitsUseCase;
  late GetActiveVisitUseCase getActiveVisitUseCase;

  final testLocation = LocationEntity(
    id: 'loc-001',
    organizationId: 'org-001',
    name: 'Main Distribution Center',
    latitude: 37.7749,
    longitude: -122.4194,
    radiusMeters: 100,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    remoteDataSource = MockVisitRemoteDataSource();
    localDataSource = VisitLocalDataSourceImpl();
    repository = VisitRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
    checkInUseCase = VisitCheckInUseCase(repository);
    checkOutUseCase = VisitCheckOutUseCase(repository);
    getVisitsUseCase = GetVisitsUseCase(repository);
    getActiveVisitUseCase = GetActiveVisitUseCase(repository);
  });

  group('VisitCheckInUseCase & Geofence Verification Tests', () {
    test('succeeds when user is within site radius', () async {
      // User is practically at the same coordinates (< 10m away, allowed is 100m)
      final visit = await checkInUseCase(
        taskId: 'tsk-001',
        location: testLocation,
        currentLatitude: 37.77492,
        currentLongitude: -122.41941,
        notes: 'Checked in on time',
        enforceRadius: true,
      );

      expect(visit.id, isNotEmpty);
      expect(visit.taskId, equals('tsk-001'));
      expect(visit.locationId, equals('loc-001'));
      expect(visit.isActive, isTrue);
      expect(visit.checkInLatitude, equals(37.77492));
    });

    test('throws ValidationFailure when user is outside site radius and enforceRadius is true', () async {
      // User is far away (~1.5 km away, allowed is 100m)
      expect(
        () async => await checkInUseCase(
          taskId: 'tsk-001',
          location: testLocation,
          currentLatitude: 37.7879,
          currentLongitude: -122.4074,
          enforceRadius: true,
        ),
        throwsA(isA<ValidationFailure>().having(
          (e) => e.message,
          'message',
          contains('You are outside the allowed site radius'),
        )),
      );
    });

    test('succeeds when outside radius if enforceRadius is explicitly disabled', () async {
      final visit = await checkInUseCase(
        taskId: 'tsk-001',
        location: testLocation,
        currentLatitude: 37.7879,
        currentLongitude: -122.4074,
        enforceRadius: false,
      );

      expect(visit.id, isNotEmpty);
      expect(visit.isActive, isTrue);
    });
  });

  group('VisitCheckOutUseCase Tests', () {
    test('checks out active visit and completes it', () async {
      // First create active visit
      final active = await checkInUseCase(
        taskId: 'tsk-002',
        location: testLocation,
        currentLatitude: 37.7749,
        currentLongitude: -122.4194,
        enforceRadius: true,
      );

      // Perform check out
      final checkedOut = await checkOutUseCase(
        visitId: active.id,
        latitude: 37.77495,
        longitude: -122.41942,
        notes: 'Completed replacement safely',
      );

      expect(checkedOut.isCompleted, isTrue);
      expect(checkedOut.checkOutAt, isNotNull);
      expect(checkedOut.checkOutLatitude, equals(37.77495));
      expect(checkedOut.notes, equals('Completed replacement safely'));
    });
  });

  group('VisitRepository Queries Tests', () {
    test('getVisitsUseCase returns visit history', () async {
      final visits = await getVisitsUseCase();
      expect(visits.isNotEmpty, isTrue);
    });

    test('getActiveVisitUseCase returns active visit for user or task', () async {
      // Clean previous active visits for clean test
      remoteDataSource.visits.removeWhere((k, v) => v.checkOutAt == null);

      final visit = await checkInUseCase(
        taskId: 'tsk-003',
        location: testLocation,
        currentLatitude: 37.7749,
        currentLongitude: -122.4194,
      );

      final active = await getActiveVisitUseCase(taskId: 'tsk-003');
      expect(active, isNotNull);
      expect(active?.id, equals(visit.id));
    });
  });
}
