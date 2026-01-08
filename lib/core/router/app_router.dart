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
// import 'package:todo_app/presentation/screens/test_login_screen.dart'; // Development only
import 'package:todo_app/presentation/screens/admin_dashboard_screen.dart';
import 'package:todo_app/presentation/screens/widget_config_screen.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Provides the application's [GoRouter] instance with authentication-aware routing.
///
/// This provider configures:
/// - **Initial location**: Starts at the login route
/// - **Auth-based redirects**: Automatically redirects users based on authentication state
/// - **Route guards**: Protects routes from unauthorized access
/// - **OAuth callback handling**: Special handling for OAuth authentication flow
///
/// The router listens to [authNotifierProvider] for auth state changes and
/// automatically refreshes routes when authentication status changes.
///
/// ## Route Structure
/// - `/login` - Login screen (public)
/// - `/register` - Registration screen (public)
/// - `/oauth-callback` - OAuth callback handler (public)
/// - `/todos` - Main todo list (protected)
/// - `/todos/:id` - Todo detail screen (protected)
/// - `/categories` - Category management (protected)
/// - `/calendar` - Calendar view (protected)
/// - `/admin-dashboard` - Admin dashboard (protected)
/// - `/widget-config` - Widget configuration (protected)
/// - `/dev-settings` - Development settings (public, dev only)
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
      // final isTestLoginRoute = state.matchedLocation == '/test-login'; // Development only

      // While loading initial auth state, stay on login/register routes
      final isLoading = userAsync.isLoading;
      // Use hasValue to check if data is available, then check if user is not null
      final isAuthenticated = userAsync.hasValue && userAsync.value != null;

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
      // if (isTestLoginRoute) {
      //   logger.d('   🧪 Test login route - allowing without auth');
      //   return null;
      // }

      if (isLoading) {
        logger.d('   ⏳ Loading state - staying on auth routes');
        if (!isLoginRoute && !isRegisterRoute && !isThemePreviewRoute && !isDevSettingsRoute) {
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

      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute && !isThemePreviewRoute && !isDevSettingsRoute) {
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
      GoRoute(
        path: '/widget-config',
        name: 'widget-config',
        builder: (context, state) => const WidgetConfigScreen(),
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
      // GoRoute(
      //   path: '/test-login',
      //   name: 'test-login',
      //   builder: (context, state) => const TestLoginScreen(),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );

  return router;
});
