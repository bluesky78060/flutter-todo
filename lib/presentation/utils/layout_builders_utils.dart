/// Layout builder utilities for todo list screen UI sections.
///
/// Provides reusable widget builder functions to reduce complexity
/// in _buildPhoneView and _buildSplitView methods.
///
/// Functions:
/// - [buildHeaderSection] - Title, subtitle, and action buttons
/// - [buildFilterChips] - Filter chips (All, Pending, Completed)
/// - [buildSearchBar] - Search input with clear functionality
/// - [buildCategoryFilter] - Horizontal scrollable category filter
/// - [buildQuickAddInput] - Quick todo input field
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/color_utils.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/widgets/filter_chip.dart' as todo_widgets;
import 'package:todo_app/presentation/widgets/category_chip.dart';
import 'package:todo_app/presentation/widgets/todo_form_dialog.dart';
import 'package:todo_app/presentation/widgets/nav_item.dart';
import 'package:todo_app/presentation/widgets/offline_banner.dart';

/// Builds the header section with title, subtitle, and action buttons.
///
/// Parameters:
/// - [isDarkMode]: Theme mode flag
/// - [context]: Build context for navigation
/// - [ref]: Riverpod reference for state management
/// - [handleClearCompleted]: Callback for clear completed button
///
/// Returns:
/// - Header widget with title, subtitle, and 4 action buttons
Widget buildHeaderSection({
  required bool isDarkMode,
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback handleClearCompleted,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: AppColors.getHeaderGradient(isDarkMode),
    ),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'todo_list'.tr(),
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'keep_it_up'.tr(),
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDarkMode),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const ConnectionStatusWidget(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                // Refresh Button
                _buildHeaderActionButton(
                  isDarkMode: isDarkMode,
                  icon: FluentIcons.arrow_clockwise_24_regular,
                  onTap: () {
                    ref.invalidate(todosProvider);
                  },
                ),
                const SizedBox(width: 8),
                // Clear Completed Button
                _buildHeaderActionButton(
                  isDarkMode: isDarkMode,
                  icon: FluentIcons.delete_24_regular,
                  onTap: handleClearCompleted,
                ),
                const SizedBox(width: 8),
                // Calendar Button
                _buildHeaderActionButton(
                  isDarkMode: isDarkMode,
                  icon: FluentIcons.calendar_24_regular,
                  onTap: () {
                    context.go('/calendar');
                  },
                ),
                const SizedBox(width: 8),
                // Add Button
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
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
                        builder: (context) {
                          return const TodoFormDialog();
                        },
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
      ],
    ),
  );
}

/// Helper widget for building standard header action buttons.
class _buildHeaderActionButton extends StatelessWidget {
  final bool isDarkMode;
  final IconData icon;
  final VoidCallback onTap;

  const _buildHeaderActionButton({
    required this.isDarkMode,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDarkMode).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: AppColors.getTextSecondary(isDarkMode),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}


/// Builds the filter chips section (All, Pending, Completed).
///
/// Parameters:
/// - [todosAsync]: Async todos data for calculating counts
/// - [currentFilter]: Current selected filter
/// - [ref]: Riverpod reference for state management
///
/// Returns:
/// - Row widget with three filter chips
Widget buildFilterChips({
  required AsyncValue<List<Todo>> todosAsync,
  required TodoFilter currentFilter,
  required WidgetRef ref,
}) {
  return todosAsync.when(
    data: (allTodos) {
      final activeCount = allTodos.where((t) => !t.isCompleted).length;
      final completedCount = allTodos.where((t) => t.isCompleted).length;
      final totalCount = allTodos.length;

      return Row(
        children: [
          Expanded(
            child: todo_widgets.TodoFilterChip(
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
            child: todo_widgets.TodoFilterChip(
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
            child: todo_widgets.TodoFilterChip(
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
  );
}

/// Builds the search bar with clear functionality.
///
/// Parameters:
/// - [isDarkMode]: Theme mode flag
/// - [searchController]: Text controller for search input
/// - [ref]: Riverpod reference for state management
///
/// Returns:
/// - Container with search TextField and clear button
Widget buildSearchBar({
  required bool isDarkMode,
  required TextEditingController searchController,
  required WidgetRef ref,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.getInput(isDarkMode),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.getBorder(isDarkMode).withValues(alpha: 0.5),
        width: 1,
      ),
    ),
    child: ValueListenableBuilder<TextEditingValue>(
      valueListenable: searchController,
      builder: (context, value, child) {
        return TextField(
          controller: searchController,
          style: TextStyle(
            color: AppColors.getText(isDarkMode),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'search_todos'.tr(),
            hintStyle: TextStyle(
              color: AppColors.getTextSecondary(isDarkMode),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              FluentIcons.search_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
              size: 20,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      FluentIcons.dismiss_circle_24_filled,
                      color: AppColors.getTextSecondary(isDarkMode),
                      size: 20,
                    ),
                    onPressed: () {
                      searchController.clear();
                      ref.read(searchQueryProvider.notifier).clearQuery();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      },
    ),
  );
}

/// Builds the category filter with horizontal scroll.
///
/// Parameters:
/// - [ref]: Riverpod reference for state management
///
/// Returns:
/// - Horizontal scrollable list of category chips
Widget buildCategoryFilter({
  required WidgetRef ref,
}) {
  return ref.watch(categoriesProvider).when(
    data: (categories) {
      if (categories.isEmpty) return const SizedBox.shrink();

      final selectedCategoryId = ref.watch(categoryFilterProvider);

      return Container(
        height: 50,
        margin: const EdgeInsets.only(top: 12),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // All categories chip
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: 'all'.tr(),
                icon: null,
                color: null,
                isSelected: selectedCategoryId == null,
                onTap: () => ref
                    .read(categoryFilterProvider.notifier)
                    .clearCategory(),
              ),
            ),
            // Individual category chips
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  label: category.name,
                  icon: category.icon,
                  color: ColorUtils.parseColor(category.color),
                  isSelected: selectedCategoryId == category.id,
                  onTap: () => ref
                      .read(categoryFilterProvider.notifier)
                      .setCategory(category.id),
                ),
              );
            }),
          ],
        ),
      );
    },
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
  );
}

/// Builds the quick add input field.
///
/// Parameters:
/// - [isDarkMode]: Theme mode flag
/// - [inputController]: Text controller for input
/// - [onSubmitted]: Callback when user submits text
///
/// Returns:
/// - Padding-wrapped container with TextField
Widget buildQuickAddInput({
  required bool isDarkMode,
  required TextEditingController inputController,
  required VoidCallback onSubmitted,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.getInput(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: inputController,
        onSubmitted: (_) => onSubmitted(),
        style: TextStyle(
          color: AppColors.getText(isDarkMode),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'title_hint'.tr(),
          hintStyle: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
          ),
          prefixIcon: Icon(
            FluentIcons.add_24_regular,
            color: AppColors.getTextSecondary(isDarkMode),
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
  );
}
