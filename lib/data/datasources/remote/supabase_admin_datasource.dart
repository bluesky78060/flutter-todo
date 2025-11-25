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
