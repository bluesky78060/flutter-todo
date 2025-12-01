/// Utilities for reordering todos in drag-and-drop operations.
///
/// Provides helper functions to:
/// - Calculate actual positions in flattened todo lists
/// - Reorder grouped todos while maintaining group integrity
/// - Update position metadata for repository storage
///
/// Example:
/// ```dart
/// final reordered = reorderTodos(
///   groupedTodos: grouped,
///   oldIndex: 0,
///   newIndex: 2,
/// );
/// // Returns todos with updated position values
/// ```
library;

import 'package:todo_app/domain/entities/todo.dart';

/// Result of a reorder operation containing updated todos.
class ReorderResult {
  /// All todos in their new order with updated position values
  final List<Todo> reorderedTodos;

  /// Total number of todos that were reordered
  final int totalCount;

  const ReorderResult({
    required this.reorderedTodos,
    required this.totalCount,
  });
}

/// Reorder grouped todos when a group is moved via drag-and-drop.
///
/// This function handles the complex logic of:
/// 1. Converting group indices to positions in a flattened list
/// 2. Removing the moved group from its old position
/// 3. Inserting the moved group at its new position
/// 4. Updating position metadata for all todos
///
/// The operation maintains group integrity - all todos in a group
/// move together as a unit.
///
/// Parameters:
/// - [groupedTodos]: List of todo groups from [groupTodosBySeries]
/// - [oldIndex]: The group index being moved from
/// - [newIndex]: The group index being moved to
///
/// Returns:
/// - [ReorderResult] containing reordered todos with updated positions
///
/// Example:
/// ```dart
/// // Grouped: [[A], [B, C], [D]]
/// // Move group at index 1 (B, C) to index 0
/// final result = reorderTodos(
///   groupedTodos: grouped,
///   oldIndex: 1,
///   newIndex: 0,
/// );
/// // Result: [B, C, A, D] with position 0, 1, 2, 3
/// ```
ReorderResult reorderTodos({
  required List<List<Todo>> groupedTodos,
  required int oldIndex,
  required int newIndex,
}) {
  print('🔄 reorderTodos: oldIndex=$oldIndex, newIndex=$newIndex');
  print('📊 Number of groups: ${groupedTodos.length}');

  // Adjust newIndex for Flutter's drag-and-drop behavior
  // (dragging down requires decrementing the target index)
  int adjustedNewIndex = newIndex;
  if (oldIndex < newIndex) {
    adjustedNewIndex -= 1;
    print('📌 Adjusted newIndex to: $adjustedNewIndex');
  }

  // Flatten the grouped todos to work with actual positions
  final List<Todo> allTodos = [];
  for (final group in groupedTodos) {
    allTodos.addAll(group);
  }
  print('📋 Total todos after flattening: ${allTodos.length}');
  print(
    '📝 Todos before reorder: '
    '${allTodos.map((t) => '${t.title}(pos:${t.position})').join(', ')}',
  );

  // Create a mutable copy to modify
  final mutableTodos = List<Todo>.from(allTodos);

  // Get the group that's being moved
  final movedGroup = groupedTodos[oldIndex];
  print(
    '📦 Moving group with ${movedGroup.length} todos: '
    '${movedGroup.map((t) => t.title).join(', ')}',
  );

  // Calculate the actual position in the flattened list for old index
  int actualOldIndex = 0;
  for (int i = 0; i < oldIndex; i++) {
    actualOldIndex += groupedTodos[i].length;
  }

  // Calculate the actual position in the flattened list for new index
  int actualNewIndex = 0;
  for (int i = 0; i < adjustedNewIndex; i++) {
    actualNewIndex += groupedTodos[i].length;
  }
  print('🎯 Actual positions: oldIndex=$actualOldIndex → newIndex=$actualNewIndex');

  // Remove all todos in the moved group from their old position
  for (int i = movedGroup.length - 1; i >= 0; i--) {
    mutableTodos.removeAt(actualOldIndex);
  }

  // Insert them at the new position (together as a group)
  for (int i = 0; i < movedGroup.length; i++) {
    mutableTodos.insert(actualNewIndex + i, movedGroup[i]);
  }

  // Update position metadata for all todos to match their new order
  final updatedTodos = <Todo>[];
  for (int i = 0; i < mutableTodos.length; i++) {
    updatedTodos.add(mutableTodos[i].copyWith(position: i));
  }
  print(
    '📝 Todos after reorder: '
    '${updatedTodos.map((t) => '${t.title}(pos:${t.position})').join(', ')}',
  );

  return ReorderResult(
    reorderedTodos: updatedTodos,
    totalCount: updatedTodos.length,
  );
}

/// Calculate the flattened position of a group in grouped todos.
///
/// Used internally by [reorderTodos] to convert group indices
/// to positions in a flattened list.
///
/// Parameters:
/// - [groupedTodos]: List of todo groups
/// - [groupIndex]: The group index to get the position for
///
/// Returns:
/// - Index in a flattened list where this group starts
int calculateGroupStartPosition(
  List<List<Todo>> groupedTodos,
  int groupIndex,
) {
  int position = 0;
  for (int i = 0; i < groupIndex && i < groupedTodos.length; i++) {
    position += groupedTodos[i].length;
  }
  return position;
}
