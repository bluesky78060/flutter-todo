import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens a database connection for web platform
QueryExecutor openConnection() {
  return WebDatabase('app_database', logStatements: false);
}
