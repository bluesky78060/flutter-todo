import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/services/battery_optimization_service.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
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
  bool _isRequestingPermissions = false; // 중복 요청 방지 플래그

  @override
  void initState() {
    super.initState();
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

        // 2단계: 배터리 최적화 제외 요청 (알림 권한 허용 후)
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
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          title: const Text(
            '알림 권한 요청',
            style: TextStyle(color: AppColors.textWhite),
          ),
          content: const Text(
            '할일 알림을 받으시겠습니까?\n알림을 허용하면 설정한 시간에 할일을 알려드립니다.',
            style: TextStyle(color: AppColors.textGray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('나중에', style: TextStyle(color: AppColors.textGray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('허용', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        await notificationService.requestPermissions();
      }
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      final isIgnoring = await BatteryOptimizationService.isIgnoringBatteryOptimizations();

      if (!isIgnoring && mounted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkCard,
            title: const Text(
              '배터리 최적화 제외',
              style: TextStyle(color: AppColors.textWhite),
            ),
            content: const Text(
              '정확한 시간에 알림을 받으려면 배터리 최적화를 제외해야 합니다.\n\n앱이 백그라운드에서 종료되지 않도록 설정하시겠습니까?',
              style: TextStyle(color: AppColors.textGray),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('나중에', style: TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text('설정하기', style: TextStyle(color: Colors.white)),
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
                                color: AppColors.darkBorder.withValues(alpha: 0.5),
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
                          label: '전체',
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
                            color: Color(int.parse('0xFF${category.color}')),
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
                            color: AppColors.textGray.withValues(alpha: 0.5),
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
                    color: AppColors.darkBorder.withValues(alpha: 0.3),
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

// Category Chip Widget
class _CategoryChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                : AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppColors.primaryBlue)
                  : AppColors.darkBorder,
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
                  color: isSelected ? AppColors.textWhite : AppColors.textGray,
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
