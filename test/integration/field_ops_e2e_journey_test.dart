import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:field_ops/features/attendance/data/datasources/mock_attendance_remote_datasource.dart';
import 'package:field_ops/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:field_ops/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:field_ops/features/attendance/presentation/screens/field_home_screen.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/dashboard/presentation/screens/manager_dashboard_screen.dart';
import 'package:field_ops/features/navigation/presentation/screens/admin_settings_screen.dart';
import 'package:field_ops/features/organization/data/datasources/organization_remote_datasource.dart';
import 'package:field_ops/features/organization/presentation/controllers/organization_settings_controller.dart';
import 'package:field_ops/features/organization/presentation/screens/organization_profile_screen.dart';
import 'package:field_ops/features/organization/presentation/screens/role_permissions_screen.dart';
import 'package:field_ops/features/organization/presentation/screens/team_members_screen.dart';
import 'package:field_ops/features/organization/presentation/screens/teams_management_screen.dart';
import 'package:field_ops/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:field_ops/features/reports/presentation/controllers/reports_controller.dart';
import 'package:field_ops/features/reports/presentation/screens/field_reports_screen.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';
import 'package:field_ops/features/tasks/domain/repositories/task_repository.dart';
import 'package:field_ops/features/tasks/presentation/controllers/task_controller.dart';
import 'package:field_ops/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:field_ops/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:field_ops/features/tasks/presentation/screens/task_list_screen.dart';

class StubTaskRepoForJourney implements TaskRepository {
  TaskEntity task;

  StubTaskRepoForJourney(this.task);

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

  final testEmployee = UserEntity(
    id: 'usr-employee-001',
    email: 'employee@fieldops.com',
    name: 'Alex Rivera',
    organizationId: 'org-acme-ops-001',
    role: UserRole.employee,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleTask = TaskEntity(
    id: 'task-001',
    organizationId: 'org-acme-ops-001',
    title: 'AC Service & Coil Cleaning',
    description: 'Quarterly deep cleaning of rooftop compressors',
    status: TaskStatus.assigned,
    priority: TaskPriority.high,
    assignedToUserId: 'usr-employee-001',
    assignedToUserName: 'Alex Rivera',
    customerName: 'Metro Health Plaza',
    locationName: 'Roof Unit 4',
    requiresGps: true,
    requiresPhoto: true,
    requiresForm: false,
    notes: 'Security clearance code is 1234',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockLocationService = MockLocationService(
    initialCoordinates: const LocationCoordinates(
      latitude: 37.7749,
      longitude: -122.4194,
      accuracy: 5.0,
    ),
  );

  Widget buildTestApp(Widget home) {
    final remoteAttendance = MockAttendanceRemoteDataSource(seedData: true);
    final localAttendance = AttendanceLocalDataSourceImpl();
    final attendanceRepo = AttendanceRepositoryImpl(
      remoteDataSource: remoteAttendance,
      localDataSource: localAttendance,
    );
    final stubTaskRepo = StubTaskRepoForJourney(sampleTask);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => testEmployee),
        locationServiceProvider.overrideWithValue(mockLocationService),
        attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        taskRepositoryProvider.overrideWithValue(stubTaskRepo),
        reportsRemoteDataSourceProvider.overrideWithValue(MockReportsRemoteDataSource()),
        organizationRemoteDataSourceProvider.overrideWithValue(MockOrganizationRemoteDataSourceImpl()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: home,
      ),
    );
  }

  group('FieldOps End-to-End Real-World User Journeys', () {
    testWidgets('Journey 1: Field Employee Daily Operational Lifecycle', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Employee Opens Field Home
      await tester.pumpWidget(buildTestApp(const FieldHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Field Home'), findsOneWidget);
      expect(find.text('Daily Attendance'), findsOneWidget);
      expect(find.byKey(const Key('attendance_checkin_button')), findsOneWidget);

      // 2. Perform Attendance Check-In with GPS
      await tester.tap(find.byKey(const Key('attendance_checkin_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After check-in, status changes to Checked In and checkout button appears
      expect(find.byKey(const Key('attendance_checkout_button')), findsOneWidget);

      // 3. Navigate to Tasks List
      await tester.pumpWidget(buildTestApp(const TaskListScreen(mode: TaskViewMode.employee)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('My Field Tasks'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Assigned'), findsWidgets);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // 4. Open Task Detail
      await tester.pumpWidget(buildTestApp(const TaskDetailScreen(taskId: 'task-001')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('AC Service & Coil Cleaning'), findsOneWidget);
      expect(find.text('Start Field Task'), findsOneWidget);

      // 5. Start the Work Order
      await tester.tap(find.text('Start Field Task'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 6. Complete Work Order button ready
      expect(find.text('Complete Task & Submit Proof'), findsOneWidget);
    });

    testWidgets('Journey 2: Dispatch Manager Command & Reports Center', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Manager Cockpit & Live Radar
      await tester.pumpWidget(buildTestApp(const ManagerDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Team Field Dispatch'), findsOneWidget);
      expect(find.text('Active Techs'), findsOneWidget);
      expect(find.text('Assign Task'), findsOneWidget);

      // 2. Dispatch a New Urgent Task
      await tester.pumpWidget(buildTestApp(const CreateTaskScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create New Task'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Urgent Chiller Repair - Data Center',
      );
      await tester.pump();

      // Tap Urgent Priority Chip
      await tester.tap(find.text('Urgent'));
      await tester.pump();

      // 3. Open Field Operations Analytics & CSV Center
      await tester.pumpWidget(buildTestApp(const FieldReportsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Field Reports'), findsOneWidget);
      expect(find.text('Instant CSV Export Center'), findsOneWidget);
      expect(find.text('Task Completion'), findsOneWidget);
      expect(find.text('Customer Visits'), findsOneWidget);
    });

    testWidgets('Journey 3: Multi-Tenant Admin & Organization Customization', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Admin Settings Hub
      await tester.pumpWidget(buildTestApp(const AdminSettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Organization Settings'), findsOneWidget);
      expect(find.text('Teams & Dispatch Groups'), findsOneWidget);
      expect(find.text('Team Members & User Directory'), findsOneWidget);
      expect(find.text('Role Permissions Matrix (RBAC)'), findsOneWidget);

      // 2. Organization Profile & Geofence Policy
      await tester.pumpWidget(buildTestApp(const OrganizationProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Organization Tenant ID'), findsOneWidget);
      expect(find.text('Default Site Geofence Radius'), findsOneWidget);
      expect(find.text('Require GPS Verification on Check-in'), findsOneWidget);
      expect(find.text('Require Photo Proof on Task Completion'), findsOneWidget);

      // 3. Teams Management
      await tester.pumpWidget(buildTestApp(const TeamsManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Dispatch Teams'), findsOneWidget);
      expect(find.text('North Bay HVAC Fleet'), findsOneWidget);

      // 4. Staff Directory
      await tester.pumpWidget(buildTestApp(const TeamMembersScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);

      // 5. Role Permissions Matrix
      await tester.pumpWidget(buildTestApp(const RolePermissionsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Role Permissions Matrix'), findsOneWidget);
      expect(find.text('Create & Schedule Tasks'), findsOneWidget);
      expect(find.text('Save Permissions'), findsOneWidget);
    });
  });
}
