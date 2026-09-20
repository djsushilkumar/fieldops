import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../auth/presentation/screens/forgot_password_screen.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../auth/presentation/screens/splash_screen.dart';
import '../../attendance/presentation/screens/my_attendance_history_screen.dart';
import '../../customers/presentation/screens/create_customer_screen.dart';
import '../../customers/presentation/screens/customer_detail_screen.dart';
import '../../forms/presentation/screens/fill_form_screen.dart';
import '../../forms/presentation/screens/form_builder_screen.dart';
import '../../forms/presentation/screens/form_submissions_screen.dart';
import '../../forms/presentation/screens/forms_management_screen.dart';
import '../../tasks/presentation/screens/create_task_screen.dart';
import '../../tasks/presentation/screens/task_detail_screen.dart';
import '../../visits/presentation/screens/visit_detail_screen.dart';
import '../../sync/presentation/screens/sync_screen.dart';
import 'screens/admin_shell_screen.dart';
import 'screens/employee_shell_screen.dart';
import 'screens/manager_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider.notifier);
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final currentLoc = state.uri.path;
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading && authState.user == null;
      final role = authState.role;

      // While checking session initially, stay on splash
      if (isLoading && currentLoc == '/splash') {
        return null;
      }

      // If unauthenticated and not already on an auth screen, send to login
      final isAuthRoute = currentLoc == '/login' ||
          currentLoc == '/forgot-password' ||
          currentLoc == '/splash';
      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      // If authenticated and trying to access an auth screen, redirect to role home
      if (isAuth && isAuthRoute) {
        if (role?.isAdmin ?? false) return '/admin/dashboard';
        if (role?.isManager ?? false) return '/manager/dashboard';
        return '/employee/home';
      }

      // Role authorization guards: Protect Admin routes
      if (currentLoc.startsWith('/admin') && (role == null || !role.isAdmin)) {
        return '/employee/home';
      }

      // Role authorization guards: Protect Manager routes
      if (currentLoc.startsWith('/manager') && (role == null || (!role.isManager && !role.isAdmin))) {
        return '/employee/home';
      }

      // Role authorization guard: Protect Task Creation (Admin and Manager only)
      if (currentLoc == '/tasks/create' && (role == null || !role.canCreateTasks)) {
        return '/employee/home';
      }

      // Role authorization guard: Protect Customer Creation (Admin and Manager only)
      if (currentLoc == '/customers/create' && (role == null || !role.canManageCustomers)) {
        return '/employee/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Admin shell
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminShellScreen(),
      ),
      // Manager shell
      GoRoute(
        path: '/manager/dashboard',
        builder: (context, state) => const ManagerShellScreen(),
      ),
      // Employee shell
      GoRoute(
        path: '/employee/home',
        builder: (context, state) => const EmployeeShellScreen(),
      ),
      // Task detail screen
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: id);
        },
      ),
      // Create task screen
      GoRoute(
        path: '/tasks/create',
        builder: (context, state) => const CreateTaskScreen(),
      ),
      // Customer detail screen
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),
      // Create customer screen
      GoRoute(
        path: '/customers/create',
        builder: (context, state) => const CreateCustomerScreen(),
      ),
      // Visit detail screen
      GoRoute(
        path: '/visits/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VisitDetailScreen(visitId: id);
        },
      ),
      // Attendance history screen
      GoRoute(
        path: '/attendance/history',
        builder: (context, state) => const MyAttendanceHistoryScreen(),
      ),
      // Forms management screen
      GoRoute(
        path: '/forms',
        builder: (context, state) => const FormsManagementScreen(),
      ),
      // Form builder screen
      GoRoute(
        path: '/forms/builder',
        builder: (context, state) => const FormBuilderScreen(),
      ),
      // Fill form screen
      GoRoute(
        path: '/forms/:id/fill',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final taskId = state.uri.queryParameters['taskId'];
          final taskTitle = state.uri.queryParameters['taskTitle'];
          return FillFormScreen(formId: id, taskId: taskId, taskTitle: taskTitle);
        },
      ),
      // Form submissions screen
      GoRoute(
        path: '/forms/:id/submissions',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FormSubmissionsScreen(formId: id);
        },
      ),
      // Task checklist submissions screen
      GoRoute(
        path: '/tasks/:id/submissions',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FormSubmissionsScreen(taskId: id, title: 'Task Checklist Submissions');
        },
      ),
      // Offline sync and queue management screen
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
