import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/widget_action_provider.dart';

/// Widget MethodChannel handler
/// Handles communication between native Android widget code and Flutter
class WidgetMethodChannelHandler {
  static const String _channel = 'kr.bluesky.dodo/widget';

  static void setupMethodChannel(WidgetRef ref) {
    final channel = MethodChannel(_channel);

    channel.setMethodCallHandler((call) async {
      logger.d('Widget MethodChannel call: ${call.method}');

      try {
        switch (call.method) {
          case 'toggleTodo':
            final todoId = call.argument<String>('todo_id');
            if (todoId == null) {
              return false;
            }
            await ref.read(widgetActionProvider.notifier).toggleTodoFromWidget(todoId);
            return true;

          case 'deleteTodo':
            final todoId = call.argument<String>('todo_id');
            if (todoId == null) {
              return false;
            }
            await ref.read(widgetActionProvider.notifier).deleteTodoFromWidget(todoId);
            return true;

          default:
            logger.w('Unknown widget method: ${call.method}');
            return false;
        }
      } catch (e) {
        logger.e('Error handling widget method: $e');
        return false;
      }
    });
  }
}

/// Provider for setting up widget MethodChannel
final widgetMethodChannelProvider = FutureProvider<void>((ref) async {
  WidgetMethodChannelHandler.setupMethodChannel(ref);
});
