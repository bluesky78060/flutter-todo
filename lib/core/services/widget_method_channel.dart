import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

/// Widget MethodChannel 핸들러
/// 네이티브 위젯 코드와 Flutter 간의 통신 처리
class WidgetMethodChannelHandler {
  static const String _channel = 'kr.bluesky.dodo/widget';
  static final MethodChannel _methodChannel = MethodChannel(_channel);
  static ProviderContainer? _container;

  /// Set the provider container for dependency injection
  static void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  /// MethodChannel 리스너 설정
  static void setupMethodChannelListener() {
    _methodChannel.setMethodCallHandler((call) async {
      logger.d('🔔 위젯 MethodChannel 호출: ${call.method}');

      try {
        switch (call.method) {
          case 'toggleTodo':
            final args = call.arguments as Map?;
            final todoId = args?['todo_id'] as String?;
            if (todoId == null) {
              logger.w('⚠️ toggleTodo: todo_id 없음');
              return false;
            }
            logger.d('✅ 위젯에서 할일 토글 요청: $todoId');
            return await _handleToggleTodo(todoId);

          case 'addTodo':
            logger.d('✅ 위젯에서 할일 추가 요청');
            // 할일 추가는 앱 UI에서 처리 (추후 구현)
            return true;

          case 'deleteTodo':
            final args = call.arguments as Map?;
            final todoId = args?['todo_id'] as String?;
            if (todoId == null) {
              logger.w('⚠️ deleteTodo: todo_id 없음');
              return false;
            }
            logger.d('✅ 위젯에서 할일 삭제: $todoId');
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

  /// 할일 완료 토글 처리
  static Future<bool> _handleToggleTodo(String todoIdStr) async {
    try {
      final todoId = int.tryParse(todoIdStr);
      if (todoId == null) {
        logger.e('❌ 잘못된 todoId: $todoIdStr');
        return false;
      }

      final container = _container;
      if (container == null) {
        logger.e('❌ ProviderContainer가 설정되지 않음');
        return false;
      }

      // Use TodoActions to toggle completion (syncs with Supabase)
      final todoActions = container.read(todoActionsProvider);
      await todoActions.toggleCompletion(todoId);
      logger.d('✅ 할일 토글 완료 (Supabase 동기화 포함): $todoId');

      // Note: Widget update is already called inside todoActions.toggleCompletion()
      return true;
    } catch (e, st) {
      logger.e('❌ 할일 토글 처리 오류: $e', stackTrace: st);
      return false;
    }
  }
}
