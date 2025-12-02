/// Filter chip widget for todo list filtering.
///
/// Displays a label with count and supports tap interaction.
/// Used in the todo list header to filter by status (All, Pending, Completed).
///
/// Example:
/// ```dart
/// FilterChip(
///   label: 'Pending',
///   count: 5,
///   isSelected: true,
///   onTap: () { /* handle filter change */ },
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

/// Filter chip widget for filtering todos by status.
class TodoFilterChip extends ConsumerWidget {
  /// Label text displayed in the chip (e.g., "All", "Pending", "Completed")
  final String label;

  /// Count of todos matching this filter
  final int count;

  /// Whether this filter is currently selected
  final bool isSelected;

  /// Callback when the chip is tapped
  final VoidCallback onTap;

  const TodoFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getInput(isDarkMode),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: AppColors.scaledFontSize(14),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: AppColors.scaledFontSize(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
