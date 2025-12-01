/// Utilities for grouping and sorting todos by recurring series.
///
/// Provides helper functions to:
/// - Group todos by parent recurring series
/// - Sort todos by due date
/// - Prepare grouped todos for display
///
/// Example:
/// ```dart
/// final groupedTodos = groupTodosBySeries(allTodos);
/// // Returns: [[todo1], [todo2, todo3], [todo4]]
/// // Where [todo2, todo3] are from the same recurring series
/// ```
library;

import 'package:todo_app/domain/entities/todo.dart';

/// Group todos by recurring series for display.
///
/// Returns a list of lists where:
/// - Single non-recurring todos are wrapped in single-element lists
/// - Recurring todos from the same series are grouped together
/// - Each group is sorted by due date (null dates last)
/// - Final result is sorted by first item's due date
///
/// This enables UI to display recurring groups with a header and
/// expandable/collapsible behavior.
///
/// Parameters:
/// - [todos]: List of todos to group
///
/// Returns:
/// - List of lists, where each inner list is a display group
///
/// Example:
/// ```dart
/// final todos = [
///   Todo(id: 1, title: 'Single', parentRecurringTodoId: null),
///   Todo(id: 2, title: 'Series-A', parentRecurringTodoId: 10),
///   Todo(id: 3, title: 'Series-B', parentRecurringTodoId: 10),
/// ];
///
/// final grouped = groupTodosBySeries(todos);
/// // grouped[0] = [Todo(id: 1)]      // Single todo
/// // grouped[1] = [Todo(id: 2), Todo(id: 3)]  // Recurring series
/// ```
List<List<Todo>> groupTodosBySeries(List<Todo> todos) {
  print('🔍 groupTodosBySeries: Processing ${todos.length} todos');

  final Map<int, List<Todo>> groupedByParent = {};
  final List<Todo> nonRecurring = [];

  // First pass: separate recurring and non-recurring todos
  for (final todo in todos) {
    print('   Todo: ${todo.id} - ${todo.title}, parent: ${todo.parentRecurringTodoId}');
    if (todo.parentRecurringTodoId != null) {
      // This is a recurring instance
      final parentId = todo.parentRecurringTodoId!;
      if (!groupedByParent.containsKey(parentId)) {
        groupedByParent[parentId] = [];
      }
      groupedByParent[parentId]!.add(todo);
    } else {
      // Non-recurring todo
      nonRecurring.add(todo);
    }
  }

  print('   Grouped by parent: ${groupedByParent.length} groups');
  for (final entry in groupedByParent.entries) {
    print('      Parent ${entry.key}: ${entry.value.length} todos');
  }
  print('   Non-recurring: ${nonRecurring.length} todos');

  // Combine and sort: single todos + grouped recurring series
  final List<List<Todo>> result = [];

  // Add non-recurring todos as single-element lists
  for (final todo in nonRecurring) {
    result.add([todo]);
  }

  // Add grouped recurring series (sorted by due date within each group)
  for (final group in groupedByParent.values) {
    // Sort by due date within group
    group.sort((a, b) => _compareTodosByDueDate(a, b));
    result.add(group);
  }

  // Sort the result by the first todo's due date in each group
  result.sort((a, b) => _compareTodosByDueDate(a.first, b.first));

  return result;
}

/// Compare two todos by due date for sorting.
///
/// Returns:
/// - 0 if both are null or equal
/// - 1 if a is null (sorts to end)
/// - -1 if b is null (sorts to end)
/// - Result of comparing dates if both are non-null
///
/// This ensures todos with due dates sort before todos without.
int _compareTodosByDueDate(Todo a, Todo b) {
  if (a.dueDate == null && b.dueDate == null) return 0;
  if (a.dueDate == null) return 1;
  if (b.dueDate == null) return -1;
  return a.dueDate!.compareTo(b.dueDate!);
}

/// Flatten grouped todos back into a single list.
///
/// Used to convert display groups back to a flat list before
/// performing reordering operations.
///
/// Parameters:
/// - [groupedTodos]: List of lists from [groupTodosBySeries]
///
/// Returns:
/// - Single flat list of all todos in order
///
/// Example:
/// ```dart
/// final grouped = [[todo1], [todo2, todo3]];
/// final flat = flattenTodos(grouped);
/// // flat = [todo1, todo2, todo3]
/// ```
List<Todo> flattenTodos(List<List<Todo>> groupedTodos) {
  final List<Todo> allTodos = [];
  for (final group in groupedTodos) {
    allTodos.addAll(group);
  }
  return allTodos;
}
