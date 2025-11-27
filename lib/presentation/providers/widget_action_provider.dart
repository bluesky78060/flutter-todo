import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Provider for handling widget actions (toggle/delete from home screen widget)
class WidgetActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Toggle todo completion status from widget
  Future<void> toggleTodoFromWidget(String todoId) async {
    try {
      state = const AsyncValue.loading();

      final repository = ref.read(todoRepositoryProvider);
      final todoIdInt = int.tryParse(todoId);

      if (todoIdInt == null) {
        logger.e('Invalid todo ID from widget: $todoId');
        state = AsyncValue.error(
          'Invalid todo ID',
          StackTrace.current,
        );
        return;
      }

      // Toggle completion
      final result = await repository.toggleCompletion(todoIdInt);

      result.fold(
        (failure) {
          logger.e('Failed to toggle todo from widget: $failure');
          state = AsyncValue.error(failure, StackTrace.current);
        },
        (_) {
          logger.d('Successfully toggled todo from widget: $todoId');
          // Invalidate todos provider to refresh the list
          ref.invalidate(todosProvider);
          state = const AsyncValue.data(null);
        },
      );
    } catch (e, st) {
      logger.e('Error toggling todo from widget: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete todo from widget
  Future<void> deleteTodoFromWidget(String todoId) async {
    try {
      state = const AsyncValue.loading();

      final repository = ref.read(todoRepositoryProvider);
      final todoIdInt = int.tryParse(todoId);

      if (todoIdInt == null) {
        logger.e('Invalid todo ID from widget: $todoId');
        state = AsyncValue.error(
          'Invalid todo ID',
          StackTrace.current,
        );
        return;
      }

      // Delete todo
      final result = await repository.deleteTodo(todoIdInt);

      result.fold(
        (failure) {
          logger.e('Failed to delete todo from widget: $failure');
          state = AsyncValue.error(failure, StackTrace.current);
        },
        (_) {
          logger.d('Successfully deleted todo from widget: $todoId');
          // Invalidate todos provider to refresh the list
          ref.invalidate(todosProvider);
          state = const AsyncValue.data(null);
        },
      );
    } catch (e, st) {
      logger.e('Error deleting todo from widget: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for widget actions
final widgetActionProvider = NotifierProvider<WidgetActionNotifier, AsyncValue<void>>(
  WidgetActionNotifier.new,
);
