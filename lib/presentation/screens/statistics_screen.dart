import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/screens/settings_screen.dart';

// Provider for all todos (unfiltered)
final allTodosProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  final result = await repository.getTodos();
  return result.fold(
    (failure) => throw Exception(failure),
    (todos) => todos,
  );
});

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final todosAsync = ref.watch(allTodosProvider);

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'statistics'.tr(),
                        style: TextStyle(
                          color: AppColors.getText(isDarkMode),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'my_work_status'.tr(),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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
                        onTap: () => ref.invalidate(allTodosProvider),
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            FluentIcons.arrow_sync_24_filled,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Statistics Content
            Expanded(
              child: todosAsync.when(
                data: (todos) {
                  final stats = _calculateStatistics(todos);
                  return _buildStatisticsContent(stats);
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
                        '${'error'.tr()}: $error',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: FluentIcons.task_list_square_ltr_24_regular,
                            label: 'work'.tr(),
                            isActive: false,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: FluentIcons.data_histogram_24_filled,
                            label: 'statistics'.tr(),
                            isActive: true,
                            onTap: () {},
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(_StatisticsData stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Progress Card
          _OverallProgressCard(stats: stats),
          const SizedBox(height: 16),

          // Today's Statistics
          _TodayStatisticsCard(stats: stats),
          const SizedBox(height: 16),

          // Weekly Statistics
          _WeeklyStatisticsCard(stats: stats),
          const SizedBox(height: 16),

          // Category Breakdown
          _CategoryBreakdownCard(stats: stats),
          const SizedBox(height: 16),

          // Time-based Statistics
          _TimeBasedStatisticsCard(stats: stats),
        ],
      ),
    );
  }

  _StatisticsData _calculateStatistics(List<Todo> todos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    // Overall statistics
    final totalTodos = todos.length;
    final completedTodos = todos.where((t) => t.isCompleted).length;
    final completionRate = totalTodos > 0 ? (completedTodos / totalTodos * 100) : 0.0;

    // Today's statistics
    final todayCreated = todos.where((t) {
      final created = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      return created.isAtSameMomentAs(today);
    }).length;

    final todayCompleted = todos.where((t) {
      if (t.completedAt == null) return false;
      final completed = DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day);
      return completed.isAtSameMomentAs(today);
    }).length;

    final todayPending = todos.where((t) => !t.isCompleted).length;

    // Weekly statistics
    final weekCompleted = todos.where((t) {
      if (t.completedAt == null) return false;
      return t.completedAt!.isAfter(weekStart);
    }).length;

    // Daily completion data for the week
    final dailyCompletions = <String, int>{};
    final dayKeys = ['monday'.tr(), 'tuesday'.tr(), 'wednesday'.tr(), 'thursday'.tr(), 'friday'.tr(), 'saturday'.tr(), 'sunday'.tr()];

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayKey = dayKeys[i];
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = todos.where((t) {
        if (t.completedAt == null) return false;
        return t.completedAt!.isAfter(dayStart) && t.completedAt!.isBefore(dayEnd);
      }).length;

      dailyCompletions[dayKey] = count;
    }

    // Time-based statistics
    final completedWithTimes = todos.where((t) => t.isCompleted && t.completedAt != null).toList();
    double avgCompletionHours = 0;
    if (completedWithTimes.isNotEmpty) {
      final totalHours = completedWithTimes.fold<int>(0, (sum, t) {
        final diff = t.completedAt!.difference(t.createdAt);
        return sum + diff.inHours;
      });
      avgCompletionHours = totalHours / completedWithTimes.length;
    }

    // Most productive day
    String mostProductiveDay = 'monday'.tr();
    int maxCompletions = 0;
    dailyCompletions.forEach((day, count) {
      if (count > maxCompletions) {
        maxCompletions = count;
        mostProductiveDay = day;
      }
    });

    return _StatisticsData(
      totalTodos: totalTodos,
      completedTodos: completedTodos,
      completionRate: completionRate,
      todayCreated: todayCreated,
      todayCompleted: todayCompleted,
      todayPending: todayPending,
      weekCompleted: weekCompleted,
      dailyCompletions: dailyCompletions,
      avgCompletionHours: avgCompletionHours,
      mostProductiveDay: mostProductiveDay,
    );
  }
}

// Statistics Data Model
class _StatisticsData {
  final int totalTodos;
  final int completedTodos;
  final double completionRate;
  final int todayCreated;
  final int todayCompleted;
  final int todayPending;
  final int weekCompleted;
  final Map<String, int> dailyCompletions;
  final double avgCompletionHours;
  final String mostProductiveDay;

  _StatisticsData({
    required this.totalTodos,
    required this.completedTodos,
    required this.completionRate,
    required this.todayCreated,
    required this.todayCompleted,
    required this.todayPending,
    required this.weekCompleted,
    required this.dailyCompletions,
    required this.avgCompletionHours,
    required this.mostProductiveDay,
  });
}

// Overall Progress Card
class _OverallProgressCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _OverallProgressCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FluentIcons.chart_multiple_24_filled,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'overall_progress'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'total'.tr(),
                value: '${stats.totalTodos}',
                icon: FluentIcons.apps_list_24_regular,
              ),
              _StatItem(
                label: 'completed'.tr(),
                value: '${stats.completedTodos}',
                icon: FluentIcons.checkmark_circle_24_regular,
              ),
              _StatItem(
                label: 'completion_rate'.tr(),
                value: '${stats.completionRate.toStringAsFixed(0)}%',
                icon: FluentIcons.trophy_24_regular,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.totalTodos > 0 ? stats.completedTodos / stats.totalTodos : 0,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends ConsumerWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Today's Statistics Card
class _TodayStatisticsCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _TodayStatisticsCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FluentIcons.calendar_today_24_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'today_statistics'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: FluentIcons.add_circle_24_regular,
                  label: 'created'.tr(),
                  value: '${stats.todayCreated}',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: FluentIcons.checkmark_circle_24_regular,
                  label: 'completed'.tr(),
                  value: '${stats.todayCompleted}',
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: FluentIcons.clock_24_regular,
                  label: 'waiting'.tr(),
                  value: '${stats.todayPending}',
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getInput(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextSecondary(isDarkMode),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Weekly Statistics Card
class _WeeklyStatisticsCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _WeeklyStatisticsCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FluentIcons.calendar_week_start_24_filled,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'this_week_statistics'.tr(),
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'completed_count'.tr(namedArgs: {'count': '${stats.weekCompleted}'}),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DailyCompletionChart(completions: stats.dailyCompletions),
        ],
      ),
    );
  }
}

class _DailyCompletionChart extends ConsumerWidget {
  final Map<String, int> completions;

  const _DailyCompletionChart({required this.completions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final maxValue = completions.values.isEmpty ? 1 : completions.values.reduce((a, b) => a > b ? a : b).toDouble();
    final days = ['monday'.tr(), 'tuesday'.tr(), 'wednesday'.tr(), 'thursday'.tr(), 'friday'.tr(), 'saturday'.tr(), 'sunday'.tr()];

    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final value = completions[day] ?? 0;
          final height = maxValue > 0 ? (value / maxValue * 100) : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value > 0)
                    Text(
                      '$value',
                      style: TextStyle(
                        color: AppColors.getTextSecondary(isDarkMode),
                        fontSize: 10,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: height.clamp(20, 100),
                    decoration: BoxDecoration(
                      gradient: value > 0 ? AppColors.primaryGradient : null,
                      color: value == 0 ? AppColors.getInput(isDarkMode) : null,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDarkMode),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Category Breakdown Card
class _CategoryBreakdownCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _CategoryBreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final incomplete = stats.totalTodos - stats.completedTodos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FluentIcons.data_pie_24_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'category_analysis'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProgressItem(
            label: 'completed'.tr(),
            value: stats.completedTodos,
            total: stats.totalTodos,
            color: const Color(0xFF4CAF50),
            icon: FluentIcons.checkmark_circle_24_filled,
          ),
          const SizedBox(height: 12),
          _ProgressItem(
            label: 'incomplete'.tr(),
            value: incomplete,
            total: stats.totalTodos,
            color: const Color(0xFFFF9800),
            icon: FluentIcons.circle_24_regular,
          ),
        ],
      ),
    );
  }
}

class _ProgressItem extends ConsumerWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final IconData icon;

  const _ProgressItem({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final percentage = total > 0 ? (value / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
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
            Text(
              '$value (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            minHeight: 8,
            backgroundColor: AppColors.getInput(isDarkMode),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// Time-based Statistics Card
class _TimeBasedStatisticsCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _TimeBasedStatisticsCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FluentIcons.clock_24_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'time_analysis'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimeInfoCard(
                  icon: FluentIcons.timer_24_regular,
                  label: 'avg_completion_time'.tr(),
                  value: stats.avgCompletionHours < 1
                      ? 'less_than_one_hour'.tr()
                      : 'hours'.tr(namedArgs: {'count': stats.avgCompletionHours.toStringAsFixed(0)}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeInfoCard(
                  icon: FluentIcons.star_24_regular,
                  label: 'most_productive_day'.tr(),
                  value: stats.mostProductiveDay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeInfoCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TimeInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getInput(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextSecondary(isDarkMode),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Navigation Item Widget
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
