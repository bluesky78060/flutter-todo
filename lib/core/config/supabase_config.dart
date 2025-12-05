import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Conditional import for web/non-web platforms
import 'supabase_config_stub.dart'
    if (dart.library.html) 'supabase_config_web.dart';

/// Supabase configuration loaded from environment variables
///
/// SECURITY: Credentials are loaded from .env file (not committed to git)
/// Web: Credentials are loaded from window.ENV (injected by scripts/inject_env.sh)
/// See .env.example for required environment variables
class SupabaseConfig {
  /// Supabase project URL
  /// Loaded from SUPABASE_URL environment variable
  static String get url {
    if (kIsWeb) {
      // Web: Read from window.ENV
      final webUrl = getEnvFromWindow('SUPABASE_URL');
      if (webUrl != null && webUrl.isNotEmpty) {
        return webUrl;
      }
    }

    // Mobile/Desktop: Read from .env file or use default
    try {
      final url = dotenv.env['SUPABASE_URL'];
      if (url != null && url.isNotEmpty) {
        return url;
      }
    } catch (e) {
      // dotenv not initialized, use default
    }

    // Default Supabase URL
    return 'https://bulwfcsyqgsvmbadhlye.supabase.co';
  }

  /// Supabase anonymous key
  /// Loaded from SUPABASE_ANON_KEY environment variable
  static String get anonKey {
    if (kIsWeb) {
      // Web: Read from window.ENV
      final webKey = getEnvFromWindow('SUPABASE_ANON_KEY');
      if (webKey != null && webKey.isNotEmpty) {
        return webKey;
      }
    }

    // Mobile/Desktop: Read from .env file or use default
    try {
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (e) {
      // dotenv not initialized, use default
    }

    // Default Supabase anonymous key
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bHdmY3N5cWdzdm1iYWRobHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMzM1MjMsImV4cCI6MjA3NzcwOTUyM30._5Ft7sTK6m946oDSRHgjFgDBRc7YH-nD9KC8gLkHeo0';
  }
}
