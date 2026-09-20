import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/customers/domain/entities/location_entity.dart';
import 'package:field_ops/features/visits/data/datasources/mock_visit_remote_datasource.dart';
import 'package:field_ops/features/visits/data/datasources/visit_local_datasource.dart';
import 'package:field_ops/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:field_ops/features/visits/presentation/controllers/visit_controller.dart';
import 'package:field_ops/features/visits/presentation/screens/visit_detail_screen.dart';
import 'package:field_ops/features/visits/presentation/screens/visit_list_screen.dart';
import 'package:field_ops/features/visits/presentation/widgets/gps_visit_execution_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final employeeUser = UserEntity(
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

  Widget createWidgetUnderTest(Widget child) {
    final visitRepo = VisitRepositoryImpl(
      remoteDataSource: MockVisitRemoteDataSource(),
      localDataSource: VisitLocalDataSourceImpl(),
    );

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => employeeUser),
        visitRepositoryProvider.overrideWithValue(visitRepo),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('VisitListScreen Widget Tests', () {
    testWidgets('renders tabs and visit items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createWidgetUnderTest(const VisitListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Visits'), findsOneWidget);
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Active (0)'), findsOneWidget);
      expect(find.text('Completed (2)'), findsOneWidget);

      // Verify list contains seeded visits
      expect(find.text('Metro Health Plaza'), findsWidgets);
    });
  });

  group('VisitDetailScreen Widget Tests', () {
    testWidgets('renders visit details and check-in/out timestamps', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createWidgetUnderTest(
        const VisitDetailScreen(visitId: 'vst-001'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Visit Details'), findsOneWidget);
      expect(find.text('GPS Execution Audit'), findsOneWidget);
      expect(find.text('Check-In'), findsOneWidget);
      expect(find.text('Check-Out'), findsOneWidget);
      expect(find.textContaining('Lat: 37.774900'), findsWidgets);
    });
  });

  group('GpsVisitExecutionCard Widget Tests', () {
    testWidgets('renders target site radius and GPS Check-In button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      final targetLocation = LocationEntity(
        id: 'loc-001',
        organizationId: 'org-001',
        name: 'Apex Logistics Main Warehouse',
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMeters: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(
        Scaffold(
          body: GpsVisitExecutionCard(
            taskId: 'tsk-001',
            targetLocation: targetLocation,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Field GPS Verification'), findsOneWidget);
      expect(find.text('Apex Logistics Main Warehouse'), findsOneWidget);
      expect(find.textContaining('Radius: 100m'), findsOneWidget);
      expect(find.byKey(const Key('gps_checkin_button')), findsOneWidget);

      // Tap GPS Check-In button
      await tester.tap(find.byKey(const Key('gps_checkin_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should now display active visit badge and check-out button
      expect(find.byKey(const Key('gps_checkout_button')), findsOneWidget);
    });
  });
}
