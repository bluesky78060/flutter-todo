# 위젯 개선 기술문서

**작성일**: 2024-11-30
**버전**: 1.0.14
**작성자**: Claude Code

---

## 개요

오늘의 할일(TodoList) 위젯에 대한 여러 개선사항을 구현했습니다. 주요 변경사항은 다음과 같습니다:

1. 위젯 표시 항목 수를 4개에서 3개로 변경
2. 당일 할일만 표시하도록 필터링 로직 추가
3. 마감일 없는 할일도 생성일 기준으로 오늘의 할일에 포함
4. 위젯 체크박스 토글 시 Supabase 동기화 문제 해결
5. 위젯 컨테이너 클릭으로 앱 열기 기능 제거 (+ 버튼만 앱 실행)

---

## 1. 위젯 표시 항목 수 변경 (4개 → 3개)

### 변경 파일

#### `lib/core/widget/widget_service.dart`
```dart
// Before
final displayTodos = todoData.todos.take(4).toList();
for (int i = 0; i < 4; i++) { ... }

// After
final displayTodos = todoData.todos.take(3).toList();
for (int i = 0; i < 3; i++) { ... }
```

#### `android/app/src/main/kotlin/kr/bluesky/dodo/widgets/TodoListWidget.kt`
```kotlin
// Before
for (index in 1..4) { ... }

// After
for (index in 1..3) { ... }
```

#### `android/app/src/main/res/layout/widget_todo_list.xml`
- 4번째 할일 항목 (`widget_todo_4_container`) 제거
- 관련 TextView 및 ImageView 제거

---

## 2. 당일 할일만 표시하도록 필터링

### 변경 파일

#### `lib/core/widget/widget_models.dart`

**변경 전**: 모든 미완료 할일 표시

**변경 후**: 오늘 날짜의 할일만 표시

```dart
static TodoListData fromTodos(List<Todo> todos) {
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  // 위젯용: 오늘의 미완료 할일만 표시
  final pendingTodos = todos.where((todo) {
    if (todo.isCompleted) return false;

    // Case 1: 마감일이 있는 경우 - 오늘인지 확인
    if (todo.dueDate != null) {
      return todo.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
             todo.dueDate!.isBefore(todayEnd);
    }

    // Case 2: 마감일이 없는 경우 - 생성일이 오늘인지 확인
    return todo.createdAt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
           todo.createdAt.isBefore(todayEnd);
  }).toList();

  // 정렬: 마감일 → 알림시간 → 생성일 순
  pendingTodos.sort((a, b) {
    // 마감일 기준 정렬 (마감일 있는 것 우선)
    final aDue = a.dueDate;
    final bDue = b.dueDate;

    if (aDue != null && bDue != null) {
      final cmp = aDue.compareTo(bDue);
      if (cmp != 0) return cmp;
    } else if (aDue != null) {
      return -1; // a가 마감일 있음 → a 우선
    } else if (bDue != null) {
      return 1;  // b가 마감일 있음 → b 우선
    }

    // 알림시간 기준 정렬
    if (a.notificationTime != null && b.notificationTime != null) {
      final cmp = a.notificationTime!.compareTo(b.notificationTime!);
      if (cmp != 0) return cmp;
    }

    // 생성일 기준 정렬
    return a.createdAt.compareTo(b.createdAt);
  });

  return TodoListData(...);
}
```

### 필터링 로직 상세

| 조건 | 결과 |
|------|------|
| 완료된 할일 | 제외 |
| 마감일 = 오늘 | 포함 |
| 마감일 ≠ 오늘 | 제외 |
| 마감일 없음 + 생성일 = 오늘 | 포함 |
| 마감일 없음 + 생성일 ≠ 오늘 | 제외 |

---

## 3. 위젯 체크박스 토글 Supabase 동기화 문제 해결

### 문제 상황

위젯에서 체크박스를 눌러 완료 토글하면:
1. "✓ 완료!" 토스트 메시지 표시
2. 잠시 후 원래 상태로 되돌아감

### 원인 분석

```
[기존 흐름]
Android WidgetActionReceiver
    ↓ SharedPreferences 업데이트
    ↓ MethodChannel로 Flutter 알림
    ↓ refreshAllWidgets() ← 문제!

Flutter widget_method_channel.dart
    ↓ localDatabaseProvider.toggleTodoCompletion() ← 로컬 DB만 업데이트
    ↓ widgetService.updateWidget() ← Supabase 데이터로 위젯 덮어씀
```

**핵심 문제**:
1. Flutter가 로컬 DB만 업데이트하고 Supabase는 업데이트하지 않음
2. Android와 Flutter 양쪽에서 위젯을 새로고침하여 레이스 컨디션 발생
3. 최종적으로 Supabase의 (변경 안 된) 데이터로 위젯이 덮어써짐

### 해결 방법

#### `lib/core/services/widget_method_channel.dart`

```dart
// Before
static Future<bool> _handleToggleTodo(String todoIdStr) async {
  // ...
  // 로컬 DB만 업데이트
  final database = container.read(localDatabaseProvider);
  final result = await database.toggleTodoCompletion(todoId);

  // 위젯 업데이트
  final widgetService = container.read(widgetServiceProvider);
  await widgetService.updateWidget();
  // ...
}

// After
static Future<bool> _handleToggleTodo(String todoIdStr) async {
  // ...
  // TodoActions 사용 (Supabase 동기화 포함)
  final todoActions = container.read(todoActionsProvider);
  await todoActions.toggleCompletion(todoId);
  logger.d('✅ 할일 토글 완료 (Supabase 동기화 포함): $todoId');

  // Note: 위젯 업데이트는 toggleCompletion() 내부에서 이미 수행됨
  return true;
}
```

#### `android/app/src/main/kotlin/kr/bluesky/dodo/widgets/WidgetActionReceiver.kt`

```kotlin
// Before
// Flutter에 알리고 Android에서도 위젯 새로고침
channel.invokeMethod("toggleTodo", mapOf("todo_id" to todoId))
flutterNotified = true
// ... 계속 진행하여 refreshAllWidgets() 호출

// After
channel.invokeMethod("toggleTodo", mapOf("todo_id" to todoId))
flutterNotified = true
// Flutter가 모든 것을 처리하도록 함
val message = if (newState) "✓ 완료!" else "↩ 미완료"
Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
return // Flutter에게 처리 위임, Android에서는 위젯 새로고침 안 함
```

### 수정 후 동작 흐름

```
[수정된 흐름 - 앱 실행 중]
Android WidgetActionReceiver
    ↓ SharedPreferences 업데이트
    ↓ MethodChannel로 Flutter 알림
    ↓ Toast 표시
    ↓ return (Android에서 위젯 새로고침 안 함)

Flutter widget_method_channel.dart
    ↓ TodoActions.toggleCompletion()
        ↓ Repository.toggleCompletion() → Supabase 동기화!
        ↓ _updateWidget() → 위젯 업데이트
    ↓ 완료

[수정된 흐름 - 앱 닫힘]
Android WidgetActionReceiver
    ↓ SharedPreferences 업데이트
    ↓ MethodChannel 실패 (FlutterEngine 없음)
    ↓ toggleTodoInDatabase() → 로컬 DB 업데이트 시도
    ↓ refreshAllWidgets()
    ↓ Toast 표시
    ↓ (다음 앱 실행 시 Supabase와 동기화 필요)
```

---

## 4. 위젯 컨테이너 클릭 기능 제거

### 변경 파일

#### `android/app/src/main/kotlin/kr/bluesky/dodo/widgets/TodoListWidget.kt`

```kotlin
// Before
// Set up container click - opens app
val containerIntent = Intent(context, MainActivity::class.java).apply {
    action = Intent.ACTION_VIEW
    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
}
val containerPendingIntent = PendingIntent.getActivity(...)
views.setOnClickPendingIntent(R.id.widget_container, containerPendingIntent)

// After
// NOTE: Container click to open app is removed per user request
// Only the + (add) button will open the app now
```

### 변경 결과

| 위젯 영역 | 이전 동작 | 변경 후 동작 |
|----------|----------|-------------|
| + 버튼 | 앱 열기 (할일 추가) | 앱 열기 (할일 추가) |
| 할일 텍스트 | 앱 열기 | 동작 없음 |
| 체크박스 | 완료 토글 | 완료 토글 |
| 빈 공간 | 앱 열기 | 동작 없음 |

---

## 수정된 파일 목록

| 파일 경로 | 변경 내용 |
|----------|----------|
| `lib/core/widget/widget_models.dart` | 오늘 할일 필터링 로직 추가 |
| `lib/core/widget/widget_service.dart` | 표시 항목 수 4→3 변경 |
| `lib/core/services/widget_method_channel.dart` | TodoActions 사용으로 Supabase 동기화 |
| `android/.../widgets/TodoListWidget.kt` | 루프 범위 변경, 컨테이너 클릭 제거 |
| `android/.../widgets/WidgetActionReceiver.kt` | Flutter 처리 시 early return 추가 |
| `android/.../res/layout/widget_todo_list.xml` | 4번째 항목 제거 |

---

## 테스트 체크리스트

- [x] 위젯에 할일이 3개까지만 표시되는지 확인
- [x] 오늘 마감인 할일만 표시되는지 확인
- [x] 마감일 없이 오늘 생성한 할일이 표시되는지 확인
- [x] 어제 생성한 마감일 없는 할일이 표시되지 않는지 확인
- [x] 체크박스 토글 시 상태가 유지되는지 확인 (앱 실행 중)
- [x] 위젯 빈 공간 클릭 시 앱이 열리지 않는지 확인
- [x] + 버튼 클릭 시 앱이 열리는지 확인

---

## 알려진 제한사항

1. **앱이 닫혀 있을 때 위젯 토글**:
   - SharedPreferences와 로컬 DB만 업데이트됨
   - Supabase 동기화는 다음 앱 실행 시 수행 필요
   - 현재는 앱 실행 시 자동 동기화 로직 미구현

2. **오프라인 상태에서 위젯 토글**:
   - 로컬 DB 업데이트만 수행
   - 온라인 전환 시 동기화 필요

---

## 향후 개선 사항

1. 앱이 닫혀 있을 때도 위젯 토글이 Supabase에 동기화되도록 WorkManager 또는 Background Service 구현
2. 위젯에서 직접 할일 삭제 기능 추가
3. 위젯 크기에 따른 동적 항목 수 조절
