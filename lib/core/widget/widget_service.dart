import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/services/korean_holiday_service.dart';
import 'package:todo_app/core/utils/app_logger.dart';
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

  // Widget appearance keys (for iOS native widget)
  static const String _cardOpacityDarkKey = 'widget_card_opacity_dark';
  static const String _cardOpacityLightKey = 'widget_card_opacity_light';

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

  // ===============================================
  // Widget Appearance Settings (Card Opacity)
  // ===============================================

  /// Get card opacity for dark mode (0.0 ~ 1.0)
  /// Default: 0.15
  double getCardOpacityDark() {
    return preferences.getDouble(_cardOpacityDarkKey) ?? 0.15;
  }

  /// Get card opacity for light mode (0.0 ~ 1.0)
  /// Default: 0.7
  double getCardOpacityLight() {
    return preferences.getDouble(_cardOpacityLightKey) ?? 0.7;
  }

  /// Set card opacity for dark mode
  Future<void> setCardOpacityDark(double opacity) async {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    await preferences.setDouble(_cardOpacityDarkKey, clampedOpacity);

    // Save to App Group for iOS native widget
    await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');
    await HomeWidget.saveWidgetData<double>(_cardOpacityDarkKey, clampedOpacity);
    logger.d('📱 [WidgetService] Saved cardOpacityDark: $clampedOpacity');
  }

  /// Set card opacity for light mode
  Future<void> setCardOpacityLight(double opacity) async {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    await preferences.setDouble(_cardOpacityLightKey, clampedOpacity);

    // Save to App Group for iOS native widget
    await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');
    await HomeWidget.saveWidgetData<double>(_cardOpacityLightKey, clampedOpacity);
    logger.d('📱 [WidgetService] Saved cardOpacityLight: $clampedOpacity');
  }

  /// Set both card opacities at once
  Future<void> setCardOpacity({
    required double darkMode,
    required double lightMode,
  }) async {
    await setCardOpacityDark(darkMode);
    await setCardOpacityLight(lightMode);

    // Update all widget types to apply new opacity
    await _updateAllWidgetsForOpacity();
  }

  /// Update all widgets after opacity change
  Future<void> _updateAllWidgetsForOpacity() async {
    try {
      await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');

      // Update all three widget types
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoListWidget',
        iOSName: 'TodoListWidget',
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoDetailWidget',
        iOSName: 'TodoDetailWidget',
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoCalendarWidget',
        iOSName: 'TodoCalendarWidget',
      );

      logger.d('📱 [WidgetService] All widgets updated for opacity change');

      // Also trigger native update
      await _forceNativeWidgetUpdate();
    } catch (e) {
      logger.e('❌ [WidgetService] Error updating widgets for opacity: $e');
    }
  }

  /// Update last modification timestamp
  Future<void> _updateLastModified() async {
    await preferences.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  // Cached todos to avoid redundant DB queries within same update cycle
  List<Todo>? _cachedTodos;
  DateTime? _cacheTimestamp;
  static const _cacheValidityMs = 1000; // Cache valid for 1 second

  // Cached holidays to avoid redundant API calls (holidays don't change frequently)
  Set<int>? _cachedHolidays;
  int? _cachedHolidayYear;
  int? _cachedHolidayMonth;

  /// Get todos with caching to avoid redundant DB queries
  Future<List<Todo>> _getTodosWithCache() async {
    final now = DateTime.now();
    if (_cachedTodos != null &&
        _cacheTimestamp != null &&
        now.difference(_cacheTimestamp!).inMilliseconds < _cacheValidityMs) {
      logger.d('   Using cached todos (${_cachedTodos!.length} items)');
      return _cachedTodos!;
    }

    final result = await todoRepository.getTodos();
    _cachedTodos = result.fold(
      (failure) => <Todo>[],
      (todos) => todos,
    );
    _cacheTimestamp = now;
    return _cachedTodos!;
  }

  /// Get holidays with caching (holidays don't change during a session)
  Future<Set<int>> _getHolidaysWithCache(int year, int month) async {
    // Return cached holidays if same year/month
    if (_cachedHolidays != null &&
        _cachedHolidayYear == year &&
        _cachedHolidayMonth == month) {
      return _cachedHolidays!;
    }

    try {
      _cachedHolidays = await KoreanHolidayService.getHolidaysForMonth(year, month);
      _cachedHolidayYear = year;
      _cachedHolidayMonth = month;
      return _cachedHolidays!;
    } catch (e) {
      logger.w('   Failed to fetch holidays: $e');
      return {};
    }
  }

  /// Clear the cache (call after data modifications)
  void invalidateCache() {
    _cachedTodos = null;
    _cacheTimestamp = null;
    // Note: Holiday cache is NOT cleared as holidays don't change with todo modifications
  }

  /// Get calendar data for the current month (uses cache)
  Future<CalendarData> getCalendarData() async {
    try {
      final todos = await _getTodosWithCache();
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

  /// Get today's todo data (uses cache)
  Future<TodoListData> getTodaysTodos() async {
    try {
      final todos = await _getTodosWithCache();
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

  /// Get both calendar and todo data in one call (most efficient)
  Future<(CalendarData, TodoListData)> getWidgetData() async {
    final todos = await _getTodosWithCache();
    return (
      CalendarData.fromTodos(todos, DateTime.now()),
      TodoListData.fromTodos(todos),
    );
  }

  /// Update widget display based on current configuration (optimized)
  Future<void> updateWidget() async {
    logger.d('📱 WidgetService.updateWidget() called (optimized)');
    final stopwatch = Stopwatch()..start();
    try {
      final config = getWidgetConfig();
      logger.d('   Config: viewType=${config.viewType}, isEnabled=${config.isEnabled}');

      if (!config.isEnabled) {
        logger.d('   Widget disabled, clearing data');
        await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');
        await HomeWidget.saveWidgetData<String>('view_type', 'none');
        return;
      }

      // Fetch todos ONCE and share between both widgets
      final result = await todoRepository.getTodos();
      final todos = result.fold(
        (failure) => <Todo>[],
        (todos) => todos,
      );
      logger.d('   Fetched ${todos.length} todos in ${stopwatch.elapsedMilliseconds}ms');

      // Update widgets SEQUENTIALLY to avoid SharedPreferences conflicts
      // (parallel execution causes data race on same keys)
      await _updateTodoListWidgetWithData(todos);
      await _updateCalendarWidgetWithData(todos);

      // Save last update time
      await _updateLastModified();

      // Force native widget update for immediate sync (Android only)
      // Note: Batched saves with _executeFuturesInBatches already ensure proper disk sync,
      // so we only need a single update call without artificial delays
      await _forceNativeWidgetUpdate();

      // Invalidate cache after successful update
      invalidateCache();

      stopwatch.stop();
      logger.d('   Widget update completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      logger.e('❌ Error updating widget: $e');
    }
  }

  /// Force native widget update via MethodChannel
  /// This triggers ACTION_APPWIDGET_UPDATE for immediate refresh
  Future<void> _forceNativeWidgetUpdate() async {
    if (kIsWeb) return; // Skip on web

    try {
      await _widgetChannel.invokeMethod('forceUpdateWidgets');
      logger.d('   Native widget force update triggered');
    } catch (e) {
      // Silently ignore if channel not available (e.g., app in background)
      logger.d('   Native force update skipped: $e');
    }
  }

  /// Update calendar widget with pre-fetched data (optimized)
  Future<void> _updateCalendarWidgetWithData(List<Todo> todos) async {
    try {
      await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');

      final now = DateTime.now();
      final calendarData = CalendarData.fromTodos(todos, now);

      // Debug: Log todos that have due dates in current month
      if (kDebugMode) {
        final thisMonthTodos = todos.where((t) =>
          t.dueDate != null &&
          t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month
        ).toList();
        logger.d('📅 WidgetService: Updating calendar widget (with shared data)');
        logger.d('   Total todos: ${todos.length}, This month todos: ${thisMonthTodos.length}');
        for (final todo in thisMonthTodos) {
          logger.d('   - Day ${todo.dueDate!.day}: "${todo.title}" (completed: ${todo.isCompleted})');
        }
      }

      // Calculate calendar grid (Sunday first layout)
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;
      final firstWeekday = firstDayOfMonth.weekday % 7;

      // PERFORMANCE: Use cached holidays to avoid redundant API calls
      final holidays = await _getHolidaysWithCache(now.year, now.month);

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

      // Save day-specific todos for calendar day click feature
      _addDayTodosFutures(saveFutures, todos, now.year, now.month);

      // Execute saves in batches to avoid overwhelming SharedPreferences
      // Batch size of 15 balances parallelism vs disk I/O contention
      await _executeFuturesInBatches(saveFutures, batchSize: 15);

      // Notify native widget
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoCalendarWidget',
        iOSName: 'TodoCalendarWidget',
      );
      logger.d('✅ Calendar widget updated');
    } catch (e) {
      logger.e('❌ Error updating calendar widget: $e');
    }
  }

  /// Add day-specific todos for calendar day click feature
  /// Format: "day_todos_12_17" = "title1|time1;;title2|time2;;title3|time3"
  void _addDayTodosFutures(List<Future<void>> futures, List<Todo> todos, int year, int month) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;

    // Group todos by day
    final Map<int, List<Todo>> todosByDay = {};
    for (final todo in todos) {
      if (todo.dueDate != null &&
          todo.dueDate!.year == year &&
          todo.dueDate!.month == month &&
          !todo.isCompleted) {
        final day = todo.dueDate!.day;
        todosByDay.putIfAbsent(day, () => []);
        todosByDay[day]!.add(todo);
      }
    }

    // Save todos for each day (up to 5 per day)
    for (int day = 1; day <= lastDayOfMonth; day++) {
      final dayTodos = todosByDay[day] ?? [];
      if (dayTodos.isNotEmpty) {
        // Sort by time, then by position
        dayTodos.sort((a, b) {
          final timeA = a.notificationTime ?? a.dueDate;
          final timeB = b.notificationTime ?? b.dueDate;
          if (timeA != null && timeB != null) {
            final cmp = timeA.compareTo(timeB);
            if (cmp != 0) return cmp;
          }
          return (a.position).compareTo(b.position);
        });

        // Format: "title1|time1;;title2|time2"
        final todosStr = dayTodos.take(5).map((todo) {
          String timeStr = '';
          if (todo.notificationTime != null) {
            final t = todo.notificationTime!;
            timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          } else if (todo.dueDate != null &&
              (todo.dueDate!.hour != 0 || todo.dueDate!.minute != 0)) {
            timeStr = '${todo.dueDate!.hour.toString().padLeft(2, '0')}:${todo.dueDate!.minute.toString().padLeft(2, '0')}';
          }
          return '${todo.title}|$timeStr';
        }).join(';;');

        futures.add(HomeWidget.saveWidgetData<String>('day_todos_${month}_$day', todosStr));
        if (kDebugMode) {
          logger.d('   📆 Day $day todos: ${dayTodos.length} items saved');
        }
      } else {
        // Clear day data if no todos
        futures.add(HomeWidget.saveWidgetData<String>('day_todos_${month}_$day', ''));
      }
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
        // Use empty string instead of null to ensure previous data is cleared
        // null may not remove the key from SharedPreferences
        futures.add(HomeWidget.saveWidgetData<String>('upcoming_event_$i', ''));
      }
    }
    futures.add(HomeWidget.saveWidgetData<int>('upcoming_event_count', upcomingTodos.length));
  }

  /// Update todo list widget with pre-fetched data (optimized)
  Future<void> _updateTodoListWidgetWithData(List<Todo> todos) async {
    try {
      await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');

      final todoData = TodoListData.fromTodos(todos);
      logger.d('📱 WidgetService: Updating todo list widget (with shared data)');
      logger.d('   Today\'s todos count: ${todoData.todos.length}');

      // Calculate progress (completed / total for today)
      final todayTodos = _getTodayTodos(todos);
      final completedCount = todayTodos.where((t) => t.isCompleted).length;
      final totalCount = todayTodos.length;

      // Sort and categorize todos by date group (incomplete only)
      final incompleteTodos = todos.where((t) => !t.isCompleted).toList();
      if (kDebugMode) {
        final noDueDateCount = incompleteTodos.where((t) => t.dueDate == null).length;
        logger.d('   Incomplete todos: ${incompleteTodos.length}, No due date: $noDueDateCount');
      }

      // Sort by user's position (drag-and-drop order) instead of date groups
      final sortedTodos = _sortTodosByPosition(incompleteTodos);
      if (kDebugMode) {
        logger.d('   Sorted todos count: ${sortedTodos.length}');
      }

      // Get top 10 todos to save (display 2, but save 10 for multiple shift operations on completion)
      // This allows up to 8 consecutive completions without reopening the app
      final displayTodos = sortedTodos.take(10).toList();
      if (kDebugMode) {
        logger.d('   Buffer todos (10 max): ${displayTodos.map((t) => "${t.title} (dueDate: ${t.dueDate})").toList()}');
      }

      // Prepare all widget data in parallel
      final List<Future<void>> todoFutures = [
        HomeWidget.saveWidgetData<String>('view_type', 'todo_list'),
        HomeWidget.saveWidgetData<int>('todo_completed_count', completedCount),
        HomeWidget.saveWidgetData<int>('todo_total_count', totalCount),
      ];

      // Save todo items (10 items for extended shift capability, but widget displays only 2)
      for (int i = 0; i < 10; i++) {
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
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_description', todo.description),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_id', todo.id.toString()),
            HomeWidget.saveWidgetData<bool>('todo_${i + 1}_completed', todo.isCompleted),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_time', timeStr),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_group', dateGroup),
          ]);
        } else {
          todoFutures.addAll([
            HomeWidget.saveWidgetData<String?>('todo_${i + 1}_text', null),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_description', ''),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_time', ''),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_id', ''),
            HomeWidget.saveWidgetData<bool>('todo_${i + 1}_completed', false),
            HomeWidget.saveWidgetData<String>('todo_${i + 1}_group', ''),
          ]);
        }
      }

      // Execute saves in batches to avoid overwhelming SharedPreferences
      await _executeFuturesInBatches(todoFutures, batchSize: 15);

      // Notify native widgets (both TodoListWidget and TodoDetailWidget)
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoListWidget',
        iOSName: 'TodoListWidget',
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoDetailWidget',
        iOSName: 'TodoDetailWidget',
      );
      logger.d('✅ Todo list widgets updated (list + detail)');
    } catch (e) {
      logger.e('❌ Error updating todo list widget: $e');
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

  /// Sort todos by user's position (drag-and-drop order)
  /// Position takes precedence - user's manual ordering is respected
  List<Todo> _sortTodosByPosition(List<Todo> todos) {
    final sorted = List<Todo>.from(todos);
    sorted.sort((a, b) {
      final posA = a.position;
      final posB = b.position;
      return posA.compareTo(posB);
    });
    return sorted;
  }

  /// Get date group string for a todo
  String _getDateGroup(DateTime? dueDate) {
    if (dueDate == null) return 'no_due_date';

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
      await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');
      await HomeWidget.saveWidgetData<String>('view_type', 'none');
      await setWidgetEnabled(false);
    } catch (e) {
      logger.e('Error disabling widgets: $e');
    }
  }

  /// Clear widget data on logout
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.setAppGroupId('group.kr.bluesky.dodo');
      await HomeWidget.saveWidgetData<String>('view_type', 'none');
      await HomeWidget.saveWidgetData<String>('calendar_data', '');
      await HomeWidget.saveWidgetData<String>('todo_data', '');
    } catch (e) {
      logger.e('Error clearing widget data: $e');
    }
  }

  /// Reset widget configuration to defaults
  Future<void> resetConfiguration() async {
    await preferences.remove(_viewTypeKey);
    await preferences.remove(_enabledKey);
    await preferences.remove(_lastUpdateKey);
    await clearWidgetData();
  }

  /// Execute futures in batches to avoid overwhelming SharedPreferences
  /// This prevents disk I/O contention and improves reliability
  Future<void> _executeFuturesInBatches(
    List<Future<void>> futures, {
    int batchSize = 15,
  }) async {
    for (var i = 0; i < futures.length; i += batchSize) {
      final batch = futures.skip(i).take(batchSize).toList();
      await Future.wait(batch);
    }
  }
}
