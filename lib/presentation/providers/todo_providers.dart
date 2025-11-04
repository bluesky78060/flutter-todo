import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

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

// Todos List Provider
final todosProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  final filter = ref.watch(todoFilterProvider);

  final filterString = switch (filter) {
    TodoFilter.all => 'all',
    TodoFilter.pending => 'pending',
    TodoFilter.completed => 'completed',
  };

  final result = await repository.getFilteredTodos(filterString);
  return result.fold(
    (failure) => throw Exception(failure),
    (todos) => todos,
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
    DateTime? notificationTime,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.createTodo(
      title,
      description,
      dueDate,
      notificationTime: notificationTime,
    );

    await result.fold(
      (failure) => throw Exception(failure),
      (todoId) async {
        // Schedule notification if notificationTime is set
        if (notificationTime != null) {
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.scheduleNotification(
            id: todoId,
            title: '할일 알림',
            body: title,
            scheduledDate: notificationTime,
          );
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
