import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/domain/entities/auth_user.dart';
import 'package:todo_app/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseAuthDataSource dataSource;

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
