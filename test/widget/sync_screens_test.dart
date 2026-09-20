import 'package:flutter/material.dart';
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
import 'package:field_ops/features/sync/domain/entities/sync_entity_type.dart';
import 'package:field_ops/features/sync/domain/entities/sync_operation.dart';
import 'package:field_ops/features/sync/presentation/controllers/sync_controller.dart';
import 'package:field_ops/features/sync/presentation/screens/sync_screen.dart';
import 'package:field_ops/features/sync/presentation/widgets/sync_status_bar.dart';
import 'package:field_ops/features/sync/services/network_connectivity_service.dart';
import 'package:field_ops/features/sync/services/sync_queue_engine.dart';

void main() {
  late SqliteDatabase db;
  late SyncQueueLocalDataSource localDataSource;
  late SyncQueueRepositoryImpl repository;
  late MockSyncRemoteDataSource remoteDataSource;
  late NetworkConnectivityServiceImpl connectivityService;
  late SyncQueueEngine engine;

  final testUser = UserEntity(
    id: 'user-widget-001',
    organizationId: 'org-001',
    email: 'tech@fieldops.com',
    role: UserRole.employee,
    name: 'Field Tech',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = SqliteDatabaseImpl(name: 'test_widget_db', tables: AppDatabase.allTables, prefs: prefs);
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
  });

  Widget createWidgetUnderTest(Widget child, {List<Override> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncQueueLocalDataSourceProvider.overrideWithValue(localDataSource),
        syncQueueRepositoryProvider.overrideWithValue(repository),
        syncRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
        networkConnectivityServiceProvider.overrideWithValue(connectivityService),
        syncQueueEngineProvider.overrideWithValue(engine),
        currentUserProvider.overrideWithValue(testUser),
        ...extraOverrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Sync Widgets & Screens Tests', () {
    testWidgets('SyncStatusBar renders all changes synced when online and empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const Scaffold(body: SyncStatusBar())));
      await tester.pumpAndSettle();

      expect(find.text('All changes synced'), findsOneWidget);
    });

    testWidgets('SyncStatusBar renders offline warning banner when offline with pending items', (tester) async {
      connectivityService.setOnline(false);

      await repository.enqueue(
        SyncQueueModel(
          id: 'item-off-1',
          userId: 'user-widget-001',
          operation: SyncOperation.update,
          entityType: SyncEntityType.task,
          entityId: 'task-999',
          payload: {'status': 'IN_PROGRESS'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(const Scaffold(body: SyncStatusBar())));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline • 1 changes queued'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('SyncScreen renders metrics, strategy selector, and queue list', (tester) async {
      await repository.enqueue(
        SyncQueueModel(
          id: 'item-scr-1',
          userId: 'user-widget-001',
          operation: SyncOperation.create,
          entityType: SyncEntityType.task,
          entityId: 'task-777',
          payload: {'title': 'Compressor Filter Service'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(const SyncScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Offline Sync & Local Queue'), findsOneWidget);
      expect(find.text('Online (Connected)'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Conflict Resolution Strategy'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.textContaining('Task: task-777'), findsOneWidget);
    });

    testWidgets('SyncScreen toggles online simulation and triggers sync', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const SyncScreen()));
      await tester.pumpAndSettle();

      // Find simulation switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap switch to simulate offline
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode Active'), findsOneWidget);
    });
  });
}

