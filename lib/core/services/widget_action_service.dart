import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Service for handling widget actions (toggle/delete todos from widget)
class WidgetActionService {
  static const String _channel = 'kr.bluesky.dodo/widget';
  static const String _methodToggleTodo = 'toggleTodo';
  static const String _methodDeleteTodo = 'deleteTodo';

  /// Toggle todo completion status from widget
  static Future<bool> toggleTodo(String todoId) async {
    try {
      final MethodChannel channel = const MethodChannel(_channel);
      final bool result = await channel.invokeMethod<bool>(
        _methodToggleTodo,
        {'todo_id': todoId},
      ) ?? false;

      logger.d('Widget toggle todo: $todoId → $result');
      return result;
    } catch (e) {
      logger.e('Error toggling todo from widget: $e');
      return false;
    }
  }

  /// Delete todo from widget
  static Future<bool> deleteTodo(String todoId) async {
    try {
      final MethodChannel channel = const MethodChannel(_channel);
      final bool result = await channel.invokeMethod<bool>(
        _methodDeleteTodo,
        {'todo_id': todoId},
      ) ?? false;

      logger.d('Widget delete todo: $todoId → $result');
      return result;
    } catch (e) {
      logger.e('Error deleting todo from widget: $e');
      return false;
    }
  }
}

/// Provider for widget action service
final widgetActionServiceProvider = Provider((_) => WidgetActionService);
