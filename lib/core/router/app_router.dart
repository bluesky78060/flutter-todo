import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/router/auth_notifier.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/screens/stylish_login_screen.dart';
import 'package:todo_app/presentation/screens/register_screen.dart';
import 'package:todo_app/presentation/screens/todo_detail_screen.dart';
import 'package:todo_app/presentation/screens/todo_list_screen.dart';
import 'package:todo_app/presentation/screens/oauth_callback_screen.dart';
import 'package:todo_app/presentation/screens/category_management_screen.dart';
import 'package:todo_app/presentation/screens/calendar_screen.dart';
// import 'package:todo_app/presentation/screens/theme_preview_screen.dart'; // Temporarily disabled
import 'package:todo_app/presentation/screens/settings_screen.dart';
import 'package:todo_app/presentation/screens/test_login_screen.dart';
import 'package:todo_app/presentation/screens/admin_dashboard_screen.dart';
import 'package:todo_app/core/utils/app_logger.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  final router = GoRouter(
    initialLocation: AppConstants.loginRoute,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Read current auth state from provider
      final userAsync = ref.read(currentUserProvider);

      final isLoginRoute = state.matchedLocation == AppConstants.loginRoute;
      final isRegisterRoute =
          state.matchedLocation == AppConstants.registerRoute;
      final isOAuthCallbackRoute = state.matchedLocation == '/oauth-callback';
      final isThemePreviewRoute = state.matchedLocation == '/theme-preview';
      final isDevSettingsRoute = state.matchedLocation == '/dev-settings';
      final isTestLoginRoute = state.matchedLocation == '/test-login';

      // While loading initial auth state, stay on login/register routes
      final isLoading = userAsync.isLoading;
      final isAuthenticated = userAsync.value != null;

      logger.d('🚦 Router redirect: location=${state.matchedLocation}, isLoading=$isLoading, isAuth=$isAuthenticated');

      // Allow OAuth callback route without redirect
      if (isOAuthCallbackRoute) {
        logger.d('   🔗 OAuth callback route - allowing');
        return null;
      }

      // Allow theme preview route without authentication
      if (isThemePreviewRoute) {
        logger.d('   🎨 Theme preview route - allowing without auth');
        return null;
      }

      // Allow dev settings route without authentication (local development only)
      if (isDevSettingsRoute) {
        logger.d('   🔧 Dev settings route - allowing without auth');
        return null;
      }

      // Allow test login route without authentication (local development only)
      if (isTestLoginRoute) {
        logger.d('   🧪 Test login route - allowing without auth');
        return null;
      }

      if (isLoading) {
        logger.d('   ⏳ Loading state - staying on auth routes');
        if (!isLoginRoute && !isRegisterRoute && !isThemePreviewRoute && !isDevSettingsRoute && !isTestLoginRoute) {
          return AppConstants.loginRoute;
        }
        return null;
      }

      // If authenticated and at root, redirect to todos (when todos isn't root)
      if (isAuthenticated && state.matchedLocation == '/') {
        logger.d('   🏠 Authenticated at root - redirecting to todos');
        // Avoid returning the same path to prevent loops
        if (AppConstants.todosRoute != state.matchedLocation) {
          return AppConstants.todosRoute;
        }
      }

      // Allow direct access to app routes for local development testing
      final isAppRoute = state.matchedLocation == '/todos' ||
                        state.matchedLocation.startsWith('/todos/') ||
                        state.matchedLocation == '/calendar' ||
                        state.matchedLocation == '/categories' ||
                        state.matchedLocation == '/admin-dashboard';

      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute && !isThemePreviewRoute && !isDevSettingsRoute && !isTestLoginRoute && !isAppRoute) {
        logger.d('   🔒 Not authenticated - redirecting to login');
        return AppConstants.loginRoute;
      }

      if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
        logger.d('   ✅ Authenticated - redirecting to todos');
        if (state.matchedLocation != AppConstants.todosRoute) {
          return AppConstants.todosRoute;
        }
      }

      logger.d('   ➡️ No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const StylishLoginScreen(),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/oauth-callback',
        name: 'oauth-callback',
        builder: (context, state) => const OAuthCallbackScreen(),
      ),
      GoRoute(
        path: AppConstants.todosRoute,
        name: 'todos',
        builder: (context, state) => const TodoListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: AppConstants.todoDetailRoute,
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return TodoDetailScreen(todoId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      // GoRoute(
      //   path: '/theme-preview',
      //   name: 'theme-preview',
      //   builder: (context, state) => const ThemePreviewScreen(),
      // ),
      // Development-only route to access settings screen locally
      GoRoute(
        path: '/dev-settings',
        name: 'dev-settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Test login route for local development
      GoRoute(
        path: '/test-login',
        name: 'test-login',
        builder: (context, state) => const TestLoginScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );

  return router;
});
