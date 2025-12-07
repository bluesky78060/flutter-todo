/// Subtask state management providers using Riverpod.
///
/// Provides subtask (checklist item) data access and CRUD operations
/// with local-first sync strategy.
///
/// Key providers:
/// - [subtaskRepositoryProvider]: Local repository for subtasks
/// - [remoteSubtaskRepositoryProvider]: Remote Supabase repository
/// - [subtaskListProvider]: List of subtasks for a specific todo
/// - [subtaskActionsProvider]: CRUD operations for subtasks
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/data/repositories/subtask_repository_impl.dart';
import 'package:todo_app/data/repositories/supabase_subtask_repository.dart';
import 'package:todo_app/domain/entities/subtask.dart' as entity;
import 'package:todo_app/domain/repositories/subtask_repository.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

/// Provides the local subtask repository for offline operations.
final subtaskRepositoryProvider = Provider<SubtaskRepository>((ref) {
  final database = ref.watch(localDatabaseProvider);
  return SubtaskRepositoryImpl(database);
});

/// Provides the remote Supabase subtask repository for cloud sync.
final remoteSubtaskRepositoryProvider = Provider<SubtaskRepository>((ref) {
  final supabase = Supabase.instance.client;
  return SupabaseSubtaskRepository(supabase);
});

/// Provides subtasks for a specific todo.
///
/// Uses remote repository for authenticated users with local fallback,
/// or local-only for unauthenticated users.
final subtaskListProvider =
    FutureProvider.family<List<entity.Subtask>, int>((ref, todoId) async {
  // Check if user is authenticated
  final authState = ref.watch(currentUserProvider);

  return await authState.when(
    data: (session) async {
      if (session != null) {
        // User is authenticated - try remote first, fallback to local
        final remoteRepo = ref.read(remoteSubtaskRepositoryProvider);
        final result = await remoteRepo.getSubtasksByTodoId(todoId);

        return result.fold(
          (failure) async {
            // If remote fails, fallback to local
            final localRepo = ref.read(subtaskRepositoryProvider);
            final localResult = await localRepo.getSubtasksByTodoId(todoId);
            return localResult.getOrElse((l) => []);
          },
          (subtasks) => subtasks,
        );
      } else {
        // User is not authenticated - use local only
        final localRepo = ref.read(subtaskRepositoryProvider);
        final result = await localRepo.getSubtasksByTodoId(todoId);
        return result.getOrElse((l) => []);
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provides completion statistics for a todo's subtasks.
///
/// Returns a map with 'total' and 'completed' counts.
/// Uses remote repository for authenticated users with local fallback.
final subtaskStatsProvider =
    FutureProvider.family<Map<String, int>, int>((ref, todoId) async {
  // Check if user is authenticated
  final authState = ref.watch(currentUserProvider);

  return await authState.when(
    data: (session) async {
      if (session != null) {
        // User is authenticated - try remote first, fallback to local
        final remoteRepo = ref.read(remoteSubtaskRepositoryProvider);
        final result = await remoteRepo.getSubtaskStats(todoId);

        return result.fold(
          (failure) async {
            // If remote fails, fallback to local
            final localRepo = ref.read(subtaskRepositoryProvider);
            final localResult = await localRepo.getSubtaskStats(todoId);
            return localResult.getOrElse((l) => {'total': 0, 'completed': 0});
          },
          (stats) => stats,
        );
      } else {
        // User is not authenticated - use local only
        final localRepo = ref.read(subtaskRepositoryProvider);
        final result = await localRepo.getSubtaskStats(todoId);
        return result.getOrElse((l) => {'total': 0, 'completed': 0});
      }
    },
    loading: () => {'total': 0, 'completed': 0},
    error: (_, __) => {'total': 0, 'completed': 0},
  );
});

/// Provides the [SubtaskActions] instance for subtask operations.
final subtaskActionsProvider = Provider((ref) => SubtaskActions(ref));

/// Action class for subtask CRUD operations.
///
/// Implements local-first sync strategy: writes to local first,
/// then syncs to remote if user is authenticated.
class SubtaskActions {
  final Ref _ref;

  SubtaskActions(this._ref);

  Future<void> createSubtask(entity.Subtask subtask) async {
    final authState = _ref.read(currentUserProvider);

    await authState.when(
      data: (session) async {
        // Save to local first
        final localRepo = _ref.read(subtaskRepositoryProvider);
        await localRepo.createSubtask(subtask);

        // If user is authenticated, save to remote as well
        if (session != null) {
          final remoteRepo = _ref.read(remoteSubtaskRepositoryProvider);
          await remoteRepo.createSubtask(subtask);
        }

        // Refresh subtask list
        _ref.invalidate(subtaskListProvider(subtask.todoId));
        _ref.invalidate(subtaskStatsProvider(subtask.todoId));
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> updateSubtask(entity.Subtask subtask) async {
    final authState = _ref.read(currentUserProvider);

    await authState.when(
      data: (session) async {
        // Update local first
        final localRepo = _ref.read(subtaskRepositoryProvider);
        await localRepo.updateSubtask(subtask);

        // If user is authenticated, update remote as well
        if (session != null) {
          final remoteRepo = _ref.read(remoteSubtaskRepositoryProvider);
          await remoteRepo.updateSubtask(subtask);
        }

        // Refresh subtask list
        _ref.invalidate(subtaskListProvider(subtask.todoId));
        _ref.invalidate(subtaskStatsProvider(subtask.todoId));
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> deleteSubtask(int id, int todoId) async {
    final authState = _ref.read(currentUserProvider);

    await authState.when(
      data: (session) async {
        // Delete from local first
        final localRepo = _ref.read(subtaskRepositoryProvider);
        await localRepo.deleteSubtask(id);

        // If user is authenticated, delete from remote as well
        if (session != null) {
          final remoteRepo = _ref.read(remoteSubtaskRepositoryProvider);
          await remoteRepo.deleteSubtask(id);
        }

        // Refresh subtask list
        _ref.invalidate(subtaskListProvider(todoId));
        _ref.invalidate(subtaskStatsProvider(todoId));
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> toggleSubtaskCompletion(int id, int todoId) async {
    final authState = _ref.read(currentUserProvider);

    await authState.when(
      data: (session) async {
        // Toggle in local first
        final localRepo = _ref.read(subtaskRepositoryProvider);
        await localRepo.toggleSubtaskCompletion(id);

        // If user is authenticated, toggle in remote as well
        if (session != null) {
          final remoteRepo = _ref.read(remoteSubtaskRepositoryProvider);
          await remoteRepo.toggleSubtaskCompletion(id);
        }

        // Refresh subtask list
        _ref.invalidate(subtaskListProvider(todoId));
        _ref.invalidate(subtaskStatsProvider(todoId));
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> reorderSubtasks(int todoId, List<entity.Subtask> subtasks) async {
    final authState = _ref.read(currentUserProvider);

    await authState.when(
      data: (session) async {
        // Update positions for all subtasks
        for (var i = 0; i < subtasks.length; i++) {
          final updatedSubtask = entity.Subtask(
            id: subtasks[i].id,
            todoId: subtasks[i].todoId,
            userId: subtasks[i].userId,
            title: subtasks[i].title,
            isCompleted: subtasks[i].isCompleted,
            position: i,
            createdAt: subtasks[i].createdAt,
            completedAt: subtasks[i].completedAt,
          );

          // Update local
          final localRepo = _ref.read(subtaskRepositoryProvider);
          await localRepo.updateSubtask(updatedSubtask);

          // Update remote if authenticated
          if (session != null) {
            final remoteRepo = _ref.read(remoteSubtaskRepositoryProvider);
            await remoteRepo.updateSubtask(updatedSubtask);
          }
        }

        // Refresh subtask list
        _ref.invalidate(subtaskListProvider(todoId));
      },
      loading: () {},
      error: (_, __) {},
    );
  }
}
