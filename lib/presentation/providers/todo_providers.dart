import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Todo actions
class TodoActions {
  final Ref ref;
  TodoActions(this.ref);

  Future<void> createTodo(String title, String description) async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.createTodo(title, description);
    result.fold(
      (failure) => throw Exception(failure),
      (_) => ref.invalidate(todosProvider),
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
