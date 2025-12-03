# 캘린더 일자 선택 할일 추가 기능

## 개요

캘린더 화면에서 특정 날짜를 선택한 후 해당 날짜에 할일을 바로 추가할 수 있는 기능입니다.

## 기능 요구사항

### 사용자 스토리
- 사용자가 캘린더에서 날짜를 선택하면, 해당 날짜에 할일을 추가할 수 있는 버튼이 표시된다
- 버튼을 클릭하면 할일 추가 다이얼로그가 열리며, 마감일이 선택한 날짜로 자동 설정된다
- 할일 추가 완료 후 캘린더 화면의 할일 목록이 즉시 갱신된다

### 기능 명세
| 항목 | 설명 |
|------|------|
| 트리거 | 선택 날짜 헤더 옆 + 버튼 클릭 |
| 초기값 | 마감일 = 선택 날짜, 하루 종일 = true |
| 제약사항 | 과거 날짜는 추가 버튼 비활성화 |

## 기술 설계

### 수정 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `lib/presentation/widgets/todo_form_dialog.dart` | `initialDueDate` 파라미터 추가 |
| `lib/presentation/screens/calendar_screen.dart` | 할일 추가 버튼 UI 및 로직 추가 |
| `assets/translations/en.json` | 번역 키 추가 |
| `assets/translations/ko.json` | 번역 키 추가 |

### 데이터 흐름

```
[캘린더 날짜 선택] → [_selectedDay 상태 업데이트]
         ↓
[+ 버튼 클릭] → [_addTodoForSelectedDate() 호출]
         ↓
[TodoFormDialog(initialDueDate: _selectedDay, initialAllDay: true)]
         ↓
[사용자 입력 완료 → _save() 호출]
         ↓
[todoRepository.createTodo(...)]
         ↓
[ref.invalidate(todosProvider)] → [캘린더 목록 자동 갱신]
```

### TodoFormDialog 변경사항

#### 새 파라미터
```dart
class TodoFormDialog extends ConsumerStatefulWidget {
  final Todo? existingTodo;
  final DateTime? initialDueDate;   // 캘린더에서 선택한 날짜
  final bool initialAllDay;          // 하루 종일 옵션 초기값

  const TodoFormDialog({
    super.key,
    this.existingTodo,
    this.initialDueDate,
    this.initialAllDay = false,
  });
}
```

#### initState 수정
```dart
@override
void initState() {
  super.initState();
  // ...기존 코드...

  // 새 할일 생성 시 초기 날짜 설정
  if (!_isEditMode) {
    if (widget.initialDueDate != null) {
      _selectedDueDate = widget.initialDueDate;
      _isAllDay = widget.initialAllDay;
    }
  }
}
```

### CalendarScreen 변경사항

#### 추가 버튼 UI
- 위치: 선택 날짜 헤더 ("2025년 1월 15일 (3개)") 오른쪽
- 아이콘: `FluentIcons.add_24_regular`
- 조건: 선택 날짜가 오늘 또는 미래일 때만 활성화

#### 추가 함수
```dart
void _addTodoForSelectedDate() {
  if (_selectedDay == null) return;

  showDialog(
    context: context,
    builder: (context) => TodoFormDialog(
      initialDueDate: DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        0,
        0,
      ),
      initialAllDay: true,
    ),
  );
}
```

### 번역 키

| 키 | 영어 | 한국어 |
|----|------|--------|
| `add_todo_for_date` | Add todo | 할일 추가 |

## UI/UX 고려사항

### 버튼 상태
- **활성화**: 오늘 또는 미래 날짜 선택 시
- **비활성화**: 과거 날짜 선택 시 (회색 처리, 클릭 불가)

### 접근성
- 버튼에 툴팁 추가: "할일 추가"
- 충분한 터치 영역 확보 (최소 44x44)

### 다크모드 지원
- 기존 AppColors 테마 시스템 활용
- 활성화: `AppColors.primary`
- 비활성화: `AppColors.textGray.withOpacity(0.3)`

## 테스트 시나리오

### 정상 케이스
1. 캘린더에서 미래 날짜 선택 → + 버튼 클릭 → 다이얼로그 열림
2. 마감일이 선택 날짜로 자동 설정됨 확인
3. 하루 종일 옵션이 켜져 있음 확인
4. 할일 추가 후 캘린더 목록에 즉시 표시됨 확인

### 예외 케이스
1. 과거 날짜 선택 시 + 버튼 비활성화 확인
2. 날짜 선택 안 된 상태에서 + 버튼 숨김 확인
3. 다이얼로그에서 취소 시 원래 상태 유지 확인

## 구현 완료 기준

- [ ] TodoFormDialog에 initialDueDate, initialAllDay 파라미터 추가
- [ ] CalendarScreen에 + 버튼 UI 구현
- [ ] 과거 날짜 비활성화 로직 구현
- [ ] 번역 키 추가 완료
- [ ] 정상 케이스 테스트 통과
