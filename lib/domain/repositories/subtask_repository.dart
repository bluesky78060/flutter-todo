import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/subtask.dart';

/// Abstract repository interface for subtask operations.
///
/// Defines the contract for subtask (checklist item) persistence operations.
/// Subtasks are child items of todos that can be independently managed
/// and tracked for completion.
///
/// Implementations:
/// - [SubtaskRepositoryImpl] for local Drift database operations
/// - [SupabaseSubtaskRepository] for remote Supabase operations
///
/// See also:
/// - [Subtask] for the entity this repository manages
/// - [Todo] for the parent entity
abstract class SubtaskRepository {
  /// Retrieves all subtasks for a specific todo.
  ///
  /// [todoId] is the ID of the parent todo.
  /// Returns subtasks ordered by position.
  Future<Either<Failure, List<Subtask>>> getSubtasksByTodoId(int todoId);

  /// Retrieves a single subtask by its ID.
  ///
  /// Returns [Right] with the subtask on success,
  /// or [Left] with [Failure] if not found.
  Future<Either<Failure, Subtask>> getSubtaskById(int id);

  /// Creates a new subtask.
  ///
  /// [subtask] contains all required properties for the new subtask.
  /// Returns [Right] with the new subtask's ID on success.
  Future<Either<Failure, int>> createSubtask(Subtask subtask);

  /// Updates an existing subtask with new values.
  ///
  /// [subtask] contains the updated subtask entity.
  Future<Either<Failure, Unit>> updateSubtask(Subtask subtask);

  /// Deletes a subtask by its ID.
  Future<Either<Failure, Unit>> deleteSubtask(int id);

  /// Toggles the completion status of a subtask.
  ///
  /// Sets [completedAt] timestamp when completing,
  /// clears it when uncompleting.
  Future<Either<Failure, Unit>> toggleSubtaskCompletion(int id);

  /// Retrieves completion statistics for a todo's subtasks.
  ///
  /// [todoId] is the ID of the parent todo.
  /// Returns a map with keys:
  /// - `'total'`: Total number of subtasks
  /// - `'completed'`: Number of completed subtasks
  Future<Either<Failure, Map<String, int>>> getSubtaskStats(int todoId);
}
