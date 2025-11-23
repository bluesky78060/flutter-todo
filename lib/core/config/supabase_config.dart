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

    // Mobile/Desktop: Read from .env file
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL not found in .env file. '
        'Please copy .env.example to .env and fill in your credentials.',
      );
    }
    return url;
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

    // Mobile/Desktop: Read from .env file
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY not found in .env file. '
        'Please copy .env.example to .env and fill in your credentials.',
      );
    }
    return key;
  }
}
