# Home Screen Widget Implementation Guide

## 📋 Overview

This guide documents the Flutter home screen widget implementation for the DoDo Todo App. The widget provides two display modes: Calendar View and Today's To-Do List.

## 🎯 Current Implementation Status

### ✅ Completed Tasks
1. **Design Document** - Comprehensive widget architecture design
2. **Dependencies** - Added `home_widget: ^0.5.0` to pubspec.yaml
3. **Data Models** - Created freezed models for calendar and todo list data
4. **Widget Service** - Implemented WidgetService for data management
5. **Riverpod Providers** - Created state management providers
6. **Configuration UI** - Built widget settings screen
7. **Initialization** - Set up widget system initialization

### 🔄 In Progress
- Android native widget implementation
- iOS native widget implementation

### ⏳ Pending
- Integration with todo sync
- Background update scheduling
- Testing on physical devices

## 📁 File Structure

```
lib/
├── core/
│   └── widget/
│       ├── widget_models.dart      # Data models (CalendarData, TodoListData)
│       ├── widget_service.dart     # Widget management service
│       └── widget_init.dart        # System initialization
│
└── presentation/
    ├── providers/
    │   └── widget_provider.dart    # Riverpod state management
    │
    └── screens/
        └── widget_config_screen.dart # Settings UI
```

## 🔧 Key Components

### 1. Widget Models (`widget_models.dart`)

**CalendarData**
- Represents calendar view data
- Tracks days with tasks and completion status
- Methods: `fromTodos()`, `getTaskCount()`, `hasTasksOnDay()`

**TodoListData**
- Represents today's todo list data
- Filters todos for current date
- Methods: `fromTodos()`, `getDisplayTodos()`, `progressPercentage`

**WidgetViewType Enum**
```dart
enum WidgetViewType {
  calendar,  // Calendar view
  today,     // Today's todo list
}
```

### 2. Widget Service (`widget_service.dart`)

Core service handling widget lifecycle:

```dart
// Update widget display
await widgetService.updateWidget();

// Get calendar data
final calendarData = await widgetService.getCalendarData();

// Get today's todos
final todoData = await widgetService.getTodaysTodos();

// Set view preference
await widgetService.setWidgetViewType(WidgetViewType.calendar);

// Handle logout
await widgetService.clearWidgetData();
```

### 3. Riverpod Providers (`widget_provider.dart`)

**State Providers**
- `widgetConfigProvider` - Current widget configuration
- `widgetViewTypeProvider` - Selected view type
- `widgetEnabledProvider` - Enable/disable state

**Data Providers**
- `widgetCalendarDataProvider` - Calendar data (FutureProvider)
- `widgetTodoListDataProvider` - Today's todos (FutureProvider)

**Action Providers**
- `updateWidgetViewTypeProvider` - Change view type
- `toggleWidgetEnabledProvider` - Enable/disable widget
- `manualWidgetUpdateProvider` - Manual refresh

**Example Usage**
```dart
// In consumer widget
final viewType = ref.watch(widgetViewTypeProvider);
final calendarData = ref.watch(widgetCalendarDataProvider);

// Update view type
ref.read(updateWidgetViewTypeProvider(WidgetViewType.calendar));
```

### 4. Configuration Screen (`widget_config_screen.dart`)

User interface for widget settings:
- Toggle widget enable/disable
- Select between calendar and today's list views
- Real-time updates

## 🚀 How to Use

### Adding Widget to App

1. **Initialize on app startup** (in `main.dart`):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... other initialization ...

  // Initialize widget system
  await initializeWidgetSystem();

  runApp(const MyApp());
}
```

2. **Add widget settings route** to your navigation:
```dart
GoRoute(
  path: '/widget-config',
  name: 'widgetConfig',
  builder: (context, state) => const WidgetConfigScreen(),
),
```

3. **Update widget after todo changes**:
```dart
// In TodoActions or wherever todos are modified
Future<void> addTodo(TodoEntity todo) async {
  // ... add todo logic ...

  // Update widget
  ref.read(widgetUpdateNotifierProvider.notifier).updateWidget();
}
```

### Widget Settings Integration

In your settings screen, add link to widget configuration:
```dart
ListTile(
  title: const Text('Widget Settings'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/widget-config'),
),
```

## 🔄 Data Flow

### On App Start
```
App Launch
  ↓
initializeWidgetSystem()
  ↓
HomeWidget.setAppGroupId()
  ↓
Load previous widget data
  ↓
Update widget display
```

### When Todo Changes
```
Todo Added/Updated/Deleted
  ↓
Notify TodoRepository
  ↓
widgetUpdateNotifierProvider.updateWidget()
  ↓
WidgetService.updateWidget()
  ↓
Get fresh data (CalendarData or TodoListData)
  ↓
Save to SharedPreferences/AppGroup
  ↓
Notify native widget
  ↓
Native widget updates display
```

### When View Type Changes
```
User selects Calendar/Today's List
  ↓
ref.read(updateWidgetViewTypeProvider(newType))
  ↓
WidgetService.setWidgetViewType()
  ↓
Save preference
  ↓
WidgetService.updateWidget()
  ↓
Native widget updates display
```

## 📱 Platform-Specific Implementation

### Android Native Widget

Location: `android/app/src/main/kotlin/com/dodo/todo_app/`

**Required Files**:
- `TodoCalendarWidget.kt` - Calendar widget implementation
- `TodoListWidget.kt` - Today's list widget implementation

**Key Features**:
- RemoteViews for widget layout
- BroadcastReceiver for app updates
- JobService for background refresh
- Configuration activity for settings

**Example**:
```kotlin
class TodoCalendarWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}
```

### iOS Native Widget

Location: `ios/Runner/Widgets/`

**Required Files**:
- `TodoCalendarWidget/` - Calendar widget with SwiftUI
- `TodoListWidget/` - List widget with SwiftUI

**Key Features**:
- WidgetKit for modern widget system
- Timeline entries for scheduled updates
- AppGroups for app-widget data sharing
- Deep links with App Intents

**Example**:
```swift
@main
struct TodoCalendarWidget: Widget {
    let kind: String = "TodoCalendarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            TodoCalendarWidgetEntryView(entry: entry)
        }
    }
}
```

## 🔌 Integration Points

### 1. Authentication Logout
When user logs out, clear widget data:
```dart
// In auth_provider or auth_actions
await ref.read(widgetServiceProvider).clearWidgetData();
```

### 2. Todo Sync
After successful sync:
```dart
// In todo_providers or sync_provider
ref.read(manualWidgetUpdateProvider);
```

### 3. Settings Screen
Add widget configuration link:
```dart
// In settings_screen
GestureDetector(
  onTap: () => context.push('/widget-config'),
  child: ListTile(
    title: Text(tr('widget_settings')),
    trailing: Icon(Icons.chevron_right),
  ),
),
```

## 🧪 Testing

### Unit Tests
```dart
test('Calendar data generation', () {
  final todos = [/* test todos */];
  final calendarData = CalendarData.fromTodos(todos, DateTime.now());

  expect(calendarData.month, DateTime.now());
  expect(calendarData.daysWithTasks.length, greaterThan(0));
});

test('Widget preference persistence', () async {
  final service = WidgetService(
    todoRepository: mockRepo,
    preferences: mockPrefs,
  );

  await service.setWidgetViewType(WidgetViewType.calendar);
  final config = service.getWidgetConfig();

  expect(config.viewType, WidgetViewType.calendar);
});
```

### Manual Testing Checklist
- [ ] Widget displays today's tasks correctly
- [ ] Widget displays calendar view correctly
- [ ] Toggle between views works
- [ ] Widget updates when todo added/updated
- [ ] Widget persists selection after app close
- [ ] Widget works in offline mode
- [ ] Widget clears on logout
- [ ] Widget does not appear on web platform
- [ ] Android widget responds to taps
- [ ] iOS widget updates on schedule

## 📊 Background Updates

### WorkManager Integration (Optional)

For periodic widget updates:

```dart
void setupWidgetUpdates() {
  Workmanager().initializeFlutterBackgroundDispatcher();

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
      // Get service from repository
      final service = /* get WidgetService */;
      await service.updateWidget();
      return true;
    }
    return false;
  });
}
```

## 🐛 Troubleshooting

### Widget Not Updating
1. Check if `homeWidget.setAppGroupId()` was called
2. Verify `WidgetService.updateWidget()` completes without error
3. Ensure native widget is properly registered in AndroidManifest.xml or Info.plist

### Data Not Persisting
1. Verify SharedPreferences initialization in `widgetServiceProvider`
2. Check if AppGroupId matches between app and widget
3. Ensure data serialization (toJson/fromJson) works correctly

### Widget Crashes on Launch
1. Check if required dependencies are installed
2. Verify native code (Kotlin/Swift) has no syntax errors
3. Check logcat (Android) or Xcode logs (iOS) for detailed errors

## 📚 Related Documentation

- `WIDGET_DESIGN.md` - Architecture and design specifications
- `CLAUDE.md` - Project development guide
- `FUTURE_TASKS.md` - Overall feature roadmap

## 🔄 Next Steps

1. **Implement Android Widget** (1.5 days)
   - Create TodoCalendarWidget.kt
   - Create TodoListWidget.kt
   - Test on Android emulator

2. **Implement iOS Widget** (1.5 days)
   - Create TodoCalendarWidget SwiftUI
   - Create TodoListWidget SwiftUI
   - Test on iOS simulator

3. **Integration Testing** (1 day)
   - Full flow testing with real data
   - Background update verification
   - Sync coordination testing

4. **Release** (Documentation + Deployment)
   - Update BEGINNER_GUIDE.md
   - Update RELEASE_NOTES.md
   - Version bump in pubspec.yaml
   - Git commit and push

## 💡 Tips and Best Practices

1. **Data Serialization** - Always implement `toJson()` and `fromJson()` for data models
2. **Error Handling** - Gracefully handle widget updates failures
3. **Performance** - Limit widget data to essential fields only
4. **User Experience** - Provide visual feedback for widget state changes
5. **Testing** - Test widget on real devices, not just emulators
6. **Documentation** - Keep widget configuration options clearly documented
