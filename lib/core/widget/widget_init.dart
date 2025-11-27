import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Initialize widget system on app startup
Future<void> initializeWidgetSystem() async {
  try {
    // Set app group for shared data between app and widget
    // This enables communication between main app and home screen widget
    await HomeWidget.setAppGroupId('group.dodo.widget');

    if (!kIsWeb) {
      // Register widget update callback
      HomeWidget.widgetClicked.listen((String uri) {
        _handleWidgetClick(uri);
      });
    }

    print('Widget system initialized');
  } catch (e) {
    print('Error initializing widget system: $e');
  }
}

/// Handle widget click/tap events
void _handleWidgetClick(String uri) {
  print('Widget clicked: $uri');
  // Handle widget tap to open app or navigate to specific screen
  // This can be implemented based on the URI pattern from widget
}

/// Update widget after data changes in the app
Future<void> updateWidgetAfterChange() async {
  try {
    if (!kIsWeb) {
      // This will be called from WidgetService when data changes
      await HomeWidget.updateWidget(
        name: 'TodoListWidget',
        iOSName: 'TodoListWidget',
      );
    }
  } catch (e) {
    print('Error updating widget after change: $e');
  }
}

/// Request widget update from background task
Future<void> requestWidgetUpdate() async {
  try {
    if (!kIsWeb) {
      await HomeWidget.updateWidget(
        name: 'TodoListWidget',
        iOSName: 'TodoListWidget',
        qualifiedAndroidClassName: 'com.dodo.todo_app.TodoListWidget',
      );
    }
  } catch (e) {
    print('Error requesting widget update: $e');
  }
}
