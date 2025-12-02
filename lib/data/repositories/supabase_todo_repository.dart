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
  Future<Either<Failure, int>> createTodo(
    String title,
    String description,
    DateTime? dueDate, {
    int? categoryId,
    DateTime? notificationTime,
    String? recurrenceRule,
    String? priority,
    int? parentRecurringTodoId,
    double? locationLatitude,
    double? locationLongitude,
    String? locationName,
    double? locationRadius,
  }) async {
    try {
      final id = await dataSource.createTodo(
        title,
        description,
        dueDate,
        categoryId: categoryId,
        notificationTime: notificationTime,
        recurrenceRule: recurrenceRule,
        priority: priority,
        parentRecurringTodoId: parentRecurringTodoId,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        locationName: locationName,
        locationRadius: locationRadius,
      );
      return Right(id); // Return actual ID from Supabase
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
  Future<Either<Failure, Unit>> updateTodoPositions(List<Todo> todos) async {
    try {
      print('📦 [SupabaseTodoRepository] updateTodoPositions called with ${todos.length} todos');
      for (final todo in todos) {
        print('  💾 Updating todo: ${todo.title} (id=${todo.id}, position=${todo.position})');
        await dataSource.updateTodo(todo);
      }
      print('✅ [SupabaseTodoRepository] All positions updated successfully');
      return right(unit);
    } catch (e) {
      print('❌ [SupabaseTodoRepository] Error updating positions: $e');
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

  @override
  Future<Either<Failure, int>> deleteCompletedTodos() async {
    try {
      final deletedCount = await dataSource.deleteCompletedTodos();
      return Right(deletedCount);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> searchTodos(String query) async {
    try {
      final todos = await dataSource.searchTodos(query);
      return Right(todos);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
