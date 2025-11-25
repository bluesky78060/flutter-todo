# 관리자 데이터 접근 권한 관리 구현 가이드

**작성일**: 2025-11-25
**상태**: 설계 완료, 구현 대기
**예상 소요 시간**: 4-6시간
**우선순위**: 🔴 High

---

## 📋 목차

1. [개요](#개요)
2. [문제 상황](#문제-상황)
3. [해결 방안](#해결-방안)
4. [Phase 1: Supabase SQL 함수 생성](#phase-1-supabase-sql-함수-생성)
5. [Phase 2: Flutter Datasource 구현](#phase-2-flutter-datasource-구현)
6. [Phase 3: Provider 및 State Management](#phase-3-provider-및-state-management)
7. [Phase 4: UI 구현](#phase-4-ui-구현)
8. [Phase 5: 테스트 및 검증](#phase-5-테스트-및-검증)

---

## 개요

### 목표
관리자가 사용자 개인 데이터에 직접 접근하지 않고도, 익명화된 통계를 통해 서비스 현황을 파악할 수 있도록 합니다.

### 핵심 원칙
- **Privacy by Design**: 개인정보는 절대 노출하지 않음
- **익명화된 집계**: 통계만 제공, 개별 사용자 데이터 접근 불가
- **SECURITY DEFINER**: Supabase 함수로 안전하게 통계 생성

---

## 문제 상황

### 현재 상태
```
관리자 → Supabase Dashboard → Table Editor → todos 테이블
→ 모든 사용자의 Todo 제목, 설명, 위치 정보 확인 가능 ❌
```

### 문제점
1. **프라이버시 침해 위험**: 관리자가 사용자 Todo 내용 직접 열람 가능
2. **위치 정보 노출**: 사용자의 위치 데이터가 그대로 노출
3. **법적 리스크**: GDPR/개인정보보호법 위반 가능성
4. **신뢰 문제**: 사용자 신뢰 저하 우려

---

## 해결 방안

### 접근 방식
1. **Supabase SQL 함수**: `SECURITY DEFINER`로 익명화된 통계 생성
2. **Flutter 관리자 대시보드**: 통계만 시각화하는 전용 화면
3. **RLS 유지**: Row Level Security는 그대로 유지

### 아키텍처
```
Flutter App (Admin Dashboard)
    ↓
Supabase RPC (SECURITY DEFINER Functions)
    ↓
PostgreSQL (Aggregated Statistics)
    ↓
익명화된 JSON 통계 반환
```

---

## Phase 1: Supabase SQL 함수 생성

### 예상 소요 시간: 10분

### 체크리스트
- [ ] Supabase Dashboard 접속
- [ ] SQL Editor 열기
- [ ] 함수 1: `get_user_statistics()` 생성
- [ ] 함수 2: `get_todo_statistics()` 생성
- [ ] 함수 3: `get_category_statistics()` 생성
- [ ] 함수 4: `get_activity_by_hour()` 생성
- [ ] 함수 5: `get_completion_by_weekday()` 생성
- [ ] 각 함수 실행 후 "Success" 확인

---

### 함수 1: 사용자 통계

```sql
-- 전체 사용자 수 및 활성 사용자 수
CREATE OR REPLACE FUNCTION get_user_statistics()
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM auth.users),
    'active_users_7d', (
      SELECT COUNT(DISTINCT user_id)
      FROM todos
      WHERE created_at > NOW() - INTERVAL '7 days'
    ),
    'active_users_30d', (
      SELECT COUNT(DISTINCT user_id)
      FROM todos
      WHERE created_at > NOW() - INTERVAL '30 days'
    ),
    'new_users_7d', (
      SELECT COUNT(*)
      FROM auth.users
      WHERE created_at > NOW() - INTERVAL '7 days'
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- 권한 설정
REVOKE ALL ON FUNCTION get_user_statistics() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_user_statistics() TO authenticated;
```

**예상 반환값:**
```json
{
  "total_users": 1523,
  "active_users_7d": 342,
  "active_users_30d": 876,
  "new_users_7d": 45
}
```

---

### 함수 2: Todo 통계

```sql
-- Todo 통계 (전체 집계)
CREATE OR REPLACE FUNCTION get_todo_statistics()
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_todos', (SELECT COUNT(*) FROM todos),
    'completed_todos', (SELECT COUNT(*) FROM todos WHERE is_completed = true),
    'pending_todos', (SELECT COUNT(*) FROM todos WHERE is_completed = false),
    'completion_rate', (
      SELECT ROUND(
        (COUNT(*) FILTER (WHERE is_completed = true)::NUMERIC /
         NULLIF(COUNT(*), 0)) * 100,
        2
      )
      FROM todos
    ),
    'todos_created_7d', (
      SELECT COUNT(*)
      FROM todos
      WHERE created_at > NOW() - INTERVAL '7 days'
    ),
    'todos_with_location', (
      SELECT COUNT(*)
      FROM todos
      WHERE location_latitude IS NOT NULL
    ),
    'todos_with_recurrence', (
      SELECT COUNT(*)
      FROM todos
      WHERE recurrence_rule IS NOT NULL
    )
  ) INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION get_todo_statistics() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_todo_statistics() TO authenticated;
```

**예상 반환값:**
```json
{
  "total_todos": 12453,
  "completed_todos": 7821,
  "pending_todos": 4632,
  "completion_rate": 62.81,
  "todos_created_7d": 342,
  "todos_with_location": 1234,
  "todos_with_recurrence": 567
}
```

---

### 함수 3: 카테고리 통계

```sql
-- 카테고리 사용 통계
CREATE OR REPLACE FUNCTION get_category_statistics()
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_categories', (SELECT COUNT(*) FROM categories),
    'avg_categories_per_user', (
      SELECT ROUND(AVG(category_count), 2)
      FROM (
        SELECT COUNT(*) as category_count
        FROM categories
        GROUP BY user_id
      ) as user_categories
    ),
    'categories_created_7d', (
      SELECT COUNT(*)
      FROM categories
      WHERE created_at > NOW() - INTERVAL '7 days'
    ),
    'most_used_colors', (
      SELECT json_agg(json_build_object('color', color, 'count', count))
      FROM (
        SELECT color, COUNT(*) as count
        FROM categories
        GROUP BY color
        ORDER BY count DESC
        LIMIT 5
      ) as color_stats
    )
  ) INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION get_category_statistics() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_category_statistics() TO authenticated;
```

**예상 반환값:**
```json
{
  "total_categories": 4567,
  "avg_categories_per_user": 3.42,
  "categories_created_7d": 89,
  "most_used_colors": [
    {"color": "#2B8DEE", "count": 1234},
    {"color": "#10B981", "count": 987}
  ]
}
```

---

### 함수 4: 시간대별 활동 통계

```sql
-- 시간대별 활동 통계 (24시간)
CREATE OR REPLACE FUNCTION get_activity_by_hour()
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'hour', hour,
      'todo_count', todo_count
    )
  )
  INTO result
  FROM (
    SELECT
      EXTRACT(HOUR FROM created_at) as hour,
      COUNT(*) as todo_count
    FROM todos
    WHERE created_at > NOW() - INTERVAL '30 days'
    GROUP BY hour
    ORDER BY hour
  ) as hourly_stats;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION get_activity_by_hour() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_activity_by_hour() TO authenticated;
```

**예상 반환값:**
```json
[
  {"hour": 0, "todo_count": 45},
  {"hour": 1, "todo_count": 23},
  {"hour": 9, "todo_count": 456},
  {"hour": 10, "todo_count": 523}
]
```

---

### 함수 5: 요일별 완료율 통계

```sql
-- 요일별 완료율 통계 (일~토: 0~6)
CREATE OR REPLACE FUNCTION get_completion_by_weekday()
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'weekday', weekday,
      'weekday_name', CASE weekday
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
      END,
      'total_todos', total_todos,
      'completed_todos', completed_todos,
      'completion_rate', completion_rate
    )
  )
  INTO result
  FROM (
    SELECT
      EXTRACT(DOW FROM created_at) as weekday,
      COUNT(*) as total_todos,
      COUNT(*) FILTER (WHERE is_completed = true) as completed_todos,
      ROUND(
        (COUNT(*) FILTER (WHERE is_completed = true)::NUMERIC /
         NULLIF(COUNT(*), 0)) * 100,
        2
      ) as completion_rate
    FROM todos
    WHERE created_at > NOW() - INTERVAL '90 days'
    GROUP BY weekday
    ORDER BY weekday
  ) as weekday_stats;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION get_completion_by_weekday() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_completion_by_weekday() TO authenticated;
```

**예상 반환값:**
```json
[
  {
    "weekday": 0,
    "weekday_name": "Sunday",
    "total_todos": 1234,
    "completed_todos": 789,
    "completion_rate": 63.92
  },
  {
    "weekday": 1,
    "weekday_name": "Monday",
    "total_todos": 1456,
    "completed_todos": 923,
    "completion_rate": 63.39
  }
]
```

---

### 검증 쿼리

함수 생성 후 테스트:

```sql
-- 각 함수 호출 테스트
SELECT get_user_statistics();
SELECT get_todo_statistics();
SELECT get_category_statistics();
SELECT get_activity_by_hour();
SELECT get_completion_by_weekday();
```

---

## Phase 2: Flutter Datasource 구현

### 예상 소요 시간: 1시간

### 체크리스트
- [ ] `lib/data/datasources/remote/supabase_admin_datasource.dart` 파일 생성
- [ ] 5개 함수 호출 메서드 구현
- [ ] 에러 핸들링 추가
- [ ] 로깅 추가

---

### 파일 구조

```
lib/
├── data/
│   └── datasources/
│       └── remote/
│           └── supabase_admin_datasource.dart  # 생성 필요
```

---

### 코드 구현

**파일**: `lib/data/datasources/remote/supabase_admin_datasource.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Supabase 관리자 통계 데이터소스
/// 익명화된 통계만 조회 가능
class SupabaseAdminDatasource {
  final SupabaseClient _client;

  SupabaseAdminDatasource(this._client);

  /// 사용자 통계 조회
  ///
  /// 반환값:
  /// - total_users: 전체 사용자 수
  /// - active_users_7d: 최근 7일 활성 사용자
  /// - active_users_30d: 최근 30일 활성 사용자
  /// - new_users_7d: 최근 7일 신규 가입자
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      AppLogger.info('📊 Fetching user statistics...');

      final response = await _client.rpc('get_user_statistics');

      if (response == null) {
        throw Exception('No data returned from get_user_statistics');
      }

      AppLogger.debug('✅ User statistics: $response');
      return response as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to fetch user statistics',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Todo 통계 조회
  ///
  /// 반환값:
  /// - total_todos: 전체 Todo 수
  /// - completed_todos: 완료된 Todo 수
  /// - pending_todos: 미완료 Todo 수
  /// - completion_rate: 완료율 (%)
  /// - todos_created_7d: 최근 7일 생성된 Todo 수
  /// - todos_with_location: 위치가 설정된 Todo 수
  /// - todos_with_recurrence: 반복 일정 Todo 수
  Future<Map<String, dynamic>> getTodoStatistics() async {
    try {
      AppLogger.info('📊 Fetching todo statistics...');

      final response = await _client.rpc('get_todo_statistics');

      if (response == null) {
        throw Exception('No data returned from get_todo_statistics');
      }

      AppLogger.debug('✅ Todo statistics: $response');
      return response as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to fetch todo statistics',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 카테고리 통계 조회
  ///
  /// 반환값:
  /// - total_categories: 전체 카테고리 수
  /// - avg_categories_per_user: 사용자당 평균 카테고리 수
  /// - categories_created_7d: 최근 7일 생성된 카테고리 수
  /// - most_used_colors: 가장 많이 사용된 색상 Top 5
  Future<Map<String, dynamic>> getCategoryStatistics() async {
    try {
      AppLogger.info('📊 Fetching category statistics...');

      final response = await _client.rpc('get_category_statistics');

      if (response == null) {
        throw Exception('No data returned from get_category_statistics');
      }

      AppLogger.debug('✅ Category statistics: $response');
      return response as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to fetch category statistics',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 시간대별 활동 통계 조회 (최근 30일)
  ///
  /// 반환값: List<{hour: int, todo_count: int}>
  Future<List<Map<String, dynamic>>> getActivityByHour() async {
    try {
      AppLogger.info('📊 Fetching activity by hour...');

      final response = await _client.rpc('get_activity_by_hour');

      if (response == null) {
        throw Exception('No data returned from get_activity_by_hour');
      }

      final list = List<Map<String, dynamic>>.from(response as List);
      AppLogger.debug('✅ Activity by hour: ${list.length} hours');
      return list;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to fetch activity by hour',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 요일별 완료율 통계 조회 (최근 90일)
  ///
  /// 반환값: List<{weekday: int, weekday_name: string, total_todos: int, completed_todos: int, completion_rate: double}>
  Future<List<Map<String, dynamic>>> getCompletionByWeekday() async {
    try {
      AppLogger.info('📊 Fetching completion by weekday...');

      final response = await _client.rpc('get_completion_by_weekday');

      if (response == null) {
        throw Exception('No data returned from get_completion_by_weekday');
      }

      final list = List<Map<String, dynamic>>.from(response as List);
      AppLogger.debug('✅ Completion by weekday: ${list.length} days');
      return list;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to fetch completion by weekday',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
```

---

## Phase 3: Provider 및 State Management

### 예상 소요 시간: 30분

### 체크리스트
- [ ] `lib/presentation/providers/admin_providers.dart` 파일 생성
- [ ] Datasource Provider 생성
- [ ] 5개 통계 Provider 생성
- [ ] 에러 상태 처리

---

### 코드 구현

**파일**: `lib/presentation/providers/admin_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/data/datasources/remote/supabase_admin_datasource.dart';

/// Supabase Admin Datasource Provider
final supabaseAdminDatasourceProvider = Provider<SupabaseAdminDatasource>((ref) {
  final client = Supabase.instance.client;
  return SupabaseAdminDatasource(client);
});

/// 사용자 통계 Provider
final userStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getUserStatistics();
});

/// Todo 통계 Provider
final todoStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getTodoStatistics();
});

/// 카테고리 통계 Provider
final categoryStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getCategoryStatistics();
});

/// 시간대별 활동 통계 Provider
final activityByHourProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getActivityByHour();
});

/// 요일별 완료율 통계 Provider
final completionByWeekdayProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getCompletionByWeekday();
});
```

---

## Phase 4: UI 구현

### 예상 소요 시간: 2-3시간

### 체크리스트
- [ ] `lib/presentation/screens/admin_dashboard_screen.dart` 파일 생성
- [ ] 사용자 통계 카드 위젯
- [ ] Todo 통계 카드 위젯
- [ ] 카테고리 통계 카드 위젯
- [ ] 시간대별 활동 그래프 (선택사항)
- [ ] 요일별 완료율 그래프 (선택사항)
- [ ] 설정 화면에서 관리자 대시보드 진입 버튼 추가

---

### 화면 구조

```
AdminDashboardScreen
├── AppBar (제목: "관리자 대시보드")
├── ScrollView
│   ├── UserStatisticsCard
│   ├── TodoStatisticsCard
│   ├── CategoryStatisticsCard
│   ├── ActivityByHourChart (선택사항)
│   └── CompletionByWeekdayChart (선택사항)
```

---

### 최소 구현 (그래프 없이)

**파일**: `lib/presentation/screens/admin_dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/admin_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: AppColors.getCard(isDarkMode),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 모든 Provider 새로고침
          ref.invalidate(userStatisticsProvider);
          ref.invalidate(todoStatisticsProvider);
          ref.invalidate(categoryStatisticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사용자 통계 카드
              _UserStatisticsCard(),
              const SizedBox(height: 16),

              // Todo 통계 카드
              _TodoStatisticsCard(),
              const SizedBox(height: 16),

              // 카테고리 통계 카드
              _CategoryStatisticsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사용자 통계 카드
class _UserStatisticsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final statsAsync = ref.watch(userStatisticsProvider);

    return Card(
      color: AppColors.getCard(isDarkMode),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👥 사용자 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _StatRow('전체 사용자', '${stats['total_users']}명', isDarkMode),
                  _StatRow('7일 활성', '${stats['active_users_7d']}명', isDarkMode),
                  _StatRow('30일 활성', '${stats['active_users_30d']}명', isDarkMode),
                  _StatRow('7일 신규', '${stats['new_users_7d']}명', isDarkMode),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                '오류: $error',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Todo 통계 카드
class _TodoStatisticsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final statsAsync = ref.watch(todoStatisticsProvider);

    return Card(
      color: AppColors.getCard(isDarkMode),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Todo 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _StatRow('전체 Todo', '${stats['total_todos']}개', isDarkMode),
                  _StatRow('완료', '${stats['completed_todos']}개', isDarkMode),
                  _StatRow('진행중', '${stats['pending_todos']}개', isDarkMode),
                  _StatRow('완료율', '${stats['completion_rate']}%', isDarkMode),
                  const Divider(),
                  _StatRow('7일 생성', '${stats['todos_created_7d']}개', isDarkMode),
                  _StatRow('위치 설정', '${stats['todos_with_location']}개', isDarkMode),
                  _StatRow('반복 일정', '${stats['todos_with_recurrence']}개', isDarkMode),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                '오류: $error',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 통계 카드
class _CategoryStatisticsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final statsAsync = ref.watch(categoryStatisticsProvider);

    return Card(
      color: AppColors.getCard(isDarkMode),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📁 카테고리 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _StatRow('전체 카테고리', '${stats['total_categories']}개', isDarkMode),
                  _StatRow('평균/사용자', '${stats['avg_categories_per_user']}개', isDarkMode),
                  _StatRow('7일 생성', '${stats['categories_created_7d']}개', isDarkMode),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                '오류: $error',
                style: TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 통계 행 위젯
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkMode;

  const _StatRow(this.label, this.value, this.isDarkMode);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.getText(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 설정 화면에 진입 버튼 추가

**파일**: `lib/presentation/screens/settings_screen.dart`

기존 설정 화면에 버튼 추가:

```dart
// 관리자 대시보드 버튼 (개발자/관리자 전용)
ListTile(
  leading: const Icon(Icons.admin_panel_settings),
  title: const Text('관리자 대시보드'),
  subtitle: const Text('익명화된 통계 보기'),
  onTap: () {
    context.push('/admin-dashboard');
  },
),
```

**라우터 설정**: `lib/core/router/app_router.dart`

```dart
GoRoute(
  path: '/admin-dashboard',
  builder: (context, state) => const AdminDashboardScreen(),
),
```

---

## Phase 5: 테스트 및 검증

### 예상 소요 시간: 30분

### 체크리스트
- [ ] Supabase 함수 직접 호출 테스트
- [ ] Flutter 앱에서 통계 조회 테스트
- [ ] 에러 핸들링 테스트 (네트워크 오류 등)
- [ ] UI 렌더링 확인
- [ ] 새로고침 기능 테스트

---

### 테스트 시나리오

#### 1. Supabase 함수 테스트

Supabase SQL Editor에서:

```sql
-- 각 함수 호출
SELECT get_user_statistics();
SELECT get_todo_statistics();
SELECT get_category_statistics();
SELECT get_activity_by_hour();
SELECT get_completion_by_weekday();
```

**예상 결과**: JSON 데이터 반환

---

#### 2. Flutter 앱 테스트

```bash
# 앱 실행
flutter run -d RF9NB0146AB

# 테스트 시나리오:
# 1. 설정 화면 열기
# 2. "관리자 대시보드" 버튼 탭
# 3. 통계 카드 3개가 정상 로드되는지 확인
# 4. Pull-to-refresh 테스트
# 5. 네트워크 끊고 에러 핸들링 확인
```

---

#### 3. 개인정보 보호 검증

**확인 사항**:
- [ ] 관리자 대시보드에 개인 Todo 내용이 표시되지 않음
- [ ] 위치 정보 (위도/경도/주소)가 표시되지 않음
- [ ] 사용자 이메일/이름이 표시되지 않음
- [ ] 집계된 숫자와 비율만 표시됨

---

## 📊 완료 기준

### Phase 1 완료
- ✅ 5개 SQL 함수가 Supabase에 생성됨
- ✅ 각 함수가 JSON 데이터를 반환함
- ✅ 권한 설정 완료 (authenticated만 접근 가능)

### Phase 2 완료
- ✅ `supabase_admin_datasource.dart` 파일 생성
- ✅ 5개 메서드 구현 및 테스트 통과

### Phase 3 완료
- ✅ `admin_providers.dart` 파일 생성
- ✅ 5개 Provider 정의

### Phase 4 완료
- ✅ `admin_dashboard_screen.dart` 파일 생성
- ✅ 3개 통계 카드 위젯 구현
- ✅ 설정 화면에 진입 버튼 추가
- ✅ 라우터 설정 완료

### Phase 5 완료
- ✅ 모든 테스트 시나리오 통과
- ✅ 개인정보 보호 검증 완료

---

## 🎯 다음 단계 (선택사항)

### 추가 기능
1. **그래프 시각화** (fl_chart 패키지)
   - 시간대별 활동 선 그래프
   - 요일별 완료율 막대 그래프

2. **날짜 필터**
   - 7일/30일/90일 필터 추가

3. **엑셀 내보내기**
   - 통계 데이터를 CSV/Excel로 내보내기

4. **실시간 갱신**
   - 자동 새로고침 (1분마다)

---

## 🔐 보안 체크리스트

- ✅ `SECURITY DEFINER` 함수 사용
- ✅ 개인 식별 정보 노출 없음
- ✅ 집계된 통계만 반환
- ✅ RLS 정책 유지
- ✅ `authenticated` 권한 필수
- ✅ SQL Injection 방지 (parameterized queries)

---

## 📚 참고 자료

- [Supabase Security Definer Functions](https://supabase.com/docs/guides/database/functions#security-definer-vs-invoker)
- [PostgreSQL JSON Functions](https://www.postgresql.org/docs/current/functions-json.html)
- [Flutter Riverpod Guide](https://riverpod.dev/docs/getting_started)
- [GDPR Privacy by Design](https://gdpr.eu/privacy-by-design/)

---

**작성자**: Claude Code
**최종 업데이트**: 2025-11-25
