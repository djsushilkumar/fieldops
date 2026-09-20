import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../auth/presentation/screens/forgot_password_screen.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../auth/presentation/screens/splash_screen.dart';
import '../../tasks/presentation/screens/create_task_screen.dart';
import '../../tasks/presentation/screens/task_detail_screen.dart';
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

      // When checking session on startup, remain on splash
      if (isLoading && currentLoc == '/splash') {
        return null;
      }

      final isAuthRoute = currentLoc == '/login' || currentLoc == '/forgot-password' || currentLoc == '/splash';

      // If user is not authenticated
      if (!isAuth) {
        if (currentLoc == '/forgot-password') {
          return null;
        }
        return isAuthRoute ? (currentLoc == '/splash' ? '/login' : null) : '/login';
      }

      // User IS authenticated
      // If they are on an auth screen, redirect to their role-specific home
      if (isAuthRoute) {
        if (role != null && role.isAdmin) {
          return '/admin/dashboard';
        } else if (role != null && role.isManager) {
          return '/manager/dashboard';
        } else {
          return '/employee/home';
        }
      }

      // Role authorization guards: Protect Admin routes
      if (currentLoc.startsWith('/admin') && (role == null || !role.isAdmin)) {
        if (role != null && role.isManager) {
          return '/manager/dashboard';
        }
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
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
