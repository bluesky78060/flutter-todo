/// Clock abstraction for testable time-dependent code
///
/// This abstraction allows production code to use real time while tests
/// can inject a fixed time for deterministic behavior.
///
/// Usage in production:
/// ```dart
/// final service = RecurringTodoService(repository); // Uses Clock()
/// ```
///
/// Usage in tests:
/// ```dart
/// final testClock = TestClock(DateTime.utc(2025, 6, 1));
/// final service = RecurringTodoService(repository, clock: testClock);
/// ```
class Clock {
  /// Returns the current date and time
  DateTime now() => DateTime.now();
}

/// Test implementation of Clock that returns a fixed time
///
/// This allows tests to have deterministic behavior regardless of
/// when they are executed.
class TestClock extends Clock {
  final DateTime _fixedTime;

  /// Creates a test clock that always returns [fixedTime]
  TestClock(this._fixedTime);

  @override
  DateTime now() => _fixedTime;
}
