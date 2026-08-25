# 플랜 — DTA-3-6: 홈 위젯이 등록일 기준으로 표시되는 문제

- 작성일: 2026-08-21
- 발견 경위: DTA-3-1/DTA-3-4 실기기 확인 중 사용자가 신고
- **기존 결함이다.** 이번 세션의 변경은 위젯 코드를 건드리지 않았다
  (`git log --name-only 7d08dad..HEAD | grep widget` → 테스트 파일 4개뿐).
  앱을 재설치하며 App Group 데이터가 새로 채워져 드러났다.

## 신고 내용

> "위젯이 다음 할일이 아니라 등록일 기준으로 표시가 되는게 문제야"
> "가족여행은 11월인데" (오늘 할 일 위젯에 표시됨)

## 방향 변경 기록 (중요)

티켓 발행 시에는 **"오늘 + 기간 중인 일정"** 으로 적었으나,
사용자가 미리보기를 보고 **"다가오는 순서 (다음 할일)"** 로 다시 정했다.

| | 티켓 기재 | **확정** |
|---|---|---|
| 선정 | 오늘 마감 + 기간이 오늘을 걸침 | **미완료 전부** |
| 정렬 | (미정) | **마감이 가까운 순** |
| 오늘 할 일이 없는 날 | 빈 위젯 | **다음 것으로 채움** |

사용자가 고른 미리보기:
```
오늘 할 일  (8/21)
┌─────────────────────────┐
│ ○ 봉화균수배 볼링대회   8/22 │
│ ○ 스칼라...            8/25 │
└─────────────────────────┘
· 가족여행(11월)은 뒤로 밀려 안 보임
· 범위 일정이 오늘을 걸치면 맨 앞에
```

**이 플랜은 확정본을 따른다.** 티켓 설명의 "오늘 + 기간 중"은 무효다
(AI PM MCP가 설명 수정을 지원하지 않아 여기에 기록한다).

## 원인 — 확인된 사실

### (1) 올바른 필터가 계산되고 **버려진다** — 핵심

`lib/core/widget/widget_models.dart:125-136` 에 제대로 된 로직이 있다.

```dart
if (todo.isCompleted) return false;
if (todo.dueDate != null) {
  return 오늘 마감인가;        // 마감일 기준
}
return 오늘 등록됐는가;        // 마감일 없으면 등록일 기준  ← 사용자가 본 "등록일"
```

그런데 `widget_service.dart:478-480`:

```dart
final todoData = TodoListData.fromTodos(todos);
logger.d('   Today\'s todos count: ${todoData.todos.length}');   // 로그에만 쓴다
```

**결과를 로그로 찍고 버린다.** 실제 위젯에 들어가는 것은 `:488-502` 다.

```dart
final incompleteTodos = todos.where((t) => !t.isCompleted).toList();  // 날짜 무시
final sortedTodos = _sortTodosByPosition(incompleteTodos);            // position 순
final displayTodos = sortedTodos.take(10).toList();
```

`_sortTodosByPosition` 은 `position`(드래그 순서)으로 정렬한다.
`position` 은 생성 시 증가하므로 **결과적으로 등록 순**이 된다.
사용자가 "등록일 기준" 이라고 본 것이 이것이다.

> 이 저장소에서 같은 패턴을 세 번째 본다.
> DTA-3-1 의 동기화 버튼 스텁, `widget_init.dart` 의 `(to be implemented with actual data)`,
> 그리고 이것. **고칠 코드가 없는 게 아니라 연결이 안 돼 있다.**

### (2) `M/d` 가 `12:00 AM` 으로 렌더링된다

`ios/TodoWidgets/SharedData.swift:87-94` 의 `parseDateString` 은
`"11/15"` 에서 month/day/year 만 뽑고 **시·분을 넣지 않는다.**
자정 `Date` 가 되고 위젯이 시간 형식으로 그리니 `12:00 AM` 이 된다. 날짜가 사라진다.

Flutter 쪽(`widget_service.dart:522-529`)은 오늘이 아니면 `"M/d"` 를 정상적으로 넣고 있다.
**문제는 Swift 표시 계층이다.**

### (3) 캘린더 위젯과 기준이 어긋난다

캘린더 위젯은 `:390-394` 에서 `dueDate` 가 그 날짜인 것만 표시한다.
(1) 때문에 목록 위젯은 날짜를 무시하므로 같은 화면에서 서로 다른 날짜를 보여 준다.

## 변경 목록

### 1. 선정·정렬 교체 — `widget_service.dart:488-502`

```dart
// 미완료만 남기고, 마감이 가까운 순으로 정렬한다.
// position(드래그 순서)로 정렬하면 결과적으로 등록 순이 되어
// "다음 할 일"이 아니라 "먼저 만든 것"이 위에 온다.
final upcoming = todos.where((t) => !t.isCompleted).toList()
  ..sort(_compareByUpcoming);
final displayTodos = upcoming.take(10).toList();
```

정렬 규칙 `_compareByUpcoming` (순수 함수로 분리해 테스트한다):

1. **기간이 오늘을 걸치는 일정이 최우선** (`occursOn(today)`)
   — 사용자 요구: "범위 일정이 오늘을 걸치면 맨 앞에"
2. 그다음 **마감일 오름차순** (가까운 것부터)
3. 마감일이 같으면 **알림 시각** 오름차순
4. 마감일이 없는 것은 **맨 뒤**
5. 그래도 같으면 `position` (사용자 드래그 순서 존중)

`occursOn` 은 DTA-3-4 에서 만든 것을 그대로 쓴다.
**이로써 DTA-3-4 에서 의도적으로 제외했던 "홈 위젯의 범위 일정 미반영"도 함께 해소된다.**

### 2. 죽은 계산 제거

`TodoListData.fromTodos(todos)` 호출은 로그 한 줄에만 쓰인다.
남겨 두면 "필터가 적용되고 있다"는 오해를 준다. **제거하거나 실제로 쓰거나 해야 한다.**
이번에는 제거한다 — 확정된 기준이 `fromTodos` 와 다르기 때문이다
(`fromTodos` 는 오늘 것만, 확정본은 다가오는 순서).

`TodoListData` 자체는 다른 곳에서 쓰이는지 확인 후 판단한다.

### 3. Swift 날짜 표시 — `SharedData.swift`

`M/d` 형식이면 **시각이 아니라 날짜로** 표시해야 한다.
`TodoItem` 에 표시용 문자열을 그대로 전달하거나,
`parseDateString` 이 날짜/시각을 구분해 렌더링 쪽에 알리도록 한다.

현재 구조상 `dueDate: Date?` 하나만 넘기므로 **"이게 날짜인지 시각인지" 정보가 소실**된다.
표시 문자열을 별도 필드로 넘기는 쪽이 단순하고 안전하다.

### 4. 진행률 카운트 확인

`todo_completed_count` / `todo_total_count` 는 `_getTodayTodos`(`:574`)를 쓴다.
이건 **오늘 기준이 맞다** (진행률이니까). 건드리지 않는다.
다만 목록과 기준이 다르다는 점을 주석에 남긴다.

## 검증

**자동**
- `_compareByUpcoming` 단위 테스트: 기간 중 우선 / 마감 가까운 순 / 마감 없음 뒤로 /
  동일 마감일 때 알림 시각 / 완전 동일 시 position
- 하위호환: 기간 없는 할 일만 있을 때 마감일 순으로 나오는지
- 변이 검증: 정렬을 `position` 순으로 되돌리면 테스트가 죽는지

**수동 (자동 불가)**
- 위젯에 8/22, 8/25 가 이 순서로 뜨는지
- 11월 일정이 뒤로 밀려 안 보이는지
- 날짜가 `12:00 AM` 이 아니라 `8/22` 로 보이는지
- 기간이 오늘을 걸치는 일정이 맨 앞에 오는지

## 리스크

| 리스크 | 대응 |
|---|---|
| Swift 변경은 실기기에서만 확인 가능 | 자동 검증 불가를 명시. 수동 확인 필수 |
| `TodoListData` 를 다른 곳에서 쓸 수 있음 | 제거 전 전수 조사 |
| 위젯은 `updateWidget()` 이 불릴 때만 갱신됨 | 이번 범위 밖. 앱 시작 시 갱신은 별도 티켓 |
| Android 위젯도 같은 데이터를 읽음 | `todo_N_*` 키 형식을 바꾸지 않는다. 값만 바뀐다 |

## 이번 범위 밖 (기록)

- **앱 시작 시 위젯이 갱신되지 않는다.** `initializeWidgetSystem()`(`widget_init.dart`)은
  `print` 세 줄뿐이고 `updateWidgetAfterChange`/`requestWidgetUpdate` 도
  `(to be implemented with actual data)` 스텁이다.
  할 일을 추가·수정해야만 위젯이 채워진다. **별도 티켓 대상.**
- `_addUpcomingEventsFutures`(`:439`)가 쓰는 `upcoming_event_N` 키는 별개 위젯 데이터다.
  1차 진단에서 이 둘을 혼동했다. 이번에는 건드리지 않는다.
