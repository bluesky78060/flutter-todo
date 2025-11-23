import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

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
      try {
        final env = js_util.getProperty(html.window, 'ENV');
        if (env != null) {
          final url = js_util.getProperty(env, 'SUPABASE_URL');
          if (url != null && url.toString().isNotEmpty) {
            return url.toString();
          }
        }
      } catch (e) {
        // Fall through to dotenv for local development
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
      try {
        final env = js_util.getProperty(html.window, 'ENV');
        if (env != null) {
          final key = js_util.getProperty(env, 'SUPABASE_ANON_KEY');
          if (key != null && key.toString().isNotEmpty) {
            return key.toString();
          }
        }
      } catch (e) {
        // Fall through to dotenv for local development
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
