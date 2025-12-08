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
import 'package:todo_app/presentation/providers/category_providers.dart';
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
    final categoriesAsync = ref.watch(categoriesProvider);

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
                          fontSize: AppColors.scaledFontSize(24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'my_work_status'.tr(),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
                          fontSize: AppColors.scaledFontSize(14),
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
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ref.invalidate(allTodosProvider);
                          ref.invalidate(categoriesProvider);
                        },
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
                  return categoriesAsync.when(
                    data: (categories) {
                      final stats = _calculateStatistics(todos, categories);
                      return _buildStatisticsContent(stats);
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
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
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: FluentIcons.task_list_square_ltr_24_regular,
                        label: 'todos'.tr(),
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
          // Overall Progress Card with Pie Chart (purple gradient)
          _OverallProgressCard(stats: stats),
          const SizedBox(height: 16),

          // Weekly Bar Chart Card (with subtitle)
          _WeeklyBarChartCard(stats: stats),
          const SizedBox(height: 16),

          // Monthly Line Chart Card
          _MonthlyLineChartCard(stats: stats),
          const SizedBox(height: 16),

          // Monthly Analysis Card (simplified)
          _MonthlyAnalysisCard(stats: stats),
          const SizedBox(height: 16),

          // Weekly Pattern Card (circle icons)
          _WeeklyPatternCard(stats: stats),
          const SizedBox(height: 16),

          // Insights Card (auto-generated insights)
          _InsightsCard(stats: stats),
          const SizedBox(height: 16),

          // Today's Statistics
          _TodayStatisticsCard(stats: stats),
          const SizedBox(height: 16),

          // Time-based Statistics
          _TimeBasedStatisticsCard(stats: stats),

          // Category Analysis Card (moved to bottom, optional)
          if (stats.categoryStats.isNotEmpty)
            const SizedBox(height: 16),
          if (stats.categoryStats.isNotEmpty)
            _CategoryAnalysisCard(stats: stats),
        ],
      ),
    );
  }

  _StatisticsData _calculateStatistics(List<Todo> todos, List<dynamic> categories) {
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
      // Convert to local time and compare date parts
      final completedLocal = t.completedAt!.toLocal();
      final completedDate = DateTime(completedLocal.year, completedLocal.month, completedLocal.day);
      return !completedDate.isBefore(weekStart);
    }).length;

    // Daily completion data for the week (numeric values for chart)
    // NOTE: Use raw English keys for consistency, translate only for display
    final dailyCompletions = <int, int>{};
    final dailyCompletionsNamed = <String, int>{};
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayKey = dayKeys[i];
      final targetDate = DateTime(day.year, day.month, day.day);

      final count = todos.where((t) {
        if (t.completedAt == null) return false;
        // Convert to local time and compare only the date part
        final completedLocal = t.completedAt!.toLocal();
        final completedDate = DateTime(completedLocal.year, completedLocal.month, completedLocal.day);
        return completedDate.isAtSameMomentAs(targetDate);
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
        // Convert to local time and compare date parts
        final completedLocal = t.completedAt!.toLocal();
        final completedDate = DateTime(completedLocal.year, completedLocal.month, completedLocal.day);
        return !completedDate.isBefore(weekStartDate) && completedDate.isBefore(weekEndDate);
      }).length;

      monthlyCompletions[3 - i] = count; // Reverse order (oldest first)
    }

    // Yearly completion data (last 12 months)
    final yearlyCompletions = <int, int>{};
    for (int i = 0; i < 12; i++) {
      final monthStart = DateTime(today.year, today.month - i, 1);
      final monthEnd = (i == 0)
          ? today.add(const Duration(days: 1))
          : DateTime(today.year, today.month - i + 1, 1);

      final count = todos.where((t) {
        if (t.completedAt == null) return false;
        final completedLocal = t.completedAt!.toLocal();
        return completedLocal.isAfter(monthStart) && completedLocal.isBefore(monthEnd);
      }).length;

      yearlyCompletions[11 - i] = count; // Reverse order (oldest first)
    }

    // Calculate streak (consecutive days with at least 1 completion)
    int streak = 0;
    DateTime checkDate = today;
    while (true) {
      final targetDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

      final hasCompletion = todos.any((t) {
        if (t.completedAt == null) return false;
        // Convert to local time and compare date parts
        final completedLocal = t.completedAt!.toLocal();
        final completedDate = DateTime(completedLocal.year, completedLocal.month, completedLocal.day);
        return completedDate.isAtSameMomentAs(targetDate);
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
        // Convert to local time for date key
        final completedLocal = todo.completedAt!.toLocal();
        final dateKey = '${completedLocal.year}-${completedLocal.month.toString().padLeft(2, '0')}-${completedLocal.day.toString().padLeft(2, '0')}';
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

    // Most productive day of week (stored as raw English key)
    String mostProductiveDay = 'monday';
    int maxCompletions = 0;
    dailyCompletionsNamed.forEach((day, count) {
      if (count > maxCompletions) {
        maxCompletions = count;
        mostProductiveDay = day;
      }
    });

    // Calculate category statistics
    final categoryStats = <String, _CategoryStats>{};
    for (final category in categories) {
      final categoryName = category.name as String;
      final categoryId = category.id as int;

      final todosInCategory = todos.where((t) => t.categoryId == categoryId).toList();
      final totalInCategory = todosInCategory.length;
      final completedInCategory = todosInCategory.where((t) => t.isCompleted).length;
      final completionRateCategory = totalInCategory > 0
        ? (completedInCategory / totalInCategory * 100)
        : 0.0;

      if (totalInCategory > 0) {
        categoryStats[categoryName] = _CategoryStats(
          categoryName: categoryName,
          totalCount: totalInCategory,
          completedCount: completedInCategory,
          completionRate: completionRateCategory,
        );
      }
    }

    // Add uncategorized todos
    final uncategorizedTodos = todos.where((t) => t.categoryId == null).toList();
    if (uncategorizedTodos.isNotEmpty) {
      final totalUncategorized = uncategorizedTodos.length;
      final completedUncategorized = uncategorizedTodos.where((t) => t.isCompleted).length;
      final completionRateUncategorized = (completedUncategorized / totalUncategorized * 100);

      categoryStats['uncategorized'] = _CategoryStats(
        categoryName: 'uncategorized'.tr(),
        totalCount: totalUncategorized,
        completedCount: completedUncategorized,
        completionRate: completionRateUncategorized,
      );
    }

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
      yearlyCompletions: yearlyCompletions,
      avgCompletionHours: avgCompletionHours,
      mostProductiveDay: mostProductiveDay,
      streak: streak,
      bestDayCount: bestDayCount,
      bestDayDate: bestDayDate,
      categoryStats: categoryStats,
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
  final Map<int, int> yearlyCompletions; // 12 months data
  final double avgCompletionHours;
  final String mostProductiveDay;
  final int streak;
  final int bestDayCount;
  final String bestDayDate;
  final Map<String, _CategoryStats> categoryStats; // Category-based statistics

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
    required this.yearlyCompletions,
    required this.avgCompletionHours,
    required this.mostProductiveDay,
    required this.streak,
    required this.bestDayCount,
    required this.bestDayDate,
    required this.categoryStats,
  });
}

/// Category statistics for individual categories
class _CategoryStats {
  final String categoryName;
  final int totalCount;
  final int completedCount;
  final double completionRate;

  _CategoryStats({
    required this.categoryName,
    required this.totalCount,
    required this.completedCount,
    required this.completionRate,
  });
}

// Overall Progress Card with Pie Chart - Purple gradient design
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C3AED), // Purple
            Color(0xFF6366F1), // Indigo
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FluentIcons.chart_multiple_24_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'overall_progress'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppColors.scaledFontSize(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats and Pie Chart Row
          Row(
            children: [
              // Left side - Stats list
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressStatRow(
                      label: 'total'.tr(),
                      value: stats.totalTodos,
                      dotColor: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    _ProgressStatRow(
                      label: 'completed'.tr(),
                      value: stats.completedTodos,
                      dotColor: const Color(0xFF4ADE80), // Green
                    ),
                    const SizedBox(height: 8),
                    _ProgressStatRow(
                      label: 'incomplete'.tr(),
                      value: incomplete,
                      dotColor: const Color(0xFFFBBF24), // Orange/Yellow
                    ),
                  ],
                ),
              ),

              // Right side - Large Pie Chart with percentage
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: stats.completedTodos.toDouble(),
                            title: '',
                            color: const Color(0xFF4ADE80),
                            radius: 16,
                          ),
                          PieChartSectionData(
                            value: incomplete > 0 ? incomplete.toDouble() : (stats.totalTodos == 0 ? 1 : 0),
                            title: '',
                            color: Colors.white.withValues(alpha: 0.3),
                            radius: 14,
                          ),
                        ],
                      ),
                    ),
                    // Center percentage
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stats.completionRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppColors.scaledFontSize(22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'completion_rate'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: AppColors.scaledFontSize(9),
                          ),
                        ),
                      ],
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

// Progress stat row for the purple card
class _ProgressStatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color dotColor;

  const _ProgressStatRow({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: AppColors.scaledFontSize(13),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppColors.scaledFontSize(13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
            fontSize: AppColors.scaledFontSize(12),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: AppColors.scaledFontSize(14),
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
              iconColor: AppColors.primary,
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
            fontSize: AppColors.scaledFontSize(24),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: AppColors.scaledFontSize(11),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: AppColors.scaledFontSize(10),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Weekly Bar Chart Card - Simple design with subtitle
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
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FluentIcons.data_bar_horizontal_24_filled,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'weekly_trend'.tr(),
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: AppColors.scaledFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'recent_7_days'.tr(),
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDarkMode),
                      fontSize: AppColors.scaledFontSize(12),
                    ),
                  ),
                ],
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
                          fontSize: AppColors.scaledFontSize(12),
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} ${'tasks'.tr()}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.black54 : Colors.white70,
                              fontSize: AppColors.scaledFontSize(11),
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
                              fontSize: AppColors.scaledFontSize(11),
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
                              fontSize: AppColors.scaledFontSize(10),
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
                  fontSize: AppColors.scaledFontSize(18),
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
                            fontSize: AppColors.scaledFontSize(11),
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
                                fontSize: AppColors.scaledFontSize(11),
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
                              fontSize: AppColors.scaledFontSize(10),
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
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.0),
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
                  fontSize: AppColors.scaledFontSize(18),
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
              fontSize: AppColors.scaledFontSize(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextSecondary(isDarkMode),
              fontSize: AppColors.scaledFontSize(12),
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
                  fontSize: AppColors.scaledFontSize(18),
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
                  value: stats.mostProductiveDay.tr(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label on top
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextSecondary(isDarkMode),
              fontSize: AppColors.scaledFontSize(12),
            ),
          ),
          const SizedBox(height: 4),
          // Value below
          Text(
            value,
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: AppColors.scaledFontSize(18),
              fontWeight: FontWeight.bold,
            ),
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
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.vertical(
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
                    ? AppColors.primary
                    : AppColors.getTextSecondary(isDarkMode),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.getTextSecondary(isDarkMode),
                  fontSize: AppColors.scaledFontSize(12),
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

// Category Analysis Card with Horizontal Bar Chart
class _CategoryAnalysisCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _CategoryAnalysisCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Sort categories by completion rate (highest first)
    final sortedCategories = stats.categoryStats.values.toList()
      ..sort((a, b) => b.completionRate.compareTo(a.completionRate));

    // Limit to top 5 categories
    final displayCategories = sortedCategories.length > 5
      ? sortedCategories.sublist(0, 5)
      : sortedCategories;

    // Get color for each bar (use success green for high completion, accent orange for medium, red for low)
    Color getColorForRate(double rate) {
      if (rate >= 75) return AppColors.successGreen;
      if (rate >= 50) return AppColors.accentOrange;
      return AppColors.dangerRed;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(isDarkMode),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'category_analysis'.tr(),
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: AppColors.scaledFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'completion_by_category'.tr(),
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDarkMode),
                      fontSize: AppColors.scaledFontSize(12),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${displayCategories.length}/${stats.categoryStats.length}',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontSize: AppColors.scaledFontSize(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Bars
          ...displayCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final isLast = index == displayCategories.length - 1;

            return Column(
              children: [
                // Category name and percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        category.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.getText(isDarkMode),
                          fontSize: AppColors.scaledFontSize(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${category.completionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: getColorForRate(category.completionRate),
                        fontSize: AppColors.scaledFontSize(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: category.completionRate / 100,
                    backgroundColor: AppColors.getBorder(isDarkMode),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      getColorForRate(category.completionRate),
                    ),
                  ),
                ),

                // Completed/Total count
                const SizedBox(height: 4),
                Text(
                  '${category.completedCount}/${category.totalCount} completed',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: AppColors.scaledFontSize(10),
                  ),
                ),

                if (!isLast) const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// Monthly Analysis Card - Simplified version (no chart, only stats)
class _MonthlyAnalysisCard extends ConsumerWidget {
  final _StatisticsData stats;

  const _MonthlyAnalysisCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Get month labels for last 12 months
    final now = DateTime.now();
    final monthLabels = <String>[];
    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      monthLabels.add('${monthDate.month.toString().padLeft(2, '0')}월');
    }

    // Calculate statistics
    final yearlyValues = stats.yearlyCompletions.values.toList();
    final avgValue = yearlyValues.isNotEmpty ? (yearlyValues.fold<int>(0, (a, b) => a + b) / yearlyValues.length).round() : 0;

    // Find best month
    int bestMonth = 0;
    int bestValue = 0;
    for (int i = 0; i < yearlyValues.length; i++) {
      if (yearlyValues[i] > bestValue) {
        bestValue = yearlyValues[i];
        bestMonth = i;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(isDarkMode),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '월간 추이 분석',
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: AppColors.scaledFontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Summary - Only 월평균 and 최고기록
          Row(
            children: [
              // 월평균
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getInput(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '월평균',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
                          fontSize: AppColors.scaledFontSize(12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$avgValue개',
                        style: TextStyle(
                          color: AppColors.getText(isDarkMode),
                          fontSize: AppColors.scaledFontSize(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 최고기록
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getInput(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '최고기록',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
                          fontSize: AppColors.scaledFontSize(12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        yearlyValues.isNotEmpty ? '${monthLabels[bestMonth]} $bestValue개' : '-',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: AppColors.scaledFontSize(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Weekly Pattern Card - Shows day-by-day completion patterns with circle icons
class _WeeklyPatternCard extends ConsumerWidget {
  final _StatisticsData stats;
  const _WeeklyPatternCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Get completion counts for each day of week
    // NOTE: dailyCompletionsNamed uses raw English keys, translate only for display
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayCompletions = <String, int>{};
    int maxCompletions = 0;

    for (final day in days) {
      final count = stats.dailyCompletionsNamed[day] ?? 0;
      dayCompletions[day] = count;
      if (count > maxCompletions) {
        maxCompletions = count;
      }
    }

    // Get most productive day
    String mostProductiveDay = stats.mostProductiveDay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'weekly_pattern'.tr(),
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: AppColors.scaledFontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Day circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = days[index];
              final count = dayCompletions[day] ?? 0;
              final isDayMostProductive = day == mostProductiveDay;

              // Calculate opacity based on completion count
              final opacity = maxCompletions > 0
                  ? 0.3 + (count / maxCompletions) * 0.7
                  : 0.3;

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDayMostProductive
                          ? AppColors.successGreen.withValues(alpha: opacity)
                          : AppColors.primary.withValues(alpha: opacity),
                      border: isDayMostProductive
                          ? Border.all(color: AppColors.successGreen, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isDayMostProductive
                              ? AppColors.successGreen
                              : AppColors.getText(isDarkMode),
                          fontSize: AppColors.scaledFontSize(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${day}_short'.tr(),
                    style: TextStyle(
                      color: isDayMostProductive
                          ? AppColors.successGreen
                          : AppColors.getTextSecondary(isDarkMode),
                      fontSize: AppColors.scaledFontSize(12),
                      fontWeight: isDayMostProductive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Insights Card - Auto-generated insights about productivity
class _InsightsCard extends ConsumerWidget {
  final _StatisticsData stats;
  const _InsightsCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Generate insights
    final insights = <String>[];

    // Insight 1: Most productive day (translate the day name)
    if (stats.mostProductiveDay.isNotEmpty) {
      insights.add('insight_productive_day|${stats.mostProductiveDay.tr()}');
    }

    // Insight 2: Overall completion rate
    final completionRate = stats.completionRate.toStringAsFixed(0);
    if (stats.completionRate >= 70) {
      insights.add('insight_excellent|$completionRate');
    } else if (stats.completionRate >= 50) {
      insights.add('insight_good|$completionRate');
    } else if (stats.completionRate > 0) {
      insights.add('insight_fair|$completionRate');
    }

    // Insight 3: Streak
    if (stats.streak > 0) {
      insights.add('insight_streak|${stats.streak}');
    }

    // Insight 4: Best day record
    if (stats.bestDayCount > 5) {
      insights.add('insight_best_day|${stats.bestDayCount}');
    }

    // Insight 5: Completion time
    if (stats.avgCompletionHours > 0) {
      final hours = stats.avgCompletionHours.toStringAsFixed(1);
      insights.add('insight_completion_time|$hours');
    }

    // Fallback insight if no insights generated
    if (insights.isEmpty) {
      insights.add('insight_start_tracking');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'insights_title'.tr(),
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: AppColors.scaledFontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'insights_subtitle'.tr(),
            style: TextStyle(
              color: AppColors.getTextSecondary(isDarkMode),
              fontSize: AppColors.scaledFontSize(12),
            ),
          ),
          const SizedBox(height: 16),

          // Insights list
          Column(
            children: List.generate(
              insights.length,
              (index) {
                final insight = insights[index];
                final parts = insight.split('|');
                final key = parts[0];
                final value = parts.length > 1 ? parts[1] : '';

                String insightText = '';
                IconData? insightIcon;
                Color? insightColor;

                switch (key) {
                  case 'insight_productive_day':
                    insightText = '${'insight_productive_day_text'.tr()} ${value.tr()} 💪';
                    insightIcon = FluentIcons.star_24_filled;
                    insightColor = const Color(0xFFFFD700);
                    break;
                  case 'insight_excellent':
                    insightText = '${'insight_excellent_text'.tr()} $value% 🎉';
                    insightIcon = FluentIcons.checkmark_circle_24_filled;
                    insightColor = const Color(0xFF4CAF50);
                    break;
                  case 'insight_good':
                    insightText = '${'insight_good_text'.tr()} $value% ✨';
                    insightIcon = FluentIcons.triangle_24_filled;
                    insightColor = AppColors.primary;
                    break;
                  case 'insight_fair':
                    insightText = '${'insight_fair_text'.tr()} $value% 💪';
                    insightIcon = FluentIcons.arrow_up_24_filled;
                    insightColor = const Color(0xFFFFA500);
                    break;
                  case 'insight_streak':
                    insightText = '${'insight_streak_text'.tr()} $value ${'days'.tr()} 🔥';
                    insightIcon = FluentIcons.fire_24_filled;
                    insightColor = const Color(0xFFFF5722);
                    break;
                  case 'insight_best_day':
                    insightText = '${'insight_best_day_text'.tr()} $value ${'tasks'.tr()} 🚀';
                    insightIcon = FluentIcons.rocket_24_filled;
                    insightColor = AppColors.primary;
                    break;
                  case 'insight_completion_time':
                    insightText = '${'insight_completion_time_text'.tr()} $value ${'hours'.tr()} ⏱️';
                    insightIcon = FluentIcons.timer_24_filled;
                    insightColor = const Color(0xFF9C27B0);
                    break;
                  case 'insight_start_tracking':
                    insightText = 'insight_start_tracking_text'.tr();
                    insightIcon = FluentIcons.lightbulb_24_regular;
                    insightColor = AppColors.primary;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (insightIcon != null)
                        Icon(
                          insightIcon,
                          color: insightColor ?? AppColors.primary,
                          size: 18,
                        ),
                      if (insightIcon != null) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insightText,
                          style: TextStyle(
                            color: AppColors.getText(isDarkMode),
                            fontSize: AppColors.scaledFontSize(13),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
