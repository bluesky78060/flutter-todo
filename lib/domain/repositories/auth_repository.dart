import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> login(String email, String password);
  Future<Either<Failure, AuthUser>> register(
      String email, String password, String name);
  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, AuthUser?>> getCurrentUser();
}
