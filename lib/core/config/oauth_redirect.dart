import 'package:flutter/foundation.dart' show kIsWeb;
// Use universal_html package for cross-platform compatibility
import 'package:universal_html/html.dart' as html;

/// Returns a redirect URL appropriate for the current runtime.
/// - On web, returns the current origin + /oauth-callback path.
/// - On mobile/desktop, returns null to use Supabase default deep link.
String? oauthRedirectUrl() {
  if (kIsWeb) {
    // On web, explicitly construct the callback URL from current origin
    final origin = html.window.location.origin;
    final redirectUrl = '$origin/oauth-callback';
    print('🔗 OAuth Redirect URL (Web): $redirectUrl');
    return redirectUrl;
  }

  // For non-web (iOS/Android/desktop), return null to use Supabase default
  // The deep link scheme is configured in Supabase dashboard
  print('🔗 OAuth Redirect URL (Mobile): null (using Supabase default)');
  return null;
}
