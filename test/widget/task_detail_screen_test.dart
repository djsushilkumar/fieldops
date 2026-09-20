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
import 'package:field_ops/features/tasks/presentation/screens/task_detail_screen.dart';

class StubTaskRepoForDetailTest implements TaskRepository {
  TaskEntity task;

  StubTaskRepoForDetailTest(this.task);

  @override
  Future<List<TaskEntity>> getTasks({dynamic filter}) async => [task];

  @override
  Future<TaskEntity> getTask(String taskId) async => task;

  @override
  Future<TaskEntity> createTask(TaskEntity task, {String? assignToUserId}) async => task;

  @override
  Future<TaskEntity> assignTask(String taskId, String userId) async {
    task = task.copyWith(assignedToUserId: userId);
    return task;
  }

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status, {String? notes}) async {
    task = task.copyWith(
      status: status,
      notes: notes ?? task.notes,
      actualStart: status == TaskStatus.inProgress ? DateTime.now() : task.actualStart,
      actualEnd: status == TaskStatus.completed ? DateTime.now() : task.actualEnd,
    );
    return task;
  }

  @override
  Future<TaskEntity> startTask(String taskId) async {
    return await updateTaskStatus(taskId, TaskStatus.inProgress);
  }

  @override
  Future<TaskEntity> completeTask(String taskId, {String? notes}) async {
    return await updateTaskStatus(taskId, TaskStatus.completed, notes: notes);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleTask = TaskEntity(
    id: 'tsk-001',
    organizationId: 'org-001',
    title: 'AC Service & Coil Cleaning',
    description: 'Quarterly deep cleaning of rooftop compressors',
    status: TaskStatus.assigned,
    priority: TaskPriority.high,
    assignedToUserId: 'usr-emp-001',
    assignedToUserName: 'David Miller',
    customerName: 'Metro Health Plaza',
    locationName: 'Roof Unit 4',
    requiresGps: true,
    requiresPhoto: true,
    requiresForm: true,
    notes: 'Security clearance code is 1234',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
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

  testWidgets('TaskDetailScreen renders task details, proof checklist and action buttons', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = StubTaskRepoForDetailTest(sampleTask);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(employeeUser),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskDetailScreen(taskId: 'tsk-001'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify task headers
    expect(find.text('AC Service & Coil Cleaning'), findsOneWidget);
    expect(find.text('Metro Health Plaza'), findsOneWidget);
    expect(find.text('Roof Unit 4'), findsOneWidget);
    expect(find.text('Mandatory Proof Requirements'), findsOneWidget);
    expect(find.text('Security clearance code is 1234'), findsOneWidget);

    // In 'assigned' status, 'Start Field Task' button should be visible
    expect(find.text('Start Field Task'), findsOneWidget);

    // Tap 'Start Field Task'
    await tester.ensureVisible(find.text('Start Field Task'));
    await tester.tap(find.text('Start Field Task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Now task status is IN_PROGRESS, 'Complete Task & Submit Proof' button should appear
    expect(find.text('Complete Task & Submit Proof'), findsOneWidget);

    // Tap 'Complete Task & Submit Proof'
    await tester.ensureVisible(find.text('Complete Task & Submit Proof'));
    await tester.tap(find.text('Complete Task & Submit Proof'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Now task is completed
    expect(find.text('Task Successfully Completed'), findsOneWidget);
  });
}
