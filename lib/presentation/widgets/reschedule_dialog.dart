/// Todo due date rescheduling dialog.
///
/// Provides quick options to reschedule a todo's due date.
///
/// Options:
/// - [RescheduleOption.today]: Move due date to today
/// - [RescheduleOption.tomorrow]: Move due date to tomorrow
/// - [RescheduleOption.custom]: Open date picker for custom date
///
/// Returns a [RescheduleOption] indicating user's choice, or null if cancelled.
///
/// See also:
/// - [TodoDetailScreen] for reschedule trigger
/// - [todoActionsProvider] for updating the todo
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Reschedule option choices for due date modification.
enum RescheduleOption {
  today,
  tomorrow,
  custom,
}

class RescheduleDialog extends ConsumerWidget {
  const RescheduleDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Dialog(
      backgroundColor: AppColors.getCard(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  FluentIcons.calendar_arrow_right_24_regular,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'reschedule_title'.tr(),
                  style: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Options
            _RescheduleOption(
              icon: FluentIcons.calendar_today_24_regular,
              label: 'reschedule_to_today'.tr(),
              onTap: () => Navigator.of(context).pop(RescheduleOption.today),
            ),
            const SizedBox(height: 12),
            _RescheduleOption(
              icon: FluentIcons.calendar_arrow_right_24_regular,
              label: 'reschedule_to_tomorrow'.tr(),
              onTap: () => Navigator.of(context).pop(RescheduleOption.tomorrow),
            ),
            const SizedBox(height: 12),
            _RescheduleOption(
              icon: FluentIcons.calendar_edit_24_regular,
              label: 'reschedule_custom'.tr(),
              onTap: () => Navigator.of(context).pop(RescheduleOption.custom),
            ),
            const SizedBox(height: 20),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RescheduleOption extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RescheduleOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.getBackground(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.getTextSecondary(isDarkMode).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: AppColors.getText(isDarkMode),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
