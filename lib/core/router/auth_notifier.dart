import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// ChangeNotifier that listens to auth state and notifies GoRouter to refresh
class AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuthenticated = false;
  bool _wasLoading = true;

  AuthNotifier(this._ref) {
    // Listen to currentUserProvider and notify when auth state changes
    _ref.listen<AsyncValue<dynamic>>(
      currentUserProvider,
      (previous, next) {
        final wasAuthenticated = _isAuthenticated;
        final wasLoading = _wasLoading;

        // Update loading state
        _wasLoading = next.isLoading;

        // Check authentication based on AsyncValue state
        next.when(
          data: (user) {
            _isAuthenticated = user != null;
            logger.d('🔔 AuthNotifier: data state - user=${user != null}, wasAuth=$wasAuthenticated, isAuth=$_isAuthenticated');
          },
          loading: () {
            // Keep previous auth state during loading
            logger.d('🔔 AuthNotifier: loading state - keeping isAuth=$_isAuthenticated');
          },
          error: (e, st) {
            _isAuthenticated = false;
            logger.d('🔔 AuthNotifier: error state - setting isAuth=false, error=$e');
          },
        );

        // Notify GoRouter when:
        // 1. Auth state actually changes
        // 2. Transition from loading to data/error
        final shouldNotify = wasAuthenticated != _isAuthenticated ||
                            (wasLoading && !next.isLoading);

        if (shouldNotify) {
          logger.d('🔄 AuthNotifier: Notifying GoRouter to refresh (wasAuth=$wasAuthenticated, isAuth=$_isAuthenticated, wasLoading=$wasLoading, isLoading=${next.isLoading})');
          notifyListeners();
        }
      },
    );
  }

  bool get isAuthenticated => _isAuthenticated;
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier(ref);
});
