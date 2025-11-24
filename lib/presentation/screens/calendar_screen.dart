import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/widgets/custom_todo_item.dart';
import 'package:todo_app/presentation/widgets/recurring_delete_dialog.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
          '캘린더',
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
                },
                eventLoader: (day) => _getEventsForDay(day, todos),
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
                  defaultTextStyle: const TextStyle(
                    color: AppColors.textWhite,
                  ),
                  weekendTextStyle: const TextStyle(
                    color: AppColors.accentOrange,
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
                      '${_selectedDay!.year}년 ${_selectedDay!.month}월 ${_selectedDay!.day}일',
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
                        '${_getTodosForDay(_selectedDay!, todos).length}개',
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
                    '날짜를 선택하세요',
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
            '오류: $error',
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
              '이 날짜에 할일이 없습니다',
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
                content: Text('오류: $e'),
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
              content: Text('오류: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
