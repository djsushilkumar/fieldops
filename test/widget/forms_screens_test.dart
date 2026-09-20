import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/forms/presentation/screens/fill_form_screen.dart';
import 'package:field_ops/features/forms/presentation/screens/form_builder_screen.dart';
import 'package:field_ops/features/forms/presentation/screens/forms_management_screen.dart';
import 'package:field_ops/features/forms/presentation/widgets/task_form_execution_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Forms Feature Widget Tests', () {
    testWidgets('FormsManagementScreen renders search and pre-seeded forms', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const FormsManagementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Custom Forms & Checklists'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
      expect(find.text('HVAC & Mechanical Maintenance Checklist'), findsOneWidget);
      expect(find.text('Site Safety & PPE Audit'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Fill Form'), findsWidgets);
      expect(find.text('Submissions'), findsWidgets);
    });

    testWidgets('FormBuilderScreen renders title input and allows adding fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const FormBuilderScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Custom Form'), findsOneWidget);
      expect(find.text('Form Title *'), findsOneWidget);
      expect(find.text('Description / Instructions'), findsOneWidget);
      expect(find.text('Form Fields'), findsOneWidget);
      expect(find.text('Add Field'), findsOneWidget);

      // Tap 'Add Field' to open bottom sheet
      await tester.tap(find.text('Add Field'));
      await tester.pumpAndSettle();

      expect(find.text('Select Field Type'), findsOneWidget);
      expect(find.text('Number'), findsOneWidget);
      expect(find.text('Dropdown Selection'), findsOneWidget);
      expect(find.text('Checkbox (Yes / No)'), findsOneWidget);

      // Select 'Number' field
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();

      expect(find.text('Save Form'), findsOneWidget);
    });

    testWidgets('FillFormScreen dynamically renders fields and submit button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          const FillFormScreen(
            formId: 'form-acme-hvac-001',
            taskId: 'task-001',
            taskTitle: 'Emergency HVAC Repair',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('HVAC & Mechanical Maintenance Checklist'), findsOneWidget);
      expect(find.text('Linked to Task'), findsOneWidget);
      expect(find.text('Emergency HVAC Repair'), findsOneWidget);

      // Verify dynamic fields rendered
      expect(find.text('Equipment Serial / Asset ID'), findsOneWidget);
      expect(find.text('Refrigerant Suction Pressure (PSI)'), findsOneWidget);
      expect(find.text('Overall System Condition'), findsOneWidget);
      expect(find.text('Air Filters Replaced During Visit'), findsOneWidget);
      expect(find.text('Submit Checklist'), findsOneWidget);
    });

    testWidgets('TaskFormExecutionCard renders status and action button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: TaskFormExecutionCard(
                taskId: 'task-test-uncompleted',
                taskTitle: 'Repair Heat Pump',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service Checklist & Audit'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Fill Service Checklist'), findsOneWidget);
    });
  });
}
