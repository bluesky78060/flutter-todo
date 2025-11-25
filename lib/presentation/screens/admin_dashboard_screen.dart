import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/presentation/providers/admin_providers.dart';

/// 관리자 대시보드 화면
/// 익명화된 통계만 표시하며, 개인정보는 절대 노출되지 않음
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 관리자 권한 체크
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
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
                  const Text(
                    '접근 권한이 없습니다',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '관리자만 접근할 수 있는 페이지입니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text('돌아가기'),
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
              const Text(
                '권한 확인 중 오류 발생',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text('돌아가기'),
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
                    '개인정보 보호',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '이 대시보드는 익명화된 통계만 표시합니다.\n개인 식별 정보는 절대 노출되지 않습니다.',
                    style: TextStyle(
                      fontSize: 12,
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
                const Text(
                  '사용자 통계',
                  style: TextStyle(
                    fontSize: 18,
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
                    label: '전체 사용자',
                    value: '${stats['total_users'] ?? 0}명',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: '최근 7일 활성 사용자',
                    value: '${stats['active_users_7d'] ?? 0}명',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: '최근 30일 활성 사용자',
                    value: '${stats['active_users_30d'] ?? 0}명',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: '최근 7일 신규 가입자',
                    value: '${stats['new_users_7d'] ?? 0}명',
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
                const Text(
                  'Todo 통계',
                  style: TextStyle(
                    fontSize: 18,
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
                      label: '전체 Todo',
                      value: '${stats['total_todos'] ?? 0}개',
                      icon: Icons.list,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '완료된 Todo',
                      value: '${stats['completed_todos'] ?? 0}개',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '미완료 Todo',
                      value: '${stats['pending_todos'] ?? 0}개',
                      icon: Icons.pending_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '완료율',
                      value: '${completionRate.toStringAsFixed(1)}%',
                      icon: Icons.percent,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '최근 7일 생성',
                      value: '${stats['todos_created_7d'] ?? 0}개',
                      icon: Icons.add_circle_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '위치 설정된 Todo',
                      value: '${stats['todos_with_location'] ?? 0}개',
                      icon: Icons.location_on,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '반복 일정 Todo',
                      value: '${stats['todos_with_recurrence'] ?? 0}개',
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
                const Text(
                  '카테고리 통계',
                  style: TextStyle(
                    fontSize: 18,
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
                      label: '전체 카테고리',
                      value: '${stats['total_categories'] ?? 0}개',
                      icon: Icons.folder,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '사용자당 평균',
                      value: avgCategories.toStringAsFixed(1),
                      icon: Icons.person_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '최근 7일 생성',
                      value: '${stats['categories_created_7d'] ?? 0}개',
                      icon: Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                    if (mostUsedColors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '인기 색상 Top 5',
                        style: TextStyle(
                          fontSize: 14,
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
                                style: const TextStyle(fontSize: 13),
                              ),
                              const Spacer(),
                              Text(
                                '$count개',
                                style: TextStyle(
                                  fontSize: 13,
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
                const Text(
                  '시간대별 활동 (최근 30일)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            activityData.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('데이터가 없습니다'),
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
                              style: const TextStyle(fontSize: 12),
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
                              style: const TextStyle(
                                fontSize: 12,
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
                const Text(
                  '요일별 완료율 (최근 90일)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            completionData.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('데이터가 없습니다'),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${completionRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
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
                                  fontSize: 12,
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
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
            '데이터를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
