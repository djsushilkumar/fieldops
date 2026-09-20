import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/database/app_database.dart';
import 'package:field_ops/core/database/sqlite_database.dart';
import 'package:field_ops/features/sync/data/datasources/sync_queue_local_datasource.dart';
import 'package:field_ops/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:field_ops/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:field_ops/features/sync/domain/entities/conflict_resolution_strategy.dart';
import 'package:field_ops/features/sync/domain/entities/sync_entity_type.dart';
import 'package:field_ops/features/sync/domain/entities/sync_operation.dart';
import 'package:field_ops/features/sync/domain/entities/sync_status.dart';
import 'package:field_ops/features/sync/services/network_connectivity_service.dart';
import 'package:field_ops/features/sync/services/sync_queue_engine.dart';

void main() {
  late SqliteDatabase db;
  late SyncQueueLocalDataSource localDataSource;
  late SyncQueueRepositoryImpl repository;
  late MockSyncRemoteDataSource remoteDataSource;
  late NetworkConnectivityServiceImpl connectivityService;
  late SyncQueueEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = SqliteDatabaseImpl(
      name: 'test_sync_db',
      tables: AppDatabase.allTables,
      prefs: prefs,
    );
    await db.open();

    localDataSource = SyncQueueLocalDataSourceImpl(database: db);
    repository = SyncQueueRepositoryImpl(localDataSource: localDataSource);
    remoteDataSource = MockSyncRemoteDataSource();
    connectivityService = NetworkConnectivityServiceImpl(initialOnline: true);

    engine = SyncQueueEngine(
      repository: repository,
      remoteDataSource: remoteDataSource,
      database: db,
      connectivityService: connectivityService,
      conflictStrategy: ConflictResolutionStrategy.clientWins,
    );
  });

  tearDown(() {
    engine.dispose();
    connectivityService.dispose();
  });

  group('SyncQueueEngine Tests', () {
    test('enqueueMutation saves item in queue and optimistic record in local db', () async {
      final item = await engine.enqueueMutation(
        userId: 'user-001',
        entityType: SyncEntityType.task,
        entityId: 'task-offline-01',
        operation: SyncOperation.update,
        payload: {
          'id': 'task-offline-01',
          'title': 'Emergency Valve Inspection',
          'status': 'IN_PROGRESS',
          'organization_id': 'org-001',
        },
      );

      expect(item.id.isNotEmpty, isTrue);
      expect(item.status, SyncStatus.pending);

      // Verify in sync_queue
      final pending = await repository.getPendingItems();
      expect(pending.length, 1);
      expect(pending.first.entityId, 'task-offline-01');

      // Verify in local sqlite tasks table
      final localTask = await db.query('tasks', where: 'id = ?', whereArgs: ['task-offline-01']);
      expect(localTask.isNotEmpty, isTrue);
      expect(localTask.first['status'], 'IN_PROGRESS');
    });

    test('processQueue pushes pending items to remote and marks them as synced', () async {
      await engine.enqueueMutation(
        userId: 'user-001',
        entityType: SyncEntityType.task,
        entityId: 'task-001',
        operation: SyncOperation.update,
        payload: {'id': 'task-001', 'title': 'Inspect Generator'},
      );

      final result = await engine.processQueue();
      expect(result.isSuccess, isTrue);
      expect(result.successCount, 1);
      expect(result.failedCount, 0);

      // Remote data source received it
      expect(remoteDataSource.pushedItems.length, 1);
      expect(remoteDataSource.pushedItems.first.entityId, 'task-001');

      // Queue item status updated to synced
      final allItems = await repository.getAllItems();
      expect(allItems.first.isSynced, isTrue);
    });

    test('processQueue applies exponential backoff on network failure', () async {
      remoteDataSource.simulateError = true;

      await engine.enqueueMutation(
        userId: 'user-001',
        entityType: SyncEntityType.visit,
        entityId: 'visit-001',
        operation: SyncOperation.create,
        payload: {'id': 'visit-001'},
      );

      final result = await engine.processQueue();
      expect(result.hasErrors, isTrue);
      expect(result.failedCount, 1);

      final items = await repository.getAllItems();
      final item = items.first;
      expect(item.attempts, 1);
      expect(item.lastError, contains('Simulated network error'));
      expect(item.scheduledRetryAt, isNotNull);
      expect(item.scheduledRetryAt!.isAfter(DateTime.now()), isTrue);
    });

    test('offline mode defers sync and connectivity change auto-syncs', () async {
      connectivityService.setOnline(false);

      await engine.enqueueMutation(
        userId: 'user-001',
        entityType: SyncEntityType.formSubmission,
        entityId: 'sub-001',
        operation: SyncOperation.create,
        payload: {'id': 'sub-001'},
      );

      // Attempting to process queue while offline should defer
      final result = await engine.processQueue();
      expect(result.errors.first, contains('offline'));
      expect(remoteDataSource.pushedItems.isEmpty, isTrue);

      // Transition to online should trigger syncAll
      connectivityService.setOnline(true);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(remoteDataSource.pushedItems.length, 1);
    });

    test('conflict resolution serverWins overrides local database', () async {
      engine.conflictStrategy = ConflictResolutionStrategy.serverWins;

      // 1. Enqueue local pending edit
      await engine.enqueueMutation(
        userId: 'user-001',
        entityType: SyncEntityType.task,
        entityId: 'task-conflict-01',
        operation: SyncOperation.update,
        payload: {
          'id': 'task-conflict-01',
          'title': 'Local Client Title',
          'status': 'IN_PROGRESS',
          'organization_id': 'org-001',
        },
      );

      // 2. Add server delta with updated status
      remoteDataSource.addServerDelta('task', {
        'id': 'task-conflict-01',
        'title': 'Server Authority Title',
        'status': 'COMPLETED',
        'organization_id': 'org-001',
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. Pull deltas
      await engine.pullDeltas();

      // Verify server record replaced local record
      final taskRow = (await db.query('tasks', where: 'id = ?', whereArgs: ['task-conflict-01'])).first;
      expect(taskRow['title'], 'Server Authority Title');
      expect(taskRow['status'], 'COMPLETED');
    });
  });
}
