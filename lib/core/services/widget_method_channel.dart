import 'package:flutter/services.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Widget MethodChannel 핸들러
/// 네이티브 위젯 코드와 Flutter 간의 통신 처리
class WidgetMethodChannelHandler {
  static const String _channel = 'kr.bluesky.dodo/widget';
  static final MethodChannel _methodChannel = MethodChannel(_channel);

  /// MethodChannel 리스너 설정
  static void setupMethodChannelListener() {
    _methodChannel.setMethodCallHandler((call) async {
      logger.d('🔔 위젯 MethodChannel 호출: ${call.method}');

      try {
        switch (call.method) {
          case 'toggleTodo':
            final todoId = call.arguments['todo_id'] as String?;
            if (todoId == null) {
              logger.w('⚠️ toggleTodo: todo_id 없음');
              return false;
            }
            logger.d('✅ 위젯에서 할일 토글: $todoId');
            // 실제 처리는 MainActivity 또는 앱 시작 후에 처리
            return true;

          case 'deleteTodo':
            final todoId = call.arguments['todo_id'] as String?;
            if (todoId == null) {
              logger.w('⚠️ deleteTodo: todo_id 없음');
              return false;
            }
            logger.d('✅ 위젯에서 할일 삭제: $todoId');
            // 실제 처리는 MainActivity 또는 앱 시작 후에 처리
            return true;

          default:
            logger.w('❓ 알 수 없는 위젯 메서드: ${call.method}');
            return false;
        }
      } catch (e, st) {
        logger.e('❌ 위젯 메서드 처리 오류: $e', stackTrace: st);
        return false;
      }
    });

    logger.d('✅ Widget MethodChannel 리스너 등록 완료');
  }

  /// 위젯 액션 처리 (앱 시작 후 호출)
  static Future<bool> handleToggleTodo(String todoId) async {
    logger.d('🔄 할일 토글 처리: $todoId');
    // 이 메서드는 나중에 앱 시작 후 Riverpod으로 처리
    return true;
  }

  static Future<bool> handleDeleteTodo(String todoId) async {
    logger.d('🔄 할일 삭제 처리: $todoId');
    // 이 메서드는 나중에 앱 시작 후 Riverpod으로 처리
    return true;
  }
}
