import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/auth_user.dart' as domain;
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';

// Stream-based Current User Provider that listens to Supabase auth state changes
final currentUserProvider = StreamProvider<domain.AuthUser?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);

  logger.d('🎯 currentUserProvider: Starting auth stream');

  // Listen to Supabase auth state changes
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

// Auth state provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Auth actions
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

final authActionsProvider = Provider((ref) => AuthActions(ref));
