import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/navigation/presentation/screens/admin_shell_screen.dart';
import 'package:field_ops/features/navigation/presentation/screens/employee_shell_screen.dart';
import 'package:field_ops/features/navigation/presentation/screens/manager_shell_screen.dart';
import 'package:field_ops/features/navigation/presentation/screens/slice_placeholder_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Role Shell Navigation Widget Tests', () {
    testWidgets('AdminShellScreen renders navigation destinations and dashboard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminShellScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('FieldOps Command Center'), findsWidgets);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('ManagerShellScreen renders navigation destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ManagerShellScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Team Field Dispatch'), findsWidgets);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Visits'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      // Tap on Reports navigation destination
      await tester.tap(find.text('Reports'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies that FieldReportsScreen renders in ManagerShellScreen
      expect(find.text('Field Reports'), findsWidgets);
      expect(find.text('Instant CSV Export Center'), findsOneWidget);
    });

    testWidgets('EmployeeShellScreen renders navigation destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EmployeeShellScreen(),
          ),
        ),
      );

      expect(find.text('Field Home'), findsWidgets);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Visits'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Tasks navigation destination
      await tester.tap(find.text('Tasks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies that real TaskListScreen renders in employee shell
      expect(find.text('My Field Tasks'), findsOneWidget);
    });

    testWidgets('SlicePlaceholderScreen displays content and supports state switching', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SlicePlaceholderScreen(
              title: 'Task Hub',
              subtitle: 'Dispatch & Review',
              slicePhase: 'Slice 2',
              icon: Icons.task,
              capabilities: ['Capability A', 'Capability B'],
            ),
          ),
        ),
      );

      expect(find.text('Task Hub'), findsWidgets);
      expect(find.text('Capability A'), findsOneWidget);
      expect(find.text('Capability B'), findsOneWidget);

      // Open state toggle popup
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Tap 'Loading State'
      await tester.tap(find.text('Loading State'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Open state toggle popup again
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap 'Empty State'
      await tester.tap(find.text('Empty State'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No Task Hub Found'), findsOneWidget);

      // Open state toggle popup again
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap 'Error State'
      await tester.tap(find.text('Error State'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Connection Issue'), findsOneWidget);
    });
  });
}
