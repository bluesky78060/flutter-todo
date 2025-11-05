import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';

/// OAuth callback landing screen
/// This screen is shown briefly after OAuth authentication completes
/// It checks auth state and redirects appropriately
class OAuthCallbackScreen extends ConsumerWidget {
  const OAuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔗 OAuthCallbackScreen: Building');

    // Listen to auth state
    final userAsync = ref.watch(currentUserProvider);

    // Handle auth state
    ref.listen<AsyncValue<dynamic>>(
      currentUserProvider,
      (previous, next) {
        print('🔗 OAuthCallbackScreen: Auth state changed');

        if (next.value != null) {
          // User is authenticated, navigate to todos
          print('✅ OAuthCallbackScreen: User authenticated, navigating to todos');
          Future.microtask(() {
            if (context.mounted) {
              context.go(AppConstants.todosRoute);
            }
          });
        } else if (!next.isLoading) {
          // No user and not loading, go to login
          print('❌ OAuthCallbackScreen: Not authenticated, navigating to login');
          Future.microtask(() {
            if (context.mounted) {
              context.go(AppConstants.loginRoute);
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
