import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/navigation/presentation/screens/admin_settings_screen.dart';
import 'package:field_ops/features/organization/data/datasources/organization_remote_datasource.dart';
import 'package:field_ops/features/organization/presentation/controllers/organization_settings_controller.dart';
import 'package:field_ops/features/organization/presentation/screens/organization_profile_screen.dart';
import 'package:field_ops/features/organization/presentation/screens/role_permissions_screen.dart';
import 'package:field_ops/features/organization/presentation/screens/team_members_screen.dart';
import 'package:field_ops/features/organization/presentation/screens/teams_management_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child, {MockOrganizationRemoteDataSourceImpl? mockDs}) {
    final ds = mockDs ?? MockOrganizationRemoteDataSourceImpl();
    return ProviderScope(
      overrides: [
        organizationRemoteDataSourceProvider.overrideWithValue(ds),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Slice 10 Organization & Admin Widget Tests', () {
    testWidgets('OrganizationProfileScreen renders fields and allows updating policies', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const OrganizationProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Verify header and fields
      expect(find.text('Organization Tenant ID'), findsOneWidget);
      expect(find.text('Organization Name'), findsOneWidget);
      expect(find.text('Commercial HVAC & Mechanical'), findsOneWidget);
      expect(find.text('Default Site Geofence Radius'), findsOneWidget);
      expect(find.text('Require GPS Verification on Check-in'), findsOneWidget);
      expect(find.text('Require Photo Proof on Task Completion'), findsOneWidget);
      expect(find.text('Save Organization Settings'), findsOneWidget);

      // Select 500m geofence segment
      await tester.ensureVisible(find.text('500m'));
      await tester.tap(find.text('500m'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.ensureVisible(find.text('Save Organization Settings'));
      await tester.tap(find.text('Save Organization Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Organization settings saved!'), findsOneWidget);
    });

    testWidgets('TeamsManagementScreen lists dispatch teams and creates a new team', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const TeamsManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Verify existing dispatch teams
      expect(find.text('North Bay HVAC Fleet'), findsOneWidget);
      expect(find.text('SF Metro Rapid Response'), findsOneWidget);
      expect(find.text('East Bay Electrical & Solar'), findsOneWidget);

      // Tap New Team button
      await tester.tap(find.text('New Team'));
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Create Dispatch Team'), findsOneWidget);

      // Enter team name
      final nameField = find.widgetWithText(TextField, 'Team Name *');
      await tester.enterText(nameField, 'Peninsula Automation Unit');

      // Click Create
      await tester.tap(find.text('Create'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Peninsula Automation Unit'), findsOneWidget);
    });

    testWidgets('TeamsManagementScreen allows deleting a dispatch team', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const TeamsManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('SF Metro Rapid Response'), findsOneWidget);

      // Tap delete icon on one of the cards
      final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteButtons, findsWidgets);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Verify delete confirmation dialog
      expect(find.text('Delete Team'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Team removed
      expect(find.text('North Bay HVAC Fleet'), findsNothing);
    });

    testWidgets('TeamMembersScreen renders staff roster, searches, and opens invite modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const TeamMembersScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('Chloe Bennett'), findsOneWidget);

      // Filter via search
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Chloe');
      await tester.pumpAndSettle();

      expect(find.text('Chloe Bennett'), findsOneWidget);
      expect(find.text('Elena Rostova'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Elena Rostova'), findsOneWidget);

      // Open invite dialog via FAB
      await tester.tap(find.text('Invite Member'));
      await tester.pumpAndSettle();

      expect(find.text('Invite Team Member'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);

      // Enter details
      final nameField = find.widgetWithText(TextField, 'Full Name *');
      final emailField = find.widgetWithText(TextField, 'Email Address *');
      await tester.enterText(nameField, 'James Holden');
      await tester.enterText(emailField, 'jholden@fieldops.com');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Send Invite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('James Holden'), findsOneWidget);
    });

    testWidgets('RolePermissionsScreen toggles permissions and resets to defaults', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const RolePermissionsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Role Permissions Matrix'), findsOneWidget);
      expect(find.text('Manager'), findsWidgets);
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Field Employee'), findsWidgets);

      // Switch to Employee
      await tester.tap(find.text('Field Employee'));
      await tester.pumpAndSettle();

      // Expect specific permission tiles
      expect(find.text('Create & Schedule Tasks'), findsOneWidget);
      expect(find.text('Manage Customers & Locations'), findsOneWidget);
      expect(find.text('Cross-Team Operations Visibility'), findsOneWidget);
      expect(find.text('Reports & CSV Export Center'), findsOneWidget);
      expect(find.text('Dynamic Form Builder Access'), findsOneWidget);
      expect(find.text('Organization Settings & User Management'), findsOneWidget);

      // Tap Reset Defaults
      await tester.ensureVisible(find.text('Reset Defaults'));
      await tester.tap(find.text('Reset Defaults'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Save permissions
      await tester.ensureVisible(find.text('Save Permissions'));
      await tester.tap(find.text('Save Permissions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Permissions matrix updated!'), findsOneWidget);
    });

    testWidgets('AdminSettingsScreen navigates to Slice 10 management screens', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const AdminSettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify tiles are present
      expect(find.text('Teams & Dispatch Groups'), findsOneWidget);
      expect(find.text('Team Members & User Directory'), findsOneWidget);
      expect(find.text('Role Permissions Matrix (RBAC)'), findsOneWidget);

      // Navigate to Teams
      await tester.ensureVisible(find.text('Teams & Dispatch Groups'));
      await tester.tap(find.text('Teams & Dispatch Groups'));
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Teams'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Navigate to Members
      await tester.ensureVisible(find.text('Team Members & User Directory'));
      await tester.tap(find.text('Team Members & User Directory'));
      await tester.pumpAndSettle();

      expect(find.text('Team Members'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Navigate to Role Permissions
      await tester.ensureVisible(find.text('Role Permissions Matrix (RBAC)'));
      await tester.tap(find.text('Role Permissions Matrix (RBAC)'));
      await tester.pumpAndSettle();

      expect(find.text('Role Permissions Matrix'), findsOneWidget);
      expect(find.text('Field Employee'), findsWidgets);
    });
  });
}
