import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Returns a redirect URL appropriate for the current runtime.
/// - On web, returns the current origin + path (handles subpaths).
/// - On mobile/desktop, falls back to an app-hosted URL if needed.
/// For Supabase OAuth on web, using the current URL avoids hardcoded domains.
String oauthRedirectUrl() {
  if (kIsWeb) {
    final base = Uri.base.removeFragment();
    final origin = '${base.scheme}://${base.authority}';
    final path = base.path.endsWith('/') ? base.path : '${base.path}/';
    final redirectUrl = '$origin$path';

    // Debug: Print redirect URL to console
    print('🔗 OAuth Redirect URL: $redirectUrl');

    return redirectUrl;
  }
  // For non-web (iOS/Android/desktop), you generally need a deep link or custom scheme.
  // Keep this as a placeholder; configure platform-specific redirect if you add native OAuth.
  return 'https://example.com/';
}

