import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/sync_queue_local_datasource.dart';
import '../../data/datasources/sync_remote_datasource.dart';
import '../../data/repositories/sync_queue_repository_impl.dart';
import '../../domain/entities/conflict_resolution_strategy.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../services/network_connectivity_service.dart';
import '../../services/sync_queue_engine.dart';

// --- Dependency Providers ---

final networkConnectivityServiceProvider = Provider<NetworkConnectivityService>((ref) {
  final service = NetworkConnectivityServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

final syncRemoteDataSourceProvider = Provider<SyncRemoteDataSource>((ref) {
  return MockSyncRemoteDataSource();
});

final syncQueueLocalDataSourceProvider = Provider<SyncQueueLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncQueueLocalDataSourceImpl(database: db);
});

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  final local = ref.watch(syncQueueLocalDataSourceProvider);
  return SyncQueueRepositoryImpl(localDataSource: local);
});

final syncQueueEngineProvider = Provider<SyncQueueEngine>((ref) {
  final repo = ref.watch(syncQueueRepositoryProvider);
  final remote = ref.watch(syncRemoteDataSourceProvider);
  final db = ref.watch(appDatabaseProvider);
  final conn = ref.watch(networkConnectivityServiceProvider);

  final engine = SyncQueueEngine(
    repository: repo,
    remoteDataSource: remote,
    database: db,
    connectivityService: conn,
  );

  ref.onDispose(() => engine.dispose());
  return engine;
});

// --- Controller State ---

class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final List<SyncQueueItem> queueItems;
  final ConflictResolutionStrategy strategy;

  const SyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.lastError,
    this.queueItems = const [],
    this.strategy = ConflictResolutionStrategy.clientWins,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? lastError,
    List<SyncQueueItem>? queueItems,
    ConflictResolutionStrategy? strategy,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      queueItems: queueItems ?? this.queueItems,
      strategy: strategy ?? this.strategy,
    );
  }
}

// --- Controller Notifier ---

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncQueueEngine _engine;
  final SyncQueueRepository _repository;
  final NetworkConnectivityService _connectivity;
  final Ref _ref;

  SyncNotifier({
    required SyncQueueEngine engine,
    required SyncQueueRepository repository,
    required NetworkConnectivityService connectivity,
    required Ref ref,
  })  : _engine = engine,
        _repository = repository,
        _connectivity = connectivity,
        _ref = ref,
        super(SyncState(
          isOnline: connectivity.isOnline,
          strategy: engine.conflictStrategy,
        )) {
    _init();
  }

  StreamSubscription<ConnectivityStatus>? _connSub;

  void _init() {
    _connSub = _connectivity.onConnectivityChanged.listen((status) {
      if (!mounted) return;
      state = state.copyWith(isOnline: status == ConnectivityStatus.online);
      loadQueue();
    });

    loadQueue();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  String? _currentUserId() {
    final user = _ref.read(currentUserProvider);
    return user?.id;
  }

  Future<void> loadQueue() async {
    final userId = _currentUserId();
    final items = await _repository.getAllItems(userId: userId);
    final pendingCount = items.where((i) => i.isPending || i.isSyncing).length;

    if (!mounted) return;
    state = state.copyWith(
      isOnline: _connectivity.isOnline,
      isSyncing: _engine.isSyncing,
      pendingCount: pendingCount,
      lastSyncTime: _engine.lastSyncTime ?? state.lastSyncTime,
      queueItems: items,
    );
  }

  Future<SyncResult> syncNow() async {
    if (state.isSyncing) {
      return const SyncResult(errors: ['Sync already in progress']);
    }

    state = state.copyWith(isSyncing: true, lastError: null);
    try {
      final result = await _engine.syncAll(userId: _currentUserId());
      await loadQueue();
      if (!mounted) return result;
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: _engine.lastSyncTime,
        lastError: result.hasErrors ? result.errors.first : null,
      );
      return result;
    } catch (e) {
      if (!mounted) return SyncResult(errors: [e.toString()]);
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      return SyncResult(errors: [e.toString()]);
    }
  }

  Future<void> retryAllFailed() async {
    state = state.copyWith(isSyncing: true);
    await _engine.retryAllFailed(userId: _currentUserId());
    await loadQueue();
    state = state.copyWith(isSyncing: false);
  }

  Future<void> retryItem(String id) async {
    await _repository.updateItemStatus(id, SyncStatus.pending, scheduledRetryAt: null);
    await syncNow();
  }

  Future<void> deleteItem(String id) async {
    await _repository.removeItem(id);
    await loadQueue();
  }

  Future<void> clearSynced() async {
    await _repository.clearSyncedItems();
    await loadQueue();
  }

  void setConflictStrategy(ConflictResolutionStrategy strategy) {
    _engine.conflictStrategy = strategy;
    state = state.copyWith(strategy: strategy);
  }

  void toggleOnlineSimulation() {
    final conn = _connectivity;
    if (conn is NetworkConnectivityServiceImpl) {
      final current = conn.isOnline;
      conn.setOnline(!current);
      state = state.copyWith(isOnline: !current);
    }
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final engine = ref.watch(syncQueueEngineProvider);
  final repo = ref.watch(syncQueueRepositoryProvider);
  final conn = ref.watch(networkConnectivityServiceProvider);

  return SyncNotifier(
    engine: engine,
    repository: repo,
    connectivity: conn,
    ref: ref,
  );
});
