import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class TodoDetailScreen extends ConsumerWidget {
  final int todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}. ${dateTime.month}. ${dateTime.day}. ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoDetailProvider(todoId));

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

              // Status
              _InfoRow(
                icon: todo.isCompleted
                    ? FluentIcons.checkmark_circle_24_filled
                    : FluentIcons.circle_24_regular,
                label: '상태',
                value: todo.isCompleted ? '완료' : '진행중',
                color: todo.isCompleted ? Colors.green : AppColors.textGray,
              ),

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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
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
        ],
      ),
    );
  }
}
