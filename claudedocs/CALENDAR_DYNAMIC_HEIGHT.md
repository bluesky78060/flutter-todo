# 캘린더 동적 높이 기능 기술 문서

## 개요

캘린더 뷰에서 포맷(월/2주/주)을 전환할 때 캘린더 높이가 동적으로 조절되고, 하단 할일 목록 영역이 남은 공간을 자동으로 채우는 기능입니다.

## 구현 날짜

2025-12-08

## 변경 파일

- `lib/presentation/screens/calendar_view_screen.dart`

## 핵심 변경 사항

### 이전 구현 (문제점)

```dart
// ❌ 문제: LayoutBuilder + AnimatedContainer로 고정 높이 계산
return LayoutBuilder(
  builder: (context, constraints) {
    final calendarHeight = switch (_calendarFormat) {
      CalendarFormat.month => constraints.maxHeight * 0.55,
      CalendarFormat.twoWeeks => constraints.maxHeight * 0.35,
      CalendarFormat.week => constraints.maxHeight * 0.25,
    };

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: calendarHeight,  // 고정 높이 - 유연성 부족
          child: TableCalendar(...),
        ),
        Expanded(child: todoList),  // Expanded가 제대로 동작하지 않음
      ],
    );
  },
);
```

**문제점:**
1. `AnimatedContainer`의 고정 높이가 `TableCalendar` 내부 레이아웃과 충돌
2. `RenderFlex overflow` 오류 발생 (120 pixels on bottom)
3. 포맷 변경 시 할일 목록 영역이 동적으로 조절되지 않음

### 현재 구현 (해결)

```dart
// ✅ 해결: 단순 Column 구조로 TableCalendar가 자체 높이 결정
return Column(
  children: [
    // Calendar - intrinsic height based on format
    _buildCalendar(
      isDarkMode: isDarkMode,
      primaryColor: primaryColor,
      selectedDate: selectedDate,
      todosByDate: todosByDate,
    ),

    // Divider
    Divider(
      height: 1,
      color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.2),
    ),

    // Selected date header
    _buildDateHeader(
      selectedDate: selectedDate,
      todoCount: selectedTodos.length,
      isDarkMode: isDarkMode,
      primaryColor: primaryColor,
    ),

    // Todo list - fills remaining space
    Expanded(
      child: selectedTodos.isEmpty
          ? _buildEmptyState(isDarkMode)
          : _buildTodoList(selectedTodos, isDarkMode),
    ),
  ],
);
```

## TableCalendar 설정

```dart
TableCalendar<Todo>(
  firstDay: DateTime.utc(2020, 1, 1),
  lastDay: DateTime.utc(2030, 12, 31),
  focusedDay: _focusedDay,
  calendarFormat: _calendarFormat,

  // 포맷 버튼 레이블 설정
  availableCalendarFormats: const {
    CalendarFormat.month: '월',
    CalendarFormat.twoWeeks: '2주',
    CalendarFormat.week: '주',
  },

  // 일관된 행 높이 (셀 내 할일 제목 표시용)
  rowHeight: 52,

  startingDayOfWeek: StartingDayOfWeek.sunday,
  selectedDayPredicate: (day) => isSameDay(selectedDate, day),
  onDaySelected: _onDaySelected,

  // 포맷 변경 핸들러
  onFormatChanged: (format) {
    setState(() {
      _calendarFormat = format;
    });
  },

  // ... 기타 설정
)
```

## 레이아웃 동작 원리

### 포맷별 높이 변화

| 포맷 | 표시 행 수 | 대략적 높이 |
|------|-----------|------------|
| 월 (month) | 4-6주 | ~360px |
| 2주 (twoWeeks) | 2주 | ~160px |
| 주 (week) | 1주 | ~100px |

### Expanded 위젯 동작

1. `Column`은 자식들의 높이를 순차적으로 배치
2. `TableCalendar`는 `_calendarFormat`에 따라 자체 높이 결정
3. `Expanded`는 남은 공간을 모두 차지
4. 포맷 변경 → 캘린더 높이 변경 → `Expanded` 자동 재계산

```
┌─────────────────────────────┐
│     TableCalendar           │ ← 포맷에 따라 높이 변동
│     (intrinsic height)      │
├─────────────────────────────┤
│     Divider                 │ ← 고정 1px
├─────────────────────────────┤
│     DateHeader              │ ← 고정 높이
├─────────────────────────────┤
│                             │
│     Expanded                │ ← 남은 공간 모두 차지
│     (Todo List)             │
│                             │
└─────────────────────────────┘
```

## State 관리

```dart
class _CalendarViewScreenState extends State<CalendarViewScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;  // 기본값: 월
  DateTime _focusedDay = DateTime.now();

  // 포맷 변경 시 setState로 리빌드 트리거
  onFormatChanged: (format) {
    setState(() {
      _calendarFormat = format;
    });
  },
}
```

## 수정된 버그

### 1. RenderFlex Overflow 오류

**원인:** `AnimatedContainer`의 고정 높이가 `TableCalendar` 내부 Column과 충돌

**해결:** `AnimatedContainer` 제거, `TableCalendar`가 자체 높이 결정하도록 변경

### 2. 중복 rowHeight 오류

**원인:** `rowHeight: 52`가 두 번 정의됨 (line 146, line 344)

**해결:** 두 번째 정의 제거

```dart
// 제거된 코드 (line 343-344)
// Row height for showing todo titles (52px for larger cells)
// rowHeight: 52,
```

## 테스트 방법

1. 앱 실행 후 캘린더 화면으로 이동
2. 캘린더 오른쪽 상단의 포맷 버튼 클릭 (월 → 2주 → 주)
3. 확인 사항:
   - 캘린더 높이가 자연스럽게 변경되는지
   - 할일 목록 영역이 남은 공간을 채우는지
   - 스크롤이 정상 동작하는지
   - overflow 오류가 발생하지 않는지

## 관련 패키지

- `table_calendar: ^3.1.2` - 캘린더 위젯

## 참고 사항

- `TableCalendar`는 내부적으로 `Column`을 사용하므로 외부에서 고정 높이를 강제하면 충돌 발생
- `availableCalendarFormats`로 포맷 버튼 레이블을 한국어로 커스터마이징
- `rowHeight`는 한 번만 정의해야 함 (중복 시 빌드 오류)
