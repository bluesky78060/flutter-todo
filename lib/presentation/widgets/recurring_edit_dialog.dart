/// Recurring todo edit mode selection dialog.
///
/// When editing a recurring todo instance, this dialog asks the user
/// how the edit should be applied.
///
/// Options:
/// - [RecurringEditMode.thisOnly]: Edit only the current instance (detach from series)
/// - [RecurringEditMode.thisAndFuture]: Edit this and all future instances (update master)
///
/// Returns a [RecurringEditMode] value, or null if cancelled.
///
/// See also:
/// - [RecurringDeleteDialog] for delete options on recurring todos
/// - [TodoFormDialog] where this dialog is triggered
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

/// Dialog to ask user how to edit a recurring todo instance.
///
/// Options:
/// - Edit only this instance
/// - Edit this and future instances
/// - Cancel
class RecurringEditDialog extends ConsumerWidget {
  const RecurringEditDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Dialog(
      backgroundColor: AppColors.getCard(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'edit_recurring_event'.tr(),
              style: TextStyle(
                color: AppColors.getText(isDarkMode),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // Description
            Text(
              'edit_recurring_message'.tr(),
              style: TextStyle(
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Edit only this instance
            _buildOption(
              context,
              isDarkMode: isDarkMode,
              title: 'edit_only_this'.tr(),
              description: 'edit_only_this_desc'.tr(),
              onTap: () => Navigator.of(context).pop(RecurringEditMode.thisOnly),
            ),
            SizedBox(height: 12),

            // Option 2: Edit this and future instances
            _buildOption(
              context,
              isDarkMode: isDarkMode,
              title: 'edit_this_and_future'.tr(),
              description: 'edit_this_and_future_desc'.tr(),
              onTap: () => Navigator.of(context).pop(RecurringEditMode.thisAndFuture),
            ),
            const SizedBox(height: 24),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getTextSecondary(isDarkMode),
                  side: BorderSide(
                    color: AppColors.getBorder(isDarkMode),
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'cancel'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required bool isDarkMode,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getInput(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.getBorder(isDarkMode),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.getText(isDarkMode),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enum for recurring edit modes
enum RecurringEditMode {
  /// Edit only this instance (detach from series)
  thisOnly,

  /// Edit this and all future instances (update master)
  thisAndFuture,
}
