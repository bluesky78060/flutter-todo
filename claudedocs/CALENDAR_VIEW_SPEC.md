# 캘린더 뷰 기능 기술 명세서

## 1. 개요

### 1.1 목적
모바일 앱에서 할 일 목록을 **리스트 뷰** 또는 **캘린더 뷰**로 표시할 수 있도록 뷰 모드 선택 기능을 추가합니다.

### 1.2 요구사항
- 환경설정에서 기본 뷰 모드 선택 (리스트/캘린더)
- 기존 헤더 유지
- 캘린더에 할 일 마커 표시
- 선택된 날짜의 할 일 상세 목록 표시 (하단)
- 설정값 영구 저장 (SharedPreferences)

---

## 2. UI/UX 설계

### 2.1 환경설정 화면 (Settings)
```
┌─────────────────────────────────────┐
│  테마 설정                          │
│  ├─ 다크 모드 토글                  │
│  ├─ 테마 색상                       │
│  └─ 글꼴 크기                       │
├─────────────────────────────────────┤
│  표시 설정                    [NEW] │
│  └─ 기본 뷰 모드                    │
│      ○ 리스트 뷰                    │
│      ● 캘린더 뷰  ← 선택됨          │
└─────────────────────────────────────┘
```

### 2.2 캘린더 뷰 (Calendar View)
```
┌─────────────────────────────────────┐
│  [기존 헤더 - 검색, 필터, 설정]     │
├─────────────────────────────────────┤
│      ◀  2025년 12월  ▶              │
├─────────────────────────────────────┤
│  일   월   화   수   목   금   토   │
├─────────────────────────────────────┤
│  30   1    2    3    4    5   ██6██ │
│                                      │
│   7  ┌─8──┐  9   10   11   12   13  │
│      │식빵│                          │
│      │구매│                          │
│      └────┘                          │
│  14   15   16   17   18   19   20   │
│                                      │
│  21   22   23   24  🔴25   26   27  │
│                                      │
│  28   29   30   31   1    2    3    │
└─────────────────────────────────────┘
│                                      │
│  2025년 12월 8일 (월)                │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ 하루종일  │ 식빵구매        │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 14:00     │ 회의 참석       │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  ┌──────────────────┐               │
│  │ + 새로운 할 일    │               │
│  └──────────────────┘               │
└─────────────────────────────────────┘
```

### 2.3 날짜 스타일 규칙

| 상태 | 스타일 |
|------|--------|
| **선택된 날짜** | 둥근 테두리 (primaryColor) + 할 일 제목 표시 |
| **오늘** | 어두운 배경 (회색) |
| **공휴일/주말** | 빨간색 텍스트 |
| **이전/다음 달** | 연한 회색 텍스트 |
| **할 일 있는 날** | 셀 안에 첫 번째 할 일 제목 표시 |

---

## 3. 아키텍처

### 3.1 파일 구조
```
lib/
├── presentation/
│   ├── providers/
│   │   └── view_mode_provider.dart      [NEW] 뷰 모드 상태 관리
│   │
│   ├── screens/
│   │   ├── todo_list_screen.dart        [MODIFY] 뷰 모드에 따라 분기
│   │   ├── settings_screen.dart         [MODIFY] 뷰 모드 설정 추가
│   │   └── calendar_view_screen.dart    [NEW] 캘린더 뷰 화면
│   │
│   └── widgets/
│       ├── calendar_day_cell.dart       [NEW] 캘린더 날짜 셀
│       └── selected_date_todos.dart     [NEW] 선택 날짜 할 일 목록
│
├── assets/translations/
│   ├── en.json                          [MODIFY] 번역 키 추가
│   └── ko.json                          [MODIFY] 번역 키 추가
```

### 3.2 데이터 흐름
```
┌──────────────────────────────────────────────────────────────┐
│                     SharedPreferences                         │
│                    (view_mode: 'list' | 'calendar')           │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                     viewModeProvider                          │
│                  StateNotifierProvider<ViewMode>              │
└──────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────┐
│    TodoListScreen       │     │      SettingsScreen         │
│    (뷰 모드에 따라 분기) │     │      (뷰 모드 설정 UI)      │
└─────────────────────────┘     └─────────────────────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
┌─────────┐     ┌─────────────────┐
│ ListView │     │ CalendarView    │
│ (기존)   │     │ (신규)          │
└─────────┘     └─────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌────────────┐  ┌────────────┐  ┌────────────────┐
│ TableCalendar│  │SelectedDate│  │ selectedDate   │
│ Widget      │  │ TodosList   │  │ Provider       │
└────────────┘  └────────────┘  └────────────────┘
```

---

## 4. 상세 구현

### 4.1 뷰 모드 Provider

**파일**: `lib/presentation/providers/view_mode_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 뷰 모드 열거형
enum ViewMode {
  list,     // 리스트 뷰
  calendar, // 캘린더 뷰
}

/// 뷰 모드 Provider
final viewModeProvider = StateNotifierProvider<ViewModeNotifier, ViewMode>((ref) {
  return ViewModeNotifier();
});

class ViewModeNotifier extends StateNotifier<ViewMode> {
  static const String _key = 'view_mode';

  ViewModeNotifier() : super(ViewMode.list) {
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? 'list';
    state = value == 'calendar' ? ViewMode.calendar : ViewMode.list;
  }

  Future<void> setViewMode(ViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ViewMode.calendar ? 'calendar' : 'list');
  }
}
```

### 4.2 캘린더 관련 Providers

**파일**: `lib/presentation/providers/calendar_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

/// 선택된 날짜 Provider
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 날짜별 할 일 맵 Provider
final todosByDateProvider = Provider<Map<DateTime, List<Todo>>>((ref) {
  final todosAsync = ref.watch(todosProvider);

  return todosAsync.when(
    data: (todos) {
      final Map<DateTime, List<Todo>> result = {};

      for (final todo in todos) {
        if (todo.dueDate != null) {
          final dateKey = DateTime(
            todo.dueDate!.year,
            todo.dueDate!.month,
            todo.dueDate!.day,
          );
          result.putIfAbsent(dateKey, () => []);
          result[dateKey]!.add(todo);
        }
      }

      return result;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// 선택된 날짜의 할 일 목록 Provider
final selectedDateTodosProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final todosByDate = ref.watch(todosByDateProvider);

  final dateKey = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );

  return todosByDate[dateKey] ?? [];
});
```

### 4.3 캘린더 뷰 화면

**파일**: `lib/presentation/screens/calendar_view_screen.dart`

**주요 기능**:
- TableCalendar 위젯 사용
- 선택된 날짜 하이라이트 (둥근 테두리)
- 할 일 있는 날짜에 제목 표시
- 오늘 날짜 특별 스타일
- 공휴일/주말 색상 구분
- 하단에 선택 날짜 할 일 목록

```dart
class CalendarViewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final todosByDate = ref.watch(todosByDateProvider);
    final selectedTodos = ref.watch(selectedDateTodosProvider);

    return Column(
      children: [
        // 캘린더
        TableCalendar(
          focusedDay: selectedDate,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          onDaySelected: (selected, focused) {
            ref.read(selectedDateProvider.notifier).state = selected;
          },
          eventLoader: (day) => todosByDate[day] ?? [],
          calendarBuilders: CalendarBuilders(
            // 커스텀 날짜 셀 빌더
            defaultBuilder: _buildDayCell,
            selectedBuilder: _buildSelectedDayCell,
            todayBuilder: _buildTodayCell,
            markerBuilder: _buildMarker,
          ),
        ),

        // 선택된 날짜 헤더
        _buildDateHeader(selectedDate),

        // 할 일 목록
        Expanded(
          child: ListView.builder(
            itemCount: selectedTodos.length,
            itemBuilder: (context, index) {
              return TodoTile(todo: selectedTodos[index]);
            },
          ),
        ),

        // 할 일 추가 버튼
        _buildAddTodoButton(),
      ],
    );
  }
}
```

### 4.4 날짜 셀 위젯

**파일**: `lib/presentation/widgets/calendar_day_cell.dart`

```dart
class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final List<Todo>? todos;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: isSelected
          ? Border.all(color: primaryColor, width: 2)
          : null,
        borderRadius: BorderRadius.circular(8),
        color: isToday
          ? Colors.grey.withOpacity(0.3)
          : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 날짜 숫자
          Text(
            '${date.day}',
            style: TextStyle(
              color: _getDateColor(date),
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),

          // 첫 번째 할 일 제목 (있는 경우)
          if (todos != null && todos!.isNotEmpty)
            Text(
              todos!.first.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9),
            ),
        ],
      ),
    );
  }

  Color _getDateColor(DateTime date) {
    // 주말/공휴일: 빨간색
    if (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      return Colors.red;
    }
    // 기본: 테마 텍스트 색상
    return AppColors.getText(isDarkMode);
  }
}
```

### 4.5 환경설정 뷰 모드 섹션

**파일**: `lib/presentation/screens/settings_screen.dart` (수정)

```dart
Widget _buildDisplaySettings() {
  final viewMode = ref.watch(viewModeProvider);

  return _buildGlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('display_settings'.tr()),

        // 뷰 모드 선택
        _buildListTile(
          icon: FluentIcons.list_24_regular,
          title: 'default_view_mode'.tr(),
          trailing: SegmentedButton<ViewMode>(
            segments: [
              ButtonSegment(
                value: ViewMode.list,
                label: Text('list_view'.tr()),
                icon: Icon(FluentIcons.list_24_regular),
              ),
              ButtonSegment(
                value: ViewMode.calendar,
                label: Text('calendar_view'.tr()),
                icon: Icon(FluentIcons.calendar_24_regular),
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (Set<ViewMode> selection) {
              ref.read(viewModeProvider.notifier)
                  .setViewMode(selection.first);
            },
          ),
        ),
      ],
    ),
  );
}
```

### 4.6 TodoListScreen 분기 처리

**파일**: `lib/presentation/screens/todo_list_screen.dart` (수정)

```dart
@override
Widget build(BuildContext context) {
  final viewMode = ref.watch(viewModeProvider);

  return Scaffold(
    body: Column(
      children: [
        // 기존 헤더 유지
        _buildHeader(),

        // 뷰 모드에 따라 분기
        Expanded(
          child: viewMode == ViewMode.calendar
            ? CalendarViewScreen()
            : _buildListView(),  // 기존 리스트 뷰
        ),
      ],
    ),
    floatingActionButton: _buildFAB(),
  );
}
```

---

## 5. 번역 키

### 5.1 en.json
```json
{
  "display_settings": "Display Settings",
  "default_view_mode": "Default View Mode",
  "list_view": "List",
  "calendar_view": "Calendar",
  "all_day": "All day",
  "no_todos_for_date": "No todos for this date",
  "add_new_todo": "Add new todo"
}
```

### 5.2 ko.json
```json
{
  "display_settings": "표시 설정",
  "default_view_mode": "기본 뷰 모드",
  "list_view": "리스트",
  "calendar_view": "캘린더",
  "all_day": "하루종일",
  "no_todos_for_date": "이 날짜에 할 일이 없습니다",
  "add_new_todo": "새로운 할 일"
}
```

---

## 6. 패키지 의존성

| 패키지 | 버전 | 용도 | 상태 |
|--------|------|------|------|
| `table_calendar` | ^3.0.0 | 캘린더 위젯 | 기존 설치됨 |
| `shared_preferences` | ^2.0.0 | 설정 저장 | 기존 설치됨 |
| `flutter_riverpod` | ^2.0.0 | 상태 관리 | 기존 설치됨 |

---

## 7. 구현 체크리스트

### Phase 1: Provider 구현
- [ ] `view_mode_provider.dart` 생성
- [ ] `calendar_providers.dart` 생성
- [ ] SharedPreferences 저장/로드 로직

### Phase 2: 캘린더 뷰 구현
- [ ] `calendar_view_screen.dart` 생성
- [ ] `calendar_day_cell.dart` 생성
- [ ] 날짜 선택 기능
- [ ] 할 일 마커/제목 표시
- [ ] 선택 날짜 할 일 목록

### Phase 3: 환경설정 통합
- [ ] `settings_screen.dart` 수정 (뷰 모드 선택 UI)
- [ ] 번역 키 추가 (en.json, ko.json)

### Phase 4: TodoListScreen 통합
- [ ] 뷰 모드에 따른 분기 처리
- [ ] 기존 헤더 유지 확인
- [ ] 기능 테스트

---

## 8. 테스트 시나리오

| 시나리오 | 예상 결과 |
|----------|-----------|
| 앱 첫 실행 | 기본값: 리스트 뷰 |
| 캘린더 모드 선택 → 앱 재시작 | 캘린더 뷰로 시작 |
| 캘린더에서 날짜 선택 | 해당 날짜 하이라이트 + 하단에 할 일 표시 |
| 할 일 없는 날짜 선택 | "이 날짜에 할 일이 없습니다" 표시 |
| 캘린더에서 할 일 추가 | 선택된 날짜에 할 일 생성 |
| 공휴일/주말 표시 | 빨간색 텍스트 |

---

## 9. 예상 작업량

| 항목 | 예상 작업 |
|------|-----------|
| 신규 파일 | 4개 |
| 수정 파일 | 4개 |
| 난이도 | 중간 |

---

## 10. 참고 디자인

사용자 제공 스크린샷 기반:
- 선택된 날짜: 둥근 테두리 + 내부에 할 일 제목
- 오늘: 어두운 배경
- 공휴일: 빨간색 텍스트
- 하단: 날짜 헤더 + 할 일 카드 + 추가 버튼
