import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// ChangeNotifier that listens to auth state and notifies GoRouter to refresh
class AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuthenticated = false;

  AuthNotifier(this._ref) {
    // Listen to currentUserProvider and notify when auth state changes
    _ref.listen<AsyncValue<dynamic>>(
      currentUserProvider,
      (previous, next) {
        final wasAuthenticated = _isAuthenticated;
        _isAuthenticated = next.value != null;

        logger.d('🔔 AuthNotifier: Auth state changed from $wasAuthenticated to $_isAuthenticated');

        if (wasAuthenticated != _isAuthenticated) {
          logger.d('🔄 AuthNotifier: Notifying GoRouter to refresh');
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
