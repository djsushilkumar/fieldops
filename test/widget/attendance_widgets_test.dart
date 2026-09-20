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
import 'package:field_ops/features/attendance/presentation/screens/my_attendance_history_screen.dart';
import 'package:field_ops/features/attendance/presentation/screens/team_attendance_screen.dart';
import 'package:field_ops/features/attendance/presentation/widgets/attendance_quick_action_card.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testEmployee = UserEntity(
    id: 'usr-employee-001',
    email: 'employee@fieldops.com',
    name: 'Alex River',
    organizationId: 'org-001',
    role: UserRole.employee,
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

  Widget createWidgetUnderTest(Widget child, {MockAttendanceRemoteDataSource? remote}) {
    final remoteDs = remote ?? MockAttendanceRemoteDataSource(seedData: true);
    final localDs = AttendanceLocalDataSourceImpl();
    final repo = AttendanceRepositoryImpl(
      remoteDataSource: remoteDs,
      localDataSource: localDs,
    );

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => testEmployee),
        attendanceRepositoryProvider.overrideWithValue(repo),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('AttendanceQuickActionCard Widget Tests', () {
    testWidgets('renders check-in button, processes check-in, shows timer and checks out',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      await tester.pumpWidget(createWidgetUnderTest(
        const Scaffold(body: SingleChildScrollView(child: AttendanceQuickActionCard())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Daily Attendance'), findsOneWidget);
      expect(find.text('Not Checked In'), findsOneWidget);
      expect(find.byKey(const Key('attendance_checkin_button')), findsOneWidget);

      // Tap Check In
      await tester.tap(find.byKey(const Key('attendance_checkin_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should now be on active shift
      expect(find.text('Active Work Shift'), findsOneWidget);
      expect(find.text('ELAPSED WORKING TIME'), findsOneWidget);
      expect(find.byKey(const Key('attendance_checkout_button')), findsOneWidget);

      // Tap Check Out -> Opens Confirmation Dialog
      await tester.tap(find.byKey(const Key('attendance_checkout_button')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Check Out'), findsNWidgets(2));
      expect(find.text('Are you sure you want to end your work shift? Your total working hours will be calculated.'),
          findsOneWidget);

      // Confirm check out in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Check Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Card now displays Shift Completed
      expect(find.text('Shift Completed'), findsOneWidget);
      expect(find.textContaining('Total Worked:'), findsOneWidget);
    });
  });

  group('FieldHomeScreen Widget Tests', () {
    testWidgets('renders employee greeting, attendance card and operations overview',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      await tester.pumpWidget(createWidgetUnderTest(const FieldHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Field Home'), findsOneWidget);
      expect(find.text('Hello, Alex River'), findsOneWidget);
      expect(find.text('Daily Attendance'), findsOneWidget);
      expect(find.text('Operations Overview'), findsOneWidget);
      expect(find.text('My Attendance History'), findsOneWidget);
    });
  });

  group('TeamAttendanceScreen Widget Tests', () {
    testWidgets('renders date picker bar, metrics, chips and team members', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      await tester.pumpWidget(createWidgetUnderTest(const TeamAttendanceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Present'), findsWidgets);
      expect(find.text('Half Day'), findsWidgets);
      expect(find.text('On Leave'), findsWidgets);

      // Verify seeded team members show up
      expect(find.text('Jordan Lee'), findsOneWidget);
      expect(find.text('Sam Taylor'), findsOneWidget);
      expect(find.text('Morgan Chen'), findsOneWidget);

      // Tap filter chip "On Leave"
      await tester.tap(find.text('On Leave (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Morgan Chen'), findsOneWidget);
      expect(find.text('Jordan Lee'), findsNothing);
    });
  });

  group('MyAttendanceHistoryScreen Widget Tests', () {
    testWidgets('renders summary metrics and history cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      await tester.pumpWidget(createWidgetUnderTest(const MyAttendanceHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Attendance History'), findsOneWidget);
      expect(find.text('Days Present'), findsOneWidget);
      expect(find.text('Total Hours'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Check-In'), findsWidgets);
      expect(find.text('Check-Out'), findsWidgets);
    });
  });
}
