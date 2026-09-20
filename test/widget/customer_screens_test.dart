import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:field_ops/features/customers/data/datasources/mock_customer_remote_datasource.dart';
import 'package:field_ops/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:field_ops/features/customers/presentation/controllers/customer_controller.dart';
import 'package:field_ops/features/customers/presentation/screens/create_customer_screen.dart';
import 'package:field_ops/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:field_ops/features/customers/presentation/screens/customer_list_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final adminUser = UserEntity(
    id: 'usr-admin-001',
    email: 'admin@fieldops.com',
    name: 'Admin User',
    organizationId: 'org-001',
    role: UserRole.admin,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createWidgetUnderTest(Widget child, {CustomerRepositoryImpl? customRepo}) {
    final repo = customRepo ??
        CustomerRepositoryImpl(
          remoteDataSource: MockCustomerRemoteDataSource(),
          localDataSource: CustomerLocalDataSourceImpl(),
        );

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => adminUser),
        customerRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('CustomerListScreen Widget Tests', () {
    testWidgets('renders search field, customer cards and create action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createWidgetUnderTest(const CustomerListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Customers & Sites'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const Key('add_customer_fab')), findsOneWidget);

      // Verify default seeded customers show up
      expect(find.text('Apex Logistics Hub'), findsOneWidget);
      expect(find.text('Metro Health Plaza'), findsOneWidget);
    });

    testWidgets('filtering by search input updates displayed customers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createWidgetUnderTest(const CustomerListScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Apex');
      await tester.pumpAndSettle();

      expect(find.text('Apex Logistics Hub'), findsOneWidget);
      expect(find.text('Metro Health Plaza'), findsNothing);
    });
  });

  group('CreateCustomerScreen Widget Tests', () {
    testWidgets('renders form fields, validates required name, and allows input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createWidgetUnderTest(const CreateCustomerScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.byKey(const Key('customer_name_field')), findsOneWidget);
      expect(find.byKey(const Key('customer_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('customer_email_field')), findsOneWidget);
      expect(find.byKey(const Key('customer_address_field')), findsOneWidget);
      expect(find.byKey(const Key('create_customer_submit_button')), findsOneWidget);

      // Tap submit without name -> triggers validation
      await tester.tap(find.byKey(const Key('create_customer_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Customer name is required'), findsOneWidget);

      // Enter name and submit
      await tester.enterText(find.byKey(const Key('customer_name_field')), 'Vanguard Industrial Corp');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_customer_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('CustomerDetailScreen Widget Tests', () {
    testWidgets('displays customer profile and site location list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createWidgetUnderTest(
        const CustomerDetailScreen(customerId: 'cust-001'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Metro Health Plaza'), findsWidgets);
      expect(find.text('Sites & Locations'), findsOneWidget);
      expect(find.byKey(const Key('add_site_button')), findsOneWidget);
    });
  });
}
