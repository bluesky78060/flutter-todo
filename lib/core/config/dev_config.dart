/// Development configuration for local testing
class DevConfig {
  /// Enable local development mode without Supabase authentication
  /// Set to true to bypass authentication for UI testing
  static const bool enableLocalDevMode = false;

  /// Mock user for local development
  static const String mockUserId = 'local-dev-user-123';
  static const String mockUserUuid = 'test-uuid-dev-local-123';
  static const String mockUserEmail = 'dev@localhost.com';
  static const String mockUserName = 'Local Dev User';
}
