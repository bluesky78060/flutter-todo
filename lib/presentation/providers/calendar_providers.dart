/// Calendar View Providers for managing calendar-specific state.
///
/// Provides:
/// - Selected date state
/// - Todos grouped by date
/// - Focused month for navigation
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

/// Notifier for selected date in the calendar
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

/// Provider for currently selected date in the calendar
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

/// Notifier for focused month in the calendar
class FocusedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

/// Provider for currently focused month for calendar navigation
final focusedMonthProvider = NotifierProvider<FocusedMonthNotifier, DateTime>(() {
  return FocusedMonthNotifier();
});

/// Normalize DateTime to date only (no time component)
DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Todos grouped by date for calendar markers
final todosByDateProvider = Provider<Map<DateTime, List<Todo>>>((ref) {
  final todosAsync = ref.watch(todosProvider);

  return todosAsync.when(
    data: (todos) {
      final Map<DateTime, List<Todo>> result = {};

      for (final todo in todos) {
        if (todo.dueDate != null) {
          final dateKey = _normalizeDate(todo.dueDate!);
          result.putIfAbsent(dateKey, () => []);
          result[dateKey]!.add(todo);
        }
      }

      // Sort todos within each date by time
      for (final dateKey in result.keys) {
        result[dateKey]!.sort((a, b) {
          // Todos without notification time come first (all-day)
          if (a.notificationTime == null && b.notificationTime != null) return -1;
          if (a.notificationTime != null && b.notificationTime == null) return 1;
          if (a.notificationTime == null && b.notificationTime == null) {
            return a.title.compareTo(b.title);
          }
          return a.notificationTime!.compareTo(b.notificationTime!);
        });
      }

      return result;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Todos for the currently selected date
final selectedDateTodosProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final todosByDate = ref.watch(todosByDateProvider);

  final dateKey = _normalizeDate(selectedDate);
  return todosByDate[dateKey] ?? [];
});

/// Check if a date has any todos
final hasEventsForDateProvider = Provider.family<bool, DateTime>((ref, date) {
  final todosByDate = ref.watch(todosByDateProvider);
  final dateKey = _normalizeDate(date);
  return todosByDate.containsKey(dateKey) && todosByDate[dateKey]!.isNotEmpty;
});

/// Get events count for a specific date
final eventsCountForDateProvider = Provider.family<int, DateTime>((ref, date) {
  final todosByDate = ref.watch(todosByDateProvider);
  final dateKey = _normalizeDate(date);
  return todosByDate[dateKey]?.length ?? 0;
});

/// Get first todo title for a date (for display in calendar cell)
final firstTodoTitleForDateProvider = Provider.family<String?, DateTime>((ref, date) {
  final todosByDate = ref.watch(todosByDateProvider);
  final dateKey = _normalizeDate(date);
  final todos = todosByDate[dateKey];
  if (todos != null && todos.isNotEmpty) {
    return todos.first.title;
  }
  return null;
});
