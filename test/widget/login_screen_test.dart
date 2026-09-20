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

  testWidgets('LoginScreen renders fields, validation and demo buttons', (WidgetTester tester) async {
    // Provide sufficient test view size for form content
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

    // Allow mock async session check to finish
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Tagline elements
    expect(find.text('Welcome to FieldOps'), findsOneWidget);
    expect(find.text('Work Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify Demo Persona Switcher buttons
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('Employee'), findsOneWidget);

    // Tap the 'Employee' demo button
    await tester.ensureVisible(find.text('Employee'));
    await tester.tap(find.text('Employee'));
    await tester.pump();

    // Verify field updated to employee email
    expect(find.text('employee@fieldops.com'), findsOneWidget);

    // Tap the 'Manager' demo button
    await tester.ensureVisible(find.text('Manager'));
    await tester.tap(find.text('Manager'));
    await tester.pump();

    // Verify field updated to manager email
    expect(find.text('manager@fieldops.com'), findsOneWidget);
  });
}
