import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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

  // MethodChannel for native widget updates
  static const MethodChannel _widgetChannel = MethodChannel('kr.bluesky.dodo/widget');

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

  /// Update widget display based on current configuration (optimized)
  Future<void> updateWidget() async {
    print('📱 WidgetService.updateWidget() called (optimized)');
    final stopwatch = Stopwatch()..start();
    try {
      final config = getWidgetConfig();
      print('   Config: viewType=${config.viewType}, isEnabled=${config.isEnabled}');

      if (!config.isEnabled) {
        print('   Widget disabled, clearing data');
        await HomeWidget.setAppGroupId('group.dodo.widget');
        await HomeWidget.saveWidgetData<String>('view_type', 'none');
        return;
      }

      // Fetch todos ONCE and share between both widgets
      final result = await todoRepository.getTodos();
      final todos = result.fold(
        (failure) => <Todo>[],
        (todos) => todos,
      );
      print('   Fetched ${todos.length} todos in ${stopwatch.elapsedMilliseconds}ms');

      // Update widgets SEQUENTIALLY to avoid SharedPreferences conflicts
      // (parallel execution causes data race on same keys)
      await _updateTodoListWidgetWithData(todos);
      await _updateCalendarWidgetWithData(todos);

      // Save last update time
      await _updateLastModified();

      // Delay to ensure SharedPreferences are flushed to disk
      // home_widget uses apply() which is async, so we need to wait for disk write
      // 300ms is more reliable than 100ms based on testing
      await Future.delayed(const Duration(milliseconds: 300));

      // Force native widget update for immediate sync (Android only)
      await _forceNativeWidgetUpdate();

      // Double-update mechanism: trigger a second update after a brief delay
      // This catches any race conditions where the first read gets stale data
      Future.delayed(const Duration(milliseconds: 500), () {
        _forceNativeWidgetUpdate();
      });

      stopwatch.stop();
      print('   Widget update completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('❌ Error updating widget: $e');
    }
  }

  /// Force native widget update via MethodChannel
  /// This triggers ACTION_APPWIDGET_UPDATE for immediate refresh
  Future<void> _forceNativeWidgetUpdate() async {
    if (kIsWeb) return; // Skip on web

    try {
      await _widgetChannel.invokeMethod('forceUpdateWidgets');
      print('   Native widget force update triggered');
    } catch (e) {
      // Silently ignore if channel not available (e.g., app in background)
      print('   Native force update skipped: $e');
    }
  }

  /// Update calendar widget with pre-fetched data (optimized)
  Future<void> _updateCalendarWidgetWithData(List<Todo> todos) async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');

      final now = DateTime.now();
      final calendarData = CalendarData.fromTodos(todos, now);

      // Debug: Log todos that have due dates in current month
      final thisMonthTodos = todos.where((t) =>
        t.dueDate != null &&
        t.dueDate!.year == now.year &&
        t.dueDate!.month == now.month
      ).toList();
      print('📅 WidgetService: Updating calendar widget (with shared data)');
      print('   Total todos: ${todos.length}, This month todos: ${thisMonthTodos.length}');
      for (final todo in thisMonthTodos) {
        print('   - Day ${todo.dueDate!.day}: "${todo.title}" (completed: ${todo.isCompleted})');
      }

      // Calculate calendar grid (Sunday first layout)
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;
      final firstWeekday = firstDayOfMonth.weekday % 7;

      // Fetch holidays in parallel with preparing calendar data
      Set<int> holidays = {};
      try {
        holidays = await KoreanHolidayService.getHolidaysForMonth(now.year, now.month);
      } catch (e) {
        print('   Failed to fetch holidays: $e');
      }

      // Prepare all calendar day data
      final Map<int, String> calendarDays = {};
      for (int day = 1; day <= daysInMonth; day++) {
        final gridPosition = firstWeekday + day;
        final taskCount = calendarData.getTaskCount(day);
        final isHoliday = holidays.contains(day);
        String dayText = taskCount > 0 ? '$day●' : '$day';
        if (isHoliday) {
          dayText = '$dayText★';
        }
        calendarDays[gridPosition] = dayText;
      }

      // Batch save all widget data in parallel
      final List<Future<void>> saveFutures = [
        HomeWidget.saveWidgetData<String>('view_type', 'calendar'),
        HomeWidget.saveWidgetData<String>('calendar_holidays', holidays.join(',')),
      ];

      for (int i = 1; i <= 42; i++) {
        saveFutures.add(HomeWidget.saveWidgetData<String>('calendar_day_$i', calendarDays[i] ?? ''));
      }

      // Also save upcoming events in the same batch
      _addUpcomingEventsFutures(saveFutures, todos);

      // Execute ALL saves in parallel (calendar + events)
      await Future.wait(saveFutures);

      // Notify native widget
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoCalendarWidget',
        iOSName: 'TodoCalendarWidget',
      );
      print('✅ Calendar widget updated');
    } catch (e) {
      print('❌ Error updating calendar widget: $e');
    }
  }

  /// Add upcoming events save futures to the batch (no await, just adds futures)
  void _addUpcomingEventsFutures(List<Future<void>> futures, List<Todo> todos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingTodos = todos.where((todo) {
      if (todo.dueDate == null || todo.isCompleted) return false;
      final dueDateOnly = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return dueDateOnly.isAfter(today.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));

    // Save all 5 event slots
    for (int i = 1; i <= 5; i++) {
      if (i <= upcomingTodos.length) {
        final todo = upcomingTodos[i - 1];
        final dueDate = todo.dueDate!;
        String timeStr = '';
        if (todo.notificationTime != null) {
          final time = todo.notificationTime!;
          timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        } else if (dueDate.hour != 0 || dueDate.minute != 0) {
          timeStr = '${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
        }
        futures.add(HomeWidget.saveWidgetData<String>('upcoming_event_$i', '${dueDate.month}|${dueDate.day}|$timeStr|${todo.title}'));
      } else {
        futures.add(HomeWidget.saveWidgetData<String?>('upcoming_event_$i', null));
      }
    }
    futures.add(HomeWidget.saveWidgetData<int>('upcoming_event_count', upcomingTodos.length));
  }

  /// Update todo list widget with pre-fetched data (optimized)
  Future<void> _updateTodoListWidgetWithData(List<Todo> todos) async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');

      final todoData = TodoListData.fromTodos(todos);
      print('📱 WidgetService: Updating todo list widget (with shared data)');
      print('   Today\'s todos count: ${todoData.todos.length}');

      // Calculate progress (completed / total for today)
      final todayTodos = _getTodayTodos(todos);
      final completedCount = todayTodos.where((t) => t.isCompleted).length;
      final totalCount = todayTodos.length;

      // Sort and categorize todos by date group
      final sortedTodos = _sortTodosByDateGroup(todos.where((t) => !t.isCompleted).toList());

      // Get top 3 todos to display
      final displayTodos = sortedTodos.take(3).toList();

      // Prepare all widget data in parallel
      final List<Future<void>> todoFutures = [
        HomeWidget.saveWidgetData<String>('view_type', 'todo_list'),
        HomeWidget.saveWidgetData<int>('todo_completed_count', completedCount),
        HomeWidget.saveWidgetData<int>('todo_total_count', totalCount),
      ];

      // Save todo items (3 items max) with date group info
      for (int i = 0; i < 3; i++) {
        if (i < displayTodos.length) {
          final todo = displayTodos[i];
          String timeStr = '';
          if (todo.notificationTime != null) {
            final time = todo.notificationTime!;
            timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          } else if (todo.dueDate != null) {
            final date = todo.dueDate!;
            final now = DateTime.now();
            if (date.year != now.year || date.month != now.month || date.day != now.day) {
              timeStr = '${date.month}/${date.day}';
            } else if (date.hour != 0 || date.minute != 0) {
              timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            }
          }

          // Get date group for this todo
          final dateGroup = _getDateGroup(todo.dueDate);

          todoFutures.addAll([
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_text', todo.title),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_id', todo.id.toString()),
            HomeWidget.saveWidgetData<bool>('todo_${i + 1}_completed', todo.isCompleted),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_time', timeStr),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_group', dateGroup),
          ]);
        } else {
          todoFutures.addAll([
            HomeWidget.saveWidgetData<String?>('todo_${i + 1}_text', null),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_time', ''),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_id', ''),
            HomeWidget.saveWidgetData<bool>('todo_${i + 1}_completed', false),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_group', ''),
          ]);
        }
      }

      // Execute all saves in parallel
      await Future.wait(todoFutures);

      // Notify native widget
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoListWidget',
        iOSName: 'TodoListWidget',
      );
      print('✅ Todo list widget updated');
    } catch (e) {
      print('❌ Error updating todo list widget: $e');
    }
  }

  /// Get todos for today only
  List<Todo> _getTodayTodos(List<Todo> todos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return todos.where((todo) {
      if (todo.dueDate == null) return false;
      final dueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return dueDate.isAtSameMomentAs(today) || (dueDate.isAfter(today) && dueDate.isBefore(tomorrow));
    }).toList();
  }

  /// Sort todos by date group (overdue first, then today, tomorrow, etc.)
  List<Todo> _sortTodosByDateGroup(List<Todo> todos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Separate todos by group
    final overdue = <Todo>[];
    final todayTodos = <Todo>[];
    final tomorrowTodos = <Todo>[];
    final thisWeekTodos = <Todo>[];
    final nextWeekTodos = <Todo>[];
    final laterTodos = <Todo>[];
    final noDueDateTodos = <Todo>[];

    for (final todo in todos) {
      if (todo.dueDate == null) {
        noDueDateTodos.add(todo);
        continue;
      }

      final dueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      final tomorrow = today.add(const Duration(days: 1));
      final endOfWeek = today.add(Duration(days: 7 - today.weekday));
      final endOfNextWeek = endOfWeek.add(const Duration(days: 7));

      if (dueDate.isBefore(today)) {
        overdue.add(todo);
      } else if (dueDate.isAtSameMomentAs(today)) {
        todayTodos.add(todo);
      } else if (dueDate.isAtSameMomentAs(tomorrow)) {
        tomorrowTodos.add(todo);
      } else if (dueDate.isBefore(endOfWeek) || dueDate.isAtSameMomentAs(endOfWeek)) {
        thisWeekTodos.add(todo);
      } else if (dueDate.isBefore(endOfNextWeek) || dueDate.isAtSameMomentAs(endOfNextWeek)) {
        nextWeekTodos.add(todo);
      } else {
        laterTodos.add(todo);
      }
    }

    // Sort each group by due date
    overdue.sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));
    todayTodos.sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));
    tomorrowTodos.sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));
    thisWeekTodos.sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));
    nextWeekTodos.sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));
    laterTodos.sort((a, b) => (a.dueDate ?? now).compareTo(b.dueDate ?? now));

    // Combine in order
    return [
      ...overdue,
      ...todayTodos,
      ...tomorrowTodos,
      ...thisWeekTodos,
      ...nextWeekTodos,
      ...laterTodos,
      ...noDueDateTodos,
    ];
  }

  /// Get date group string for a todo
  String _getDateGroup(DateTime? dueDate) {
    if (dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));
    final endOfNextWeek = endOfWeek.add(const Duration(days: 7));

    if (dueDateOnly.isBefore(today)) {
      return 'overdue';
    } else if (dueDateOnly.isAtSameMomentAs(today)) {
      return 'today';
    } else if (dueDateOnly.isAtSameMomentAs(tomorrow)) {
      return 'tomorrow';
    } else if (dueDateOnly.isBefore(endOfWeek) || dueDateOnly.isAtSameMomentAs(endOfWeek)) {
      return 'this_week';
    } else if (dueDateOnly.isBefore(endOfNextWeek) || dueDateOnly.isAtSameMomentAs(endOfNextWeek)) {
      return 'next_week';
    } else {
      return 'later';
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
