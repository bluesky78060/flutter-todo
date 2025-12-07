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
  final String? holidayName;
  final List<Todo>? todos;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    this.isSelected = false,
    this.isToday = false,
    this.isOutsideMonth = false,
    this.holidayName,
    this.todos,
    this.onTap,
  });

  bool get isHoliday => holidayName != null && holidayName!.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final primaryColor = ref.watch(primaryColorProvider);

    final isWeekend = date.weekday == DateTime.saturday ||
                      date.weekday == DateTime.sunday;
    final hasTodos = todos != null && todos!.isNotEmpty;
    final firstTodoTitle = hasTodos ? todos!.first.title : null;

    // Holiday red color
    final holidayColor = isDarkMode
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFE53935);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            // Selected date: border with primaryColor
            border: isSelected
                ? Border.all(color: primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
            // Background color priority: selected > today > hasTodos
            color: isSelected
                ? (isDarkMode
                    ? primaryColor.withOpacity(0.1)
                    : primaryColor.withOpacity(0.05))
                : isToday
                    ? (isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300)
                    : (hasTodos && !isOutsideMonth)
                        ? (isDarkMode
                            ? primaryColor.withOpacity(0.15)
                            : primaryColor.withOpacity(0.06))
                        : null,
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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
                    isHoliday: isHoliday,
                    primaryColor: primaryColor,
                  ),
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
              // Holiday name or Todo indicator
              if (isHoliday && !isOutsideMonth && !hasTodos)
                Text(
                  holidayName!.length > 3 ? '${holidayName!.substring(0, 3)}…' : holidayName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    height: 1.0,
                    color: holidayColor,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (hasTodos)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // First todo
                    Text(
                      firstTodoTitle!.length > 5 ? '${firstTodoTitle.substring(0, 5)}…' : firstTodoTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        height: 1.0,
                        fontWeight: FontWeight.w600,
                        color: isOutsideMonth
                            ? AppColors.getTextSecondary(isDarkMode).withOpacity(0.5)
                            : AppColors.getTextSecondary(isDarkMode),
                      ),
                    ),
                    // Second todo or "+N more"
                    if (todos!.length > 1)
                      Text(
                        todos!.length == 2
                            ? (todos![1].title.length > 5 ? '${todos![1].title.substring(0, 5)}…' : todos![1].title)
                            : '+${todos!.length - 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          height: 1.0,
                          fontWeight: FontWeight.w600,
                          color: isOutsideMonth
                              ? AppColors.getTextSecondary(isDarkMode).withOpacity(0.5)
                              : (todos!.length > 2 ? primaryColor : AppColors.getTextSecondary(isDarkMode)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDateColor({
    required bool isDarkMode,
    required bool isOutsideMonth,
    required bool isWeekend,
    required bool isSelected,
    required bool isHoliday,
    required Color primaryColor,
  }) {
    if (isOutsideMonth) {
      return AppColors.getTextSecondary(isDarkMode).withOpacity(0.4);
    }
    if (isSelected) {
      return primaryColor;
    }
    // Holiday color takes priority over weekend
    if (isHoliday) {
      return isDarkMode
          ? const Color(0xFFFF6B6B)
          : const Color(0xFFE53935);
    }
    if (isWeekend) {
      return Colors.red.shade400;
    }
    return AppColors.getText(isDarkMode);
  }
}
