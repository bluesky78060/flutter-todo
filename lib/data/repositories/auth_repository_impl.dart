import 'package:drift/drift.dart' as drift;
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/domain/entities/auth_user.dart';
import 'package:todo_app/domain/repositories/auth_repository.dart';

/// Local implementation of [AuthRepository] using Drift and SharedPreferences.
///
/// This repository provides offline-capable authentication using:
/// - Drift database for user credential storage
/// - SharedPreferences for session persistence
///
/// WARNING: This is a simplified implementation for development/testing.
/// In production, use [SupabaseAuthRepository] for secure authentication.
///
/// Security Limitations:
/// - Passwords are stored in plaintext (use hashing in production)
/// - No token-based session management
/// - No password reset functionality
///
/// See also:
/// - [AuthRepository] for the interface contract
/// - [SupabaseAuthRepository] for production implementation
class AuthRepositoryImpl implements AuthRepository {
  /// The local Drift database for user storage.
  final AppDatabase database;

  /// SharedPreferences for session persistence.
  final SharedPreferences prefs;

  /// Key used to store the current user ID in SharedPreferences.
  static const String _userIdKey = 'user_id';

  /// Creates an [AuthRepositoryImpl] with the given [database] and [prefs].
  AuthRepositoryImpl(this.database, this.prefs);

  @override
  Future<Either<Failure, AuthUser>> login(
      String email, String password) async {
    try {
      final user = await database.getUserByEmail(email);
      if (user == null) {
        return const Left(AuthFailure('User not found'));
      }
      if (user.password != password) {
        // Note: In production, use proper password hashing
        return const Left(AuthFailure('Incorrect password'));
      }

      await prefs.setInt(_userIdKey, user.id);

      return Right(_mapUserToEntity(user));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register(
      String email, String password, String name) async {
    try {
      final existingUser = await database.getUserByEmail(email);
      if (existingUser != null) {
        return const Left(AuthFailure('Email already registered'));
      }

      final id = await database.insertUser(
        UsersCompanion(
          email: drift.Value(email),
          password: drift.Value(password), // Note: Use hashing in production
          name: drift.Value(name),
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      await prefs.setInt(_userIdKey, id);

      return Right(AuthUser(
        id: id,
        uuid: id.toString(), // Convert int ID to string for compatibility
        email: email,
        name: name,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await prefs.remove(_userIdKey);
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      final userId = prefs.getInt(_userIdKey);
      if (userId == null) {
        return const Right(null);
      }

      final user = await database.getUserById(userId);

      if (user == null) {
        await prefs.remove(_userIdKey);
        return const Right(null);
      }

      return Right(_mapUserToEntity(user));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  AuthUser _mapUserToEntity(User user) {
    return AuthUser(
      id: user.id,
      uuid: user.id.toString(), // Convert int ID to string for compatibility
      email: user.email,
      name: user.name,
      createdAt: user.createdAt,
    );
  }
}
