import 'package:drift/drift.dart' as drift;
import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/domain/entities/todo.dart' as entity;
import 'package:todo_app/domain/repositories/todo_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  final AppDatabase database;

  TodoRepositoryImpl(this.database);

  @override
  Future<Either<Failure, List<entity.Todo>>> getTodos() async {
    try {
      final todos = await database.getAllTodos();
      return Right(_mapTodosToEntities(todos));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<entity.Todo>>> getFilteredTodos(
      String filter) async {
    try {
      final todos = await database.getFilteredTodos(filter);
      return Right(_mapTodosToEntities(todos));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, entity.Todo>> getTodoById(int id) async {
    try {
      final todo = await database.getTodoById(id);
      if (todo == null) {
        return Left(DatabaseFailure('Todo not found'));
      }
      return Right(_mapTodoToEntity(todo));
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
    int? parentRecurringTodoId,
    double? locationLatitude,
    double? locationLongitude,
    String? locationName,
    double? locationRadius,
  }) async {
    try {
      final id = await database.insertTodo(
        TodosCompanion(
          title: drift.Value(title),
          description: drift.Value(description),
          isCompleted: const drift.Value(false),
          categoryId: drift.Value(categoryId),
          createdAt: drift.Value(DateTime.now()),
          dueDate: drift.Value(dueDate),
          notificationTime: drift.Value(notificationTime),
          recurrenceRule: drift.Value(recurrenceRule),
          parentRecurringTodoId: drift.Value(parentRecurringTodoId),
          locationLatitude: drift.Value(locationLatitude),
          locationLongitude: drift.Value(locationLongitude),
          locationName: drift.Value(locationName),
          locationRadius: drift.Value(locationRadius),
        ),
      );
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTodo(entity.Todo todo) async {
    try {
      final dbTodo = Todo(
        id: todo.id,
        title: todo.title,
        description: todo.description,
        isCompleted: todo.isCompleted,
        categoryId: todo.categoryId,
        createdAt: todo.createdAt,
        completedAt: todo.completedAt,
        dueDate: todo.dueDate,
        notificationTime: todo.notificationTime,
        recurrenceRule: todo.recurrenceRule,
        parentRecurringTodoId: todo.parentRecurringTodoId,
        snoozeCount: todo.snoozeCount,
        lastSnoozeTime: todo.lastSnoozeTime,
        locationLatitude: todo.locationLatitude,
        locationLongitude: todo.locationLongitude,
        locationName: todo.locationName,
        locationRadius: todo.locationRadius,
      );
      await database.updateTodo(dbTodo);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTodo(int id) async {
    try {
      await database.deleteTodo(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleCompletion(int id) async {
    try {
      await database.toggleTodoCompletion(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<entity.Todo>>> searchTodos(String query) async {
    try {
      // Local database search not implemented yet
      // For now, return empty list as search is primarily done on Supabase
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteCompletedTodos() async {
    try {
      // Local database bulk delete not implemented yet
      // For now, return 0 as this is primarily done on Supabase
      return const Right(0);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // Mappers
  List<entity.Todo> _mapTodosToEntities(List<Todo> todos) {
    return todos.map(_mapTodoToEntity).toList();
  }

  entity.Todo _mapTodoToEntity(Todo todo) {
    return entity.Todo(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: todo.isCompleted,
      categoryId: todo.categoryId,
      createdAt: todo.createdAt,
      completedAt: todo.completedAt,
      dueDate: todo.dueDate,
      notificationTime: todo.notificationTime,
      recurrenceRule: todo.recurrenceRule,
      parentRecurringTodoId: todo.parentRecurringTodoId,
      snoozeCount: todo.snoozeCount ?? 0,
      lastSnoozeTime: todo.lastSnoozeTime,
      locationLatitude: todo.locationLatitude,
      locationLongitude: todo.locationLongitude,
      locationName: todo.locationName,
      locationRadius: todo.locationRadius,
    );
  }
}
