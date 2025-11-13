import 'package:drift/drift.dart' as drift;
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/domain/entities/auth_user.dart';
import 'package:todo_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase database;
  final SharedPreferences prefs;

  static const String _userIdKey = 'user_id';

  AuthRepositoryImpl(this.database, this.prefs);

  @override
  Future<Either<Failure, AuthUser>> login(
      String email, String password) async {
    try {
      final user = await database.getUserByEmail(email);
      if (user == null) {
        return const Left(AuthFailure('사용자를 찾을 수 없습니다'));
      }
      if (user.password != password) {
        // Note: In production, use proper password hashing
        return const Left(AuthFailure('비밀번호가 일치하지 않습니다'));
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
        return const Left(AuthFailure('이미 등록된 이메일입니다'));
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
