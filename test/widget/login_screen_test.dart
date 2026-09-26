import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/auth/presentation/screens/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen renders clean enterprise login interface for real users', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Tagline elements
    expect(find.text('Welcome to FieldOps'), findsOneWidget);
    expect(find.text('Work Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify Demo Persona Switcher buttons do NOT exist
    expect(find.text('Quick Sign-in (Demo Personas)'), findsNothing);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Manager'), findsNothing);
    expect(find.text('Employee'), findsNothing);

    // Verify fields are empty by default
    expect(find.text('admin@fieldops.com'), findsNothing);
    expect(find.text('password123'), findsNothing);
  });

  testWidgets('LoginScreen validates empty inputs on submission', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 'Sign In' without filling credentials
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Verify validation errors appear
    expect(find.text('Please enter your email'), findsOneWidget);
  });

  testWidgets('LoginScreen accepts real user credentials and toggles password visibility', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Enter real user credentials
    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;

    await tester.enterText(emailField, 'technician@company.com');
    await tester.enterText(passwordField, 'SecurePassword2026!');
    await tester.pump();

    expect(find.text('technician@company.com'), findsOneWidget);

    // Tap visibility toggle icon
    final visibilityIcon = find.byIcon(Icons.visibility_off);
    expect(visibilityIcon, findsOneWidget);
    await tester.tap(visibilityIcon);
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
