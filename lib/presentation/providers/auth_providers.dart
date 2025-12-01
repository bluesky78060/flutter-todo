/// Authentication state management providers using Riverpod.
///
/// Provides reactive authentication state through Supabase auth streams,
/// with support for local development mode using mock users.
///
/// Providers:
/// - [currentUserProvider]: Stream of current authenticated user
/// - [isAuthenticatedProvider]: Boolean indicating auth status
/// - [authActionsProvider]: Login, register, and logout actions
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/auth_user.dart' as domain;
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/core/config/dev_config.dart';

/// Provides a stream of the current authenticated user.
///
/// Listens to Supabase auth state changes and automatically updates
/// when the user logs in, logs out, or their session changes.
///
/// In local dev mode ([DevConfig.enableLocalDevMode]), returns a mock user
/// for testing without Supabase connectivity.
final currentUserProvider = StreamProvider<domain.AuthUser?>((ref) async* {
  // Check if local dev mode is enabled
  if (DevConfig.enableLocalDevMode) {
    logger.d('🧪 Local dev mode enabled - providing mock user');
    final mockUser = domain.AuthUser(
      id: int.parse(DevConfig.mockUserId.replaceAll(RegExp(r'[^0-9]'), '123')),
      uuid: DevConfig.mockUserUuid,
      email: DevConfig.mockUserEmail,
      name: DevConfig.mockUserName,
      createdAt: DateTime.now(),
    );
    yield mockUser;
    return;
  }

  final repository = ref.watch(authRepositoryProvider);

  logger.d('🎯 currentUserProvider: Starting auth stream');

  // Emit initial auth state immediately to avoid long loading on startup
  try {
    final initial = await repository.getCurrentUser();
    final initialUser = initial.fold(
      (failure) {
        logger.d('⚠️ Failed to get initial user: $failure');
        return null;
      },
      (user) => user,
    );
    logger.d('🚀 Initial auth user: ${initialUser != null}');
    yield initialUser;
  } catch (e) {
    logger.d('⚠️ Initial auth check error: $e');
    yield null;
  }

  // Then listen to Supabase auth state changes
  await for (final authState in Supabase.instance.client.auth.onAuthStateChange) {
    logger.d('🔐 Auth stream update: ${authState.event}, session=${authState.session != null}');

    if (authState.session?.user != null) {
      // User is authenticated, fetch current user
      final result = await repository.getCurrentUser();
      final user = result.fold(
        (failure) {
          logger.d('❌ Failed to get user: $failure');
          return null;
        },
        (user) {
          logger.d('✅ User loaded from repository: ${user?.id}');
          return user;
        },
      );
      yield user;
    } else {
      // No session, user is null
      logger.d('👋 No authenticated user in session');
      yield null;
    }
  }
});

/// Provides a boolean indicating whether a user is currently authenticated.
///
/// Derives from [currentUserProvider] for reactive updates.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Action class for authentication operations.
///
/// Provides methods for login, registration, and logout.
/// Returns error messages on failure, null on success.
class AuthActions {
  final Ref ref;
  AuthActions(this.ref);

  Future<String?> login(String email, String password) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(email, password);
    return result.fold(
      (failure) {
        if (failure is AuthFailure) {
          return failure.message;
        }
        return 'Login failed';
      },
      (_) {
        // No need to invalidate - StreamProvider will auto-update
        logger.d('✅ Login successful - StreamProvider will auto-update');
        return null;
      },
    );
  }

  Future<String?> register(
      String email, String password, String name) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.register(email, password, name);
    return result.fold(
      (failure) {
        if (failure is AuthFailure) {
          return failure.message;
        }
        return 'Registration failed';
      },
      (_) {
        // No need to invalidate - StreamProvider will auto-update
        logger.d('✅ Registration successful - StreamProvider will auto-update');
        return null;
      },
    );
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    // No need to invalidate - StreamProvider will auto-update
    logger.d('✅ Logout successful - StreamProvider will auto-update');
  }
}

/// Provides the [AuthActions] instance for authentication operations.
final authActionsProvider = Provider((ref) => AuthActions(ref));
