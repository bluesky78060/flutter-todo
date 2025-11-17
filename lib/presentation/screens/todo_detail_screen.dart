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

class TodoDetailScreen extends ConsumerWidget {
  final int todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}. ${dateTime.month}. ${dateTime.day}. ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        title: Text(
          'todo_details'.tr(),
          style: const TextStyle(color: AppColors.textWhite),
        ),
        leading: IconButton(
          icon: const Icon(
            FluentIcons.arrow_left_24_regular,
            color: AppColors.textWhite,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          todoAsync.whenOrNull(
            data: (todo) => IconButton(
              icon: const Icon(
                FluentIcons.edit_24_regular,
                color: AppColors.textWhite,
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
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              if (todo.description.isNotEmpty) ...[
                Text(
                  todo.description,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Created date
              _InfoRow(
                icon: FluentIcons.calendar_add_24_regular,
                label: 'created'.tr(),
                value: _formatDateTime(todo.createdAt),
              ),
              const SizedBox(height: 12),

              // Due date
              if (todo.dueDate != null) ...[
                _InfoRow(
                  icon: FluentIcons.calendar_clock_24_regular,
                  label: 'due_date'.tr(),
                  value: _formatDateTime(todo.dueDate!),
                  color: AppColors.primaryBlue,
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
                                      const SnackBar(
                                        content: Text('스누즈 설정에 실패했습니다'),
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
                          icon: const Icon(
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
                          color: AppColors.textGray.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                ],
              ],

              // Recurrence
              if (todo.recurrenceRule != null && todo.recurrenceRule!.isNotEmpty) ...[
                _InfoRow(
                  icon: FluentIcons.arrow_repeat_all_24_regular,
                  label: 'recurrence_settings'.tr(),
                  value: RecurrenceUtils.getDescription(todo.recurrenceRule),
                  color: AppColors.primaryBlue,
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
                  color: todo.isCompleted ? Colors.green : AppColors.textGray,
                  showTapHint: true,
                ),
              ),

              // Subtasks Section
              const SizedBox(height: 24),
              _SubtasksSection(
                todoId: todoId,
                userId: ref.read(currentUserProvider).value?.uuid ?? '',
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'days_overdue'.tr(namedArgs: {
                              'days': DateTime.now().difference(todo.dueDate!).inDays.toString()
                            }),
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 12,
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
                                          colorScheme: const ColorScheme.dark(
                                            primary: AppColors.primaryBlue,
                                            surface: AppColors.darkCard,
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
                          icon: const Icon(
                            FluentIcons.calendar_arrow_right_24_regular,
                            size: 18,
                          ),
                          label: Text('reschedule'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.textWhite,
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
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'error_prefix'.tr(namedArgs: {'error': error.toString()}),
            style: const TextStyle(color: Colors.red),
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.showTapHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textGray;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
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
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showTapHint)
            Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.textGray,
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

  const _SubtasksSection({
    required this.todoId,
    required this.userId,
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
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                FluentIcons.task_list_square_ltr_24_regular,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'subtasks'.tr(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
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
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
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
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 14,
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
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'error'.tr() + ': $error',
                style: const TextStyle(color: Colors.red),
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
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'subtask_title_hint'.tr(),
                    hintStyle: const TextStyle(color: AppColors.textGray),
                    filled: true,
                    fillColor: AppColors.darkBackground,
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
                icon: const Icon(
                  FluentIcons.add_circle_24_filled,
                  color: AppColors.primaryBlue,
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
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubtaskItem({
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: IconButton(
          icon: Icon(
            subtask.isCompleted
                ? FluentIcons.checkbox_checked_24_filled
                : FluentIcons.checkbox_unchecked_24_regular,
            color: subtask.isCompleted ? Colors.green : AppColors.textGray,
          ),
          onPressed: onToggle,
        ),
        title: Text(
          subtask.title,
          style: TextStyle(
            color: subtask.isCompleted
                ? AppColors.textGray
                : AppColors.textWhite,
            decoration:
                subtask.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            FluentIcons.delete_24_regular,
            color: Colors.red,
            size: 20,
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.darkCard,
                title: Text(
                  'delete_subtask'.tr(),
                  style: const TextStyle(color: AppColors.textWhite),
                ),
                content: Text(
                  'confirm_delete_subtask'.tr(),
                  style: const TextStyle(color: AppColors.textGray),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'cancel'.tr(),
                      style: const TextStyle(color: AppColors.textGray),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'delete'.tr(),
                      style: const TextStyle(color: Colors.red),
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
