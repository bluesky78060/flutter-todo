/// Dialog helper utilities for todo list screen.
///
/// Provides reusable dialog functions to reduce code duplication
/// and centralize dialog construction logic.
///
/// Functions:
/// - [showClearCompletedDialog] - Confirmation dialog for clearing completed todos
/// - [showRecurringDeleteDialog] - Specialized recurring todo deletion dialog
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/widgets/recurring_delete_dialog.dart';

/// Typedef for recurring delete mode callback
typedef OnRecurringDeleteMode = Future<void> Function(RecurringDeleteMode? mode);

/// Shows confirmation dialog for clearing all completed todos.
///
/// Parameters:
/// - [context]: Build context for dialog
/// - [onConfirm]: Callback function to execute when user confirms
///
/// Returns:
/// - bool indicating if user confirmed (true) or cancelled (false)
///
/// Example:
/// ```dart
/// final shouldClear = await showClearCompletedDialog(context);
/// if (shouldClear) {
///   await deleteCompletedTodos();
/// }
/// ```
Future<bool> showClearCompletedDialog({
  required BuildContext context,
  required bool isDarkMode,
}) async {
  final shouldClear = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.getCard(isDarkMode),
      title: Row(
        children: [
          const Icon(
            FluentIcons.delete_24_regular,
            color: AppColors.accentOrange,
          ),
          const SizedBox(width: 12),
          Text(
            'clear_completed_title'.tr(),
            style: TextStyle(color: AppColors.textWhite),
          ),
        ],
      ),
      content: Text(
        'clear_completed_message'.tr(),
        style: TextStyle(
          color: AppColors.textGray,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'cancel'.tr(),
            style: TextStyle(color: AppColors.textGray),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dangerRed,
          ),
          child: Text(
            'delete'.tr(),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  return shouldClear ?? false;
}

/// Shows recurring delete mode dialog when deleting a recurring todo instance.
///
/// Parameters:
/// - [context]: Build context for dialog
///
/// Returns:
/// - RecurringDeleteMode selected by user, or null if cancelled
///
/// Example:
/// ```dart
/// final mode = await showRecurringDeleteDialog(context);
/// if (mode != null) {
///   await deleteTodo(todoId, recurringDeleteMode: mode);
/// }
/// ```
Future<RecurringDeleteMode?> showRecurringDeleteDialog({
  required BuildContext context,
}) async {
  final mode = await showDialog<RecurringDeleteMode>(
    context: context,
    builder: (context) => const RecurringDeleteDialog(),
  );

  return mode;
}

/// Shows a generic confirmation dialog with custom title and message.
///
/// Parameters:
/// - [context]: Build context for dialog
/// - [title]: Dialog title
/// - [message]: Dialog message content
/// - [isDarkMode]: Theme mode flag
/// - [confirmText]: Text for confirm button (default: 'delete')
/// - [cancelText]: Text for cancel button (default: 'cancel')
/// - [isDangerous]: If true, uses danger red color for confirm button
///
/// Returns:
/// - bool indicating user confirmation
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required bool isDarkMode,
  String? confirmText,
  String? cancelText,
  bool isDangerous = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.getCard(isDarkMode),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textWhite),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: AppColors.textGray,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText ?? 'cancel'.tr(),
            style: TextStyle(color: AppColors.textGray),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDangerous
                ? AppColors.dangerRed
                : AppColors.primary,
          ),
          child: Text(
            confirmText ?? 'delete'.tr(),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
