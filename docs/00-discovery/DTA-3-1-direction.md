# Discovery — DTA-3-1: Google Calendar 동기화가 동작하지 않음

- 작성일: 2026-08-21
- 상태: **Discovery Q&A 생략** — 사용자 증상 신고 + 코드 조사로 원인이 확정되어 방향 탐색의 여지가 없음

## 사용자 신고

> "범위가 있는 일정 등록이 안되는거 같은데"

## 조사 결과 — 신고 내용이 세 개의 서로 다른 문제를 가리키고 있었다

`grep`과 호출 경로 추적으로 확인한 사실이다.

### (1) 동기화 UI가 스텁 — **직접 원인**

`lib/presentation/screens/settings_screen.dart:854-859`

```dart
Future<void> _syncTodosToCalendar() async {
  // TODO: Get todos with due dates and sync them
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('syncing_to_calendar'.tr())),
  );
}
```

호출 경로 추적 결과:

| 심볼 | 호출부 |
|---|---|
| `googleCalendarProvider.notifier.addTodoToCalendar` | **0건** |
| `googleCalendarProvider.notifier.syncTodos` | **0건** |
| `GoogleCalendarService.addTodoToCalendar` | provider 내부 1건뿐 (그 provider 메서드를 아무도 안 부름) |
| `GoogleCalendarService.syncTodosToCalendar` | 동일 |

서비스와 provider까지는 구현돼 있으나 **UI에 연결되지 않았다.**
게다가 스낵바가 성공처럼 보여 증상을 가린다. 글로벌 규칙의 "No fake completion"에 정확히 해당한다.

### (2) 종일 이벤트 `end.date`가 exclusive 규칙을 어김 — **버그**

`lib/core/services/google_calendar_service.dart:150-152`

```dart
final dateStr = todo.dueDate!.toIso8601String().split('T')[0];
event.start!.date = DateTime.parse(dateStr);
event.end!.date = DateTime.parse(dateStr);   // start 와 동일
```

Google Calendar API에서 종일 이벤트의 `end.date`는 **exclusive**다.
8/21 하루짜리는 `start=8/21, end=8/22`여야 한다. 지금은 길이 0인 이벤트라 거부되거나 표시되지 않는다.

**분기별 영향**: `notificationTime != null`이면 `dateTime` 경로(1시간 이벤트)를 타서 정상이다.
`notificationTime == null`인 할 일만 이 경로로 빠진다.
(1)을 고치는 순간 이 버그가 그대로 드러나므로 함께 처리해야 한다.

### (3) 범위 일정 미구현 — **별도 티켓 (DTA-3-2)**

`Todo`에 `startDate`/`endDate`가 없다. `dueDate` 단일 필드뿐이다.
엔티티·Drift 스키마·Supabase 테이블·폼·캘린더 전부 해당한다.
앱 전체에 `showDateRangePicker` 사용처가 0건이다.

> **혼동 지점**: 반복 설정 다이얼로그의 "종료일"(`recurrence_settings_dialog.dart`)은
> RRULE의 `UNTIL`이다. *반복을 언제까지 되풀이할지*의 경계이지 일정의 기간이 아니다.

## 확정된 방향 (사용자 선택)

2026-08-21 세션에서 사용자가 **"둘 다 — 버그 먼저, 그다음 범위 기능"** 을 선택했다.

- **DTA-3-1** (이 티켓): (1) + (2). 동기화를 실제로 연결하고 종일 이벤트 버그를 고친다.
- **DTA-3-2**: (3) 범위 일정. 분량이 커서 별도 Discovery가 필요하다.

## 제약

- **실제 Google Calendar 계정 연동 검증은 자동화 불가.** OAuth 로그인과 실제 캘린더 쓰기가 필요하다.
  단위 테스트로 이벤트 객체 구성(특히 `end.date = start + 1일`)까지는 못박을 수 있다.
- 동기화 대상 할 일의 범위(전체 / 미완료만 / 기간 제한)를 정해야 한다.
  현재 `syncTodosToCalendar`는 `dueDate != null`인 것만 거른다.
- 중복 등록 방지 장치가 없다. 두 번 누르면 같은 일정이 두 번 들어간다. **이번 범위에 포함할지 판단 필요.**
