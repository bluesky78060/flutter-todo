import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// Abstract repository interface for todo operations.
///
/// Defines the contract for todo persistence operations that must be
/// implemented by concrete repository classes. Uses functional error
/// handling with [Either] to represent success/failure outcomes.
///
/// Implementations:
/// - [TodoRepositoryImpl] for local Drift database operations
/// - [SupabaseTodoRepository] for remote Supabase operations
///
/// See also:
/// - [Todo] for the entity this repository manages
/// - [Failure] for error types that may be returned
abstract class TodoRepository {
  /// Retrieves all todos for the current user.
  ///
  /// Returns [Right] with list of todos on success,
  /// or [Left] with [Failure] on error.
  Future<Either<Failure, List<Todo>>> getTodos();

  /// Retrieves todos filtered by completion status.
  ///
  /// [filter] can be 'all', 'completed', or 'pending'.
  Future<Either<Failure, List<Todo>>> getFilteredTodos(String filter);

  /// Searches todos by title or description.
  ///
  /// [query] is the search term to match against todo content.
  Future<Either<Failure, List<Todo>>> searchTodos(String query);

  /// Retrieves a single todo by its ID.
  ///
  /// Returns [Right] with the todo on success,
  /// or [Left] with [Failure] if not found or on error.
  Future<Either<Failure, Todo>> getTodoById(int id);

  /// Creates a new todo with the specified properties.
  ///
  /// Returns [Right] with the new todo's ID on success.
  ///
  /// Required parameters:
  /// - [title]: The todo title
  /// - [description]: Detailed description
  /// - [dueDate]: Optional due date
  ///
  /// Optional parameters for extended features:
  /// - [categoryId]: Category for organization
  /// - [notificationTime]: When to send reminder
  /// - [recurrenceRule]: RRULE for recurring todos
  /// - [parentRecurringTodoId]: Reference to parent recurring todo
  /// - [locationLatitude], [locationLongitude]: Geofence coordinates
  /// - [locationName]: Human-readable location name
  /// - [locationRadius]: Geofence radius in meters
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

  /// Updates an existing todo with new values.
  ///
  /// [todo] contains the updated todo entity with modified fields.
  Future<Either<Failure, Unit>> updateTodo(Todo todo);

  /// Updates the position ordering of multiple todos.
  ///
  /// Used for drag-and-drop reordering functionality.
  /// [todos] is the list of todos with updated position values.
  Future<Either<Failure, Unit>> updateTodoPositions(List<Todo> todos);

  /// Deletes a todo by its ID.
  ///
  /// Also removes associated subtasks and attachments.
  Future<Either<Failure, Unit>> deleteTodo(int id);

  /// Toggles the completion status of a todo.
  ///
  /// Sets [completedAt] timestamp when completing,
  /// clears it when uncompleting.
  Future<Either<Failure, Unit>> toggleCompletion(int id);

  /// Deletes all completed todos for the current user.
  ///
  /// Returns [Right] with the count of deleted todos.
  Future<Either<Failure, int>> deleteCompletedTodos();
}
