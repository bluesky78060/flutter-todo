import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/core/theme/app_colors.dart';

/// Dialog to ask user how to delete a recurring todo instance
///
/// Options:
/// - Delete only this instance
/// - Delete this and future instances
/// - Delete entire series (master and all instances)
class RecurringDeleteDialog extends StatelessWidget {
  const RecurringDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkCard,
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
              'delete_recurring_event'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'delete_recurring_message'.tr(),
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Delete only this instance
            _buildOption(
              context,
              title: 'delete_only_this'.tr(),
              description: 'delete_only_this_desc'.tr(),
              onTap: () => Navigator.of(context).pop(RecurringDeleteMode.thisOnly),
            ),
            const SizedBox(height: 12),

            // Option 2: Delete this and future instances
            _buildOption(
              context,
              title: 'delete_this_and_future'.tr(),
              description: 'delete_this_and_future_desc'.tr(),
              onTap: () => Navigator.of(context).pop(RecurringDeleteMode.thisAndFuture),
            ),
            const SizedBox(height: 12),

            // Option 3: Delete entire series
            _buildOption(
              context,
              title: 'delete_entire_series'.tr(),
              description: 'delete_entire_series_desc'.tr(),
              onTap: () => Navigator.of(context).pop(RecurringDeleteMode.entireSeries),
              isDestructive: true,
            ),
            const SizedBox(height: 24),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textGray,
                  side: const BorderSide(
                    color: AppColors.darkBorder,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'cancel'.tr(),
                  style: const TextStyle(
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
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.dangerRed.withOpacity(0.1)
              : AppColors.darkInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? AppColors.dangerRed.withOpacity(0.3)
                : AppColors.darkBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? AppColors.dangerRed : AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enum for recurring delete modes
enum RecurringDeleteMode {
  /// Delete only this instance (remove from series)
  thisOnly,

  /// Delete this and all future instances (keep past instances)
  thisAndFuture,

  /// Delete entire series (master and all instances)
  entireSeries,
}
