import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/domain/entities/subtask.dart' as entity;
import 'package:todo_app/domain/repositories/subtask_repository.dart';

/// Local implementation of [SubtaskRepository] using Drift database.
///
/// This repository handles all subtask operations for todos stored locally.
/// Subtasks are checklist items within a todo that can be individually completed.
///
/// Features:
/// - CRUD operations for subtasks
/// - Position-based ordering within a todo
/// - Completion toggling
/// - Stats aggregation (total/completed counts)
///
/// See also:
/// - [SubtaskRepository] for the interface contract
/// - [Subtask] for the subtask entity
/// - [AppDatabase] for the underlying database
class SubtaskRepositoryImpl implements SubtaskRepository {
  /// The local Drift database.
  final AppDatabase _database;

  /// Creates a [SubtaskRepositoryImpl] with the given database.
  SubtaskRepositoryImpl(this._database);

  @override
  Future<Either<Failure, List<entity.Subtask>>> getSubtasksByTodoId(
      int todoId) async {
    try {
      final subtasks = await _database.getSubtasksByTodoId(todoId);
      return right(subtasks.map(_mapDriftToEntity).toList());
    } catch (e) {
      return left(DatabaseFailure('Failed to load subtasks: $e'));
    }
  }

  @override
  Future<Either<Failure, entity.Subtask>> getSubtaskById(int id) async {
    try {
      final subtask = await _database.getSubtaskById(id);
      if (subtask == null) {
        return const left(DatabaseFailure('Subtask not found'));
      }
      return right(_mapDriftToEntity(subtask));
    } catch (e) {
      return left(DatabaseFailure('Failed to load subtask: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createSubtask(entity.Subtask subtask) async {
    try {
      final id = await _database.insertSubtask(
        SubtasksCompanion(
          todoId: Value(subtask.todoId),
          userId: Value(subtask.userId),
          title: Value(subtask.title),
          isCompleted: Value(subtask.isCompleted),
          position: Value(subtask.position),
          createdAt: Value(subtask.createdAt),
          completedAt: Value(subtask.completedAt),
        ),
      );
      return right(id);
    } catch (e) {
      return left(DatabaseFailure('Failed to create subtask: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateSubtask(entity.Subtask subtask) async {
    try {
      await _database.updateSubtask(_mapEntityToDrift(subtask));
      return right(unit);
    } catch (e) {
      return left(DatabaseFailure('Failed to update subtask: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSubtask(int id) async {
    try {
      await _database.deleteSubtask(id);
      return right(unit);
    } catch (e) {
      return left(DatabaseFailure('Failed to delete subtask: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleSubtaskCompletion(int id) async {
    try {
      await _database.toggleSubtaskCompletion(id);
      return right(unit);
    } catch (e) {
      return left(DatabaseFailure('Failed to toggle subtask completion: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getSubtaskStats(int todoId) async {
    try {
      final stats = await _database.getSubtaskStats(todoId);
      return right(stats);
    } catch (e) {
      return left(DatabaseFailure('Failed to load subtask stats: $e'));
    }
  }

  // Mapping functions
  entity.Subtask _mapDriftToEntity(Subtask driftSubtask) {
    return entity.Subtask(
      id: driftSubtask.id,
      todoId: driftSubtask.todoId,
      userId: driftSubtask.userId,
      title: driftSubtask.title,
      isCompleted: driftSubtask.isCompleted,
      position: driftSubtask.position,
      createdAt: driftSubtask.createdAt,
      completedAt: driftSubtask.completedAt,
    );
  }

  Subtask _mapEntityToDrift(entity.Subtask entitySubtask) {
    return Subtask(
      id: entitySubtask.id,
      todoId: entitySubtask.todoId,
      userId: entitySubtask.userId,
      title: entitySubtask.title,
      isCompleted: entitySubtask.isCompleted,
      position: entitySubtask.position,
      createdAt: entitySubtask.createdAt,
      completedAt: entitySubtask.completedAt,
    );
  }
}
