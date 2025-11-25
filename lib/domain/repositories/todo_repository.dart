import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/todo.dart';

abstract class TodoRepository {
  Future<Either<Failure, List<Todo>>> getTodos();
  Future<Either<Failure, List<Todo>>> getFilteredTodos(String filter);
  Future<Either<Failure, List<Todo>>> searchTodos(String query);
  Future<Either<Failure, Todo>> getTodoById(int id);
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
  });
  Future<Either<Failure, Unit>> updateTodo(Todo todo);
  Future<Either<Failure, Unit>> updateTodoPositions(List<Todo> todos);
  Future<Either<Failure, Unit>> deleteTodo(int id);
  Future<Either<Failure, Unit>> toggleCompletion(int id);
  Future<Either<Failure, int>> deleteCompletedTodos();
}
