import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/auth_user.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

// Current User Provider
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getCurrentUser();
  return result.fold(
    (failure) => null,
    (user) => user,
  );
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
        ref.invalidate(currentUserProvider);
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
        ref.invalidate(currentUserProvider);
        return null;
      },
    );
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    ref.invalidate(currentUserProvider);
  }
}

final authActionsProvider = Provider((ref) => AuthActions(ref));
