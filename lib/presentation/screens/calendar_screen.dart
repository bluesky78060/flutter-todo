/// Calendar view screen for visualizing todos by date.
///
/// Features:
/// - Monthly calendar view with todo markers
/// - Date selection to filter todos
/// - Visual indicators for todo density per day
/// - List view of todos for selected date
/// - Quick navigation between months
///
/// Uses table_calendar package for calendar rendering.
///
/// See also:
/// - [todosProvider] for todo data
/// - [TodoListScreen] for main list view
library;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/services/korean_holiday_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/widgets/custom_todo_item.dart';
import 'package:todo_app/presentation/widgets/recurring_delete_dialog.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Calendar screen for date-based todo visualization.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<int> _holidays = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadHolidaysForMonth(_focusedDay.year, _focusedDay.month);
  }

  Future<void> _loadHolidaysForMonth(int year, int month) async {
    try {
      final holidays = await KoreanHolidayService.getHolidaysForMonth(year, month);
      if (mounted) {
        setState(() {
          _holidays = holidays;
        });
      }
    } catch (e) {
      print('Failed to load holidays: $e');
    }
  }

  /// 특정 날짜에 해당하는 todos를 필터링
  List<Todo> _getTodosForDay(DateTime day, List<Todo> allTodos) {
    return allTodos.where((todo) {
      if (todo.dueDate == null) return false;

      // 날짜만 비교 (시간 무시)
      final todoDate = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      final targetDate = DateTime(day.year, day.month, day.day);

      return todoDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  /// 캘린더 마커 표시 (각 날짜에 몇 개의 todo가 있는지)
  List<Todo> _getEventsForDay(DateTime day, List<Todo> allTodos) {
    return _getTodosForDay(day, allTodos);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final todosAsync = ref.watch(todosProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getCard(isDarkMode),
        title: Text(
          'calendar'.tr(),
          style: TextStyle(color: AppColors.getText(isDarkMode)),
        ),
        leading: IconButton(
          icon: Icon(
            FluentIcons.arrow_left_24_regular,
            color: AppColors.getText(isDarkMode),
          ),
          onPressed: () => context.go('/todos'),
        ),
      ),
      body: todosAsync.when(
        data: (todos) => Column(
          children: [
            // Calendar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCard(isDarkMode),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadHolidaysForMonth(focusedDay.year, focusedDay.month);
                },
                eventLoader: (day) => _getEventsForDay(day, todos),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final isHoliday = _holidays.contains(day.day);
                    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                    return _buildCalendarDay(day, isHoliday, isDarkMode, isWeekend, false);
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    final isHoliday = _holidays.contains(day.day);
                    return _buildCalendarDay(day, isHoliday, isDarkMode, false, true);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final isHoliday = _holidays.contains(day.day);
                    return _buildCalendarDay(day, isHoliday, isDarkMode, false, false, isToday: true);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final isHoliday = _holidays.contains(day.day);
                    return _buildCalendarDay(day, isHoliday, isDarkMode, false, false, isSelected: true);
                  },
                ),
                calendarStyle: CalendarStyle(
                  // Today
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontWeight: FontWeight.bold,
                  ),
                  // Selected day
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontWeight: FontWeight.bold,
                  ),
                  // Default days
                  defaultTextStyle: TextStyle(
                    color: AppColors.getText(isDarkMode),
                  ),
                  weekendTextStyle: TextStyle(
                    color: isDarkMode ? AppColors.accentOrange : const Color(0xFFE53935),
                  ),
                  outsideTextStyle: TextStyle(
                    color: AppColors.textGray.withValues(alpha: 0.5),
                  ),
                  // Markers
                  markerDecoration: const BoxDecoration(
                    color: AppColors.accentOrange,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 6,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                  markersMaxCount: 3,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(
                    FluentIcons.chevron_left_24_regular,
                    color: AppColors.getText(isDarkMode),
                  ),
                  rightChevronIcon: Icon(
                    FluentIcons.chevron_right_24_regular,
                    color: AppColors.getText(isDarkMode),
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: AppColors.textGray.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  weekendStyle: TextStyle(
                    color: AppColors.accentOrange.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Selected day's todos
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      FluentIcons.calendar_24_filled,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'year_month_day'.tr(namedArgs: {
                        'year': '${_selectedDay!.year}',
                        'month': '${_selectedDay!.month}',
                        'day': '${_selectedDay!.day}'
                      }),
                      style: TextStyle(
                        color: AppColors.getText(isDarkMode),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'count_items'.tr(namedArgs: {'count': '${_getTodosForDay(_selectedDay!, todos).length}'}),
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildTodoList(_getTodosForDay(_selectedDay!, todos)),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Text(
                    'select_date_message'.tr(),
                    style: TextStyle(
                      color: AppColors.textGray.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (error, _) => Center(
          child: Text(
            '${'error'.tr()}: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.calendar_empty_24_regular,
              size: 64,
              color: AppColors.textGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'no_todos_for_date'.tr(),
              style: TextStyle(
                color: AppColors.textGray.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return CustomTodoItem(
          key: ValueKey(todo.id),
          todo: todo,
          onToggle: () => ref.read(todoActionsProvider).toggleCompletion(todo.id),
          onDelete: () => _handleDelete(todo),
          onTap: () => context.go('/todos/${todo.id}'),
        );
      },
    );
  }

  Future<void> _handleDelete(Todo todo) async {
    // Check if this is a recurring instance
    if (todo.parentRecurringTodoId != null) {
      // Show recurring delete dialog
      final mode = await showDialog<RecurringDeleteMode>(
        context: context,
        builder: (context) => const RecurringDeleteDialog(),
      );

      if (mode != null && mounted) {
        try {
          await ref.read(todoActionsProvider).deleteTodo(
                todo.id,
                recurringDeleteMode: mode,
              );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'error'.tr()}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else {
      // Regular todo - just delete
      try {
        await ref.read(todoActionsProvider).deleteTodo(todo.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Build calendar day with holiday indicator
  Widget _buildCalendarDay(
    DateTime day,
    bool isHoliday,
    bool isDarkMode,
    bool isWeekend,
    bool isOutside, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    // Determine text color
    Color textColor;
    if (isSelected) {
      textColor = AppColors.getText(isDarkMode);
    } else if (isHoliday) {
      // Holiday text in red/orange
      textColor = isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFE53935);
    } else if (isWeekend) {
      // Weekend text in orange
      textColor = isDarkMode ? AppColors.accentOrange : const Color(0xFFE53935);
    } else if (isOutside) {
      // Outside month text in gray
      textColor = AppColors.textGray.withValues(alpha: 0.5);
    } else {
      // Regular text
      textColor = AppColors.getText(isDarkMode);
    }

    // Build the cell
    Widget cell = Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle for today/selected
          if (isToday)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            )
          else if (isSelected)
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
          // Text content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              // Holiday indicator (red dot)
              if (isHoliday)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return cell;
  }
}
