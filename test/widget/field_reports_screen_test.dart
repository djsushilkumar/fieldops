import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/attendance/domain/entities/attendance_entity.dart';
import 'package:field_ops/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:field_ops/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:field_ops/features/reports/domain/entities/field_operations_report.dart';
import 'package:field_ops/features/reports/presentation/controllers/reports_controller.dart';
import 'package:field_ops/features/reports/presentation/screens/field_reports_screen.dart';
import 'package:field_ops/features/reports/presentation/widgets/csv_export_preview_dialog.dart';
import 'package:field_ops/features/reports/presentation/widgets/report_date_filter_bar.dart';
import 'package:field_ops/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:field_ops/features/reports/presentation/widgets/technician_performance_list.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/visits/domain/entities/visit_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubReportsLocalDataSource implements ReportsLocalDataSource {
  @override
  Future<FieldOperationsReport> getOperationsReport({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TaskEntity>> getTasksForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async => [];

  @override
  Future<List<VisitEntity>> getVisitsForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async => [];

  @override
  Future<List<AttendanceEntity>> getAttendanceForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async => [];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget({required Widget child, List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('FieldReportsScreen Widget Tests', () {
    testWidgets('renders filter bar, KPI overview, CSV export center, and leaderboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const FieldReportsScreen(),
          overrides: [
            reportsRemoteDataSourceProvider.overrideWithValue(MockReportsRemoteDataSource()),
            reportsLocalDataSourceProvider.overrideWithValue(StubReportsLocalDataSource()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Top title and bar
      expect(find.text('Field Reports'), findsOneWidget);
      expect(find.byType(ReportDateFilterBar), findsOneWidget);

      // Preset chips
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // KPI cards
      expect(find.byType(ReportKpiCard), findsOneWidget);
      expect(find.text('Task Completion'), findsOneWidget);
      expect(find.text('On-Time SLA'), findsOneWidget);
      expect(find.text('Customer Visits'), findsOneWidget);
      expect(find.text('Field Hours'), findsOneWidget);

      // CSV Export Center
      expect(find.text('Instant CSV Export Center'), findsOneWidget);
      expect(find.text('Tasks CSV'), findsOneWidget);
      expect(find.text('Visits CSV'), findsOneWidget);
      expect(find.text('Timesheets CSV'), findsOneWidget);
      expect(find.text('Tech Rankings CSV'), findsOneWidget);
      expect(find.text('Executive Summary CSV'), findsOneWidget);

      // Technician Performance Leaderboard
      expect(find.byType(TechnicianPerformanceList), findsOneWidget);
      expect(find.text('Technician Performance Ranking'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('Elena Rostova'), findsWidgets);
    });

    testWidgets('preset chip selection triggers state update', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const FieldReportsScreen(),
          overrides: [
            reportsRemoteDataSourceProvider.overrideWithValue(MockReportsRemoteDataSource()),
            reportsLocalDataSourceProvider.overrideWithValue(StubReportsLocalDataSource()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Tap "Today" chip
      await tester.tap(find.text('Today'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Operational Performance Overview'), findsOneWidget);
    });

    testWidgets('tapping Tasks CSV action chip triggers export modal preview', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: const FieldReportsScreen(),
          overrides: [
            reportsRemoteDataSourceProvider.overrideWithValue(MockReportsRemoteDataSource()),
            reportsLocalDataSourceProvider.overrideWithValue(StubReportsLocalDataSource()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Ensure "Tasks CSV" chip is visible and tap it
      await tester.ensureVisible(find.text('Tasks CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tasks CSV'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Modal preview dialog should appear
      expect(find.byType(CsvExportPreviewDialog), findsOneWidget);
      expect(find.text('Tasks & Work Orders'), findsOneWidget);
      expect(find.text('Copy CSV to Clipboard'), findsOneWidget);
      expect(find.text('RFC-4180 CSV Standard'), findsOneWidget);

      // Tap Copy to Clipboard
      await tester.tap(find.text('Copy CSV to Clipboard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(CsvExportPreviewDialog), findsNothing);
    });
  });
}
