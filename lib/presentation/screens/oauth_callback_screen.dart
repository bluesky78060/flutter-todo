import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// OAuth callback landing screen
/// This screen is shown briefly after OAuth authentication completes
/// It checks auth state and redirects appropriately
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  ConsumerState<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();

    // Supabase should handle OAuth callback automatically on web
    // Just wait a moment and then check auth state
    logger.d('🔗 OAuthCallbackScreen: Initializing');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuthAndRedirect();
      }
    });
  }

  void _checkAuthAndRedirect() {
    final authState = ref.read(currentUserProvider);

    logger.d('🔗 OAuthCallbackScreen: Checking auth state');

    if (authState.value != null) {
      // User is authenticated, navigate to todos
      logger.d('✅ OAuthCallbackScreen: User authenticated, navigating to todos');
      context.go(AppConstants.todosRoute);
    } else {
      // Not authenticated, go to login
      logger.d('❌ OAuthCallbackScreen: Not authenticated, navigating to login');
      context.go(AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also listen for real-time auth changes
    ref.listen<AsyncValue<dynamic>>(
      currentUserProvider,
      (previous, next) {
        logger.d('🔗 OAuthCallbackScreen: Auth state changed');

        if (next.value != null) {
          // User is authenticated, navigate to todos
          logger.d('✅ OAuthCallbackScreen: User authenticated (listener), navigating to todos');
          Future.microtask(() {
            if (context.mounted) {
              context.go(AppConstants.todosRoute);
            }
          });
        }
      },
    );

    // Show loading indicator while checking auth state
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Completing sign in...'),
          ],
        ),
      ),
    );
  }
}
