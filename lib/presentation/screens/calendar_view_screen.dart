/// Calendar View Screen for displaying todos in a calendar format.
///
/// Features:
/// - Monthly calendar grid with TableCalendar
/// - Todo indicators on dates
/// - Selected date todo list below calendar
/// - Quick add todo for selected date
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/calendar_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';
import 'package:todo_app/presentation/providers/subtask_providers.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/widgets/calendar_day_cell.dart';
import 'package:todo_app/presentation/widgets/todo_form_dialog.dart';

/// Calendar view for displaying todos on a monthly calendar
class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    ref.read(selectedDateProvider.notifier).setDate(selectedDay);
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _showAddTodoDialog() {
    final selectedDate = ref.read(selectedDateProvider);
    showDialog(
      context: context,
      builder: (context) => TodoFormDialog(
        initialDueDate: selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final primaryColor = ref.watch(primaryColorProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final todosByDate = ref.watch(todosByDateProvider);
    final selectedTodos = ref.watch(selectedDateTodosProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fixed height elements
        const headerHeight = 50.0; // _buildDateHeader
        const buttonHeight = 90.0; // _buildAddTodoButton with SafeArea
        const dividerHeight = 1.0; // Divider
        const minTodoListHeight = 50.0; // Minimum todo list height

        // Maximum calendar height based on available space
        final maxCalendarHeight = constraints.maxHeight -
            headerHeight -
            buttonHeight -
            dividerHeight -
            minTodoListHeight;

        // Desired calendar height based on format
        // month: ~350px, twoWeeks: ~180px, week: ~120px
        final desiredCalendarHeight = _calendarFormat == CalendarFormat.month
            ? 350.0
            : _calendarFormat == CalendarFormat.twoWeeks
                ? 180.0
                : 120.0;

        // Use the smaller of desired and max available height
        final calendarHeight = desiredCalendarHeight.clamp(80.0, maxCalendarHeight.clamp(80.0, 400.0));

        return Column(
          children: [
            // Calendar with fixed height based on format
            SizedBox(
              height: calendarHeight,
              child: _buildCalendar(
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
                selectedDate: selectedDate,
                todosByDate: todosByDate,
              ),
            ),

            // Divider
            Divider(
              height: 1,
              color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.2),
            ),

            // Selected date header
            _buildDateHeader(
              selectedDate: selectedDate,
              todoCount: selectedTodos.length,
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
            ),

            // Todo list for selected date (fills remaining space)
            Expanded(
              child: selectedTodos.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : _buildTodoList(selectedTodos, isDarkMode),
            ),

            // Add todo button - fixed at bottom
            _buildAddTodoButton(isDarkMode, primaryColor),
          ],
        );
      },
    );
  }

  Widget _buildCalendar({
    required bool isDarkMode,
    required Color primaryColor,
    required DateTime selectedDate,
    required Map<DateTime, List<Todo>> todosByDate,
  }) {
    return TableCalendar<Todo>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: _onDaySelected,
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: (day) {
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return todosByDate[normalizedDay] ?? [];
      },
      // Header style
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: true,
        formatButtonShowsNext: false,
        formatButtonTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 12,
        ),
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.getText(isDarkMode),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(
          FluentIcons.chevron_left_24_regular,
          color: AppColors.getText(isDarkMode),
          size: 20,
        ),
        rightChevronIcon: Icon(
          FluentIcons.chevron_right_24_regular,
          color: AppColors.getText(isDarkMode),
          size: 20,
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      // Days of week style
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: AppColors.getText(isDarkMode),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        weekendStyle: TextStyle(
          color: Colors.red.shade400,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      // Calendar style
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        cellMargin: const EdgeInsets.all(2),
        // Default day
        defaultTextStyle: TextStyle(
          color: AppColors.getText(isDarkMode),
        ),
        // Weekend
        weekendTextStyle: TextStyle(
          color: Colors.red.shade400,
        ),
        // Outside month
        outsideTextStyle: TextStyle(
          color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.4),
        ),
        // Selected day
        selectedDecoration: BoxDecoration(
          border: Border.all(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: primaryColor.withOpacity(0.1),
        ),
        selectedTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        // Today
        todayDecoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        todayTextStyle: TextStyle(
          color: AppColors.getText(isDarkMode),
          fontWeight: FontWeight.bold,
        ),
        // Markers
        markersMaxCount: 1,
        markerDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markersAlignment: Alignment.bottomCenter,
        markerMargin: const EdgeInsets.only(top: 1),
      ),
      // Custom builders
      calendarBuilders: CalendarBuilders<Todo>(
        // Custom day cell with todo title
        defaultBuilder: (context, day, focusedDay) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final todos = todosByDate[normalizedDay];
          return CalendarDayCell(
            date: day,
            todos: todos,
            onTap: () => _onDaySelected(day, focusedDay),
          );
        },
        selectedBuilder: (context, day, focusedDay) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final todos = todosByDate[normalizedDay];
          return CalendarDayCell(
            date: day,
            isSelected: true,
            todos: todos,
            onTap: () => _onDaySelected(day, focusedDay),
          );
        },
        todayBuilder: (context, day, focusedDay) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final todos = todosByDate[normalizedDay];
          final isSelected = isSameDay(ref.read(selectedDateProvider), day);
          return CalendarDayCell(
            date: day,
            isToday: true,
            isSelected: isSelected,
            todos: todos,
            onTap: () => _onDaySelected(day, focusedDay),
          );
        },
        outsideBuilder: (context, day, focusedDay) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final todos = todosByDate[normalizedDay];
          return CalendarDayCell(
            date: day,
            isOutsideMonth: true,
            todos: todos,
            onTap: () => _onDaySelected(day, focusedDay),
          );
        },
        // Hide default markers since we show todo title
        markerBuilder: (context, day, events) {
          return const SizedBox.shrink();
        },
      ),
      // Row height for showing todo titles
      rowHeight: 48,
    );
  }

  Widget _buildDateHeader({
    required DateTime selectedDate,
    required int todoCount,
    required bool isDarkMode,
    required Color primaryColor,
  }) {
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', context.locale.toString());
    final formattedDate = dateFormat.format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDarkMode),
            ),
          ),
          const Spacer(),
          if (todoCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$todoCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.calendar_empty_24_regular,
            size: 48,
            color: AppColors.getTextSecondary(isDarkMode),
          ),
          const SizedBox(height: 16),
          Text(
            'no_todos_for_date'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTodoCard(todo, isDarkMode),
        );
      },
    );
  }

  Widget _buildTodoCard(Todo todo, bool isDarkMode) {
    final primaryColor = ref.watch(primaryColorProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final subtaskStatsAsync = ref.watch(subtaskStatsProvider(todo.id));
    final hasTime = todo.notificationTime != null;
    final timeText = hasTime
        ? DateFormat('HH:mm').format(todo.notificationTime!)
        : 'all_day'.tr();
    final hasDescription = todo.description.isNotEmpty;
    final hasLocation = todo.locationName != null && todo.locationName!.isNotEmpty;

    // Get category from categoryId
    String? categoryColor;
    String? categoryName;
    if (todo.categoryId != null) {
      final categories = categoriesAsync.asData?.value ?? [];
      final category = categories.where((c) => c.id == todo.categoryId).firstOrNull;
      if (category != null) {
        categoryColor = category.color;
        categoryName = category.name;
      }
    }

    // Check if there are subtasks using when() for proper async handling
    final subtaskData = subtaskStatsAsync.when(
      data: (stats) => stats,
      loading: () => <String, int>{'total': 0, 'completed': 0},
      error: (_, __) => <String, int>{'total': 0, 'completed': 0},
    );
    final subtaskCount = subtaskData['total'] ?? 0;
    final completedSubtasks = subtaskData['completed'] ?? 0;

    return InkWell(
      onTap: () => context.push('/todos/${todo.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.darkCard
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion toggle button
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconButton(
                onPressed: () {
                  ref.read(todoActionsProvider).toggleCompletion(todo.id);
                },
                icon: Icon(
                  todo.isCompleted
                      ? FluentIcons.checkmark_circle_24_filled
                      : FluentIcons.circle_24_regular,
                  color: todo.isCompleted ? Colors.green : primaryColor,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
            const SizedBox(width: 8),
            // Category color bar
            if (categoryColor != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(categoryColor.replaceFirst('#', '0xFF')),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Title, Description, and Icons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with time badge and icons
                  Row(
                    children: [
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      // Category badge
                      if (categoryName != null && categoryColor != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(categoryColor.replaceFirst('#', '0xFF')),
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Color(
                                int.parse(categoryColor.replaceFirst('#', '0xFF')),
                              ).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(
                                int.parse(categoryColor.replaceFirst('#', '0xFF')),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Title
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: todo.isCompleted
                                ? AppColors.getTextSecondary(isDarkMode)
                                : AppColors.getText(isDarkMode),
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Subtask icon (right of title)
                      if (subtaskCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FluentIcons.task_list_square_ltr_24_regular,
                                size: 14,
                                color: AppColors.getTextSecondary(isDarkMode),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$completedSubtasks/$subtaskCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.getTextSecondary(isDarkMode),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Location icon (right of title)
                      if (hasLocation)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            FluentIcons.location_24_regular,
                            size: 14,
                            color: AppColors.getTextSecondary(isDarkMode),
                          ),
                        ),
                    ],
                  ),
                  // Description
                  if (hasDescription)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        todo.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(isDarkMode),
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              onPressed: () => _showDeleteConfirmDialog(todo),
              icon: Icon(
                FluentIcons.delete_24_regular,
                color: Colors.red.shade400,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_todo'.tr()),
        content: Text('delete_todo_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              ref.read(todoActionsProvider).deleteTodo(todo.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTodoButton(bool isDarkMode, Color primaryColor) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAddTodoDialog,
            icon: const Icon(FluentIcons.add_24_regular),
            label: Text('add_new_todo'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
