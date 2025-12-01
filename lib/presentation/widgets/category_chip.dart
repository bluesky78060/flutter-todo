/// Category chip widget for category filtering.
///
/// Displays a category with optional color indicator and icon.
/// Used in the todo list header to filter todos by category.
///
/// Example:
/// ```dart
/// CategoryChip(
///   label: 'Work',
///   icon: '💼',
///   color: Colors.blue,
///   isSelected: true,
///   onTap: () { /* handle category filter */ },
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

/// Category chip widget for filtering todos by category.
class CategoryChip extends ConsumerWidget {
  /// Category name/label displayed in the chip
  final String label;

  /// Emoji or icon character (e.g., '💼', '🎯')
  final String? icon;

  /// Color associated with the category
  final Color? color;

  /// Whether this category is currently selected
  final bool isSelected;

  /// Callback when the chip is tapped
  final VoidCallback onTap;

  const CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primaryBlue).withOpacity(0.2)
                : AppColors.getCard(isDarkMode),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppColors.primaryBlue)
                  : AppColors.getBorder(isDarkMode),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[
                Text(
                  icon!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
