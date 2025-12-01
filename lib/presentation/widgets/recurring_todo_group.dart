/// Recurring todo group widget.
///
/// Displays a group of recurring todos with expandable/collapsible behavior.
/// Shows a summary header with completion progress and individual todos when expanded.
///
/// Example:
/// ```dart
/// RecurringTodoGroup(
///   todos: recurringTodos,
///   onToggle: (todo) { /* handle todo completion */ },
///   onDelete: (todo) { /* handle todo deletion */ },
///   onTap: (todo) { /* handle todo selection */ },
/// )
/// ```
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/widgets/custom_todo_item.dart';

/// Widget for displaying a group of recurring todos.
///
/// Shows an expandable header with group information and individual todo items.
class RecurringTodoGroup extends ConsumerStatefulWidget {
  /// List of todos in this recurring group
  final List<Todo> todos;

  /// Callback when a todo's completion status is toggled
  final Function(Todo) onToggle;

  /// Callback when a todo is deleted
  final Function(Todo) onDelete;

  /// Callback when a todo is tapped
  final Function(Todo) onTap;

  const RecurringTodoGroup({
    super.key,
    required this.todos,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  ConsumerState<RecurringTodoGroup> createState() => _RecurringTodoGroupState();
}

class _RecurringTodoGroupState extends ConsumerState<RecurringTodoGroup> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    if (widget.todos.isEmpty) return const SizedBox.shrink();

    final firstTodo = widget.todos.first;
    final completedCount = widget.todos.where((t) => t.isCompleted).length;
    final totalCount = widget.todos.length;

    return Column(
      children: [
        // Group header
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.getCard(isDarkMode),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Expand/collapse icon
                    Icon(
                      _isExpanded
                          ? FluentIcons.chevron_down_24_filled
                          : FluentIcons.chevron_right_24_filled,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),

                    // Recurring icon
                    const Icon(
                      FluentIcons.arrow_repeat_all_24_filled,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),

                    // Title and info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstTodo.title,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'recurring_event_progress'.tr(namedArgs: {
                              'completed': completedCount.toString(),
                              'total': totalCount.toString(),
                            }),
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Expanded list
        if (_isExpanded)
          ...widget.todos.map((todo) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: CustomTodoItem(
              key: ValueKey(todo.id),
              todo: todo,
              onToggle: () => widget.onToggle(todo),
              onDelete: () => widget.onDelete(todo),
              onTap: () => widget.onTap(todo),
            ),
          )),
      ],
    );
  }
}
