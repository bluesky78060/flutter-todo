import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/subtask.dart';
import 'package:todo_app/domain/repositories/subtask_repository.dart';

/// Remote implementation of [SubtaskRepository] using Supabase.
///
/// This repository handles subtask operations through Supabase,
/// enabling cloud sync for todo checklist items.
///
/// Features:
/// - CRUD operations for subtasks
/// - Position-based ordering within a todo
/// - Completion toggling with timestamp
/// - Stats aggregation (total/completed counts)
///
/// Note: Requires authenticated user. Operations will fail if not logged in.
///
/// See also:
/// - [SubtaskRepository] for the interface contract
/// - [SubtaskRepositoryImpl] for local implementation
/// - [Subtask] for the subtask entity
class SupabaseSubtaskRepository implements SubtaskRepository {
  /// The Supabase client for database operations.
  final SupabaseClient _supabaseClient;

  /// Creates a [SupabaseSubtaskRepository] with the given Supabase client.
  SupabaseSubtaskRepository(this._supabaseClient);

  @override
  Future<Either<Failure, List<Subtask>>> getSubtasksByTodoId(
      int todoId) async {
    try {
      final response = await _supabaseClient
          .from('subtasks')
          .select()
          .eq('todo_id', todoId)
          .order('position');

      final subtasks = (response as List)
          .map((json) => Subtask.fromJson(_mapSupabaseToEntity(json)))
          .toList();

      return right(subtasks);
    } on PostgrestException catch (e) {
      return left(ServerFailure('Failed to load subtasks: ${e.message}'));
    } catch (e) {
      return left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Subtask>> getSubtaskById(int id) async {
    try {
      final response = await _supabaseClient
          .from('subtasks')
          .select()
          .eq('id', id)
          .single();

      return right(Subtask.fromJson(_mapSupabaseToEntity(response)));
    } on PostgrestException catch (e) {
      return left(ServerFailure('Failed to load subtask: ${e.message}'));
    } catch (e) {
      return left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createSubtask(Subtask subtask) async {
    try {
      final response = await _supabaseClient
          .from('subtasks')
          .insert(_mapEntityToSupabase(subtask))
          .select()
          .single();

      return right(response['id'] as int);
    } on PostgrestException catch (e) {
      return left(ServerFailure('Failed to create subtask: ${e.message}'));
    } catch (e) {
      return left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateSubtask(Subtask subtask) async {
    try {
      await _supabaseClient
          .from('subtasks')
          .update(_mapEntityToSupabase(subtask))
          .eq('id', subtask.id);

      return right(unit);
    } on PostgrestException catch (e) {
      return left(ServerFailure('Failed to update subtask: ${e.message}'));
    } catch (e) {
      return left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSubtask(int id) async {
    try {
      await _supabaseClient.from('subtasks').delete().eq('id', id);

      return right(unit);
    } on PostgrestException catch (e) {
      return left(ServerFailure('Failed to delete subtask: ${e.message}'));
    } catch (e) {
      return left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleSubtaskCompletion(int id) async {
    try {
      final subtaskResult = await getSubtaskById(id);

      return subtaskResult.fold(
        (failure) => left(failure),
        (subtask) async {
          final updatedSubtask = Subtask(
            id: subtask.id,
            todoId: subtask.todoId,
            userId: subtask.userId,
            title: subtask.title,
            isCompleted: !subtask.isCompleted,
            position: subtask.position,
            createdAt: subtask.createdAt,
            completedAt: !subtask.isCompleted ? DateTime.now() : null,
          );

          await _supabaseClient
              .from('subtasks')
              .update(_mapEntityToSupabase(updatedSubtask))
              .eq('id', id);

          return right(unit);
        },
      );
    } on PostgrestException catch (e) {
      return left(
          ServerFailure('Failed to toggle subtask completion: ${e.message}'));
    } catch (e) {
      return left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getSubtaskStats(int todoId) async {
    try {
      final subtasksResult = await getSubtasksByTodoId(todoId);

      return subtasksResult.fold(
        (failure) => left(failure),
        (subtasks) {
          final total = subtasks.length;
          final completed = subtasks.where((s) => s.isCompleted).length;

          return right({
            'total': total,
            'completed': completed,
          });
        },
      );
    } catch (e) {
      return left(NetworkFailure('Failed to load subtask stats: $e'));
    }
  }

  // Mapping functions
  Map<String, dynamic> _mapSupabaseToEntity(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'todoId': json['todo_id'],
      'userId': json['user_id'],
      'title': json['title'],
      'isCompleted': json['is_completed'] ?? false,
      'position': json['position'],
      'createdAt': json['created_at'],
      'completedAt': json['completed_at'],
    };
  }

  Map<String, dynamic> _mapEntityToSupabase(Subtask subtask) {
    return {
      'todo_id': subtask.todoId,
      'user_id': subtask.userId,
      'title': subtask.title,
      'is_completed': subtask.isCompleted,
      'position': subtask.position,
      'created_at': subtask.createdAt.toUtc().toIso8601String(),
      'completed_at': subtask.completedAt?.toUtc().toIso8601String(),
    };
  }
}
