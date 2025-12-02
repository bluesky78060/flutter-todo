/// Admin dashboard screen for application analytics and management.
///
/// Features:
/// - Anonymized user statistics (no personal data)
/// - Total user and todo counts
/// - Active user metrics
/// - System health indicators
/// - Admin-only access control
///
/// Privacy:
/// - Only aggregated, anonymized data is displayed
/// - No individual user data is ever shown
/// - Access restricted to users with admin role
///
/// See also:
/// - [isAdminProvider] for admin role verification
/// - [adminStatsProvider] for statistics data
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/admin_providers.dart';

/// Admin dashboard showing anonymized application statistics.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 관리자 권한 체크
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('admin_dashboard'.tr()),
        centerTitle: true,
      ),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (!isAdmin) {
            // 관리자가 아닌 경우 접근 거부 화면 표시
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'access_denied'.tr(),
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'admin_only_page'.tr(),
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(16),
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text('go_back'.tr()),
                  ),
                ],
              ),
            );
          }

          // 관리자인 경우 대시보드 표시
          return RefreshIndicator(
        onRefresh: () async {
          // 모든 통계 데이터 새로고침
          ref.invalidate(userStatisticsProvider);
          ref.invalidate(todoStatisticsProvider);
          ref.invalidate(categoryStatisticsProvider);
          ref.invalidate(activityByHourProvider);
          ref.invalidate(completionByWeekdayProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
            _PrivacyNotice(),
            SizedBox(height: 16),
            _UserStatisticsCard(),
            SizedBox(height: 16),
            _TodoStatisticsCard(),
            SizedBox(height: 16),
            _CategoryStatisticsCard(),
            SizedBox(height: 16),
            _ActivityByHourCard(),
            SizedBox(height: 16),
            _CompletionByWeekdayCard(),
          ],
        ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'permission_check_failed'.tr(),
                style: TextStyle(
                  fontSize: AppColors.scaledFontSize(24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: AppColors.scaledFontSize(14),
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                child: Text('go_back'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 개인정보 보호 안내 위젯
class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.blue.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'privacy_protection'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppColors.scaledFontSize(16),
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'privacy_dashboard_notice'.tr(),
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(12),
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사용자 통계 카드
class _UserStatisticsCard extends ConsumerWidget {
  const _UserStatisticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatisticsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'user_statistics'.tr(),
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            userStats.when(
              data: (stats) => Column(
                children: [
                  _StatRow(
                    label: 'total_users'.tr(),
                    value: '${stats['total_users'] ?? 0}',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: 'active_users_7d'.tr(),
                    value: '${stats['active_users_7d'] ?? 0}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: 'active_users_30d'.tr(),
                    value: '${stats['active_users_30d'] ?? 0}',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: 'new_users_7d'.tr(),
                    value: '${stats['new_users_7d'] ?? 0}',
                    icon: Icons.person_add,
                    color: Colors.orange,
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _ErrorWidget(error: error.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Todo 통계 카드
class _TodoStatisticsCard extends ConsumerWidget {
  const _TodoStatisticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoStats = ref.watch(todoStatisticsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'todo_statistics'.tr(),
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            todoStats.when(
              data: (stats) {
                final completionRate = (stats['completion_rate'] as num?)?.toDouble() ?? 0.0;
                return Column(
                  children: [
                    _StatRow(
                      label: 'total_todos'.tr(),
                      value: '${stats['total_todos'] ?? 0}',
                      icon: Icons.list,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'completed_todos'.tr(),
                      value: '${stats['completed_todos'] ?? 0}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'pending_todos'.tr(),
                      value: '${stats['pending_todos'] ?? 0}',
                      icon: Icons.pending_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'completion_rate'.tr(),
                      value: '${completionRate.toStringAsFixed(1)}%',
                      icon: Icons.percent,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'todos_created_7d'.tr(),
                      value: '${stats['todos_created_7d'] ?? 0}',
                      icon: Icons.add_circle_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'todos_with_location'.tr(),
                      value: '${stats['todos_with_location'] ?? 0}',
                      icon: Icons.location_on,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'todos_with_recurrence'.tr(),
                      value: '${stats['todos_with_recurrence'] ?? 0}',
                      icon: Icons.repeat,
                      color: Colors.teal,
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _ErrorWidget(error: error.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 통계 카드
class _CategoryStatisticsCard extends ConsumerWidget {
  const _CategoryStatisticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryStats = ref.watch(categoryStatisticsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'category_statistics'.tr(),
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            categoryStats.when(
              data: (stats) {
                final avgCategories = stats['avg_categories_per_user'] ?? 0.0;
                final mostUsedColors = stats['most_used_colors'] as List<dynamic>? ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      label: 'total_categories'.tr(),
                      value: '${stats['total_categories'] ?? 0}',
                      icon: Icons.folder,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'avg_categories_per_user'.tr(),
                      value: avgCategories.toStringAsFixed(1),
                      icon: Icons.person_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'categories_created_7d'.tr(),
                      value: '${stats['categories_created_7d'] ?? 0}',
                      icon: Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                    if (mostUsedColors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'most_used_colors_top5'.tr(),
                        style: TextStyle(
                          fontSize: AppColors.scaledFontSize(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...mostUsedColors.map((colorData) {
                        final color = colorData['color'] as String?;
                        final count = colorData['count'] as int?;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _parseColor(color ?? '#000000'),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                color ?? 'Unknown',
                                style: TextStyle(fontSize: AppColors.scaledFontSize(13)),
                              ),
                              const Spacer(),
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: AppColors.scaledFontSize(13),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _ErrorWidget(error: error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// 시간대별 활동 통계 카드
class _ActivityByHourCard extends ConsumerWidget {
  const _ActivityByHourCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityData = ref.watch(activityByHourProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'activity_by_hour'.tr(),
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            activityData.when(
              data: (data) {
                if (data.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('no_data'.tr()),
                    ),
                  );
                }

                final maxCount = data.map((e) => e['todo_count'] as int? ?? 0).reduce((a, b) => a > b ? a : b);

                return Column(
                  children: data.map((hourData) {
                    final hour = hourData['hour'] as int? ?? 0;
                    final count = hourData['todo_count'] as int? ?? 0;
                    final percentage = maxCount > 0 ? count / maxCount : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(fontSize: AppColors.scaledFontSize(12)),
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage,
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: AppColors.scaledFontSize(12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _ErrorWidget(error: error.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

/// 요일별 완료율 통계 카드
class _CompletionByWeekdayCard extends ConsumerWidget {
  const _CompletionByWeekdayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionData = ref.watch(completionByWeekdayProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'completion_by_weekday'.tr(),
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            completionData.when(
              data: (data) {
                if (data.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('no_data'.tr()),
                    ),
                  );
                }

                return Column(
                  children: data.map((weekdayData) {
                    final weekdayName = weekdayData['weekday_name'] as String? ?? 'Unknown';
                    final totalTodos = weekdayData['total_todos'] as int? ?? 0;
                    final completedTodos = weekdayData['completed_todos'] as int? ?? 0;
                    final completionRate = (weekdayData['completion_rate'] as num?)?.toDouble() ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                weekdayName,
                                style: TextStyle(
                                  fontSize: AppColors.scaledFontSize(14),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${completionRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: AppColors.scaledFontSize(14),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: completionRate / 100,
                                      child: Container(
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: _getCompletionColor(completionRate),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$completedTodos/$totalTodos',
                                style: TextStyle(
                                  fontSize: AppColors.scaledFontSize(12),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _ErrorWidget(error: error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.lightGreen;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// 통계 행 위젯
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: AppColors.scaledFontSize(14)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppColors.scaledFontSize(14),
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// 에러 위젯
class _ErrorWidget extends StatelessWidget {
  final String error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
          const SizedBox(height: 12),
          Text(
            'data_load_failed'.tr(),
            style: TextStyle(
              fontSize: AppColors.scaledFontSize(16),
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: AppColors.scaledFontSize(12), color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
