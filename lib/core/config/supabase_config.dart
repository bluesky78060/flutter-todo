import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration loaded from environment variables
///
/// SECURITY: Credentials are loaded from .env file (not committed to git)
/// See .env.example for required environment variables
class SupabaseConfig {
  /// Supabase project URL
  /// Loaded from SUPABASE_URL environment variable
  static String get url {
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
