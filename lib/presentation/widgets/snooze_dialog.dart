/// Notification snooze options dialog.
///
/// Allows users to postpone a notification reminder by a selected duration.
///
/// Preset options:
/// - 5 minutes
/// - 10 minutes
/// - 30 minutes
/// - 1 hour
/// - 3 hours
/// - Custom date/time picker
///
/// Returns a [Duration] representing the snooze period, or null if cancelled.
///
/// See also:
/// - [NotificationService] for rescheduling notifications
/// - [TodoDetailScreen] where snooze is triggered
library;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Dialog presenting notification snooze duration options.
class SnoozeDialog extends StatelessWidget {
  final VoidCallback? onDismiss;

  const SnoozeDialog({
    super.key,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('snooze_notification'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SnoozeOption(
            label: 'snooze_for_5_min'.tr(),
            onTap: () {
              Navigator.pop(context, const Duration(minutes: 5));
            },
          ),
          _SnoozeOption(
            label: 'snooze_for_10_min'.tr(),
            onTap: () {
              Navigator.pop(context, const Duration(minutes: 10));
            },
          ),
          _SnoozeOption(
            label: 'snooze_for_30_min'.tr(),
            onTap: () {
              Navigator.pop(context, const Duration(minutes: 30));
            },
          ),
          _SnoozeOption(
            label: 'snooze_for_1_hour'.tr(),
            onTap: () {
              Navigator.pop(context, const Duration(hours: 1));
            },
          ),
          _SnoozeOption(
            label: 'snooze_for_3_hours'.tr(),
            onTap: () {
              Navigator.pop(context, const Duration(hours: 3));
            },
          ),
          const Divider(),
          _SnoozeOption(
            label: 'snooze_custom'.tr(),
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(hours: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (selectedDate != null && context.mounted) {
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (selectedTime != null && context.mounted) {
                  final customDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final duration = customDateTime.difference(DateTime.now());
                  if (duration.isNegative) {
                    // Show error - selected time is in the past
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('error_validation'.tr()),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, duration);
                }
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDismiss?.call();
          },
          child: Text('cancel'.tr()),
        ),
      ],
    );
  }
}

class _SnoozeOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SnoozeOption({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
    );
  }
}
