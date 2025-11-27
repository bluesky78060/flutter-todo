import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/services/korean_holiday_service.dart';
import 'package:todo_app/core/widget/widget_models.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

/// Service to manage home screen widget updates and configuration
class WidgetService {
  final TodoRepository todoRepository;
  final SharedPreferences preferences;

  static const String _viewTypeKey = 'widget_view_type';
  static const String _enabledKey = 'widget_enabled';
  static const String _lastUpdateKey = 'widget_last_update';

  WidgetService({
    required this.todoRepository,
    required this.preferences,
  });

  /// Get current widget configuration
  WidgetConfig getWidgetConfig() {
    final viewTypeStr = preferences.getString(_viewTypeKey);
    final isEnabled = preferences.getBool(_enabledKey) ?? true;
    final lastUpdateStr = preferences.getString(_lastUpdateKey);

    final viewType = viewTypeStr != null
        ? WidgetViewType.values.byName(viewTypeStr)
        : WidgetViewType.today;

    final lastUpdated = lastUpdateStr != null
        ? DateTime.parse(lastUpdateStr)
        : DateTime.now();

    return WidgetConfig(
      viewType: viewType,
      isEnabled: isEnabled,
      lastUpdated: lastUpdated,
    );
  }

  /// Set widget view type preference
  Future<void> setWidgetViewType(WidgetViewType viewType) async {
    await preferences.setString(_viewTypeKey, viewType.name);
    await _updateLastModified();
  }

  /// Set widget enabled state
  Future<void> setWidgetEnabled(bool enabled) async {
    await preferences.setBool(_enabledKey, enabled);
    await _updateLastModified();
  }

  /// Update last modification timestamp
  Future<void> _updateLastModified() async {
    await preferences.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Get calendar data for the current month
  Future<CalendarData> getCalendarData() async {
    try {
      final result = await todoRepository.getTodos();
      final todos = result.fold(
        (failure) => <Todo>[],
        (todos) => todos,
      );
      return CalendarData.fromTodos(todos, DateTime.now());
    } catch (e) {
      // Return empty calendar data on error
      return CalendarData(
        month: DateTime.now(),
        dayTaskCounts: {},
        daysWithTasks: [],
        completedDays: [],
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get today's todo data
  Future<TodoListData> getTodaysTodos() async {
    try {
      final result = await todoRepository.getTodos();
      final todos = result.fold(
        (failure) => <Todo>[],
        (todos) => todos,
      );
      return TodoListData.fromTodos(todos);
    } catch (e) {
      // Return empty todo list data on error
      return TodoListData(
        date: DateTime.now(),
        todos: [],
        completedCount: 0,
        pendingCount: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Update widget display based on current configuration
  Future<void> updateWidget() async {
    print('📱 WidgetService.updateWidget() called');
    try {
      final config = getWidgetConfig();
      print('   Config: viewType=${config.viewType}, isEnabled=${config.isEnabled}');

      if (!config.isEnabled) {
        // Clear widget if disabled
        print('   Widget disabled, clearing data');
        await HomeWidget.setAppGroupId('group.dodo.widget');
        await HomeWidget.saveWidgetData<String>('view_type', 'none');
        return;
      }

      // Update both widgets (user may have both on home screen)
      print('   Updating todo list widget');
      await _updateTodoListWidget();

      print('   Updating calendar widget');
      await _updateCalendarWidget();

      // Save last update time
      await _updateLastModified();
      print('   Widget update completed');
    } catch (e) {
      print('❌ Error updating widget: $e');
    }
  }

  /// Update calendar widget display
  Future<void> _updateCalendarWidget() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');

      final calendarData = await getCalendarData();
      print('📅 WidgetService: Updating calendar widget');
      print('   Days with tasks: ${calendarData.daysWithTasks}');

      await HomeWidget.saveWidgetData<String>('view_type', 'calendar');

      // Calculate calendar grid (Sunday first layout)
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;

      // Get the weekday of the first day (DateTime.weekday: 1=Mon, 7=Sun)
      // Convert to Sunday-first (0=Sun, 1=Mon, ..., 6=Sat)
      final firstWeekday = firstDayOfMonth.weekday % 7; // 0=Sun, 1=Mon, ..., 6=Sat

      print('   First day of month: ${firstDayOfMonth.weekday} -> $firstWeekday (Sun=0)');
      print('   Days in month: $daysInMonth');

      // Fetch Korean holidays for this month
      Set<int> holidays = {};
      try {
        holidays = await KoreanHolidayService.getHolidaysForMonth(now.year, now.month);
        print('   Holidays this month: $holidays');
      } catch (e) {
        print('   Failed to fetch holidays: $e');
      }

      // Save holidays data as comma-separated string for Kotlin widget
      final holidaysStr = holidays.join(',');
      await HomeWidget.saveWidgetData<String>('calendar_holidays', holidaysStr);
      print('   Saved holidays string: $holidaysStr');

      // Clear all 42 cells first (6 rows x 7 columns)
      for (int i = 1; i <= 42; i++) {
        await HomeWidget.saveWidgetData<String>('calendar_day_$i', '');
      }

      // Fill in the days at correct positions
      for (int day = 1; day <= daysInMonth; day++) {
        // Position in grid (1-indexed): firstWeekday + day
        final gridPosition = firstWeekday + day;

        final taskCount = calendarData.getTaskCount(day);
        final isHoliday = holidays.contains(day);
        String dayText;
        if (taskCount > 0) {
          // Show dot indicator for days with tasks
          dayText = '$day●';
        } else {
          dayText = '$day';
        }
        // Add holiday marker (★) for Kotlin to detect and color red
        if (isHoliday) {
          dayText = '$dayText★';
        }
        await HomeWidget.saveWidgetData<String>('calendar_day_$gridPosition', dayText);
      }

      // Notify native widget - use full qualified class name for Android
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoCalendarWidget',
        iOSName: 'TodoCalendarWidget',
      );
      print('✅ WidgetService: Calendar widget update triggered');
    } catch (e) {
      print('❌ Error updating calendar widget: $e');
    }
  }

  /// Update today's todo list widget display
  Future<void> _updateTodoListWidget() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');

      final todoData = await getTodaysTodos();
      print('📱 WidgetService: Updating todo list widget');
      print('   Total pending todos: ${todoData.todos.length}');

      // Save view type
      await HomeWidget.saveWidgetData<String>('view_type', 'todo_list');

      // Get top 5 pending todos to display (already filtered and sorted by TodoListData)
      final displayTodos = todoData.todos.take(5).toList();

      print('   Todos to display: ${displayTodos.length}');

      // Save todo items with keys that Kotlin widget expects
      for (int i = 0; i < 5; i++) {
        if (i < displayTodos.length) {
          final todo = displayTodos[i];
          print('   Saving todo ${i + 1}: ${todo.title}');
          await HomeWidget.saveWidgetData<String>(
            'todo_${i + 1}_text',
            todo.title,
          );
          // Format time if available
          String timeStr = '';
          if (todo.notificationTime != null) {
            final time = todo.notificationTime!;
            timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          } else if (todo.dueDate != null) {
            final date = todo.dueDate!;
            timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          }
          await HomeWidget.saveWidgetData<String>(
            'todo_${i + 1}_time',
            timeStr,
          );
        } else {
          // Clear unused slots
          await HomeWidget.saveWidgetData<String?>('todo_${i + 1}_text', null);
          await HomeWidget.saveWidgetData<String>('todo_${i + 1}_time', '');
        }
      }

      // Notify native widget - use full qualified class name for Android
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoListWidget',
        iOSName: 'TodoListWidget',
      );
      print('✅ WidgetService: Widget update triggered');
    } catch (e) {
      print('❌ Error updating todo list widget: $e');
    }
  }

  /// Refresh widget data (for background updates)
  Future<void> refreshWidget() async {
    await updateWidget();
  }

  /// Get next available update time
  DateTime getNextUpdateTime({Duration interval = const Duration(minutes: 30)}) {
    final config = getWidgetConfig();
    final lastUpdate = config.lastUpdated ?? DateTime.now();
    return lastUpdate.add(interval);
  }

  /// Check if widget should be updated (based on time interval)
  bool shouldUpdateWidget({Duration interval = const Duration(minutes: 15)}) {
    final config = getWidgetConfig();
    final lastUpdate = config.lastUpdated ?? DateTime.now();
    final now = DateTime.now();
    return now.difference(lastUpdate) >= interval;
  }

  /// Disable all widgets
  Future<void> disableAllWidgets() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');
      await HomeWidget.saveWidgetData<String>('view_type', 'none');
      await setWidgetEnabled(false);
    } catch (e) {
      print('Error disabling widgets: $e');
    }
  }

  /// Clear widget data on logout
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');
      await HomeWidget.saveWidgetData<String>('view_type', 'none');
      await HomeWidget.saveWidgetData<String>('calendar_data', '');
      await HomeWidget.saveWidgetData<String>('todo_data', '');
    } catch (e) {
      print('Error clearing widget data: $e');
    }
  }

  /// Reset widget configuration to defaults
  Future<void> resetConfiguration() async {
    await preferences.remove(_viewTypeKey);
    await preferences.remove(_enabledKey);
    await preferences.remove(_lastUpdateKey);
    await clearWidgetData();
  }
}
