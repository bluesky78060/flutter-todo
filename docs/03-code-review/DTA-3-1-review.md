# 코드 리뷰 — DTA-3-1: Google Calendar 동기화 미연결 + 종일 이벤트 버그

- 작성일: 2026-08-21
- 티켓: `DTA-3-1` (`d4dab806-c25b-440c-8aeb-0dbecd80749e`)
- 리뷰어: **`code-reviewer` 에이전트 (Claude Opus, 별도 컨텍스트)**
- 리뷰 라운드: **3회** (반려 → 반려 → 승인)
- 최종 판정: **승인**

## ⚠️ 이번 리뷰의 한계 — 둘째 레인이 없었다

`~/.claude/rules/ai-pm-ticket.md`의 3중 검증 중 **둘째 레인(Claude와 다른 계열 모델의 독립 리뷰)을
수행하지 못했다.** 실제로 확인한 결과는 다음과 같다.

| CLI | 상태 (2026-08-21 실측) |
|---|---|
| `codex` | **사용 한도 초과** — `You've hit your usage limit ... try again at Sep 10th, 2026` |
| `gemini` | `GOOGLE_CLOUD_PROJECT=sample-log-electron` 설정 후에도 `You do not have a valid license of this product (#3501)` |
| `antigravity` | 미설치 |

한 줄 프롬프트를 **실제로 실행해** 확인했다(`which`만으로는 판단하지 않았다).

사용자에게 이 사실을 알리고 승인을 받아 `code-reviewer` 에이전트(Claude Opus, 별도 컨텍스트)로 대체했다.
**같은 계열 모델이므로 "다른 시각"이라는 원래 목적은 온전히 달성되지 않았다.**
이 문서에 codex/gemini 리뷰를 했다고 적지 않았다.

적대적 검증 레인은 **변이 검증**으로 실제 수행했다(아래).

## 원인 — 사용자 신고와 실제 결함이 달랐다

사용자 신고는 *"범위가 있는 일정 등록이 안 되는 것 같다"* 였다. 조사 결과 세 개의 서로 다른 문제였다.

| # | 문제 | 처리 |
|---|---|---|
| 1 | **동기화 UI가 스텁** — 눌러도 아무 일도 일어나지 않음 | 이 티켓 |
| 2 | 종일 이벤트 `end.date`가 `start.date`와 같아 길이 0인 이벤트 | 이 티켓 |
| 3 | 범위 일정(시작일~종료일) 필드 자체가 없음 | 미착수 |

`settings_screen.dart`의 `_syncTodosToCalendar()`는 `// TODO: Get todos with due dates and sync them`
주석과 "동기화 중" 스낵바뿐이었다. `googleCalendarProvider.notifier`의
`addTodoToCalendar`/`syncTodos`는 **호출부가 0건**이었다.
서비스·provider까지만 구현되고 UI에 연결되지 않은 상태였고, 성공처럼 보이는 스낵바가 증상을 가렸다.

## 라운드 1 — 반려 (CRITICAL 2 / MAJOR 3 / MINOR 8 / SUGGESTION 3)

### CRITICAL-1 — 같은 세션 2회차 동기화에서 전부 중복 등록

`_persistEventId`가 Supabase 행만 고치고 `todosProvider`를 invalidate 하지 않았다.
설정 화면은 목록 화면 위에 `Navigator.push`로 쌓여 아래 구독이 살아 있으므로 캐시가 유지된다.
2회차는 `googleEventId == null`인 낡은 객체를 보고 전부 `insert` 한다.

> **"등록이 안 되네?" 하고 한 번 더 누르는 것이 사용자의 첫 행동이다.**
> 중복 방지가 앱 재시작 후에만 동작하는 상태였다.

### CRITICAL-2 — 모든 예외에서 폴백해 중복 + 되돌릴 수 없는 고아 이벤트

주석은 404라고 썼는데 코드는 `catch (e)`로 모든 예외를 잡았다.
타임아웃·429·503도 `insert`로 떨어진다. 더 나쁜 것은 폴백으로 만든 새 ID가
기존 ID를 **덮어써서** 원본 이벤트를 영영 참조할 수 없게 만든다는 점이다.

### MAJOR-3 — `todosProvider`는 필터링된 목록이었다

`todo_providers.dart:92-127`이 `todoFilterProvider`/`categoryFilterProvider`/`searchQueryProvider`를
모두 `ref.watch` 한다. 목록 화면에서 "완료" 필터를 켠 채 설정에 들어가면 동기화 대상이 0건이 되고,
검색어가 남아 있으면 그 결과만 등록되면서 스낵바는 성공을 알린다.

**"필터링은 provider가 맡는다"고 주석까지 달았던 것이 사실과 반대였다.**

### MAJOR-4 / MAJOR-5
- `todosProvider`가 실패 시 throw 하는데 `try/catch`가 없어 기내 모드에서 결과 스낵바가 아예 안 뜸
- `_persistEventId`의 doc 주석이 "예외를 던지지 않는다"고 했으나 본문에 `try/catch`가 없음

## 라운드 2 — 반려 (MAJOR 1 / MINOR 4)

CRITICAL 2건은 닫혔으나 **수정 과정에서 MAJOR-4를 다시 뚫었다.**

### MAJOR-N1 — `fold`가 저장소 실패를 삼켜 `catch`가 도달 불가능해짐

```dart
final todos = fetched.fold((_) => const <Todo>[], (list) => list);
//                          ^^^^^^^^^^^^^^^^^^^^ 실패를 버림
```

`SupabaseTodoRepository`는 예외를 던지지 않고 `Left(DatabaseFailure)`로 감싼다.
이전에 쓰던 `todosProvider`는 이를 되던졌는데, `fold`로 직접 처리하며 그 통로를 끊었다.

결과가 무응답보다 나빴다. 기내 모드에서 `todos = []` → `succeeded 0` →
**"등록할 할 일이 없습니다"** 가 뜬다. DB를 못 읽은 것인데 **사용자에게 틀린 원인을 적극적으로 알려주는** 상태.

> 리뷰어 표현: *"오류가 사라지는 위치만 화면에서 provider로 한 층 내려갔습니다."*

이 결함이 두 번 살아남은 이유는 **`syncAllTodos` 계층에 테스트가 0건**이었기 때문이다.

## 라운드 3 — 승인 (MINOR 3 / SUGGESTION 2, 전부 비차단)

리뷰어가 데이터 경로를 전 구간 확인해 CRITICAL-1 해소를 검증했다.

- `supabase_datasource.dart:74`의 `client.from('todos').select()`가 **컬럼을 열거하지 않으므로**
  `google_event_id`가 포함된다 (열거했다면 여기서 조용히 누락됐을 것)
- `_todoFromJson:387`이 `json['google_event_id']`를 읽는다
- 캐시를 거치지 않으므로 직전 저장 ID가 반드시 반영된다

비차단 MINOR 3건도 이번에 함께 정리했다(아래).

## 최종 변경 목록

| 영역 | 내용 |
|---|---|
| **버그 수정** | 종일 이벤트 `end.date = start + 1일` (exclusive 규칙) |
| **미연결 해소** | `_syncTodosToCalendar` 스텁 → 실제 구현, 결과를 스낵바에 표시 |
| **중복 방지** | `Todo.googleEventId` + `routeEventWrite`로 update/insert 라우팅. 404/410에서만 폴백 |
| **대상 선별** | 마감일 있는 **미완료** 할 일. 화면 필터와 무관하게 저장소에서 직접 조회 |
| **실패 가시화** | `CalendarSyncResult`(성공/실패/건너뜀/미연결) + 실패 시 원인 스낵바 |
| **결합 격리** | `google_event_id`를 일반 `updateTodo` payload에 넣지 않고 `updateGoogleEventId` 전용 경로로만 |
| **동시 실행** | `_isSyncingCalendar` 가드. 진행 중 재탭 시 안내 |
| **마이그레이션** | `supabase/migrations/20260821_add_google_event_id.sql` |

## 검증받은 설계 판단

리뷰어가 근거까지 확인해 **옳다고 판정**한 것들이다.

1. **`updateGoogleEventId` 격리** — `updateTodo` payload에 컬럼이 없음을 확인했고,
   PostgREST가 미지정 컬럼을 건드리지 않으므로 일반 수정이 ID를 덮어쓸 위험도 없다.
   컬럼 미존재 시 폭발 반경이 캘린더 동기화로 한정된다.
2. **Drift 배제** — `grep -rn "TodoRepositoryImpl" lib/` 결과가 자기 정의와 doc 주석뿐이고,
   `todoRepositoryProvider`는 `SupabaseTodoRepository`를 문다. **Drift 리포지토리는 도달 불가능한 죽은 코드.**
3. **타임존** — `googleapis-12.0.0`의 `EventDateTime.toJson`이 `date`를 `toUtc()` 없이
   `year/month/day`로 직접 포맷한다. `DateTime.utc(y,m,d)`는 사용자의 로컬 달력 날짜를
   그대로 직렬화한다. **경계에서 밀리지 않는다.**
4. **`debugSetConnected`** — `GoogleCalendarService`는 생성적 생성자가 private이라 서브클래싱이
   불가능하고 인터페이스도 없다. 이 제약 아래에서 가장 작은 변경이다.

## 적대적 검증 — 변이 검증 2회 (실제 수행)

| 변이 | 결과 |
|---|---|
| `end.date = startDay` (원래 버그 재현) | **3건 사망** → 복원 시 8/8 |
| 폴백 조건 `status != 404 && status != 410` 제거 | **3건 사망** → 복원 시 17/17 |
| `fold`를 실패 삼키기로 되돌림 | **2건 사망** → 복원 시 3/3 |

테스트가 우연히 통과하는 것이 아니라 실제로 각 결함을 막는다는 것을 확인했다.

## 검증 결과

| 항목 | 결과 |
|---|---|
| `flutter analyze` | ✅ error 0 / warning 0 (117건 전부 info) |
| `flutter test` | ✅ **157 통과 / 4 skip / 0 실패** |
| CI 범위 | ✅ 148 통과 |
| 브라우저 | ✅ 4/4 |
| `flutter build web --release` | ✅ 성공 |
| 신규 테스트 | 이벤트 구성 8 + 라우팅 9 + provider 계층 3 = **20건** |

## 남은 사항 — 별도 티켓 대상 (리뷰어 동의)

어느 것도 이번 변경이 만든 결함이 아니며 데이터 정합성을 해치지 않는다.

| # | 내용 | 비고 |
|---|---|---|
| MINOR-9 | **완료·삭제된 할 일의 캘린더 이벤트가 영구히 남음** | `syncAllTodos`가 완료 항목을 제외하므로 사용자 눈에 가장 먼저 띌 것. **우선순위 상향 권고** |
| MINOR-8 | 시간 지정 이벤트가 마감일이 아니라 **알림 시간**에 등록됨 | 기존 동작. 설계 판단 필요 |
| MINOR-10 / N4 | 순차 HTTP 요청, 백오프·진행률·취소 없음 | 대상이 계정 전체로 넓어져 **위험도 상승** |
| S-15 | `copyWith`로 `googleEventId`를 null로 지울 수 없음 | sentinel 또는 Freezed |
| S-2 | `CalendarService` 인터페이스 추출 | MINOR-9 티켓에서 함께 하면 비용 절감 |
| S-17 | 작업 트리에 무관한 파일 ~24개 | **커밋 시 경로 명시해 분리** |

## 자동 검증 불가 — 사용자 수동 확인 필요

`docs/03-code-review/DTA-3-1-manual-check.md` 참조.
**선행: Supabase에 `google_event_id` 컬럼 추가 SQL 실행.**
안 돌리면 등록은 되지만 중복 방지가 동작하지 않는다(나머지 기능은 무영향).
