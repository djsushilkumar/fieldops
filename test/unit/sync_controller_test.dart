import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/database/app_database.dart';
import 'package:field_ops/core/database/sqlite_database.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/sync/data/datasources/sync_queue_local_datasource.dart';
import 'package:field_ops/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:field_ops/features/sync/data/models/sync_queue_model.dart';
import 'package:field_ops/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:field_ops/features/sync/domain/entities/conflict_resolution_strategy.dart';
import 'package:field_ops/features/sync/domain/entities/sync_entity_type.dart';
import 'package:field_ops/features/sync/domain/entities/sync_operation.dart';
import 'package:field_ops/features/sync/presentation/controllers/sync_controller.dart';
import 'package:field_ops/features/sync/services/network_connectivity_service.dart';
import 'package:field_ops/features/sync/services/sync_queue_engine.dart';

void main() {
  late ProviderContainer container;
  late SqliteDatabase db;
  late SyncQueueLocalDataSource localDataSource;
  late SyncQueueRepositoryImpl repository;
  late MockSyncRemoteDataSource remoteDataSource;
  late NetworkConnectivityServiceImpl connectivityService;
  late SyncQueueEngine engine;

  final testUser = UserEntity(
    id: 'user-sync-001',
    organizationId: 'org-001',
    email: 'field@fieldops.com',
    role: UserRole.employee,
    name: 'Field Tech',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = SqliteDatabaseImpl(name: 'test_sync_ctrl_db', tables: AppDatabase.allTables, prefs: prefs);
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
    );

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncQueueLocalDataSourceProvider.overrideWithValue(localDataSource),
        syncQueueRepositoryProvider.overrideWithValue(repository),
        syncRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
        networkConnectivityServiceProvider.overrideWithValue(connectivityService),
        syncQueueEngineProvider.overrideWithValue(engine),
        currentUserProvider.overrideWithValue(testUser),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SyncController Tests', () {
    test('initial state loads correctly and isOnline is true', () {
      final state = container.read(syncNotifierProvider);
      expect(state.isOnline, isTrue);
      expect(state.isSyncing, isFalse);
      expect(state.pendingCount, 0);
      expect(state.queueItems, isEmpty);
    });

    test('loadQueue detects pending mutations in repository', () async {
      await repository.enqueue(
        SyncQueueModel(
          id: 'item-1',
          userId: 'user-sync-001',
          operation: SyncOperation.update,
          entityType: SyncEntityType.task,
          entityId: 'task-100',
          payload: {'status': 'COMPLETED'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final notifier = container.read(syncNotifierProvider.notifier);
      await notifier.loadQueue();

      final state = container.read(syncNotifierProvider);
      expect(state.pendingCount, 1);
      expect(state.queueItems.length, 1);
      expect(state.queueItems.first.entityId, 'task-100');
    });

    test('syncNow processes pending queue and clears pending count', () async {
      await repository.enqueue(
        SyncQueueModel(
          id: 'item-2',
          userId: 'user-sync-001',
          operation: SyncOperation.create,
          entityType: SyncEntityType.visit,
          entityId: 'visit-200',
          payload: {'check_in_at': DateTime.now().toIso8601String()},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final notifier = container.read(syncNotifierProvider.notifier);
      final result = await notifier.syncNow();

      expect(result.isSuccess, isTrue);
      expect(result.successCount, 1);

      final state = container.read(syncNotifierProvider);
      expect(state.pendingCount, 0);
      expect(state.lastSyncTime, isNotNull);
    });

    test('setConflictStrategy updates strategy in state and engine', () {
      final notifier = container.read(syncNotifierProvider.notifier);
      notifier.setConflictStrategy(ConflictResolutionStrategy.serverWins);

      final state = container.read(syncNotifierProvider);
      expect(state.strategy, ConflictResolutionStrategy.serverWins);
      expect(engine.conflictStrategy, ConflictResolutionStrategy.serverWins);
    });

    test('toggleOnlineSimulation toggles connectivity status', () {
      final notifier = container.read(syncNotifierProvider.notifier);
      expect(container.read(syncNotifierProvider).isOnline, isTrue);

      notifier.toggleOnlineSimulation();
      expect(container.read(syncNotifierProvider).isOnline, isFalse);

      notifier.toggleOnlineSimulation();
      expect(container.read(syncNotifierProvider).isOnline, isTrue);
    });
  });
}

