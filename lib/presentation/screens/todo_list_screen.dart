import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/screens/settings_screen.dart';
import 'package:todo_app/presentation/screens/statistics_screen.dart';
import 'package:todo_app/presentation/widgets/custom_todo_item.dart';
import 'package:todo_app/presentation/widgets/todo_form_dialog.dart';

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addTodoFromInput() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    ref.read(todoActionsProvider).createTodo(text, '', null);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todosProvider);
    final currentFilter = ref.watch(todoFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.darkHeaderGradient,
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'todo_list'.tr(),
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'keep_it_up'.tr(),
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Refresh Button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.darkBorder.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ref.invalidate(todosProvider);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    FluentIcons.arrow_clockwise_24_regular,
                                    color: AppColors.textGray,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Add Button
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (context) => const TodoFormDialog(),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    FluentIcons.add_24_filled,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  todosAsync.when(
                    data: (allTodos) {
                      final activeCount =
                          allTodos.where((t) => !t.isCompleted).length;
                      final completedCount =
                          allTodos.where((t) => t.isCompleted).length;
                      final totalCount = allTodos.length;

                      return Row(
                        children: [
                          Expanded(
                            child: _FilterChip(
                              label: 'filter_all'.tr(),
                              count: totalCount,
                              isSelected: currentFilter == TodoFilter.all,
                              onTap: () => ref
                                  .read(todoFilterProvider.notifier)
                                  .setFilter(TodoFilter.all),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterChip(
                              label: 'filter_pending'.tr(),
                              count: activeCount,
                              isSelected: currentFilter == TodoFilter.pending,
                              onTap: () => ref
                                  .read(todoFilterProvider.notifier)
                                  .setFilter(TodoFilter.pending),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterChip(
                              label: 'filter_completed'.tr(),
                              count: completedCount,
                              isSelected: currentFilter == TodoFilter.completed,
                              onTap: () => ref
                                  .read(todoFilterProvider.notifier)
                                  .setFilter(TodoFilter.completed),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Quick Add Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkInput,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _inputController,
                  onSubmitted: (_) => _addTodoFromInput(),
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'title_hint'.tr(),
                    hintStyle: const TextStyle(
                      color: AppColors.textGray,
                    ),
                    prefixIcon: const Icon(
                      FluentIcons.add_24_regular,
                      color: AppColors.textGray,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Todo List
            Expanded(
              child: todosAsync.when(
                data: (todos) {
                  if (todos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FluentIcons.task_list_square_ltr_24_regular,
                            size: 64,
                            color: AppColors.textGray.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentFilter == TodoFilter.all
                                ? 'no_todos'.tr()
                                : currentFilter == TodoFilter.pending
                                    ? 'no_pending_todos'.tr()
                                    : 'no_completed_todos'.tr(),
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return CustomTodoItem(
                        key: ValueKey(todo.id),
                        todo: todo,
                        onToggle: () => ref
                            .read(todoActionsProvider)
                            .toggleCompletion(todo.id),
                        onDelete: () => ref
                            .read(todoActionsProvider)
                            .deleteTodo(todo.id),
                        onTap: () => context.go('/todos/${todo.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FluentIcons.error_circle_24_regular,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${'error'}: $error',
                        style: const TextStyle(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                border: Border(
                  top: BorderSide(
                    color: AppColors.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: FluentIcons.task_list_square_ltr_24_filled,
                            label: 'todos'.tr(),
                            isActive: true,
                            onTap: () {},
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: FluentIcons.data_histogram_24_regular,
                            label: 'statistics'.tr(),
                            isActive: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StatisticsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: FluentIcons.settings_24_regular,
                            label: 'settings'.tr(),
                            isActive: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkInput,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textWhite : AppColors.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(3),
                    ),
                  ),
                )
              else
                const SizedBox(height: 7),
              Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.textWhite : AppColors.textGray,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.textWhite : AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
