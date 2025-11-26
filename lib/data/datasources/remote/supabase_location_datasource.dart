import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/domain/entities/location_setting.dart';

class SupabaseLocationDataSource {
  final SupabaseClient _client;

  SupabaseLocationDataSource(this._client);

  /// 특정 Todo의 위치 설정 조회
  Future<LocationSetting?> getLocationSetting(int todoId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('location_settings')
          .select()
          .eq('user_id', userId)
          .eq('todo_id', todoId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return LocationSetting.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get location setting for todo $todoId', error: e);
      rethrow;
    }
  }

  /// 사용자의 모든 위치 설정 조회
  Future<List<LocationSetting>> getUserLocationSettings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('location_settings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => LocationSetting.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get user location settings', error: e);
      rethrow;
    }
  }

  /// 활성 위치 설정 조회 (inside/entering 상태)
  Future<List<LocationSetting>> getActiveLocationSettings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('location_settings')
          .select()
          .eq('user_id', userId)
          .inFilter('geofence_state', ['inside', 'entering']);

      return (response as List)
          .map((e) => LocationSetting.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get active location settings', error: e);
      rethrow;
    }
  }

  /// 위치 설정 생성
  Future<int> createLocationSetting(
    int todoId,
    double latitude,
    double longitude,
    int radius, {
    String? locationName,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.from('location_settings').insert({
        'user_id': userId,
        'todo_id': todoId,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'location_name': locationName,
        'geofence_state': 'outside',
      }).select().single();

      AppLogger.info(
        '📍 Created location setting for todo $todoId at ($latitude, $longitude)',
      );

      return response['id'] as int;
    } catch (e) {
      AppLogger.error(
        'Failed to create location setting for todo $todoId',
        error: e,
      );
      rethrow;
    }
  }

  /// 위치 설정 수정
  Future<void> updateLocationSetting(LocationSetting setting) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('location_settings')
          .update({
            'latitude': setting.latitude,
            'longitude': setting.longitude,
            'radius': setting.radius,
            'location_name': setting.locationName,
            'geofence_state': setting.geofenceState,
            'triggered_at': setting.triggeredAt?.toIso8601String(),
          })
          .eq('id', setting.id)
          .eq('user_id', userId);

      AppLogger.info('📍 Updated location setting ${setting.id}');
    } catch (e) {
      AppLogger.error(
        'Failed to update location setting ${setting.id}',
        error: e,
      );
      rethrow;
    }
  }

  /// 위치 설정 삭제
  Future<void> deleteLocationSetting(int id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('location_settings')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      AppLogger.info('📍 Deleted location setting $id');
    } catch (e) {
      AppLogger.error('Failed to delete location setting $id', error: e);
      rethrow;
    }
  }

  /// Geofence 상태 업데이트
  Future<void> updateGeofenceState(int id, String newState) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('location_settings')
          .update({'geofence_state': newState})
          .eq('id', id)
          .eq('user_id', userId);

      AppLogger.debug('🔄 Updated geofence state for $id to $newState');
    } catch (e) {
      AppLogger.error(
        'Failed to update geofence state for $id',
        error: e,
      );
      rethrow;
    }
  }

  /// 마지막 알림 시간 업데이트
  Future<void> updateTriggeredAt(int id, DateTime triggeredTime) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('location_settings')
          .update({
            'triggered_at': triggeredTime.toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', userId);

      AppLogger.debug('⏱️ Updated triggered_at for $id');
    } catch (e) {
      AppLogger.error(
        'Failed to update triggered_at for $id',
        error: e,
      );
      rethrow;
    }
  }

}
