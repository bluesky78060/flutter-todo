/// Calendar Day Cell Widget for custom date rendering.
///
/// Displays:
/// - Date number
/// - First todo title (if any)
/// - Special styling for selected/today/weekend dates
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';

/// A single day cell in the calendar grid
class CalendarDayCell extends ConsumerWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;
  final List<Todo>? todos;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    this.isSelected = false,
    this.isToday = false,
    this.isOutsideMonth = false,
    this.todos,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final primaryColor = ref.watch(primaryColorProvider);

    final isWeekend = date.weekday == DateTime.saturday ||
                      date.weekday == DateTime.sunday;
    final hasTodos = todos != null && todos!.isNotEmpty;
    final firstTodoTitle = hasTodos ? todos!.first.title : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          // Selected date: border with primaryColor
          border: isSelected
              ? Border.all(color: primaryColor, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
          // Today: dark background
          color: isToday && !isSelected
              ? (isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade300)
              : (isSelected
                  ? (isDarkMode
                      ? primaryColor.withOpacity(0.1)
                      : primaryColor.withOpacity(0.05))
                  : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date number
            Text(
              '${date.day}',
              style: TextStyle(
                color: _getDateColor(
                  isDarkMode: isDarkMode,
                  isOutsideMonth: isOutsideMonth,
                  isWeekend: isWeekend,
                  isSelected: isSelected,
                  primaryColor: primaryColor,
                ),
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            // Todo indicator (combined: title + count)
            if (hasTodos) ...[
              const SizedBox(height: 1),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    todos!.length > 1
                        ? '${firstTodoTitle!.length > 4 ? '${firstTodoTitle!.substring(0, 4)}…' : firstTodoTitle} +${todos!.length - 1}'
                        : firstTodoTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: isOutsideMonth
                          ? AppColors.getTextSecondary(isDarkMode).withOpacity(0.5)
                          : (todos!.length > 1 ? primaryColor : AppColors.getTextSecondary(isDarkMode)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDateColor({
    required bool isDarkMode,
    required bool isOutsideMonth,
    required bool isWeekend,
    required bool isSelected,
    required Color primaryColor,
  }) {
    if (isOutsideMonth) {
      return AppColors.getTextSecondary(isDarkMode).withOpacity(0.4);
    }
    if (isSelected) {
      return primaryColor;
    }
    if (isWeekend) {
      return Colors.red.shade400;
    }
    return AppColors.getText(isDarkMode);
  }
}
