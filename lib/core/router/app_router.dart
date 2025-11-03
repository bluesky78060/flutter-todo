import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/screens/stylish_login_screen.dart';
import 'package:todo_app/presentation/screens/register_screen.dart';
import 'package:todo_app/presentation/screens/todo_detail_screen.dart';
import 'package:todo_app/presentation/screens/todo_list_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: AppConstants.todosRoute,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == AppConstants.loginRoute;
      final isRegisterRoute =
          state.matchedLocation == AppConstants.registerRoute;

      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        return AppConstants.loginRoute;
      }

      if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
        return AppConstants.todosRoute;
      }

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
});
