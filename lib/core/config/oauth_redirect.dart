import 'package:flutter/foundation.dart' show kIsWeb;
// Use universal_html package for cross-platform compatibility
import 'package:universal_html/html.dart' as html;
import 'package:todo_app/core/utils/app_logger.dart';

/// Returns a redirect URL appropriate for the current runtime.
/// - On web, returns the current origin + /oauth-callback path.
/// - On mobile/desktop, returns null to use Supabase default deep link.
String? oauthRedirectUrl() {
  if (kIsWeb) {
    // On web, explicitly construct the callback URL from current origin + pathname
    final origin = html.window.location.origin;
    final pathname = html.window.location.pathname ?? '/';

    // Extract base path (e.g., /flutter-todo from /flutter-todo/ or /flutter-todo/login)
    final pathParts = pathname.split('/').where((p) => p.isNotEmpty).toList();
    final basePath = pathParts.isNotEmpty ? '/${pathParts.first}' : '';
    final redirectUrl = '$origin$basePath/oauth-callback';

    logger.d('🔗 OAuth Redirect URL (Web): $redirectUrl');
    return redirectUrl;
  }

  // For non-web (iOS/Android/desktop), use deep link scheme
  // Must match the scheme in AndroidManifest.xml / Info.plist
  const redirectUrl = 'kr.bluesky.dodo://oauth-callback';
  logger.d('🔗 OAuth Redirect URL (Mobile): $redirectUrl');
  return redirectUrl;
}
