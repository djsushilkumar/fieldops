import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';
import 'package:field_ops/features/tasks/domain/repositories/task_repository.dart';
import 'package:field_ops/features/tasks/presentation/controllers/task_controller.dart';
import 'package:field_ops/features/tasks/presentation/screens/task_list_screen.dart';

class MockTaskRepositoryForWidgetTest implements TaskRepository {
  final List<TaskEntity> _tasks;

  MockTaskRepositoryForWidgetTest(this._tasks);

  @override
  Future<List<TaskEntity>> getTasks({dynamic filter}) async {
    var list = List<TaskEntity>.from(_tasks);
    if (filter != null) {
      if (filter.status != null) {
        list = list.where((t) => t.status == filter.status).toList();
      }
      if (filter.searchQuery != null && filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        list = list.where((t) =>
            t.title.toLowerCase().contains(q) ||
            (t.customerName?.toLowerCase().contains(q) ?? false)).toList();
      }
    }
    return list;
  }

  @override
  Future<TaskEntity> getTask(String taskId) async {
    return _tasks.firstWhere((t) => t.id == taskId);
  }

  @override
  Future<TaskEntity> createTask(TaskEntity task, {String? assignToUserId}) async => task;

  @override
  Future<TaskEntity> assignTask(String taskId, String userId) async => _tasks.first;

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status, {String? notes}) async => _tasks.first;

  @override
  Future<TaskEntity> startTask(String taskId) async => _tasks.first;

  @override
  Future<TaskEntity> completeTask(String taskId, {String? notes}) async => _tasks.first;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final task1 = TaskEntity(
    id: 'tsk-001',
    organizationId: 'org-001',
    title: 'AC Service & Coil Cleaning',
    description: 'Clean roof compressor unit',
    status: TaskStatus.assigned,
    priority: TaskPriority.high,
    assignedToUserId: 'usr-emp-001',
    assignedToUserName: 'David Miller',
    customerName: 'Metro Health Plaza',
    locationName: 'Utility Room 4',
    requiresGps: true,
    requiresPhoto: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final task2 = TaskEntity(
    id: 'tsk-002',
    organizationId: 'org-001',
    title: 'Thermal Imaging Inspection',
    description: 'Check breaker panel thermal balance',
    status: TaskStatus.inProgress,
    priority: TaskPriority.urgent,
    assignedToUserId: 'usr-emp-001',
    assignedToUserName: 'David Miller',
    customerName: 'Omni Retail Mall',
    locationName: 'Basement Substation',
    requiresGps: true,
    requiresPhoto: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final adminUser = UserEntity(
    id: 'usr-admin-001',
    organizationId: 'org-001',
    name: 'Admin User',
    email: 'admin@fieldops.com',
    role: UserRole.admin,
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final employeeUser = UserEntity(
    id: 'usr-emp-001',
    organizationId: 'org-001',
    name: 'David Miller',
    email: 'employee@fieldops.com',
    role: UserRole.employee,
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  testWidgets('TaskListScreen renders tasks list with badges and customer names', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = MockTaskRepositoryForWidgetTest([task1, task2]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(adminUser),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskListScreen(mode: TaskViewMode.admin),
        ),
      ),
    );

    // Initial pump & settle async data
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Task Operations'), findsOneWidget);
    expect(find.text('AC Service & Coil Cleaning'), findsOneWidget);
    expect(find.text('Thermal Imaging Inspection'), findsOneWidget);
    expect(find.textContaining('Metro Health Plaza'), findsOneWidget);
    expect(find.textContaining('Omni Retail Mall'), findsOneWidget);
  });

  testWidgets('TaskListScreen FAB visible for Admin', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = MockTaskRepositoryForWidgetTest([task1]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(adminUser),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskListScreen(mode: TaskViewMode.admin),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets('TaskListScreen FAB hidden for Field Employee', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = MockTaskRepositoryForWidgetTest([task1]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(employeeUser),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskListScreen(mode: TaskViewMode.employee),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('New Task'), findsNothing);
  });

  testWidgets('TaskListScreen filter chip filters task list and empty state on no match', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = MockTaskRepositoryForWidgetTest([task1, task2]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(adminUser),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskListScreen(mode: TaskViewMode.admin),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 'In Progress' filter chip specifically
    await tester.tap(find.widgetWithText(FilterChip, 'In Progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Thermal Imaging Inspection'), findsOneWidget);
    expect(find.text('AC Service & Coil Cleaning'), findsNothing);

    // Tap 'Completed' filter chip (0 completed tasks)
    await tester.tap(find.widgetWithText(FilterChip, 'Completed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No Tasks Found'), findsOneWidget);
    expect(find.text('Clear Filter'), findsOneWidget);

    // Tap 'Clear Filter' button to restore
    await tester.tap(find.text('Clear Filter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AC Service & Coil Cleaning'), findsOneWidget);
    expect(find.text('Thermal Imaging Inspection'), findsOneWidget);
  });
}
