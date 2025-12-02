/// Todo detail screen showing comprehensive information about a single todo.
///
/// Features:
/// - Full todo information display (title, description, dates, category)
/// - Subtask management (add, toggle, delete checklist items)
/// - Attachment viewing (images, PDFs, text files)
/// - Recurrence pattern display and management
/// - Edit functionality via [TodoFormDialog]
/// - Reschedule and snooze actions
/// - Notification scheduling preview
///
/// Navigation:
/// - Accessed via `/todo/:id` route
/// - Returns to todo list on back navigation
///
/// See also:
/// - [todoDetailProvider] for fetching todo data
/// - [subtaskProvider] for subtask management
/// - [attachmentProvider] for file attachments
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/subtask_providers.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/presentation/widgets/todo_form_dialog.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';
import 'package:todo_app/presentation/widgets/reschedule_dialog.dart';
import 'package:todo_app/presentation/widgets/snooze_dialog.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:todo_app/domain/entities/subtask.dart' as entity;
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/attachment_providers.dart';
import 'package:todo_app/domain/entities/attachment.dart' as attachment_entity;
import 'package:todo_app/presentation/widgets/image_viewer_dialog.dart';
import 'package:todo_app/presentation/widgets/pdf_viewer_dialog.dart';
import 'package:todo_app/presentation/widgets/text_viewer_dialog.dart';

/// Screen displaying detailed information about a single todo.
class TodoDetailScreen extends ConsumerWidget {
  final int todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}. ${local.month}. ${local.day}. ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final todoAsync = ref.watch(todoDetailProvider(todoId));

    // Debug logging
    todoAsync.whenData((todo) {
      print('🔍 Todo Detail Debug:');
      print('   ID: ${todo.id}');
      print('   Title: ${todo.title}');
      print('   recurrenceRule: ${todo.recurrenceRule}');
      print('   parentRecurringTodoId: ${todo.parentRecurringTodoId}');
    });

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getCard(isDarkMode),
        title: Text(
          'todo_details'.tr(),
          style: TextStyle(color: AppColors.getText(isDarkMode)),
        ),
        leading: IconButton(
          icon: Icon(
            FluentIcons.arrow_left_24_regular,
            color: AppColors.getText(isDarkMode),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          todoAsync.whenOrNull(
            data: (todo) => IconButton(
              icon: Icon(
                FluentIcons.edit_24_regular,
                color: AppColors.getText(isDarkMode),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => TodoFormDialog(existingTodo: todo),
                );
              },
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: todoAsync.when(
        data: (todo) => SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                todo.title,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: AppColors.scaledFontSize(28),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              if (todo.description.isNotEmpty) ...[
                Text(
                  todo.description,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: AppColors.scaledFontSize(16),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Created date
              _InfoRow(
                icon: FluentIcons.calendar_add_24_regular,
                label: 'created'.tr(),
                value: _formatDateTime(todo.createdAt),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),

              // Due date
              if (todo.dueDate != null) ...[
                _InfoRow(
                  icon: FluentIcons.calendar_clock_24_regular,
                  label: 'due_date'.tr(),
                  value: _formatDateTime(todo.dueDate!),
                  color: AppColors.primary,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
              ],

              // Notification time
              if (todo.notificationTime != null) ...[
                _InfoRow(
                  icon: FluentIcons.alert_24_regular,
                  label: 'notification'.tr(),
                  value: _formatDateTime(todo.notificationTime!),
                  color: AppColors.accentOrange,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),

                // Snooze button and info
                if (!todo.isCompleted && todo.notificationTime!.isAfter(DateTime.now())) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final snoozeDuration = await showDialog<Duration>(
                              context: context,
                              builder: (context) => const SnoozeDialog(),
                            );

                            if (snoozeDuration != null && context.mounted) {
                              try {
                                // Snooze the notification
                                final notificationService = NotificationService();
                                final success = await notificationService.snoozeNotification(
                                  id: todo.id,
                                  title: todo.title,
                                  body: todo.description,
                                  snoozeDuration: snoozeDuration,
                                );

                                if (success) {
                                  // Update todo with new snooze data
                                  final newNotificationTime = DateTime.now().add(snoozeDuration);
                                  final updatedTodo = todo.copyWith(
                                    notificationTime: newNotificationTime,
                                    snoozeCount: todo.snoozeCount + 1,
                                    lastSnoozeTime: DateTime.now(),
                                  );

                                  await ref.read(todoActionsProvider).updateTodo(updatedTodo);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('snooze_scheduled'.tr()),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('snooze_failed'.tr()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('error_prefix'.tr(namedArgs: {'error': e.toString()})),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(
                            FluentIcons.snooze_24_regular,
                            size: 18,
                          ),
                          label: Text('snooze_notification'.tr()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentOrange,
                            side: BorderSide(color: AppColors.accentOrange.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Show snooze count if > 0
                  if (todo.snoozeCount > 0) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'snooze_count'.tr(namedArgs: {'count': todo.snoozeCount.toString()}),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode).withValues(alpha: 0.7),
                          fontSize: AppColors.scaledFontSize(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                ],
              ],

              // Location
              if (todo.locationLatitude != null && todo.locationLongitude != null) ...[
                _InfoRow(
                  icon: FluentIcons.location_24_regular,
                  label: 'location'.tr(),
                  value: todo.locationName ?? '${todo.locationLatitude!.toStringAsFixed(6)}, ${todo.locationLongitude!.toStringAsFixed(6)}',
                  color: AppColors.primary,
                  isDarkMode: isDarkMode,
                ),
                if (todo.locationRadius != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      '${'geofence_radius'.tr()}: ${todo.locationRadius!.toInt()}m',
                      style: TextStyle(
                        color: AppColors.getTextSecondary(isDarkMode).withValues(alpha: 0.7),
                        fontSize: AppColors.scaledFontSize(14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],

              // Recurrence
              if (todo.recurrenceRule != null && todo.recurrenceRule!.isNotEmpty) ...[
                _InfoRow(
                  icon: FluentIcons.arrow_repeat_all_24_regular,
                  label: 'recurrence_settings'.tr(),
                  value: RecurrenceUtils.getDescription(todo.recurrenceRule),
                  color: AppColors.primary,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
              ],

              // Status (tappable to toggle completion)
              InkWell(
                onTap: () async {
                  try {
                    await ref.read(todoActionsProvider).toggleCompletion(todoId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('error_prefix'.tr(namedArgs: {'error': e.toString()})),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: _InfoRow(
                  icon: todo.isCompleted
                      ? FluentIcons.checkmark_circle_24_filled
                      : FluentIcons.circle_24_regular,
                  label: 'status'.tr(),
                  value: todo.isCompleted ? 'completed'.tr() : 'in_progress'.tr(),
                  color: todo.isCompleted ? Colors.green : AppColors.getTextSecondary(isDarkMode),
                  showTapHint: true,
                  isDarkMode: isDarkMode,
                ),
              ),

              // Subtasks Section
              const SizedBox(height: 24),
              _SubtasksSection(
                todoId: todoId,
                userId: ref.read(currentUserProvider).value?.uuid ?? '',
                isDarkMode: isDarkMode,
              ),

              // Attachments Section
              const SizedBox(height: 24),
              _AttachmentsSection(
                todoId: todoId,
                isDarkMode: isDarkMode,
              ),

              // Overdue warning and reschedule button
              if (todo.dueDate != null &&
                  !todo.isCompleted &&
                  todo.dueDate!.isBefore(DateTime.now())) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentOrange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FluentIcons.warning_24_filled,
                            color: AppColors.accentOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'overdue'.tr(),
                            style: TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: AppColors.scaledFontSize(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'days_overdue'.tr(namedArgs: {
                              'days': DateTime.now().difference(todo.dueDate!).inDays.toString()
                            }),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: AppColors.scaledFontSize(12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final option = await showDialog<RescheduleOption>(
                              context: context,
                              builder: (context) => const RescheduleDialog(),
                            );

                            if (option != null && context.mounted) {
                              DateTime? newDate;

                              switch (option) {
                                case RescheduleOption.today:
                                  newDate = DateTime.now();
                                  break;
                                case RescheduleOption.tomorrow:
                                  newDate = DateTime.now().add(const Duration(days: 1));
                                  break;
                                case RescheduleOption.custom:
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: ColorScheme.dark(
                                            primary: AppColors.primary,
                                            surface: AppColors.getCard(isDarkMode),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    newDate = picked;
                                  }
                                  break;
                              }

                              if (newDate != null && context.mounted) {
                                try {
                                  await ref.read(todoActionsProvider).rescheduleTodo(
                                        todoId,
                                        newDate,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('rescheduled'.tr()),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('error_prefix'.tr(namedArgs: {'error': e.toString()})),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          icon: Icon(
                            FluentIcons.calendar_arrow_right_24_regular,
                            size: 18,
                          ),
                          label: Text('reschedule'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.getText(isDarkMode),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Completed date
              if (todo.completedAt != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: FluentIcons.checkmark_circle_24_filled,
                  label: 'completed_at'.tr(),
                  value: _formatDateTime(todo.completedAt!),
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                ),
              ],
            ],
          ),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'error_prefix'.tr(namedArgs: {'error': error.toString()}),
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool showTapHint;
  final bool isDarkMode;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
    this.color,
    this.showTapHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.getTextSecondary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: effectiveColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: AppColors.scaledFontSize(12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: AppColors.scaledFontSize(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showTapHint)
            Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _SubtasksSection extends ConsumerStatefulWidget {
  final int todoId;
  final String userId;
  final bool isDarkMode;

  const _SubtasksSection({
    required this.todoId,
    required this.userId,
    required this.isDarkMode,
  });

  @override
  ConsumerState<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends ConsumerState<_SubtasksSection> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addSubtask() async {
    if (_titleController.text.trim().isEmpty) return;

    final subtasksAsync = ref.read(subtaskListProvider(widget.todoId));
    final existingSubtasks = subtasksAsync.value ?? [];
    final nextPosition = existingSubtasks.length;

    final newSubtask = entity.Subtask(
      id: 0, // Will be generated by database
      todoId: widget.todoId,
      userId: widget.userId,
      title: _titleController.text.trim(),
      isCompleted: false,
      position: nextPosition,
      createdAt: DateTime.now(),
    );

    await ref.read(subtaskActionsProvider).createSubtask(newSubtask);
    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(subtaskListProvider(widget.todoId));
    final statsAsync = ref.watch(subtaskStatsProvider(widget.todoId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(widget.isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                FluentIcons.task_list_square_ltr_24_regular,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'subtasks'.tr(),
                style: TextStyle(
                  color: AppColors.getText(widget.isDarkMode),
                  fontSize: AppColors.scaledFontSize(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              statsAsync.when(
                data: (stats) => Text(
                  'subtasks_completed'.tr(namedArgs: {
                    'completed': '${stats['completed']}',
                    'total': '${stats['total']}',
                  }),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(widget.isDarkMode),
                    fontSize: AppColors.scaledFontSize(12),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtask list
          subtasksAsync.when(
            data: (subtasks) {
              if (subtasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'no_subtasks'.tr(),
                      style: TextStyle(
                        color: AppColors.getTextSecondary(widget.isDarkMode),
                        fontSize: AppColors.scaledFontSize(14),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: subtasks
                    .map<Widget>((subtask) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SubtaskItem(
                          subtask: subtask,
                          isDarkMode: widget.isDarkMode,
                          onToggle: () {
                            ref.read(subtaskActionsProvider).toggleSubtaskCompletion(
                                  subtask.id,
                                  widget.todoId,
                                );
                          },
                          onDelete: () {
                            ref.read(subtaskActionsProvider).deleteSubtask(
                                  subtask.id,
                                  widget.todoId,
                                );
                          },
                        ),
                      );
                    })
                    .toList(),
              );
            },
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'error'.tr() + ': $error',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Add subtask input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(color: AppColors.getText(widget.isDarkMode)),
                  decoration: InputDecoration(
                    hintText: 'subtask_title_hint'.tr(),
                    hintStyle: TextStyle(color: AppColors.getTextSecondary(widget.isDarkMode)),
                    filled: true,
                    fillColor: AppColors.getBackground(widget.isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _addSubtask(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addSubtask,
                icon: Icon(
                  FluentIcons.add_circle_24_filled,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubtaskItem extends StatelessWidget {
  final entity.Subtask subtask;
  final bool isDarkMode;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubtaskItem({
    required this.subtask,
    required this.isDarkMode,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBackground(isDarkMode),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: IconButton(
          icon: Icon(
            subtask.isCompleted
                ? FluentIcons.checkbox_checked_24_filled
                : FluentIcons.checkbox_unchecked_24_regular,
            color: subtask.isCompleted ? Colors.green : AppColors.getTextSecondary(isDarkMode),
          ),
          onPressed: onToggle,
        ),
        title: Text(
          subtask.title,
          style: TextStyle(
            color: subtask.isCompleted
                ? AppColors.getTextSecondary(isDarkMode)
                : AppColors.getText(isDarkMode),
            decoration:
                subtask.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            FluentIcons.delete_24_regular,
            color: Colors.red,
            size: 20,
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.getCard(isDarkMode),
                title: Text(
                  'delete_subtask'.tr(),
                  style: TextStyle(color: AppColors.getText(isDarkMode)),
                ),
                content: Text(
                  'confirm_delete_subtask'.tr(),
                  style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'cancel'.tr(),
                      style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'delete'.tr(),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              onDelete();
            }
          },
        ),
      ),
    );
  }
}

class _AttachmentsSection extends ConsumerWidget {
  final int todoId;
  final bool isDarkMode;

  const _AttachmentsSection({
    required this.todoId,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(attachmentListProvider(todoId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                FluentIcons.attach_24_regular,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'attachments'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: AppColors.scaledFontSize(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              attachmentsAsync.whenOrNull(
                data: (attachments) => Text(
                  '${attachments.length}',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: AppColors.scaledFontSize(12),
                  ),
                ),
              ) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),

          // Attachment list
          attachmentsAsync.when(
            data: (attachments) {
              if (attachments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'no_attachments'.tr(),
                      style: TextStyle(
                        color: AppColors.getTextSecondary(isDarkMode),
                        fontSize: AppColors.scaledFontSize(14),
                      ),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: attachments.length,
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  return _AttachmentItem(
                    attachment: attachment,
                    isDarkMode: isDarkMode,
                    todoId: todoId,
                    onTap: () {
                      if (attachment.mimeType.startsWith('image/')) {
                        // Show image viewer for images
                        showDialog(
                          context: context,
                          builder: (context) => ImageViewerDialog(
                            attachment: attachment,
                          ),
                        );
                      } else if (attachment.mimeType.contains('pdf')) {
                        // Show PDF viewer for PDF files
                        showDialog(
                          context: context,
                          builder: (context) => PdfViewerDialog(
                            attachment: attachment,
                          ),
                        );
                      } else if (_isTextFile(attachment.mimeType, attachment.fileName)) {
                        // Show text viewer for text files
                        showDialog(
                          context: context,
                          builder: (context) => TextViewerDialog(
                            attachment: attachment,
                          ),
                        );
                      } else {
                        // For other file types, show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('file_preview_not_supported'.tr(namedArgs: {'fileName': attachment.fileName})),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'error'.tr() + ': $error',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to check if file is a text file
  bool _isTextFile(String mimeType, String fileName) {
    // Check MIME type
    if (mimeType.startsWith('text/')) {
      return true;
    }

    // Check file extension for common text files
    final extension = fileName.toLowerCase().split('.').last;
    const textExtensions = [
      'txt', 'md', 'json', 'xml', 'html', 'css', 'js', 'ts',
      'dart', 'java', 'kt', 'swift', 'py', 'rb', 'php', 'c', 'cpp',
      'h', 'hpp', 'cs', 'go', 'rs', 'yaml', 'yml', 'toml', 'ini',
      'conf', 'config', 'log', 'csv', 'sql', 'sh', 'bash'
    ];

    return textExtensions.contains(extension);
  }
}

class _AttachmentItem extends ConsumerWidget {
  final attachment_entity.Attachment attachment;
  final bool isDarkMode;
  final VoidCallback onTap;
  final int todoId;

  const _AttachmentItem({
    required this.attachment,
    required this.isDarkMode,
    required this.onTap,
    required this.todoId,
  });

  IconData _getFileIcon() {
    if (attachment.mimeType.startsWith('image/')) {
      return FluentIcons.image_24_filled;
    } else if (attachment.mimeType.startsWith('video/')) {
      return FluentIcons.video_24_filled;
    } else if (attachment.mimeType.contains('pdf')) {
      return FluentIcons.document_pdf_24_filled;
    } else if (attachment.mimeType.contains('word') ||
               attachment.mimeType.contains('document')) {
      return FluentIcons.document_24_filled;
    } else if (attachment.mimeType.contains('excel') ||
               attachment.mimeType.contains('spreadsheet')) {
      return FluentIcons.document_table_24_filled;
    } else {
      return FluentIcons.document_24_regular;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.getBackground(isDarkMode),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.getTextSecondary(isDarkMode).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getFileIcon(),
                  color: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    attachment.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: AppColors.scaledFontSize(11),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(attachment.fileSize),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: AppColors.scaledFontSize(9),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Delete button overlay
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _showDeleteConfirmation(context, ref),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(
                FluentIcons.dismiss_24_filled,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_attachment'.tr()),
        content: Text('confirm_delete_attachment'.tr(namedArgs: {'fileName': attachment.fileName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAttachment(context, ref);
            },
            child: Text(
              'delete'.tr(),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttachment(BuildContext context, WidgetRef ref) async {
    try {
      final actions = ref.read(attachmentActionsProvider);
      await actions.deleteAttachment(
        attachment.id,
        todoId,
        attachment.storagePath,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('attachment_deleted_successfully'.tr(namedArgs: {'fileName': attachment.fileName})),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_delete_attachment'.tr(namedArgs: {'error': e.toString()})),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
