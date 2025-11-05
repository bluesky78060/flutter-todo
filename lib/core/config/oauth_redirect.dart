import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Returns a redirect URL appropriate for the current runtime.
/// - On web, returns the current origin + path (handles subpaths).
/// - On mobile/desktop, returns the deep link URL registered in Supabase dashboard.
/// For Supabase OAuth on web, using the current URL avoids hardcoded domains.
String? oauthRedirectUrl() {
  if (kIsWeb) {
    // Build a callback URL that respects hosting subpaths (e.g. GitHub Pages)
    final base = Uri.base.removeFragment();
    final origin = '${base.scheme}://${base.authority}';
    final basePath = base.path; // might be '/' or '/subpath/'
    final normalizedBasePath = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final redirectUrl = '$origin$normalizedBasePath/oauth-callback';

    print('🔗 OAuth Redirect URL (Web): $redirectUrl');
    return redirectUrl;
  }

  // For non-web (iOS/Android/desktop), use deep link URL scheme
  // This must match the CFBundleURLSchemes in Info.plist and
  // must be registered in Supabase dashboard redirect URLs
  final redirectUrl = 'com.example.todoapp://login-callback';
  print('🔗 OAuth Redirect URL (Mobile): $redirectUrl');
  return redirectUrl;
}
