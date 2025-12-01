import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/auth_user.dart';

/// Abstract repository interface for authentication operations.
///
/// Defines the contract for user authentication that must be implemented
/// by concrete repository classes. Supports email/password authentication
/// with session management.
///
/// Implementations:
/// - [AuthRepositoryImpl] for local development/testing
/// - [SupabaseAuthRepository] for production Supabase authentication
///
/// See also:
/// - [AuthUser] for the authenticated user entity
/// - [AuthFailure] for authentication-specific errors
abstract class AuthRepository {
  /// Authenticates a user with email and password.
  ///
  /// Returns [Right] with [AuthUser] on successful login,
  /// or [Left] with [AuthFailure] for invalid credentials or errors.
  Future<Either<Failure, AuthUser>> login(String email, String password);

  /// Registers a new user account.
  ///
  /// Parameters:
  /// - [email]: User's email address (must be unique)
  /// - [password]: User's chosen password
  /// - [name]: User's display name
  ///
  /// Returns [Right] with newly created [AuthUser] on success,
  /// or [Left] with [AuthFailure] if email already exists or validation fails.
  Future<Either<Failure, AuthUser>> register(
      String email, String password, String name);

  /// Logs out the current user and clears the session.
  ///
  /// Returns [Right] with [Unit] on success,
  /// or [Left] with [AuthFailure] on error.
  Future<Either<Failure, Unit>> logout();

  /// Retrieves the currently authenticated user, if any.
  ///
  /// Returns [Right] with [AuthUser] if logged in,
  /// [Right] with null if no user is logged in,
  /// or [Left] with [AuthFailure] on error.
  Future<Either<Failure, AuthUser?>> getCurrentUser();
}
