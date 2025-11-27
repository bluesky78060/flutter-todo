# Advanced Interactive Widget Implementation Guide

**문서 작성일**: 2025-11-27
**대상 기능**: Samsung Style Interactive Todo Widget
**예상 작업 시간**: 1-2주
**우선순위**: High

---

## 1. 개요

### 1.1 현재 상태
DoDo 앱의 현재 위젯은 기본적인 정보 표시만 지원합니다:
- **TodoListWidget**: 오늘의 할일 5개 표시 (정적)
- **TodoCalendarWidget**: 월간 캘린더 + 할일 인디케이터

### 1.2 목표 (삼성 리마인더 스타일)
사용자가 위젯에서 직접 상호작용할 수 있는 풍부한 기능:
- 일자별 할일 그룹화
- 완료/삭제 직접 처리
- 새 할일 추가 바로가기
- 완료 진행률 표시
- 다가오는 이벤트 섹션

---

## 2. 기술 아키텍처

### 2.1 필요 컴포넌트

```
┌─────────────────────────────────────────────────────────────┐
│                    Android Widget System                     │
├─────────────────────────────────────────────────────────────┤
│  AppWidgetProvider (TodoListWidget)                         │
│    ├── RemoteViewsService (동적 리스트 데이터)               │
│    │     └── RemoteViewsFactory (각 아이템 생성)            │
│    ├── BroadcastReceiver (버튼 클릭 처리)                   │
│    └── PendingIntent (아이템별 액션)                        │
├─────────────────────────────────────────────────────────────┤
│  Flutter ↔ Native 통신                                      │
│    ├── MethodChannel (데이터 동기화)                        │
│    ├── SharedPreferences (home_widget)                      │
│    └── EventChannel (실시간 업데이트)                       │
├─────────────────────────────────────────────────────────────┤
│  Flutter App                                                 │
│    ├── WidgetService (데이터 제공)                          │
│    ├── TodoRepository (CRUD)                                │
│    └── MainActivity (딥링크 처리)                           │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 데이터 흐름

```
[위젯 체크박스 클릭]
    ↓
[BroadcastReceiver 수신]
    ↓
[MethodChannel → Flutter 호출]
    ↓
[TodoRepository.toggleCompletion()]
    ↓
[Drift DB + Supabase 업데이트]
    ↓
[WidgetService.updateWidget()]
    ↓
[SharedPreferences 데이터 저장]
    ↓
[AppWidgetManager.notifyAppWidgetViewDataChanged()]
    ↓
[위젯 UI 갱신]
```

---

## 3. 구현 세부사항

### 3.1 파일 구조

```
android/app/src/main/kotlin/kr/bluesky/dodo/
├── widgets/
│   ├── TodoListWidget.kt            # AppWidgetProvider (수정)
│   ├── TodoListRemoteViewsService.kt # NEW: 동적 리스트 서비스
│   ├── TodoListRemoteViewsFactory.kt # NEW: 아이템 생성 팩토리
│   ├── WidgetActionReceiver.kt      # NEW: 버튼 액션 처리
│   ├── TodoCalendarWidget.kt        # 기존 유지
│   └── WidgetDataProvider.kt        # NEW: 데이터 캐싱/제공
├── MainActivity.kt                  # 딥링크 처리 추가

android/app/src/main/res/
├── layout/
│   ├── widget_todo_list_v2.xml      # NEW: 새 레이아웃
│   ├── widget_todo_item.xml         # NEW: 개별 아이템
│   └── widget_todo_header.xml       # NEW: 날짜 헤더
├── xml/
│   └── widget_todo_list_info.xml    # 수정

lib/
├── core/
│   ├── widget/
│   │   ├── widget_service.dart      # 수정: MethodChannel 추가
│   │   └── widget_channel.dart      # NEW: Native 통신
├── presentation/
│   └── providers/
│       └── widget_provider.dart     # 수정: 실시간 동기화
```

### 3.2 RemoteViewsService 구현

```kotlin
// TodoListRemoteViewsService.kt
package kr.bluesky.dodo.widgets

import android.content.Intent
import android.widget.RemoteViewsService

class TodoListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoListRemoteViewsFactory(applicationContext, intent)
    }
}
```

### 3.3 RemoteViewsFactory 구현

```kotlin
// TodoListRemoteViewsFactory.kt
package kr.bluesky.dodo.widgets

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import kr.bluesky.dodo.R

class TodoListRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private var todoItems: List<TodoItem> = emptyList()

    data class TodoItem(
        val id: Int,
        val title: String,
        val time: String?,
        val isCompleted: Boolean,
        val dateGroup: String // "오늘", "내일", "이번 주"
    )

    override fun onCreate() {
        // 초기화
    }

    override fun onDataSetChanged() {
        // SharedPreferences에서 데이터 로드
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val todoJson = prefs.getString("todo_items_json", "[]")
        todoItems = parseTodoItems(todoJson)
    }

    override fun getCount(): Int = todoItems.size

    override fun getViewAt(position: Int): RemoteViews {
        val item = todoItems[position]
        val views = RemoteViews(context.packageName, R.layout.widget_todo_item)

        // 체크박스 상태
        views.setTextViewText(R.id.todo_checkbox, if (item.isCompleted) "✓" else "○")

        // 제목 (완료 시 취소선)
        views.setTextViewText(R.id.todo_title, item.title)

        // 시간
        views.setTextViewText(R.id.todo_time, item.time ?: "")

        // 완료 토글 인텐트
        val toggleIntent = Intent().apply {
            putExtra("action", "TOGGLE_COMPLETE")
            putExtra("todo_id", item.id)
        }
        views.setOnClickFillInIntent(R.id.todo_checkbox, toggleIntent)

        // 삭제 인텐트
        val deleteIntent = Intent().apply {
            putExtra("action", "DELETE_TODO")
            putExtra("todo_id", item.id)
        }
        views.setOnClickFillInIntent(R.id.delete_button, deleteIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 2 // 헤더 + 아이템
    override fun getItemId(position: Int): Long = todoItems[position].id.toLong()
    override fun hasStableIds(): Boolean = true
    override fun onDestroy() {}

    private fun parseTodoItems(json: String?): List<TodoItem> {
        // JSON 파싱 로직
        return emptyList()
    }
}
```

### 3.4 BroadcastReceiver 구현

```kotlin
// WidgetActionReceiver.kt
package kr.bluesky.dodo.widgets

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TOGGLE_COMPLETE = "kr.bluesky.dodo.TOGGLE_COMPLETE"
        const val ACTION_DELETE_TODO = "kr.bluesky.dodo.DELETE_TODO"
        const val ACTION_ADD_TODO = "kr.bluesky.dodo.ADD_TODO"
        const val CHANNEL_NAME = "kr.bluesky.dodo/widget_actions"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TOGGLE_COMPLETE -> {
                val todoId = intent.getIntExtra("todo_id", -1)
                if (todoId != -1) {
                    // Flutter로 완료 토글 요청
                    callFlutterMethod(context, "toggleComplete", mapOf("id" to todoId))
                }
            }
            ACTION_DELETE_TODO -> {
                val todoId = intent.getIntExtra("todo_id", -1)
                if (todoId != -1) {
                    // Flutter로 삭제 요청
                    callFlutterMethod(context, "deleteTodo", mapOf("id" to todoId))
                }
            }
            ACTION_ADD_TODO -> {
                // DoDo 앱 할일 추가 화면 열기
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    putExtra("open_add_todo", true)
                }
                context.startActivity(launchIntent)
            }
        }
    }

    private fun callFlutterMethod(context: Context, method: String, args: Map<String, Any>) {
        // home_widget 패키지를 통한 Flutter 통신
        // 또는 직접 MethodChannel 호출
    }
}
```

### 3.5 위젯 레이아웃 (widget_todo_list_v2.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="12dp"
    android:background="@drawable/widget_background">

    <!-- 헤더: 제목 + 추가 버튼 -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical">

        <!-- 체크 아이콘 -->
        <ImageView
            android:layout_width="24dp"
            android:layout_height="24dp"
            android:src="@drawable/ic_check_circle"
            android:tint="@color/widget_accent" />

        <!-- 제목 -->
        <TextView
            android:id="@+id/widget_title"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:layout_marginStart="8dp"
            android:text="@string/widget_today_tasks"
            android:textSize="18sp"
            android:textStyle="bold"
            android:textColor="@color/widget_text_primary" />

        <!-- + 추가 버튼 -->
        <ImageButton
            android:id="@+id/btn_add_todo"
            android:layout_width="36dp"
            android:layout_height="36dp"
            android:src="@drawable/ic_add"
            android:background="@drawable/widget_button_background"
            android:contentDescription="Add todo" />
    </LinearLayout>

    <!-- 동적 리스트 -->
    <ListView
        android:id="@+id/todo_list"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:layout_marginTop="8dp"
        android:divider="@null"
        android:dividerHeight="0dp" />

    <!-- 푸터: 완료 진행률 -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:layout_marginTop="8dp">

        <!-- 진행률 텍스트 -->
        <TextView
            android:id="@+id/progress_text"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="4개 중 2개 완료"
            android:textSize="12sp"
            android:textColor="@color/widget_text_secondary" />

        <!-- 진행률 바 -->
        <ProgressBar
            android:id="@+id/progress_bar"
            style="@android:style/Widget.ProgressBar.Horizontal"
            android:layout_width="match_parent"
            android:layout_height="4dp"
            android:layout_marginTop="4dp"
            android:progress="50"
            android:progressDrawable="@drawable/widget_progress_bar" />
    </LinearLayout>
</LinearLayout>
```

### 3.6 개별 아이템 레이아웃 (widget_todo_item.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:gravity="center_vertical"
    android:paddingVertical="8dp">

    <!-- 체크박스 (클릭 가능) -->
    <TextView
        android:id="@+id/todo_checkbox"
        android:layout_width="24dp"
        android:layout_height="24dp"
        android:text="○"
        android:textSize="18sp"
        android:gravity="center"
        android:background="?android:attr/selectableItemBackgroundBorderless" />

    <!-- 할일 내용 -->
    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical"
        android:layout_marginStart="12dp">

        <TextView
            android:id="@+id/todo_title"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="할일 제목"
            android:textSize="14sp"
            android:textColor="@color/widget_text_primary"
            android:maxLines="1"
            android:ellipsize="end" />
    </LinearLayout>

    <!-- 시간 뱃지 -->
    <TextView
        android:id="@+id/todo_time"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="오전 10:00"
        android:textSize="11sp"
        android:textColor="@color/widget_text_secondary"
        android:background="@drawable/widget_time_badge"
        android:paddingHorizontal="8dp"
        android:paddingVertical="2dp" />
</LinearLayout>
```

---

## 4. Flutter 측 구현

### 4.1 MethodChannel 설정

```dart
// lib/core/widget/widget_channel.dart
import 'package:flutter/services.dart';

class WidgetChannel {
  static const MethodChannel _channel = MethodChannel('kr.bluesky.dodo/widget_actions');

  static void initialize() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  static Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'toggleComplete':
        final int todoId = call.arguments['id'];
        // TodoRepository를 통해 완료 토글
        await _toggleTodoComplete(todoId);
        return true;

      case 'deleteTodo':
        final int todoId = call.arguments['id'];
        // TodoRepository를 통해 삭제
        await _deleteTodo(todoId);
        return true;

      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  static Future<void> _toggleTodoComplete(int todoId) async {
    // TodoRepository 호출
  }

  static Future<void> _deleteTodo(int todoId) async {
    // TodoRepository 호출
  }
}
```

### 4.2 위젯 데이터 JSON 형식

```dart
// WidgetService에서 저장하는 데이터 형식
Future<void> updateWidgetData() async {
  final todos = await todoRepository.getTodayTodos();

  final todoItemsJson = jsonEncode(
    todos.map((todo) => {
      'id': todo.id,
      'title': todo.title,
      'time': todo.notificationTime?.format(),
      'isCompleted': todo.isCompleted,
      'dateGroup': _getDateGroup(todo.dueDate),
    }).toList(),
  );

  await HomeWidget.saveWidgetData<String>('todo_items_json', todoItemsJson);

  // 진행률 데이터
  final completed = todos.where((t) => t.isCompleted).length;
  final total = todos.length;
  await HomeWidget.saveWidgetData<int>('completed_count', completed);
  await HomeWidget.saveWidgetData<int>('total_count', total);

  // 위젯 갱신 트리거
  await HomeWidget.updateWidget(
    qualifiedAndroidName: 'kr.bluesky.dodo.widgets.TodoListWidget',
  );
}
```

---

## 5. AndroidManifest.xml 수정

```xml
<!-- 서비스 등록 -->
<service
    android:name=".widgets.TodoListRemoteViewsService"
    android:permission="android.permission.BIND_REMOTEVIEWS"
    android:exported="false" />

<!-- 액션 리시버 등록 -->
<receiver
    android:name=".widgets.WidgetActionReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="kr.bluesky.dodo.TOGGLE_COMPLETE" />
        <action android:name="kr.bluesky.dodo.DELETE_TODO" />
        <action android:name="kr.bluesky.dodo.ADD_TODO" />
    </intent-filter>
</receiver>
```

---

## 6. 구현 단계

### Phase 1: 기반 작업 (2-3일)
1. [ ] RemoteViewsService 기본 구조 구현
2. [ ] RemoteViewsFactory 기본 구현
3. [ ] 새 레이아웃 XML 파일 생성
4. [ ] SharedPreferences JSON 데이터 형식 정의

### Phase 2: 상호작용 구현 (3-4일)
1. [ ] BroadcastReceiver 구현
2. [ ] PendingIntent 설정 (아이템별)
3. [ ] MethodChannel Flutter 통신
4. [ ] 완료 토글 기능 구현
5. [ ] 삭제 기능 구현

### Phase 3: UI 개선 (2-3일)
1. [ ] + 버튼 → 앱 열기 (딥링크)
2. [ ] 진행률 바 구현
3. [ ] 일자별 그룹 헤더
4. [ ] 테마 적용 (기존 테마 시스템 연동)

### Phase 4: 테스트 및 최적화 (2-3일)
1. [ ] 다양한 기기 테스트
2. [ ] 배터리 최적화
3. [ ] 메모리 누수 점검
4. [ ] 엣지 케이스 처리

---

## 7. 참고 자료

### Android 공식 문서
- [App Widgets Overview](https://developer.android.com/develop/ui/views/appwidgets/overview)
- [RemoteViewsService](https://developer.android.com/reference/android/widget/RemoteViewsService)
- [Collection Widgets](https://developer.android.com/develop/ui/views/appwidgets/collections)

### 삼성 위젯 분석 (참고용)
- 리마인더 위젯: 체크박스, 일자 그룹, 진행률
- 캘린더 위젯: 월 네비게이션, 이벤트 리스트

### 유사 앱 구현 사례
- Todoist Widget (RemoteViewsService 사용)
- Google Tasks Widget
- Any.do Widget

---

## 8. 주의사항

### 8.1 RemoteViews 제한사항
- 지원되는 레이아웃: FrameLayout, LinearLayout, RelativeLayout, GridLayout
- 지원되는 뷰: Button, ImageButton, ImageView, ProgressBar, TextView, ListView, GridView, StackView, AdapterViewFlipper, ViewFlipper
- **지원 안 됨**: RecyclerView, ConstraintLayout, 커스텀 뷰

### 8.2 배터리 최적화
- 위젯 갱신 주기 최소 30분 권장 (widget_info.xml)
- 불필요한 갱신 방지
- WorkManager 활용 고려

### 8.3 데이터 동기화
- SharedPreferences 크기 제한 고려
- JSON 데이터 최소화
- 네트워크 오류 처리

---

**문서 최종 업데이트**: 2025-11-27
