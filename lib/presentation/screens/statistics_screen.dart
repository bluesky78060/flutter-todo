/// Statistics screen showing todo completion analytics with charts.
///
/// Features:
/// - Completion rate percentage with pie chart
/// - Weekly trend bar chart (fl_chart)
/// - Monthly line chart for long-term trends
/// - Streak counter (consecutive completion days)
/// - Category-based statistics
/// - Time-based analytics (daily/weekly/monthly)
///
/// Accessed from main screen header or settings.
///
/// See also:
/// - [allTodosProvider] for unfiltered todo data
/// - [TodoListScreen] for main list view
library;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fl_chart/fl_chart.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/screens/settings_screen.dart';

/// Provider for all todos (unfiltered) for statistics calculation.
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
          // Overall Progress Card with Pie Chart
          _OverallProgressCard(stats: stats),
          const SizedBox(height: 16),

          // Streak and Productivity Card
          _StreakCard(stats: stats),
          const SizedBox(height: 16),

          // Weekly Bar Chart Card
          _WeeklyBarChartCard(stats: stats),
          const SizedBox(height: 16),

          // Monthly Line Chart Card
          _MonthlyLineChartCard(stats: stats),
          const SizedBox(height: 16),

          // Today's Statistics
          _TodayStatisticsCard(stats: stats),
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
      final localCreated = t.createdAt.toLocal();
      final created = DateTime(localCreated.year, localCreated.month, localCreated.day);
      return created.isAtSameMomentAs(today);
    }).length;

    final todayCompleted = todos.where((t) {
      if (t.completedAt == null) return false;
      final localCompleted = t.completedAt!.toLocal();
      final completed = DateTime(localCompleted.year, localCompleted.month, localCompleted.day);
      return completed.isAtSameMomentAs(today);
    }).length;

    final todayPending = todos.where((t) => !t.isCompleted).length;

    // Weekly statistics
    final weekCompleted = todos.where((t) {
      if (t.completedAt == null) return false;
      return t.completedAt!.isAfter(weekStart);
    }).length;

    // Daily completion data for the week (numeric values for chart)
    final dailyCompletions = <int, int>{};
    final dailyCompletionsNamed = <String, int>{};
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

      dailyCompletions[i] = count;
      dailyCompletionsNamed[dayKey] = count;
    }

    // Monthly completion data (last 4 weeks)
    final monthlyCompletions = <int, int>{};
    for (int i = 0; i < 4; i++) {
      final weekStartDate = today.subtract(Duration(days: today.weekday - 1 + (i * 7)));
      final weekEndDate = weekStartDate.add(const Duration(days: 7));

      final count = todos.where((t) {
        if (t.completedAt == null) return false;
        return t.completedAt!.isAfter(weekStartDate) && t.completedAt!.isBefore(weekEndDate);
      }).length;

      monthlyCompletions[3 - i] = count; // Reverse order (oldest first)
    }

    // Calculate streak (consecutive days with at least 1 completion)
    int streak = 0;
    DateTime checkDate = today;
    while (true) {
      final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final hasCompletion = todos.any((t) {
        if (t.completedAt == null) return false;
        return t.completedAt!.isAfter(dayStart) && t.completedAt!.isBefore(dayEnd);
      });

      if (hasCompletion) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Best day (highest single-day completions ever)
    final Map<String, int> allDayCompletions = {};
    for (final todo in todos) {
      if (todo.completedAt != null) {
        final dateKey = '${todo.completedAt!.year}-${todo.completedAt!.month.toString().padLeft(2, '0')}-${todo.completedAt!.day.toString().padLeft(2, '0')}';
        allDayCompletions[dateKey] = (allDayCompletions[dateKey] ?? 0) + 1;
      }
    }

    int bestDayCount = 0;
    String bestDayDate = '';
    allDayCompletions.forEach((date, count) {
      if (count > bestDayCount) {
        bestDayCount = count;
        bestDayDate = date;
      }
    });

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

    // Most productive day of week
    String mostProductiveDay = 'monday'.tr();
    int maxCompletions = 0;
    dailyCompletionsNamed.forEach((day, count) {
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
      dailyCompletionsNamed: dailyCompletionsNamed,
      monthlyCompletions: monthlyCompletions,
      avgCompletionHours: avgCompletionHours,
      mostProductiveDay: mostProductiveDay,
      streak: streak,
      bestDayCount: bestDayCount,
      bestDayDate: bestDayDate,
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
  final Map<int, int> dailyCompletions;
  final Map<String, int> dailyCompletionsNamed;
  final Map<int, int> monthlyCompletions;
  final double avgCompletionHours;
  final String mostProductiveDay;
  final int streak;
  final int bestDayCount;
  final String bestDayDate;

  _StatisticsData({
    required this.totalTodos,
    required this.completedTodos,
    required this.completionRate,
    required this.todayCreated,
    required this.todayCompleted,
    required this.todayPending,
    required this.weekCompleted,
    required this.dailyCompletions,
    required this.dailyCompletionsNamed,
    required this.monthlyCompletions,
    required this.avgCompletionHours,
    required this.mostProductiveDay,
    required this.streak,
    required this.bestDayCount,
    required this.bestDayDate,
  });
}

// Overall Progress Card with Pie Chart
class _OverallProgressCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _OverallProgressCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final incomplete = stats.totalTodos - stats.completedTodos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.getProgressGradient(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
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
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.2) : AppColors.primaryBlue.withValues(alpha: 0.15),
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
                  color: isDarkMode ? Colors.white : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pie Chart and Stats Row
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 25,
                    sections: [
                      PieChartSectionData(
                        value: stats.completedTodos.toDouble(),
                        title: '',
                        color: const Color(0xFF4CAF50),
                        radius: 22,
                      ),
                      PieChartSectionData(
                        value: incomplete.toDouble(),
                        title: '',
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFFE0E0E0),
                        radius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniStatRow(
                      icon: FluentIcons.apps_list_24_regular,
                      label: 'total'.tr(),
                      value: '${stats.totalTodos}',
                      color: isDarkMode ? Colors.white : AppColors.textDark,
                    ),
                    const SizedBox(height: 8),
                    _MiniStatRow(
                      icon: FluentIcons.checkmark_circle_24_regular,
                      label: 'completed'.tr(),
                      value: '${stats.completedTodos}',
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 8),
                    _MiniStatRow(
                      icon: FluentIcons.circle_24_regular,
                      label: 'incomplete'.tr(),
                      value: '$incomplete',
                      color: const Color(0xFFFF9800),
                    ),
                  ],
                ),
              ),

              // Completion Rate
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${stats.completionRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : AppColors.primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'completion_rate'.tr(),
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.textGrayDark,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Streak Card
class _StreakCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _StreakCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Streak
          Expanded(
            child: _StreakItem(
              icon: FluentIcons.fire_24_filled,
              iconColor: const Color(0xFFFF5722),
              title: 'current_streak'.tr(),
              value: '${stats.streak}',
              subtitle: 'days'.tr(),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.getBorder(isDarkMode),
          ),
          // Best Day
          Expanded(
            child: _StreakItem(
              icon: FluentIcons.star_24_filled,
              iconColor: const Color(0xFFFFD700),
              title: 'best_day'.tr(),
              value: '${stats.bestDayCount}',
              subtitle: 'tasks'.tr(),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.getBorder(isDarkMode),
          ),
          // Week Total
          Expanded(
            child: _StreakItem(
              icon: FluentIcons.calendar_week_start_24_filled,
              iconColor: AppColors.primaryBlue,
              title: 'this_week'.tr(),
              value: '${stats.weekCompleted}',
              subtitle: 'completed'.tr(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakItem extends ConsumerWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StreakItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColors.getText(isDarkMode),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Weekly Bar Chart Card
class _WeeklyBarChartCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _WeeklyBarChartCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final maxValue = stats.dailyCompletions.values.isEmpty
        ? 5.0
        : stats.dailyCompletions.values.reduce((a, b) => a > b ? a : b).toDouble();

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
                      FluentIcons.data_bar_horizontal_24_filled,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'weekly_trend'.tr(),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue < 1 ? 5 : maxValue + 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDarkMode
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.darkCard,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayNames = ['monday'.tr(), 'tuesday'.tr(), 'wednesday'.tr(),
                                        'thursday'.tr(), 'friday'.tr(), 'saturday'.tr(), 'sunday'.tr()];
                      return BarTooltipItem(
                        '${dayNames[group.x]}\n',
                        TextStyle(
                          color: isDarkMode ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} ${'tasks'.tr()}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.black54 : Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final shortDays = ['day_mon'.tr(), 'day_tue'.tr(), 'day_wed'.tr(),
                                          'day_thu'.tr(), 'day_fri'.tr(), 'day_sat'.tr(), 'day_sun'.tr()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortDays[value.toInt()],
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.getBorder(isDarkMode).withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final value = stats.dailyCompletions[index] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value.toDouble(),
                        gradient: value > 0 ? AppColors.primaryGradient : null,
                        color: value == 0 ? AppColors.getInput(isDarkMode) : null,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Monthly Line Chart Card
class _MonthlyLineChartCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _MonthlyLineChartCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final maxValue = stats.monthlyCompletions.values.isEmpty
        ? 10.0
        : stats.monthlyCompletions.values.reduce((a, b) => a > b ? a : b).toDouble();

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
                  FluentIcons.data_trending_24_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'monthly_trend'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxValue < 1 ? 10 : maxValue + 2,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDarkMode
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.darkCard,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final weekLabels = ['week_4_ago'.tr(), 'week_3_ago'.tr(),
                                           'week_2_ago'.tr(), 'last_week'.tr()];
                        return LineTooltipItem(
                          '${weekLabels[spot.x.toInt()]}\n${spot.y.toInt()} ${'tasks'.tr()}',
                          TextStyle(
                            color: isDarkMode ? Colors.black87 : Colors.white,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['4W', '3W', '2W', '1W'];
                        if (value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                color: AppColors.getTextSecondary(isDarkMode),
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue < 5 ? 1 : (maxValue / 5).ceilToDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.getBorder(isDarkMode).withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(4, (index) {
                      final value = stats.monthlyCompletions[index] ?? 0;
                      return FlSpot(index.toDouble(), value.toDouble());
                    }),
                    isCurved: true,
                    gradient: AppColors.primaryGradient,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primaryBlue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryBlue.withValues(alpha: 0.3),
                          AppColors.primaryBlue.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
