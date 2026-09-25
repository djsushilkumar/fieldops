import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/conveyance/domain/entities/conveyance_claim_entity.dart';
import 'package:field_ops/features/conveyance/domain/entities/conveyance_status.dart';
import 'package:field_ops/features/conveyance/domain/entities/vehicle_type.dart';
import 'package:field_ops/features/conveyance/presentation/widgets/conveyance_claim_card.dart';
import 'package:field_ops/features/conveyance/presentation/widgets/conveyance_discrepancy_badge.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';
import 'package:field_ops/features/tasks/presentation/widgets/task_kanban_view.dart';

void main() {
  group('ConveyanceDiscrepancyBadge Widget Tests', () {
    testWidgets('renders verified badge in green when not flagged', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConveyanceDiscrepancyBadge(
              isFlagged: false,
              discrepancyPercentage: 4.2,
            ),
          ),
        ),
      );

      expect(find.text('GPS Verified (4.2%)'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    });

    testWidgets('renders warning badge in red when flagged for fraud', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConveyanceDiscrepancyBadge(
              isFlagged: true,
              discrepancyPercentage: 35.8,
            ),
          ),
        ),
      );

      expect(find.text('Flagged: 35.8% Discrepancy'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('ConveyanceClaimCard Widget Tests', () {
    testWidgets('renders claim summary, distances and payout properly', (tester) async {
      final claim = ConveyanceClaimEntity(
        id: 'claim-01',
        organizationId: 'org-01',
        userId: 'user-01',
        userName: 'Elena Rostova',
        shiftDate: '2026-09-25',
        vehicleType: VehicleType.twoWheelerBike,
        ratePerKm: 3.50,
        claimedDistanceKm: 50.0,
        gpsDistanceKm: 48.0,
        discrepancyPercentage: 4.0,
        isFlaggedForFraud: false,
        status: ConveyanceStatus.approved,
        approvedPayoutAmount: 175.0,
        createdAt: DateTime(2026, 9, 25),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConveyanceClaimCard(claim: claim),
          ),
        ),
      );

      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('50.0 km'), findsOneWidget);
      expect(find.text('48.0 km'), findsOneWidget);
      expect(find.text('₹175.00'), findsOneWidget);
      expect(find.text('Approved & Reimbursable'), findsOneWidget);
    });
  });

  group('TaskKanbanView Widget Tests', () {
    testWidgets('renders To Do, In Progress, and Completed columns', (tester) async {
      final now = DateTime.now();
      final task1 = TaskEntity(
        id: 'task-1',
        organizationId: 'org-01',
        title: 'Inspect Central HVAC Unit',
        priority: TaskPriority.high,
        status: TaskStatus.assigned,
        createdAt: now,
        updatedAt: now,
      );

      final task2 = TaskEntity(
        id: 'task-2',
        organizationId: 'org-01',
        title: 'Replace Circuit Breaker',
        priority: TaskPriority.urgent,
        status: TaskStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      );

      final task3 = TaskEntity(
        id: 'task-3',
        organizationId: 'org-01',
        title: 'Monthly Generator Audit',
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaskKanbanView(
                tasks: [task1, task2, task3],
              ),
            ),
          ),
        ),
      );

      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Inspect Central HVAC Unit'), findsOneWidget);
      expect(find.text('Replace Circuit Breaker'), findsOneWidget);
      expect(find.text('Monthly Generator Audit'), findsOneWidget);
    });
  });
}
