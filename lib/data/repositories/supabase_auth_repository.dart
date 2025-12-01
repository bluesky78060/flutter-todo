import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/domain/entities/auth_user.dart';
import 'package:todo_app/domain/repositories/auth_repository.dart';

/// Remote implementation of [AuthRepository] using Supabase Auth.
///
/// This repository handles all authentication operations through Supabase,
/// including email/password auth and session management.
///
/// Features:
/// - Email/password login and registration
/// - Session persistence across app restarts
/// - Secure logout with session cleanup
///
/// Note: OAuth providers (Google, Kakao) are handled separately through
/// the Supabase SDK's OAuth flow, not through this repository.
///
/// See also:
/// - [AuthRepository] for the interface contract
/// - [SupabaseAuthDataSource] for underlying operations
/// - [AuthNotifier] for auth state management
class SupabaseAuthRepository implements AuthRepository {
  /// The Supabase auth data source.
  final SupabaseAuthDataSource dataSource;

  /// Creates a [SupabaseAuthRepository] with the given [dataSource].
  SupabaseAuthRepository(this.dataSource);

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      final user = await dataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> login(String email, String password) async {
    try {
      await dataSource.login(email, password);
      final user = await dataSource.getCurrentUser();
      return Right(user!);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register(
      String email, String password, String name) async {
    try {
      await dataSource.register(email, password, name);
      final user = await dataSource.getCurrentUser();
      return Right(user!);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await dataSource.logout();
      return right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
