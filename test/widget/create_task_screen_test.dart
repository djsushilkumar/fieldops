import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/organization/domain/entities/organization_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';
import 'package:field_ops/features/tasks/domain/repositories/task_repository.dart';
import 'package:field_ops/features/tasks/presentation/controllers/task_controller.dart';
import 'package:field_ops/features/tasks/presentation/screens/create_task_screen.dart';

class StubTaskRepoForCreateTest implements TaskRepository {
  TaskEntity? lastCreatedTask;
  String? lastAssignedUserId;

  @override
  Future<List<TaskEntity>> getTasks({dynamic filter}) async => [];

  @override
  Future<TaskEntity> getTask(String taskId) async => throw UnimplementedError();

  @override
  Future<TaskEntity> createTask(TaskEntity task, {String? assignToUserId}) async {
    lastCreatedTask = task;
    lastAssignedUserId = assignToUserId;
    return task.copyWith(id: 'created-task-id');
  }

  @override
  Future<TaskEntity> assignTask(String taskId, String userId) async => throw UnimplementedError();

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status, {String? notes}) async =>
      throw UnimplementedError();

  @override
  Future<TaskEntity> startTask(String taskId) async => throw UnimplementedError();

  @override
  Future<TaskEntity> completeTask(String taskId, {String? notes}) async => throw UnimplementedError();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final managerUser = UserEntity(
    id: 'usr-mgr-001',
    organizationId: 'org-001',
    name: 'Marcus Vance',
    email: 'manager@fieldops.com',
    role: UserRole.manager,
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final testOrg = OrganizationEntity(
    id: 'org-001',
    name: 'Acme Operations Ltd',
    timezone: 'America/New_York',
    currency: 'USD',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  testWidgets('CreateTaskScreen renders form, validates title, and submits task', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = StubTaskRepoForCreateTest();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(managerUser),
          currentOrgProvider.overrideWithValue(testOrg),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateTaskScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify initial fields are rendered
    expect(find.text('Create New Task'), findsOneWidget);
    expect(find.text('Task Title *'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Client / Customer Name'), findsOneWidget);
    expect(find.text('Site / Location'), findsOneWidget);
    expect(find.text('Publish & Dispatch Task'), findsOneWidget);

    // Try submitting empty title -> validation error
    await tester.ensureVisible(find.text('Publish & Dispatch Task'));
    await tester.tap(find.text('Publish & Dispatch Task'));
    await tester.pump();

    expect(find.text('Please enter task title'), findsOneWidget);

    // Enter a valid title
    await tester.enterText(
      find.byType(TextFormField).first,
      'Emergency Water Pipe Fix',
    );
    await tester.pump();

    // Tap Urgent priority
    await tester.ensureVisible(find.text('Urgent'));
    await tester.tap(find.text('Urgent'));
    await tester.pump();

    // Submit valid task
    await tester.ensureVisible(find.text('Publish & Dispatch Task'));
    await tester.tap(find.text('Publish & Dispatch Task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify repository received the task with correct fields
    expect(repo.lastCreatedTask, isNotNull);
    expect(repo.lastCreatedTask!.title, equals('Emergency Water Pipe Fix'));
    expect(repo.lastCreatedTask!.priority, equals(TaskPriority.urgent));
    expect(repo.lastCreatedTask!.requiresGps, isTrue);
    expect(repo.lastCreatedTask!.requiresPhoto, isTrue);
    expect(repo.lastAssignedUserId, equals('usr-emp-003'));
  });
}
