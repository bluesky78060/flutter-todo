# DTA-3-6 코드 리뷰 — 홈 위젯 정렬·라벨

일자: 2026-08-23

## 범위

| 파일 | 변경 |
| --- | --- |
| `lib/core/widget/widget_sort.dart` (신규) | `sortTodosByUpcoming`, `compareByUpcoming`, `buildWidgetTimeLabel` |
| `lib/core/widget/widget_service.dart` | 정렬 교체, 라벨 함수 사용, 죽은 코드 제거, `now` 통일 |
| `ios/TodoWidgets/SharedData.swift` | `displayTime` 추가, `getProgressCounts` 추가, `getTodayTodos` 삭제 |
| `ios/TodoWidgets/TodoListWidget.swift` | 제목, 라벨, 목록 소스·카운트 |
| `ios/TodoWidgets/TodoDetailWidget.swift` | 제목, 시간 배지 라벨 |
| `ios/TodoWidgets/TodoCalendarWidget.swift` | 제목 |
| `test/unit/widget/widget_sort_test.dart` (신규) | 18건 |

## 검증 레인

DTA-3-7 과 같은 작업 트리에서 함께 리뷰됐습니다. 두 레인 모두 이 파일들을
포함한 diff 전체를 봤습니다 — 상세는 [DTA-3-7-review.md](DTA-3-7-review.md).

레인 2(다른 계열 모델)는 `codex` 사용량 한도, `gemini` 환경변수 미설정으로
**수행하지 못했습니다.** 그 자리에서 직접 실행해 확인한 결과입니다.

## 리뷰 도중 드러난 DTA-3-6 자체의 미완성

이 티켓은 "완료"에 가까웠으나 **두 군데가 남아 있었습니다.** 사용자가
"위젯에서 완료 가능하도록 해줘"라고 요청해 위젯 코드를 다시 읽다가 발견했습니다.

### 1. `TodoDetailWidget` 의 `12:00 AM` 이 그대로 남아 있었음

`TodoListWidget` 의 라벨만 `displayTime` 으로 바꾸고, `TodoDetailWidget` 의
시간 배지(`formatTime(dueDate)`)를 빠뜨렸습니다. 같은 결함이 같은 화면에
두 군데 있었는데 한쪽만 고친 것입니다.

`parseDateString` 이 `"11/15"` 를 자정 `Date` 로 만들고 `formatTime` 이
`"h:mm a"` 로 그려 날짜가 통째로 사라집니다.

### 2. 제목과 목록 소스가 어긋나 있었음

`TodoListWidget` 의 제목을 `"다가오는 일정"` 으로 바꿔 놓고, 목록 소스는
`getTodayTodos()`(오늘만)로 두었습니다.

더 나쁜 것은 그 필터의 구현입니다 — **표시용 문자열을 되파싱**해서 날짜를
복원합니다. DTA-3-6 이 라벨을 `"8/25 09:00"` 로 바꾼 순간 파싱이 실패해
`dueDate` 가 nil 이 되고, 필터가 **항목을 통째로 걸러 냅니다.**

즉 제 변경이 이 위젯을 비울 수 있는 상태였습니다.

→ 필터를 제거하고 `getIncompleteTodos()` 를 씁니다. 무엇을 보여줄지는
Flutter 가 이미 "다가오는 순서"로 정해서 보냅니다. 진행률은 Flutter 가
오늘 기준으로 세어 저장한 `todo_completed_count` / `todo_total_count` 를
그대로 읽습니다 — 위젯이 다시 세면 목록과 기준이 어긋납니다.

## 리뷰 지적 중 이 티켓에 해당하는 것

| 심각도 | 내용 | 조치 |
| --- | --- | --- |
| SUGGESTION | 한 갱신 안에서 `DateTime.now()` 를 4번 따로 읽음. 자정 경계에서 "내일"로 정렬된 항목이 "today" 로 그룹핑될 수 있음 | `now` 하나로 통일 |
| MINOR | 오늘 항목이 0건이면 카운터가 사라지는데 목록에는 미래 일정이 보임 | **별도 티켓** — 라벨을 "오늘 N/M" 으로 바꾸는 편이 낫다 |
| MINOR | `parseDateString` 이 새 라벨 형식을 못 읽음 | **별도 티켓** — 두 위젯 모두 `displayTime` 우선이라 현재 무해하나, `dueDate` 기반 코드가 추가되면 조용히 깨진다 |
| MINOR | `todo_N_completed` 는 항상 false (미완료만 저장) → 체크 아이콘 분기가 죽은 코드 | 기록만. 동작에 영향 없음 |

리뷰어 평가: "`compareByUpcoming` 은 요소별 키 기반이라 **비교자 추이성이
성립**한다(정렬 크래시 위험 없음)", "`displayTime` 원본 문자열을 들고 다니는
결정이 옳다".

## 자동 검증

| 항목 | 결과 |
| --- | --- |
| `flutter analyze` | error 0 / warning 0 |
| `flutter test` | 242 통과 / 4 skip (이 티켓 신규 18건) |
| `flutter build ios --profile` | ✅ |
| 변이 검증 | 5건 사망 — `position` 순 되돌리기(9건 사망), 기간 우선 제거, 마감없음 규칙 제거, 알림 시 시각만, 진행 중 라벨 제거 |

## 실기기 확인

- 정렬이 "다가오는 순서"로 바뀐 것: 사용자 확인 (2026-08-23)
- **`TodoDetailWidget` 배지와 `TodoListWidget` 목록 소스 수정은 그 확인 이후**
  들어갔으므로 재확인 필요

## 판정

DTA-3-6 의 원래 목표(정렬·라벨)는 달성했고, 리뷰 중 발견한 미완성 2건을
함께 닫았습니다. 남은 MINOR 2건은 별도 티켓입니다.
