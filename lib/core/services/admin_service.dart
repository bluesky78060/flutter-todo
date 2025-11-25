import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// 관리자 권한 체크 서비스
class AdminService {
  final SupabaseClient _client;

  AdminService(this._client);

  /// 현재 사용자가 관리자인지 체크
  Future<bool> isAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        AppLogger.debug('🔒 No user logged in');
        return false;
      }

      AppLogger.debug('🔍 Checking admin status for user: ${user.email}');

      // Supabase RPC 함수 호출
      final result = await _client.rpc('is_admin');

      AppLogger.debug('✅ Admin check result: $result');
      return result == true;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to check admin status',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 사용자의 역할 조회
  Future<String?> getUserRole() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to get user role',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
