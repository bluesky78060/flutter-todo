/// Base class for all failure types in the application.
///
/// Failures represent expected error conditions that can occur during
/// normal operation (e.g., network errors, validation errors).
/// This follows the functional programming approach of using Either<Failure, T>
/// instead of throwing exceptions for expected errors.
abstract class Failure {
  /// Creates a new failure instance.
  const Failure();
}

/// Represents a failure related to local database operations.
///
/// This failure is returned when Drift/SQLite operations fail,
/// such as query errors, constraint violations, or database corruption.
class DatabaseFailure extends Failure {
  /// A human-readable description of the database error.
  final String message;

  /// Creates a new database failure with the given [message].
  const DatabaseFailure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure related to authentication operations.
///
/// This failure is returned when auth state operations fail,
/// such as session management or token refresh errors.
class AuthFailure extends Failure {
  /// A human-readable description of the auth error.
  final String message;

  /// Creates a new auth failure with the given [message].
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure due to network connectivity issues.
///
/// This failure is returned when the device cannot reach the server,
/// such as when offline or when DNS resolution fails.
class NetworkFailure extends Failure {
  /// A human-readable description of the network error.
  final String message;

  /// Creates a new network failure with the given [message].
  const NetworkFailure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure from the remote server.
///
/// This failure is returned when the server returns an error response,
/// such as 4xx or 5xx HTTP status codes from Supabase.
class ServerFailure extends Failure {
  /// A human-readable description of the server error.
  final String message;

  /// Creates a new server failure with the given [message].
  const ServerFailure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure related to local cache operations.
///
/// This failure is returned when SharedPreferences or other
/// local storage operations fail.
class CacheFailure extends Failure {
  /// A human-readable description of the cache error.
  final String message;

  /// Creates a new cache failure with the given [message].
  const CacheFailure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure due to invalid input data.
///
/// This failure is returned when user input or data doesn't meet
/// the required validation rules (e.g., empty title, invalid email).
class ValidationFailure extends Failure {
  /// A human-readable description of the validation error.
  final String message;

  /// Creates a new validation failure with the given [message].
  const ValidationFailure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure during user authentication.
///
/// This failure is returned when login/registration fails,
/// such as invalid credentials, expired tokens, or OAuth errors.
class AuthenticationFailure extends Failure {
  /// A human-readable description of the authentication error.
  final String message;

  /// Creates a new authentication failure with the given [message].
  const AuthenticationFailure(this.message);

  @override
  String toString() => message;
}
