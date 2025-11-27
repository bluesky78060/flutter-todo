import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:todo_app/domain/entities/todo_entity.dart';

part 'widget_models.freezed.dart';
part 'widget_models.g.dart';

/// Widget view type enum
enum WidgetViewType {
  calendar,
  today,
}

/// Calendar data model for widget display
@freezed
class CalendarData with _$CalendarData {
  const factory CalendarData({
    required DateTime month,
    required Map<int, int> dayTaskCounts,
    required List<int> daysWithTasks,
    required List<int> completedDays,
    required DateTime lastUpdated,
  }) = _CalendarData;

  factory CalendarData.fromJson(Map<String, dynamic> json) =>
      _$CalendarDataFromJson(json);

  /// Generate calendar data from todos
  static CalendarData fromTodos(
    List<TodoEntity> todos,
    DateTime month,
  ) {
    final Map<int, int> dayTaskCounts = {};
    final Set<int> daysWithTasks = {};
    final Set<int> completedDays = {};

    for (final todo in todos) {
      final dueDate = todo.dueDate;
      if (dueDate != null) {
        final day = dueDate.day;
        dayTaskCounts[day] = (dayTaskCounts[day] ?? 0) + 1;
        daysWithTasks.add(day);

        if (todo.isCompleted) {
          completedDays.add(day);
        }
      }
    }

    return CalendarData(
      month: month,
      dayTaskCounts: dayTaskCounts,
      daysWithTasks: daysWithTasks.toList(),
      completedDays: completedDays.toList(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get task count for a specific day
  int getTaskCount(int day) => dayTaskCounts[day] ?? 0;

  /// Check if day has tasks
  bool hasTasksOnDay(int day) => daysWithTasks.contains(day);

  /// Check if day is fully completed
  bool isCompletedDay(int day) => completedDays.contains(day);
}

/// Today's todo list data model for widget display
@freezed
class TodoListData with _$TodoListData {
  const factory TodoListData({
    required DateTime date,
    required List<TodoEntity> todos,
    required int completedCount,
    required int pendingCount,
    required DateTime lastUpdated,
  }) = _TodoListData;

  factory TodoListData.fromJson(Map<String, dynamic> json) =>
      _$TodoListDataFromJson(json);

  /// Generate today's todo data from todos
  static TodoListData fromTodos(List<TodoEntity> todos) {
    final today = DateTime.now();
    final todaysTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return dueDate != null &&
          dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day;
    }).toList();

    final completedCount = todaysTodos.where((t) => t.isCompleted).length;
    final pendingCount = todaysTodos.where((t) => !t.isCompleted).length;

    // Sort: pending first, then completed
    todaysTodos.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        // Both completed or both pending
        if (a.reminderTime != null && b.reminderTime != null) {
          return a.reminderTime!.compareTo(b.reminderTime!);
        }
        return a.createdAt.compareTo(b.createdAt);
      }
      return a.isCompleted ? 1 : -1;
    });

    return TodoListData(
      date: today,
      todos: todaysTodos,
      completedCount: completedCount,
      pendingCount: pendingCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get display todos (max 5 for widget)
  List<TodoEntity> getDisplayTodos({int maxItems = 5}) {
    return todos.take(maxItems).toList();
  }

  /// Check if all tasks are completed
  bool get isAllCompleted => pendingCount == 0 && todos.isNotEmpty;

  /// Get progress percentage
  double get progressPercentage {
    if (todos.isEmpty) return 0.0;
    return completedCount / todos.length;
  }

  /// Get formatted date string
  String getFormattedDate() {
    return '${date.month}/${date.day}';
  }
}

/// Widget configuration model
@freezed
class WidgetConfig with _$WidgetConfig {
  const factory WidgetConfig({
    required WidgetViewType viewType,
    required bool isEnabled,
    required DateTime lastUpdated,
  }) = _WidgetConfig;

  const WidgetConfig._();

  factory WidgetConfig.fromJson(Map<String, dynamic> json) =>
      _$WidgetConfigFromJson(json);

  /// Default configuration
  static const WidgetConfig defaultConfig = WidgetConfig(
    viewType: WidgetViewType.today,
    isEnabled: true,
    lastUpdated: null,
  );
}
