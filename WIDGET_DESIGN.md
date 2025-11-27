# Home Screen Widget Design Document

## 📱 Overview

Implement a home screen widget for both Android and iOS that displays either a calendar view or today's to-do list, with user-configurable toggle option.

## 🎯 Requirements

### Feature: Home Screen Widget with Dual View Options

**User Request**: "위젯 ui를 달력과 오늘 할일 중에 고를수 있도록 할수 있어???"
- Allow users to choose between calendar view and today's to-do list view
- Smooth toggle/switching mechanism
- Real-time data synchronization from app database
- Support for both Android and iOS platforms

### View Options

#### Option 1: Calendar View 📅
- Display monthly calendar with task indicators
- Highlight dates with pending tasks
- Show task count per day
- Tap date to navigate to app
- Minimal, clean design for home screen

#### Option 2: Today's To-Do List View 📋
- Display today's incomplete tasks (max 3-5 items)
- Show task title and due time
- Mark completed tasks with checkmark
- Quick action to open app
- Expandable list with scroll support

## 🏗️ Architecture

### Widget Package Dependencies
```yaml
dependencies:
  # Widget support
  home_widget: ^0.5.0          # Android/iOS widget support
  home_widget_null_safety: ^0.5.0  # Alternative with null safety

  # Additional utilities
  workmanager: ^0.5.0          # Background refresh
  uuid: ^4.0.0                 # Unique IDs for widgets
```

### Project Structure
```
lib/
├── core/
│   └── widget/
│       ├── widget_service.dart      # Widget update logic
│       ├── widget_models.dart       # Widget data models
│       └── widget_manager.dart      # Widget platform integration
│
├── presentation/
│   ├── providers/
│   │   └── widget_provider.dart    # Riverpod widget state
│   │
│   └── screens/
│       └── widget_config_screen.dart # Widget settings
│
android/
└── app/src/main/kotlin/
    └── widgets/
        ├── TodoCalendarWidget.kt    # Calendar widget
        └── TodoListWidget.kt        # List widget

ios/
└── Runner/
    └── Widgets/
        ├── TodoCalendarWidget/      # iOS calendar widget
        └── TodoListWidget/          # iOS list widget
```

## 🔄 Data Flow

### Update Flow
```
Database (Drift)
    ↓
WidgetService (read todos/dates)
    ↓
WidgetProvider (state management)
    ↓
home_widget package
    ↓
Android Native Widget / iOS WidgetKit
    ↓
Home Screen Display
```

### Toggle/Selection Mechanism
```
App Settings Screen
    ↓
User selects view type (calendar/list)
    ↓
WidgetConfigProvider stores preference
    ↓
WidgetService reads preference
    ↓
Generates appropriate data
    ↓
Native widget displays selected view
```

## 🎨 UI/UX Design

### Calendar Widget
```
┌─────────────────────────────┐
│        December 2025        │
├─────────────────────────────┤
│ Mo Tu We Th Fr Sa Su        │
│  1  2  3  4  5  6  7        │
│  8  9 10 11 12 13 14 🔴     │
│ 15 16 17 18 19 20 21        │
│ 22 23 24 25 26 27 28 ⭕     │
│ 29 30 31                    │
├─────────────────────────────┤
│  🔴 = Task today            │
│  ⭕ = Completed             │
└─────────────────────────────┘
```

### Today's List Widget
```
┌──────────────────────────┐
│   Today - Dec 25, 2025   │
├──────────────────────────┤
│ ☐ Meeting with team      │
│   📍 10:00 AM            │
├──────────────────────────┤
│ ☐ Project deadline       │
│   📍 3:00 PM             │
├──────────────────────────┤
│ ☑ Complete task          │
│   ✅ (Completed)         │
├──────────────────────────┤
│  Tap to view all todos   │
└──────────────────────────┘
```

## 🔧 Implementation Plan

### Phase 1: Setup and Models (1 day)
1. Add dependencies to pubspec.yaml
2. Create WidgetModels (CalendarData, TodoListData)
3. Create WidgetService with Drift integration
4. Create WidgetProvider with Riverpod
5. Implement widget configuration storage

### Phase 2: Widget Service (1 day)
1. Implement calendar data generation
2. Implement today's todos data generation
3. Add background refresh logic with WorkManager
4. Implement preference management

### Phase 3: Android Implementation (1.5 days)
1. Create TodoCalendarWidget.kt (Kotlin)
2. Create TodoListWidget.kt (Kotlin)
3. Implement widget configuration UI
4. Add notification callbacks for updates
5. Test on Android emulator and device

### Phase 4: iOS Implementation (1.5 days)
1. Create TodoCalendarWidget SwiftUI
2. Create TodoListWidget SwiftUI
3. Implement widget configuration
4. Test on iOS simulator and device
5. Handle WidgetKit timeline updates

### Phase 5: App Integration (1 day)
1. Create widget settings screen
2. Add widget toggle in settings
3. Implement widget data synchronization
4. Add widget preview in settings
5. Test complete flow

## 📋 Key Implementation Details

### WidgetService
```dart
class WidgetService {
  // Generate calendar data with task indicators
  Future<CalendarData> getCalendarData() async {
    final todos = await _todoRepository.getTodosForMonth(DateTime.now());
    return CalendarData.fromTodos(todos);
  }

  // Generate today's todos data
  Future<TodoListData> getTodaysTodos() async {
    final today = DateTime.now();
    final todos = await _todoRepository.getTodosForDate(today);
    return TodoListData.fromTodos(todos);
  }

  // Update widget display
  Future<void> updateWidget({required WidgetViewType type}) async {
    if (type == WidgetViewType.calendar) {
      final data = await getCalendarData();
      await homeWidget.saveWidgetData('calendar_data', data.toJson());
    } else {
      final data = await getTodaysTodos();
      await homeWidget.saveWidgetData('todos_data', data.toJson());
    }
  }
}
```

### WidgetProvider (Riverpod)
```dart
// Widget view type preference
final widgetViewTypeProvider = StateProvider<WidgetViewType>((ref) {
  return WidgetViewType.today; // Default to today's list
});

// Calendar data provider
final widgetCalendarDataProvider = FutureProvider<CalendarData>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  return service.getCalendarData();
});

// Today's todos data provider
final widgetTodosDataProvider = FutureProvider<TodoListData>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  return service.getTodaysTodos();
});

// Widget service provider
final widgetServiceProvider = Provider<WidgetService>((ref) {
  final todoRepo = ref.watch(todoRepositoryProvider);
  return WidgetService(todoRepo);
});
```

### Widget Configuration Storage
```dart
class WidgetConfig {
  static const String _viewTypeKey = 'widget_view_type';
  static const String _enabledKey = 'widget_enabled';

  Future<void> setViewType(WidgetViewType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewTypeKey, type.name);
  }

  Future<WidgetViewType> getViewType() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString(_viewTypeKey) ?? 'today';
    return WidgetViewType.values.byName(type);
  }
}
```

## 📊 State Management

### Widget View Types
```dart
enum WidgetViewType {
  calendar,  // Calendar view showing month with task indicators
  today,     // Today's to-do list view
}
```

### Data Models
```dart
@freezed
class CalendarData with _$CalendarData {
  const factory CalendarData({
    required DateTime month,
    required Map<int, int> dayTaskCounts,  // day -> task count
    required List<int> daysWithTasks,
    required DateTime lastUpdated,
  }) = _CalendarData;
}

@freezed
class TodoListData with _$TodoListData {
  const factory TodoListData({
    required DateTime date,
    required List<Todo> todos,
    required int completedCount,
    required int pendingCount,
    required DateTime lastUpdated,
  }) = _TodoListData;
}
```

## 🔔 Background Updates

### WorkManager Integration
```dart
void setupWidgetUpdates() {
  Workmanager().initializeFlutterBackgroundDispatcher();

  // Schedule periodic widget updates (every 30 minutes)
  Workmanager().registerPeriodicTask(
    'updateWidget',
    'updateWidgetTask',
    frequency: Duration(minutes: 30),
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'updateWidgetTask') {
      await WidgetService().updateWidgetDisplay();
      return true;
    }
    return false;
  });
}
```

## 🧪 Testing Strategy

### Unit Tests
- WidgetService data generation
- WidgetConfig preference storage
- Widget data model serialization

### Integration Tests
- Widget updates from database changes
- View type switching
- Background refresh triggers

### Manual Testing Checklist
- [ ] Android: Calendar widget displays correctly
- [ ] Android: Today's list widget displays correctly
- [ ] Android: Toggle between views works
- [ ] Android: Widget updates when app syncs
- [ ] iOS: Calendar widget displays correctly
- [ ] iOS: Today's list widget displays correctly
- [ ] iOS: Toggle between views works
- [ ] iOS: Widget updates in real-time
- [ ] Cross-platform: Settings persist after app close
- [ ] Cross-platform: Widget removes on app uninstall

## 📱 Platform-Specific Notes

### Android (home_widget)
- Uses RemoteViews for widget layout
- Updates via JobService for background refresh
- Configuration activity for settings
- Deep linking to app with intent

### iOS (WidgetKit)
- Uses SwiftUI for modern design
- Timeline entries for scheduled updates
- AppGroups for app-widget data sharing
- Deep links with App Intents

## 📝 Integration with Existing Features

### Sync Coordination
- Widget updates respect offline mode
- Local-first data for widget display
- Queue widget updates during sync
- Conflict resolution handled by app

### Notification Integration
- Widget can trigger notifications on tap
- Notifications can update widget state
- SharedPreferences for data passing

### Authentication
- Widget respects user authentication state
- Clear widget data on logout
- User-specific data in widget

## 🚀 Release Checklist

- [ ] Dependencies added to pubspec.yaml
- [ ] Code generation completed (build_runner)
- [ ] Android widget implementation complete
- [ ] iOS widget implementation complete
- [ ] App settings screen for widget config
- [ ] Documentation updated
- [ ] Manual testing completed on devices
- [ ] Version bumped in pubspec.yaml
- [ ] Commit and push to main branch
- [ ] Update FUTURE_TASKS.md with completion
- [ ] Add feature description to RELEASE_NOTES.md
- [ ] Update BEGINNER_GUIDE with widget usage

## 📖 Documentation Updates Required

1. **BEGINNER_GUIDE.md**: Add widget usage section
2. **BEGINNER_GUIDE.html**: Add widget tutorial tab
3. **RELEASE_NOTES.md**: Document widget feature
4. **CLAUDE.md**: Add widget development commands
5. **FUTURE_TASKS.md**: Mark widget as complete
