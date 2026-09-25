import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../data/datasources/mock_task_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/assign_task_use_case.dart';
import '../../domain/usecases/complete_task_use_case.dart';
import '../../domain/usecases/create_task_use_case.dart';
import '../../domain/usecases/get_task_detail_use_case.dart';
import '../../domain/usecases/get_tasks_use_case.dart';
import '../../domain/usecases/start_task_use_case.dart';
import '../../domain/usecases/update_task_status_use_case.dart';

// ---------------------------------------------------------------------------
// Dependency Injection Providers
// ---------------------------------------------------------------------------

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  return TaskLocalDataSourceImpl();
});

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseTaskRemoteDataSourceImpl(supabase);
  }
  return MockTaskRemoteDataSource();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remote = ref.watch(taskRemoteDataSourceProvider);
  final local = ref.watch(taskLocalDataSourceProvider);
  return TaskRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
  );
});

final getTasksUseCaseProvider = Provider<GetTasksUseCase>((ref) {
  return GetTasksUseCase(ref.watch(taskRepositoryProvider));
});

final getTaskDetailUseCaseProvider = Provider<GetTaskDetailUseCase>((ref) {
  return GetTaskDetailUseCase(ref.watch(taskRepositoryProvider));
});

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>((ref) {
  return CreateTaskUseCase(ref.watch(taskRepositoryProvider));
});

final assignTaskUseCaseProvider = Provider<AssignTaskUseCase>((ref) {
  return AssignTaskUseCase(ref.watch(taskRepositoryProvider));
});

final updateTaskStatusUseCaseProvider = Provider<UpdateTaskStatusUseCase>((ref) {
  return UpdateTaskStatusUseCase(ref.watch(taskRepositoryProvider));
});

final startTaskUseCaseProvider = Provider<StartTaskUseCase>((ref) {
  return StartTaskUseCase(ref.watch(taskRepositoryProvider));
});

final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>((ref) {
  return CompleteTaskUseCase(ref.watch(taskRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Task List State & Notifier
// ---------------------------------------------------------------------------

enum TaskListStatus { loading, success, error }

class TaskListState {
  final TaskListStatus status;
  final List<TaskEntity> tasks;
  final TaskFilter filter;
  final String? errorMessage;

  const TaskListState({
    this.status = TaskListStatus.loading,
    this.tasks = const [],
    this.filter = const TaskFilter(),
    this.errorMessage,
  });

  bool get isLoading => status == TaskListStatus.loading;
  bool get hasError => status == TaskListStatus.error;
  bool get isEmpty => status == TaskListStatus.success && tasks.isEmpty;

  TaskListState copyWith({
    TaskListStatus? status,
    List<TaskEntity>? tasks,
    TaskFilter? filter,
    String? errorMessage,
  }) {
    return TaskListState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final GetTasksUseCase _getTasksUseCase;
  final Ref _ref;

  TaskListNotifier({
    required GetTasksUseCase getTasksUseCase,
    required Ref ref,
  })  : _getTasksUseCase = getTasksUseCase,
        _ref = ref,
        super(const TaskListState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(status: TaskListStatus.loading, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      var currentFilter = state.filter;

      // If user is a field employee, constrain to tasks assigned to them by default
      if (user != null && user.role.isEmployee && currentFilter.assignedUserId == null) {
        currentFilter = currentFilter.copyWith(assignedUserId: user.id);
      }

      final tasks = await _getTasksUseCase.execute(filter: currentFilter);
      if (!mounted) return;
      state = state.copyWith(
        status: TaskListStatus.success,
        tasks: tasks,
        filter: currentFilter,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: TaskListStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
    loadTasks();
  }

  void setStatusFilter(TaskStatus? status) {
    final newFilter = state.filter.copyWith(
      status: status,
      clearStatus: status == null,
    );
    setFilter(newFilter);
  }

  void setSearchQuery(String query) {
    final newFilter = state.filter.copyWith(searchQuery: query);
    setFilter(newFilter);
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      final updateUseCase = _ref.read(updateTaskStatusUseCaseProvider);
      final updated = await updateUseCase.execute(taskId, newStatus);
      final List<TaskEntity> updatedTasks =
          state.tasks.map((t) => t.id == taskId ? updated : t).toList();
      state = state.copyWith(tasks: updatedTasks);
    } catch (_) {
      loadTasks();
    }
  }
}

final taskListNotifierProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  return TaskListNotifier(
    getTasksUseCase: ref.watch(getTasksUseCaseProvider),
    ref: ref,
  );
});

// ---------------------------------------------------------------------------
// Task Detail State & Notifier (Family Provider)
// ---------------------------------------------------------------------------

class TaskDetailState {
  final bool isLoading;
  final TaskEntity? task;
  final String? errorMessage;
  final bool isUpdating;

  const TaskDetailState({
    this.isLoading = false,
    this.task,
    this.errorMessage,
    this.isUpdating = false,
  });

  TaskDetailState copyWith({
    bool? isLoading,
    TaskEntity? task,
    String? errorMessage,
    bool? isUpdating,
  }) {
    return TaskDetailState(
      isLoading: isLoading ?? this.isLoading,
      task: task ?? this.task,
      errorMessage: errorMessage,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  final String taskId;
  final GetTaskDetailUseCase _getTaskDetailUseCase;
  final UpdateTaskStatusUseCase _updateStatusUseCase;
  final StartTaskUseCase _startTaskUseCase;
  final CompleteTaskUseCase _completeTaskUseCase;
  final AssignTaskUseCase _assignTaskUseCase;
  final Ref _ref;

  TaskDetailNotifier({
    required this.taskId,
    required GetTaskDetailUseCase getTaskDetailUseCase,
    required UpdateTaskStatusUseCase updateStatusUseCase,
    required StartTaskUseCase startTaskUseCase,
    required CompleteTaskUseCase completeTaskUseCase,
    required AssignTaskUseCase assignTaskUseCase,
    required Ref ref,
  })  : _getTaskDetailUseCase = getTaskDetailUseCase,
        _updateStatusUseCase = updateStatusUseCase,
        _startTaskUseCase = startTaskUseCase,
        _completeTaskUseCase = completeTaskUseCase,
        _assignTaskUseCase = assignTaskUseCase,
        _ref = ref,
        super(const TaskDetailState(isLoading: true)) {
    loadTask();
  }

  Future<void> loadTask() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final task = await _getTaskDetailUseCase.execute(taskId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, task: task);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> startTask() async {
    state = state.copyWith(isUpdating: true);
    try {
      final updated = await _startTaskUseCase.execute(taskId);
      if (!mounted) return false;
      state = state.copyWith(isUpdating: false, task: updated);
      _ref.read(taskListNotifierProvider.notifier).loadTasks();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> completeTask({String? notes}) async {
    state = state.copyWith(isUpdating: true);
    try {
      final updated = await _completeTaskUseCase.execute(taskId, notes: notes);
      if (!mounted) return false;
      state = state.copyWith(isUpdating: false, task: updated);
      _ref.read(taskListNotifierProvider.notifier).loadTasks();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateStatus(TaskStatus status, {String? notes}) async {
    state = state.copyWith(isUpdating: true);
    try {
      final updated = await _updateStatusUseCase.execute(taskId, status, notes: notes);
      if (!mounted) return false;
      state = state.copyWith(isUpdating: false, task: updated);
      _ref.read(taskListNotifierProvider.notifier).loadTasks();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> assignTask(String userId) async {
    state = state.copyWith(isUpdating: true);
    try {
      final updated = await _assignTaskUseCase.execute(taskId, userId);
      if (!mounted) return false;
      state = state.copyWith(isUpdating: false, task: updated);
      _ref.read(taskListNotifierProvider.notifier).loadTasks();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final taskDetailNotifierProvider =
    StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, String>(
        (ref, taskId) {
  return TaskDetailNotifier(
    taskId: taskId,
    getTaskDetailUseCase: ref.watch(getTaskDetailUseCaseProvider),
    updateStatusUseCase: ref.watch(updateTaskStatusUseCaseProvider),
    startTaskUseCase: ref.watch(startTaskUseCaseProvider),
    completeTaskUseCase: ref.watch(completeTaskUseCaseProvider),
    assignTaskUseCase: ref.watch(assignTaskUseCaseProvider),
    ref: ref,
  );
});
