import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/services/battery_optimization_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/screens/settings_screen.dart';
import 'package:todo_app/presentation/screens/statistics_screen.dart';
import 'package:todo_app/presentation/widgets/custom_todo_item.dart';
import 'package:todo_app/presentation/widgets/todo_form_dialog.dart';
import 'package:todo_app/presentation/widgets/recurring_delete_dialog.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';
import 'package:todo_app/core/utils/color_utils.dart';

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isRequestingPermissions = false; // 중복 요청 방지 플래그
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // Setup search debounce
    _searchController.addListener(_onSearchChanged);

    // Activity context가 준비된 후 권한 요청 (첫 실행 시에만)
    // 추가 지연을 둬서 Activity가 완전히 준비되도록 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndRequestPermissions();
        }
      });
    });
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer (500ms debounce)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).setQuery(_searchController.text);
      }
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    if (kIsWeb) return; // Web에서는 권한 요청 불필요
    if (_isRequestingPermissions) return; // 이미 요청 중이면 중단

    _isRequestingPermissions = true;

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final hasAsked = prefs.getBool('notification_permission_asked') ?? false;

      if (!hasAsked && mounted) {
        // 1단계: 알림 권한 요청
        await _requestNotificationPermission();

        // 짧은 지연 후 다음 권한 요청
        await Future.delayed(const Duration(milliseconds: 300));

        // 2단계: 정확한 알람 권한 요청 (Android 14+)
        if (mounted) {
          await _requestExactAlarmPermission();
        }

        await Future.delayed(const Duration(milliseconds: 300));

        // 3단계: 배터리 최적화 제외 요청
        if (mounted) {
          await _requestBatteryOptimization();
        }

        await prefs.setBool('notification_permission_asked', true);
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    } finally {
      _isRequestingPermissions = false;
    }
  }

  Future<void> _requestNotificationPermission() async {
    final notificationService = NotificationService();
    final isEnabled = await notificationService.areNotificationsEnabled();

    if (!isEnabled && mounted) {
      final isDark = ref.read(isDarkModeProvider);
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.getCard(isDark),
          title: Text(
            'permission_notification_title'.tr(),
            style: const TextStyle(color: AppColors.textWhite),
          ),
          content: Text(
            'permission_notification_desc'.tr(),
            style: const TextStyle(color: AppColors.textGray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('deny'.tr(), style: const TextStyle(color: AppColors.textGray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: Text('allow'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        await notificationService.requestPermissions();

        // 권한 허용 후 설정 화면 안내
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _showNotificationSettingsGuide();
        }
      }
    }
  }

  Future<void> _showNotificationSettingsGuide() async {
    final isDark = ref.read(isDarkModeProvider);
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        title: Row(
          children: [
            const Icon(FluentIcons.info_24_regular, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Text(
              'notification_settings'.tr(),
              style: const TextStyle(color: AppColors.textWhite),
            ),
          ],
        ),
        content: Text(
          'permission_notification_rationale'.tr(),
          style: const TextStyle(color: AppColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('deny'.tr(), style: const TextStyle(color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('settings_open'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      final notificationService = NotificationService();
      await notificationService.openNotificationSettings();
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      final isIgnoring = await BatteryOptimizationService.isIgnoringBatteryOptimizations();

      if (!isIgnoring && mounted) {
        final isDark = ref.read(isDarkModeProvider);
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.getCard(isDark),
            title: Text(
              'permission_battery_title'.tr(),
              style: const TextStyle(color: AppColors.textWhite),
            ),
            content: Text(
              'permission_battery_desc'.tr(),
              style: const TextStyle(color: AppColors.textGray),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('deny'.tr(), style: const TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: Text('settings_open'.tr(), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
        }
      }
    } catch (e) {
      // 배터리 최적화 요청 실패는 무시 (치명적이지 않음)
      debugPrint('Battery optimization request failed: $e');
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final notificationService = NotificationService();
      final canSchedule = await notificationService.canScheduleExactAlarms();

      if (!canSchedule && mounted) {
        final isDark = ref.read(isDarkModeProvider);
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.getCard(isDark),
            title: Row(
              children: [
                const Icon(FluentIcons.alert_24_regular, color: AppColors.accentOrange),
                const SizedBox(width: 12),
                Text(
                  'permission_exact_alarm_title'.tr(),
                  style: const TextStyle(color: AppColors.textWhite),
                ),
              ],
            ),
            content: Text(
              'permission_exact_alarm_desc'.tr(),
              style: const TextStyle(color: AppColors.textGray, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('deny'.tr(), style: const TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: Text('allow'.tr(), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          await notificationService.openExactAlarmSettings();
        }
      }
    } catch (e) {
      // Exact alarm 권한 요청 실패는 무시 (치명적이지 않음)
      debugPrint('Exact alarm permission request failed: $e');
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _addTodoFromInput() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    ref.read(todoActionsProvider).createTodo(text, '', null);
    _inputController.clear();
  }

  /// Handle todo deletion with recurring dialog if needed
  Future<void> _handleDelete(Todo todo) async {
    // Check if this is a recurring todo instance
    if (todo.parentRecurringTodoId != null) {
      // Show recurring delete dialog
      final mode = await showDialog<RecurringDeleteMode>(
        context: context,
        builder: (context) => const RecurringDeleteDialog(),
      );

      if (mode == null) return; // User cancelled

      await ref.read(todoActionsProvider).deleteTodo(
        todo.id,
        recurringDeleteMode: mode,
      );
    } else {
      // Regular todo deletion
      await ref.read(todoActionsProvider).deleteTodo(todo.id);
    }
  }

  /// Handle clearing all completed todos
  Future<void> _handleClearCompleted() async {
    final isDark = ref.read(isDarkModeProvider);
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        title: Row(
          children: [
            const Icon(FluentIcons.delete_24_regular, color: AppColors.accentOrange),
            const SizedBox(width: 12),
            Text(
              'clear_completed_title'.tr(),
              style: const TextStyle(color: AppColors.textWhite),
            ),
          ],
        ),
        content: Text(
          'clear_completed_message'.tr(),
          style: const TextStyle(color: AppColors.textGray, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr(), style: const TextStyle(color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
            ),
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    try {
      final deletedCount = await ref.read(todoActionsProvider).deleteCompletedTodos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('clear_completed_success'.tr(args: [deletedCount.toString()])),
            backgroundColor: AppColors.primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('clear_completed_failed'.tr(args: [e.toString()])),
            backgroundColor: AppColors.dangerRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final todosAsync = ref.watch(todosProvider);
    final currentFilter = ref.watch(todoFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'todo_list'.tr(),
                            style: TextStyle(
                              color: AppColors.getText(isDarkMode),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'keep_it_up'.tr(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
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
                                onTap: () {
                                  ref.invalidate(todosProvider);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    FluentIcons.arrow_clockwise_24_regular,
                                    color: AppColors.getTextSecondary(isDarkMode),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Clear Completed Button
                          Container(
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
                                onTap: _handleClearCompleted,
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    FluentIcons.delete_24_regular,
                                    color: AppColors.getTextSecondary(isDarkMode),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Calendar Button
                          Container(
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
                                onTap: () {
                                  context.go('/calendar');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    FluentIcons.calendar_24_regular,
                                    color: AppColors.getTextSecondary(isDarkMode),
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
                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getInput(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getBorder(isDarkMode).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return TextField(
                          controller: _searchController,
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
                                      _searchController.clear();
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
                  ),
                ],
              ),
            ),

            // Category Filter
            ref.watch(categoriesProvider).when(
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
                        child: _CategoryChip(
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
                          child: _CategoryChip(
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
            ),

            // Quick Add Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.getInput(isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _inputController,
                  onSubmitted: (_) => _addTodoFromInput(),
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
                            color: AppColors.getTextSecondary(isDarkMode).withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentFilter == TodoFilter.all
                                ? 'no_todos'.tr()
                                : currentFilter == TodoFilter.pending
                                    ? 'no_pending_todos'.tr()
                                    : 'no_completed_todos'.tr(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group todos by recurring series
                  final groupedTodos = _groupTodosBySeries(todos);

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: groupedTodos.length,
                    onReorder: (oldIndex, newIndex) {
                      _onReorder(oldIndex, newIndex, groupedTodos);
                    },
                    itemBuilder: (context, index) {
                      final group = groupedTodos[index];

                      // If it's a single todo or non-recurring, show normal item
                      if (group.length == 1) {
                        final todo = group.first;
                        return CustomTodoItem(
                          key: ValueKey(todo.id),
                          todo: todo,
                          onToggle: () => ref
                              .read(todoActionsProvider)
                              .toggleCompletion(todo.id),
                          onDelete: () => _handleDelete(todo),
                          onTap: () => context.go('/todos/${todo.id}'),
                        );
                      }

                      // If it's a recurring series, show grouped item
                      return _RecurringTodoGroup(
                        key: ValueKey('group_${group.first.parentRecurringTodoId}'),
                        todos: group,
                        onToggle: (todo) => ref
                            .read(todoActionsProvider)
                            .toggleCompletion(todo.id),
                        onDelete: (todo) => _handleDelete(todo),
                        onTap: (todo) => context.go('/todos/${todo.id}'),
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
                color: AppColors.getCard(isDarkMode),
                border: Border(
                  top: BorderSide(
                    color: AppColors.getBorder(isDarkMode).withValues(alpha: 0.3),
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

  /// Group todos by recurring series
  /// Returns a list of lists, where each inner list contains todos from the same recurring series
  /// Non-recurring todos are wrapped in single-element lists
  List<List<Todo>> _groupTodosBySeries(List<Todo> todos) {
    print('🔍 _groupTodosBySeries: Processing ${todos.length} todos');

    final Map<int, List<Todo>> groupedByParent = {};
    final List<Todo> nonRecurring = [];

    for (final todo in todos) {
      print('   Todo: ${todo.id} - ${todo.title}, parent: ${todo.parentRecurringTodoId}');
      if (todo.parentRecurringTodoId != null) {
        // This is a recurring instance
        final parentId = todo.parentRecurringTodoId!;
        if (!groupedByParent.containsKey(parentId)) {
          groupedByParent[parentId] = [];
        }
        groupedByParent[parentId]!.add(todo);
      } else {
        // Non-recurring todo
        nonRecurring.add(todo);
      }
    }

    print('   Grouped by parent: ${groupedByParent.length} groups');
    for (final entry in groupedByParent.entries) {
      print('      Parent ${entry.key}: ${entry.value.length} todos');
    }
    print('   Non-recurring: ${nonRecurring.length} todos');

    // Combine and sort: single todos + grouped recurring series
    final List<List<Todo>> result = [];

    // Add non-recurring todos as single-element lists
    for (final todo in nonRecurring) {
      result.add([todo]);
    }

    // Add grouped recurring series (sorted by due date within each group)
    for (final group in groupedByParent.values) {
      // Sort by due date within group
      group.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      result.add(group);
    }

    // Sort the result by the first todo's due date in each group
    result.sort((a, b) {
      final aDueDate = a.first.dueDate;
      final bDueDate = b.first.dueDate;
      if (aDueDate == null && bDueDate == null) return 0;
      if (aDueDate == null) return 1;
      if (bDueDate == null) return -1;
      return aDueDate.compareTo(bDueDate);
    });

    return result;
  }

  /// Handle reordering of todos
  void _onReorder(int oldIndex, int newIndex, List<List<Todo>> groupedTodos) {
    print('🔄 _onReorder called: oldIndex=$oldIndex, newIndex=$newIndex');
    print('📊 Number of groups: ${groupedTodos.length}');

    if (oldIndex < newIndex) {
      newIndex -= 1;
      print('📌 Adjusted newIndex to: $newIndex');
    }

    // Flatten the grouped todos to get all todos in display order
    final List<Todo> allTodos = [];
    for (final group in groupedTodos) {
      allTodos.addAll(group);
    }
    print('📋 Total todos after flattening: ${allTodos.length}');
    print('📝 Todos before reorder: ${allTodos.map((t) => '${t.title}(pos:${t.position})').join(', ')}');

    // Create a mutable copy
    final mutableTodos = List<Todo>.from(allTodos);

    // Get the group that's being moved
    final movedGroup = groupedTodos[oldIndex];
    print('📦 Moving group with ${movedGroup.length} todos: ${movedGroup.map((t) => t.title).join(', ')}');

    // Calculate the actual position in the flattened list
    int actualOldIndex = 0;
    for (int i = 0; i < oldIndex; i++) {
      actualOldIndex += groupedTodos[i].length;
    }

    int actualNewIndex = 0;
    for (int i = 0; i < newIndex; i++) {
      actualNewIndex += groupedTodos[i].length;
    }
    print('🎯 Actual positions: oldIndex=$actualOldIndex → newIndex=$actualNewIndex');

    // Remove all todos in the moved group
    for (int i = movedGroup.length - 1; i >= 0; i--) {
      mutableTodos.removeAt(actualOldIndex);
    }

    // Insert them at the new position
    for (int i = 0; i < movedGroup.length; i++) {
      mutableTodos.insert(actualNewIndex + i, movedGroup[i]);
    }

    // Update positions for all todos
    final updatedTodos = <Todo>[];
    for (int i = 0; i < mutableTodos.length; i++) {
      updatedTodos.add(mutableTodos[i].copyWith(position: i));
    }
    print('📝 Todos after reorder: ${updatedTodos.map((t) => '${t.title}(pos:${t.position})').join(', ')}');

    // Update positions in the repository
    print('💾 Calling updateTodoPositions with ${updatedTodos.length} todos');
    ref.read(todoActionsProvider).updateTodoPositions(updatedTodos);
    print('✅ updateTodoPositions call completed');
  }
}

class _FilterChip extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getInput(isDarkMode),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
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
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
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
                color: isActive
                    ? AppColors.primaryBlue
                    : AppColors.getTextSecondary(isDarkMode),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primaryBlue
                      : AppColors.getTextSecondary(isDarkMode),
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

// Category Chip Widget
class _CategoryChip extends ConsumerWidget {
  final String label;
  final String? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primaryBlue).withOpacity(0.2)
                : AppColors.getCard(isDarkMode),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppColors.primaryBlue)
                  : AppColors.getBorder(isDarkMode),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[
                Text(
                  icon!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 14,
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

/// Widget for displaying a group of recurring todos
class _RecurringTodoGroup extends ConsumerStatefulWidget {
  final List<Todo> todos;
  final Function(Todo) onToggle;
  final Function(Todo) onDelete;
  final Function(Todo) onTap;

  const _RecurringTodoGroup({
    super.key,
    required this.todos,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  ConsumerState<_RecurringTodoGroup> createState() => _RecurringTodoGroupState();
}

class _RecurringTodoGroupState extends ConsumerState<_RecurringTodoGroup> {
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
                        '$totalCount개',
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
