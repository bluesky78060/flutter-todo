import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

class SupabaseTodoRepository implements TodoRepository {
  final SupabaseTodoDataSource dataSource;

  SupabaseTodoRepository(this.dataSource);

  @override
  Future<Either<Failure, List<Todo>>> getTodos() async {
    try {
      final todos = await dataSource.getTodos();
      return Right(todos);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getFilteredTodos(String filter) async {
    try {
      final todos = await dataSource.getFilteredTodos(filter);
      return Right(todos);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Todo>> getTodoById(int id) async {
    try {
      final todo = await dataSource.getTodoById(id);
      return Right(todo);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createTodo(String title, String description) async {
    try {
      await dataSource.createTodo(title, description);
      return const Right(0); // Return dummy ID since Supabase handles ID generation
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTodo(Todo todo) async {
    try {
      await dataSource.updateTodo(todo);
      return right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTodo(int id) async {
    try {
      await dataSource.deleteTodo(id);
      return right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleCompletion(int id) async {
    try {
      await dataSource.toggleCompletion(id);
      return right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
