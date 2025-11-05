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

      // While loading initial auth state, stay on login/register routes
      final isLoading = userAsync.isLoading;
      final isAuthenticated = userAsync.value != null;

      print('🚦 Router redirect: location=${state.matchedLocation}, isLoading=$isLoading, isAuth=$isAuthenticated');

      // Allow OAuth callback route without redirect
      if (isOAuthCallbackRoute) {
        print('   🔗 OAuth callback route - allowing');
        return null;
      }

      if (isLoading) {
        print('   ⏳ Loading state - staying on auth routes');
        if (!isLoginRoute && !isRegisterRoute) {
          return AppConstants.loginRoute;
        }
        return null;
      }

      // If authenticated and at root, redirect to todos (when todos isn't root)
      if (isAuthenticated && state.matchedLocation == '/') {
        print('   🏠 Authenticated at root - redirecting to todos');
        // Avoid returning the same path to prevent loops
        if (AppConstants.todosRoute != state.matchedLocation) {
          return AppConstants.todosRoute;
        }
      }

      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        print('   🔒 Not authenticated - redirecting to login');
        return AppConstants.loginRoute;
      }

      if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
        print('   ✅ Authenticated - redirecting to todos');
        if (state.matchedLocation != AppConstants.todosRoute) {
          return AppConstants.todosRoute;
        }
      }

      print('   ➡️ No redirect needed');
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );

  return router;
});
