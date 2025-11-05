class AppConstants {
  // App
  static const String appName = 'Todo App';

  // Database
  static const String databaseName = 'app_database.db';
  static const int databaseVersion = 1;

  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  // Use a distinct path for the todos list to avoid self-redirect loops
  static const String todosRoute = '/todos';
  static const String todoDetailRoute = 'detail';
}
