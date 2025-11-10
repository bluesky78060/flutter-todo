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
    final isKorean = context.locale.languageCode == 'ko';

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
              isKorean ? '반복 일정 삭제' : 'Delete Recurring Event',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              isKorean
                  ? '이 일정은 반복 일정입니다. 어떻게 삭제하시겠습니까?'
                  : 'This is a recurring event. How would you like to delete it?',
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Delete only this instance
            _buildOption(
              context,
              title: isKorean ? '이 일정만' : 'Only this event',
              description: isKorean ? '이 일정만 삭제합니다' : 'Delete only this event',
              onTap: () => Navigator.of(context).pop(RecurringDeleteMode.thisOnly),
            ),
            const SizedBox(height: 12),

            // Option 2: Delete this and future instances
            _buildOption(
              context,
              title: isKorean ? '이 일정 및 향후 일정' : 'This and future events',
              description: isKorean
                  ? '이 일정과 이후의 모든 반복 일정을 삭제합니다'
                  : 'Delete this and all future recurring events',
              onTap: () => Navigator.of(context).pop(RecurringDeleteMode.thisAndFuture),
            ),
            const SizedBox(height: 12),

            // Option 3: Delete entire series
            _buildOption(
              context,
              title: isKorean ? '전체 시리즈' : 'Entire series',
              description: isKorean
                  ? '모든 반복 일정을 삭제합니다'
                  : 'Delete all recurring events in the series',
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
                  isKorean ? '취소' : 'Cancel',
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
