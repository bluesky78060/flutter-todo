/// Application-wide constant values.
///
/// This class contains all static constants used throughout the app,
/// including app metadata, database configuration, and route paths.
/// Using centralized constants ensures consistency and makes maintenance easier.
class AppConstants {
  /// The display name of the application.
  static const String appName = 'Todo App';

  /// The filename for the local SQLite database.
  static const String databaseName = 'app_database.db';

  /// The current version of the database schema.
  ///
  /// Increment this value when making schema changes that require migration.
  static const int databaseVersion = 1;

  /// Route path for the login screen.
  static const String loginRoute = '/login';

  /// Route path for the registration screen.
  static const String registerRoute = '/register';

  /// Route path for the main todo list screen.
  ///
  /// Uses a distinct path to avoid self-redirect loops in GoRouter.
  static const String todosRoute = '/todos';

  /// Route name for the todo detail screen (nested under todosRoute).
  static const String todoDetailRoute = 'detail';
}
