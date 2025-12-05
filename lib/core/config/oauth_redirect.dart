import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
// Use universal_html package for cross-platform compatibility
import 'package:universal_html/html.dart' as html;
import 'package:todo_app/core/utils/app_logger.dart';

/// Returns a redirect URL appropriate for the current runtime.
/// - On web, returns the current origin + /oauth-callback path.
/// - On mobile (Android/iOS), returns null to let Supabase SDK handle deep linking automatically.
String? oauthRedirectUrl({OAuthProvider? provider}) {
  if (kIsWeb) {
    // On web, explicitly construct the callback URL from current origin + pathname
    final origin = html.window.location.origin;
    final pathname = html.window.location.pathname ?? '/';

    // Extract base path (e.g., /flutter-todo from /flutter-todo/ or /flutter-todo/login)
    final pathParts = pathname.split('/').where((p) => p.isNotEmpty).toList();
    final basePath = pathParts.isNotEmpty ? '/${pathParts.first}' : '';

    // Use hash routing for Flutter web (#/oauth-callback)
    final redirectUrl = '$origin$basePath/#/oauth-callback';

    logger.d('🔗 OAuth Redirect URL (Web): $redirectUrl');
    return redirectUrl;
  }

  // For mobile - Special handling for Kakao which doesn't work well with custom schemes
  if (provider == OAuthProvider.kakao) {
    // Use Supabase's built-in OAuth callback URL for Kakao
    // This avoids the custom scheme conversion issues
    const kakaoRedirectUrl = 'https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/callback';
    logger.d('🔗 OAuth Redirect URL (Mobile/Kakao): $kakaoRedirectUrl');
    return kakaoRedirectUrl;
  }

  // For other providers (Google), let Supabase SDK handle deep linking automatically
  logger.d('🔗 OAuth Redirect URL (Mobile): null (SDK handles automatically)');
  return null;
}
