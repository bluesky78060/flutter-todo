import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/presentation/widgets/todo_form_dialog.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';
import 'package:todo_app/presentation/widgets/reschedule_dialog.dart';
import 'package:easy_localization/easy_localization.dart';

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
        title: const Text(
          '할일 상세',
          style: TextStyle(color: AppColors.textWhite),
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
                label: '생성일',
                value: _formatDateTime(todo.createdAt),
              ),
              const SizedBox(height: 12),

              // Due date
              if (todo.dueDate != null) ...[
                _InfoRow(
                  icon: FluentIcons.calendar_clock_24_regular,
                  label: '마감일',
                  value: _formatDateTime(todo.dueDate!),
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 12),
              ],

              // Notification time
              if (todo.notificationTime != null) ...[
                _InfoRow(
                  icon: FluentIcons.alert_24_regular,
                  label: '알림',
                  value: _formatDateTime(todo.notificationTime!),
                  color: AppColors.accentOrange,
                ),
                const SizedBox(height: 12),
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
                          content: Text('오류: $e'),
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
                  label: '상태',
                  value: todo.isCompleted ? '완료' : '진행중',
                  color: todo.isCompleted ? Colors.green : AppColors.textGray,
                  showTapHint: true,
                ),
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
                            '마감일이 지났습니다',
                            style: TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${DateTime.now().difference(todo.dueDate!).inDays}일 지남)',
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
                                      const SnackBar(
                                        content: Text('일정이 이월되었습니다'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('오류: $e'),
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
                          label: const Text('일정 이월하기'),
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
                  label: '완료일',
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
            '오류: $error',
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
