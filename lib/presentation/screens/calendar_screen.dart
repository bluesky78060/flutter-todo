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
import 'package:todo_app/core/services/korean_holiday_service.dart' as holiday_service;
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/widgets/custom_todo_item.dart';
import 'package:todo_app/presentation/widgets/recurring_delete_dialog.dart';
import 'package:todo_app/presentation/widgets/todo_form_dialog.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Calendar screen for date-based todo visualization.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  Set<int> _holidays = {};
  List<holiday_service.HolidayInfo> _holidayInfoList = [];
  holiday_service.HolidayInfo? _holidayInfoForSelectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadHolidaysForMonth(_focusedDay.year, _focusedDay.month);
  }

  Future<void> _loadHolidaysForMonth(int year, int month) async {
    try {
      final holidays = await holiday_service.KoreanHolidayService.getHolidaysForMonth(year, month);
      final holidayInfo = await holiday_service.KoreanHolidayService.getHolidayInfoForMonth(year, month);
      if (mounted) {
        setState(() {
          _holidays = holidays;
          _holidayInfoList = holidayInfo;
        });
        // Only update holiday info if the selected day is actually in this month
        if (_selectedDay != null &&
            _selectedDay!.year == year &&
            _selectedDay!.month == month) {
          _updateHolidayForSelectedDay();
        }
      }
    } catch (e) {
      print('Failed to load holidays: $e');
    }
  }

  /// Update _holidayInfoForSelectedDay based on current _selectedDay
  void _updateHolidayForSelectedDay() {
    if (_selectedDay == null) {
      setState(() {
        _holidayInfoForSelectedDay = null;
      });
      return;
    }

    // Check if selected day is in the current month
    if (_selectedDay!.year == _focusedDay.year &&
        _selectedDay!.month == _focusedDay.month) {
      // Search for holiday info for this day
      holiday_service.HolidayInfo? holidayForDay;
      for (final holiday in _holidayInfoList) {
        if (holiday.day == _selectedDay!.day) {
          holidayForDay = holiday;
          break;
        }
      }
      setState(() {
        _holidayInfoForSelectedDay = holidayForDay;
      });
    } else {
      // Selected day is in a different month, need to load holidays for that month
      _loadHolidaysForMonth(_selectedDay!.year, _selectedDay!.month).then((_) {
        // After loading, search for the holiday
        holiday_service.HolidayInfo? holidayForDay;
        for (final holiday in _holidayInfoList) {
          if (holiday.day == _selectedDay!.day) {
            holidayForDay = holiday;
            break;
          }
        }
        if (mounted) {
          setState(() {
            _holidayInfoForSelectedDay = holidayForDay;
          });
        }
      });
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
            // Calendar - TableCalendar 내장 애니메이션으로 동적 높이 변화
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.getCard(isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                sixWeekMonthsEnforced: false,  // 필요한 주 수만 표시 (4~6주)
                rowHeight: 48,  // 명시적 행 높이 설정
                daysOfWeekHeight: 32,  // 요일 헤더 높이
                availableCalendarFormats: const {
                  CalendarFormat.month: '월',
                  CalendarFormat.twoWeeks: '2주',
                  CalendarFormat.week: '주',
                },
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // Load holiday info for the selected day
                  _updateHolidayForSelectedDay();
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  _loadHolidaysForMonth(focusedDay.year, focusedDay.month);
                  // Clear holiday info when changing months (unless selected day is in this month)
                  if (_selectedDay == null ||
                      _selectedDay!.year != focusedDay.year ||
                      _selectedDay!.month != focusedDay.month) {
                    setState(() {
                      _holidayInfoForSelectedDay = null;
                    });
                  }
                },
                eventLoader: (day) => _getEventsForDay(day, todos),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final isHoliday = _holidays.contains(day.day);
                    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                    return _buildCalendarDay(day, isHoliday, isDarkMode, isWeekend, false);
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    // Don't show holiday markers for days outside the focused month
                    return _buildCalendarDay(day, false, isDarkMode, false, true);
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
                    color: AppColors.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontWeight: FontWeight.bold,
                  ),
                  // Selected day
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
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
                    fontSize: AppColors.scaledFontSize(18),
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
                ),  // TableCalendar
              ),  // ClipRRect
            ),  // Container
          ),  // Padding

            // Selected day's todos
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.calendar_24_filled,
                          color: AppColors.primary,
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
                            fontSize: AppColors.scaledFontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'count_items'.tr(namedArgs: {'count': '${_getTodosForDay(_selectedDay!, todos).length}'}),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: AppColors.scaledFontSize(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Add todo button (only for today or future dates)
                        _buildAddTodoButton(isDarkMode),
                      ],
                    ),
                    // Show holiday info if selected day is a holiday
                    if (_holidayInfoForSelectedDay != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              FluentIcons.gift_24_filled,
                              color: AppColors.accentOrange,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              _holidayInfoForSelectedDay!.nameKo,
                              style: TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: AppColors.scaledFontSize(13),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                      fontSize: AppColors.scaledFontSize(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
                fontSize: AppColors.scaledFontSize(16),
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
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            )
          else if (isSelected)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
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

  /// Check if selected day is today or in the future
  bool _canAddTodoForSelectedDay() {
    if (_selectedDay == null) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    return !selectedDate.isBefore(todayDate);
  }

  /// Build add todo button for selected date
  Widget _buildAddTodoButton(bool isDarkMode) {
    final canAdd = _canAddTodoForSelectedDay();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAdd ? _addTodoForSelectedDate : null,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: 'add_todo_for_date'.tr(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: canAdd
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.textGray.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              FluentIcons.add_24_regular,
              color: canAdd
                  ? AppColors.primary
                  : AppColors.textGray.withValues(alpha: 0.3),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Open todo form dialog with selected date pre-filled
  void _addTodoForSelectedDate() {
    if (_selectedDay == null) return;

    showDialog(
      context: context,
      builder: (context) => TodoFormDialog(
        initialDueDate: DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
          0,
          0,
        ),
        initialAllDay: true,
      ),
    );
  }

}
