import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:field_ops/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:field_ops/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:field_ops/features/dashboard/presentation/screens/manager_dashboard_screen.dart';
import 'package:field_ops/features/dashboard/presentation/widgets/activity_stream_card.dart';
import 'package:field_ops/features/dashboard/presentation/widgets/metric_summary_card.dart';
import 'package:field_ops/features/dashboard/presentation/widgets/task_distribution_card.dart';
import 'package:field_ops/features/dashboard/presentation/widgets/technician_geo_radar_card.dart';

void main() {
  Widget buildTestableWidget({required Widget child, List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('renders command center with KPIs, radar tracker, and activity stream', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AdminDashboardScreen(),
          overrides: [
            dashboardRemoteDataSourceProvider.overrideWithValue(MockDashboardRemoteDataSource()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Top title and telemetry
      expect(find.text('FieldOps Command Center'), findsOneWidget);
      expect(find.text('Executive Operations & Fleet Telemetry'), findsOneWidget);

      // 4 High-Impact KPI cards
      expect(find.byType(MetricSummaryCard), findsNWidgets(4));
      expect(find.text('Active Workforce'), findsOneWidget);
      expect(find.text('Tasks Today'), findsOneWidget);
      expect(find.text('Completed Visits'), findsOneWidget);
      expect(find.text('Proof Compliance'), findsOneWidget);

      // Quick Dispatch Actions
      expect(find.text('New Task'), findsOneWidget);
      expect(find.text('New Client'), findsOneWidget);
      expect(find.text('Forms'), findsOneWidget);
      expect(find.text('Sync Hub'), findsOneWidget);

      // Task status breakdown
      expect(find.byType(TaskDistributionCard), findsOneWidget);
      expect(find.text('Task Status Distribution'), findsOneWidget);

      // Live Fleet Radar
      expect(find.byType(TechnicianGeoRadarCard), findsOneWidget);
      expect(find.text('Live Field Fleet Tracker'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('David Miller'), findsWidgets);

      // Live Operations Activity Stream
      expect(find.byType(ActivityStreamCard), findsOneWidget);
      expect(find.text('Live Operations Activity Stream'), findsOneWidget);
    });
  });

  group('ManagerDashboardScreen Widget Tests', () {
    testWidgets('renders team field dispatch dashboard with metrics and fleet radar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const ManagerDashboardScreen(),
          overrides: [
            dashboardRemoteDataSourceProvider.overrideWithValue(MockDashboardRemoteDataSource()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Team Field Dispatch'), findsOneWidget);
      expect(find.text('Active Shift & Technician Operations'), findsOneWidget);

      // 3 Manager KPI cards
      expect(find.byType(MetricSummaryCard), findsNWidgets(3));
      expect(find.text('Active Techs'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Proofs Logged'), findsOneWidget);

      // Manager quick actions
      expect(find.text('Assign Task'), findsOneWidget);
      expect(find.text('Add Client'), findsOneWidget);
      expect(find.text('Sync Status'), findsOneWidget);

      // Fleet radar & task distribution
      expect(find.byType(TechnicianGeoRadarCard), findsOneWidget);
      expect(find.byType(TaskDistributionCard), findsOneWidget);
      expect(find.byType(ActivityStreamCard), findsOneWidget);
    });
  });
}
