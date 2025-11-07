import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';

// Todo filter state
enum TodoFilter { all, pending, completed }

class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  void setFilter(TodoFilter filter) {
    state = filter;
  }
}

final todoFilterProvider =
    NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

// Category filter state
class CategoryFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null; // null means no category filter

  void setCategory(int? categoryId) {
    state = categoryId;
  }

  void clearCategory() {
    state = null;
  }
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, int?>(CategoryFilterNotifier.new);

// Todos List Provider
final todosProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  final filter = ref.watch(todoFilterProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);

  final filterString = switch (filter) {
    TodoFilter.all => 'all',
    TodoFilter.pending => 'pending',
    TodoFilter.completed => 'completed',
  };

  final result = await repository.getFilteredTodos(filterString);
  return result.fold(
    (failure) => throw Exception(failure),
    (todos) {
      // Apply category filter if selected
      if (categoryFilter != null) {
        return todos.where((todo) => todo.categoryId == categoryFilter).toList();
      }
      return todos;
    },
  );
});

// Todo Detail Provider
final todoDetailProvider =
    FutureProvider.family<Todo, int>((ref, id) async {
  final repository = ref.watch(todoRepositoryProvider);
  final result = await repository.getTodoById(id);
  return result.fold(
    (failure) => throw Exception(failure),
    (todo) => todo,
  );
});

// Notification Service Provider
final notificationServiceProvider = Provider((ref) => NotificationService());

// Todo actions
class TodoActions {
  final Ref ref;
  TodoActions(this.ref);

  Future<void> createTodo(
    String title,
    String description,
    DateTime? dueDate, {
    int? categoryId,
    DateTime? notificationTime,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.createTodo(
      title,
      description,
      dueDate,
      categoryId: categoryId,
      notificationTime: notificationTime,
    );

    await result.fold(
      (failure) => throw Exception(failure),
      (todoId) async {
        logger.d('✅ TodoActions: Todo created with ID: $todoId');
        logger.d('   Title: $title');
        logger.d('   Due Date: $dueDate');
        logger.d('   Notification Time: $notificationTime');

        // Schedule notification if notificationTime is set
        if (notificationTime != null) {
          try {
            final notificationService = ref.read(notificationServiceProvider);
            final now = DateTime.now();
            final difference = notificationTime.difference(now);

            logger.d('📅 TodoActions: Scheduling notification for todo $todoId');
            logger.d('   Title: $title');
            logger.d('   Notification Time: $notificationTime');
            logger.d('   Current Time: $now');
            logger.d('   Time until notification: ${difference.inMinutes} minutes');

            await notificationService.scheduleNotification(
              id: todoId,
              title: '할일 알림',
              body: title,
              scheduledDate: notificationTime,
            );

            // Verify scheduling
            final pending = await notificationService.getPendingNotifications();
            final thisNotification = pending.where((n) => n.id == todoId).firstOrNull;

            if (thisNotification != null) {
              logger.d('✅ TodoActions: Notification verified in pending list');
              logger.d('   Pending notifications count: ${pending.length}');
            } else {
              logger.d('⚠️ TodoActions: Notification not found in pending list!');
            }
          } catch (e, stackTrace) {
            logger.d('❌ TodoActions: Failed to schedule notification: $e');
            logger.d('   Stack trace: $stackTrace');
            // Don't throw - allow todo creation to succeed even if notification fails
          }
        } else {
          logger.d('ℹ️ TodoActions: No notification time set');
        }
        ref.invalidate(todosProvider);
      },
    );
  }

  Future<void> updateTodo(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.updateTodo(todo);
    result.fold(
      (failure) => throw Exception(failure),
      (_) {
        ref.invalidate(todosProvider);
        ref.invalidate(todoDetailProvider(todo.id));
      },
    );
  }

  Future<void> deleteTodo(int id) async {
    final repository = ref.read(todoRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    // Cancel notification before deleting todo
    await notificationService.cancelNotification(id);

    final result = await repository.deleteTodo(id);
    result.fold(
      (failure) => throw Exception(failure),
      (_) => ref.invalidate(todosProvider),
    );
  }

  Future<void> toggleCompletion(int id) async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.toggleCompletion(id);
    result.fold(
      (failure) => throw Exception(failure),
      (_) {
        ref.invalidate(todosProvider);
        ref.invalidate(todoDetailProvider(id));
      },
    );
  }
}

final todoActionsProvider = Provider((ref) => TodoActions(ref));
