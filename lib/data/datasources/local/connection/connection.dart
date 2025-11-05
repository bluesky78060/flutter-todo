import 'package:drift/drift.dart';

/// Stub implementation - should never be called
/// Will be replaced by native.dart or web.dart at compile time
QueryExecutor openConnection() {
  throw UnsupportedError(
    'No suitable database implementation was found on this platform.',
  );
}
