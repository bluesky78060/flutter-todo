# 플랜 — DTA-3-4: 범위 일정(시작일~종료일) 지원

- 작성일: 2026-08-21
- 선행: `docs/00-discovery/DTA-3-4-direction.md` (정정 포함)
- 원칙: **`startDate == null` 이면 현재와 100% 동일하게 동작한다.**
  이 한 줄이 `dueDate` 255곳에 대한 파급 차단 장치다.

## 두 "충돌" 을 설계로 없앤다

Discovery 에서 리스크로 잡았던 둘은 실제로 피할 수 있다.

### 충돌 1 — `buildEvent` 테스트가 사양을 고정한다 → **존재하지 않음**

`test/unit/services/google_calendar_event_test.dart` 의 기존 8건은 전부
`makeTodo(dueDate: ...)` 로 만들며 `startDate` 를 주지 않는다.
`startDate` 가 nullable 로 추가되면 이 테스트들은 **`startDate == null` 케이스**를 기술하게 된다.

> ~~**고칠 것이 없고 범위 케이스를 덧붙이면 된다.**~~ **← 부분 철회. rev.2 CRITICAL-2 참조.**
> `notificationTime` 갈래를 빠뜨렸다. 시간 지정 이벤트 2건은 한정이 필요하다.

### 충돌 2 — 마이그레이션 미실행 시 모든 저장이 깨진다 → **키를 조건부로 넣어 회피**

payload 가 맵 리터럴이므로 `startDate == null` 일 때 **키 자체를 넣지 않는다.**

```dart
final payload = <String, dynamic>{ ...기존 그대로... };
// start_date 는 값이 있을 때만 넣는다.
// 넣지 않으면 컬럼이 없는 프로젝트에서도 PostgREST 가 문제 삼지 않는다.
if (startDate != null) {
  payload['start_date'] = startDate.toUtc().toIso8601String();
}
```

결과:

| 상황 | 마이그레이션 전 | 마이그레이션 후 |
|---|---|---|
| 기존 할 일 수정 | ✅ 정상 (키 없음) | ✅ 정상 |
| 하루짜리 새 할 일 | ✅ 정상 (키 없음) | ✅ 정상 |
| **범위 일정 생성** | ❌ 실패 — 새 기능만 막힘 | ✅ 정상 |

**앱이 통째로 깨지는 시나리오가 사라진다.** 실패는 새 기능에 한정되고, 사용자에게 표시된다.

> 이건 fallback shim 이 아니다. "값이 없으면 보내지 않는다" 는 것뿐이며,
> 없는 값을 지어내거나 다른 경로로 우회하지 않는다.

### ~~범위를 해제할 때 (`startDate` 를 null 로 되돌릴 때)~~ **← 이 절 전체 폐기. rev.3 참조**

키를 빼면 기존 값이 남는다. 그래서 **컬럼 존재가 확인된 경우에만** `'start_date': null` 을 보낸다.

컬럼 존재 여부는 **추가 요청 없이** 알 수 있다.
`supabase_datasource.dart:74` 의 `select()` 가 컬럼을 열거하지 않으므로 응답 행에 전 컬럼이 실린다.
`_todoFromJson` 에서 `json.containsKey('start_date')` 로 확인해 플래그를 세운다.
(PostgREST 는 값이 null 이어도 키를 포함한다.)

컬럼이 없으면 애초에 범위를 만들 수 없었으므로 **지울 것도 없다.** 논리적으로 닫힌다.

## 변경 목록

### 1. 엔티티 — `lib/domain/entities/todo.dart`
`DateTime? startDate` 추가. 생성자·`copyWith` 반영.

의미를 doc 주석에 못박는다:
- `startDate == null` → 하루짜리. `dueDate` 가 그 날
- `startDate != null` → 범위. `startDate` ~ `dueDate` (양끝 포함)

편의 게터 추가:
```dart
bool get isRanged => startDate != null && dueDate != null;
/// 이 할 일이 [day] 에 걸쳐 있는가. 날짜만 비교한다.
bool occursOn(DateTime day);
```
`occursOn` 을 한 곳에 두는 것이 핵심이다. ~~지금 날짜 매칭이 최소 2곳에 중복 구현돼 있다.~~
**정정: 4곳이다. rev.2 MINOR-1 참조.**

### 2. Supabase — `lib/data/datasources/remote/supabase_datasource.dart`
- `_todoFromJson` 에 `startDate: _parseUtcDateTime(json['start_date'] as String?)`
- 같은 자리에서 `json.containsKey('start_date')` 로 컬럼 존재 플래그 갱신
- `createTodo` / `updateTodo` payload 에 **조건부** `start_date`
- `createTodo` 시그니처에 `DateTime? startDate` 추가 → repository 인터페이스·구현 3곳 연쇄

### 3. 폼 — `lib/presentation/widgets/todo_form_dialog.dart`
- "기간으로 설정" 토글. 켜면 `showDateRangePicker`, 끄면 기존 `showDatePicker`
- 검증: 시작일 ≤ 종료일. 위반 시 저장 차단
- **반복 설정과 동시 사용 차단** (Discovery 합의). 기간이 켜져 있으면 반복 UI 비활성 + 사유 표시

### 4. 캘린더 — 날짜 매칭 일원화
- `calendar_providers.dart:55` `todosByDateProvider` — 기간 내 **모든 날짜 키**에 추가
- `calendar_screen.dart:121` `_getTodosForDay` — 중복 구현을 `todo.occursOn(day)` 로 교체
- `selectedDateTodosProvider` 는 `todosByDateProvider` 를 쓰므로 **자동으로 따라온다**

> 이 변경 하나가 "캘린더 기간 표시" 와 "오늘 선택 시 진행 중인 일정 노출" 을 동시에 해결한다.

### 5. Google Calendar — `lib/core/services/google_calendar_service.dart`
```dart
final startDay = dateOnly(todo.startDate ?? todo.dueDate!);
final endDay   = dateOnly(todo.dueDate!);
event.start!.date = startDay;
event.end!.date   = endDay.add(const Duration(days: 1));  // exclusive
// 주의: 이 한 번의 +1일은 안전하다(단일 날짜 산술).
// 기간 '열거'에 Duration 을 누적하면 DST 에서 깨진다 — rev.2 MAJOR-2 참조.
```
`startDate == null` 이면 `startDay == endDay` 가 되어 기존과 동일하다.

### 6. 알림
시작일에 예약한다. `notificationTime` 은 그대로 쓰되,
범위 일정이면 **시작일 기준**으로 계산되도록 예약 지점을 확인한다.

### 7. 마이그레이션
~~`supabase/migrations/20260821_add_start_date.sql`~~ → **`20260821000001_add_start_date.sql`** (rev.2 MINOR-3)

## 검증 게이트

| 단계 | 기준 |
|---|---|
| `flutter analyze` | error 0, warning 0 |
| `flutter test` | 실패 0 |
| CI 범위 / 브라우저 | 실패 0 |
| `flutter build web --release` | 성공 |

## 테스트 (회귀 방지 핵심)

**하위호환 — 가장 중요**
- `startDate == null` 인 할 일이 캘린더에서 이전과 동일하게 하루만 차지
- `buildEvent` 기존 8건이 그대로 통과 (수정 없이)
- `start_date` 키가 payload 에 들어가지 않음

**범위 동작**
- `occursOn` 경계: 시작일 / 중간 / 종료일 = true, 하루 전 / 하루 후 = false
- `todosByDateProvider` 가 기간 내 모든 날짜에 매핑
- `buildEvent` 범위: `end.date == 종료일 + 1일` (월말·연말 경계 포함)
- 시작일 > 종료일 저장 차단

**변이 검증**
- `occursOn` 을 `dueDate` 단일 비교로 되돌려 테스트가 죽는지
- `end.date` 를 `startDay + 1일` 로 되돌려 범위 테스트가 죽는지

## 리스크

| 리스크 | 대응 |
|---|---|
| `dueDate` 255곳 | 새 분기는 `startDate != null` 일 때만. null 경로는 손대지 않는다 |
| 날짜 매칭 중복 구현 | `Todo.occursOn` 한 곳으로 모은다. 안 그러면 한쪽만 고쳐진다 |
| 홈 위젯 불일치 | `_getTodayTodos` 는 범위 밖. **기간 중 위젯에 안 뜬다.** 의도된 미해결이며 별도 티켓 |
| 타임존 | ~~날짜 비교는 반드시 로컬 기준 `dateOnly` 로~~ → **`dateOnlyLocal` / `dateOnlyUtc` 로 분할. rev.2 MAJOR-1** |
| 반복 조합 | UI 에서 차단하되, 이미 저장된 데이터에 둘 다 있으면 어떻게 되는지 정의 필요 → 반복을 우선하고 기간 무시 |

## 미해결 (사용자 확인 필요)

1. **`startDate` 는 있는데 `dueDate` 가 없는 경우** — 범위가 성립하지 않는다.
   폼에서 종료일을 필수로 할지, 시작일=종료일로 정규화할지.
   → 폼에서 필수로 잡는 것을 기본으로 진행하되, 방어적으로 `occursOn` 은 `dueDate == null` 이면 false
2. **홈 위젯 미반영을 감수할지** — Discovery 합의대로 제외하지만,
   "기간 중인데 위젯에 안 뜬다" 가 눈에 띌 수 있다

---

# 개정 (rev.2) — 플랜 리뷰 반영

- 개정일: 2026-08-21
- 근거: `critic` 에이전트(Opus) 독립 리뷰 — **조건부 승인** (CRITICAL 2 / MAJOR 5 / MINOR 5 / SUGGESTION 5)
- **rev.1 과 충돌하면 rev.2 가 우선한다.**

지적 전건을 코드로 대조해 **전부 사실임을 확인**했다.

## CRITICAL-1 — `copyWith` 로는 `startDate` 를 null 로 되돌릴 수 없다

rev.1 에서 가장 공들인 "범위 해제" 절이 **도달 불가능한 코드**였다.

`todo.dart` 의 `copyWith` 는 전 필드가 `x ?? this.x` 다.
편집 저장은 `todo_form_dialog.dart:799` 에서 `existingTodo.copyWith(...)` 를 쓴다.
따라서 `copyWith(startDate: null)` → `null ?? this.startDate` → **기존 값이 그대로 살아남는다.**
`updateTodo` 가 받는 `todo.startDate` 는 **절대 null 이 되지 않는다.**

### 조치 — sentinel 로 "지정 안 함" 과 "null 로 지정" 을 구분한다

```dart
/// "인자를 주지 않았다" 를 "null 을 주었다" 와 구분하기 위한 표식.
const _unset = Object();

Todo copyWith({
  ...,
  Object? startDate = _unset,
}) {
  return Todo(
    ...,
    startDate: identical(startDate, _unset)
        ? this.startDate
        : startDate as DateTime?,
  );
}
```

**`startDate` 에만 적용한다.** `dueDate`·`categoryId` 등도 같은 잠재 결함이 있으나
기존 결함이고 이번 범위 밖이다. `startDate` 는 **해제 흐름을 명시적으로 설계했기 때문에** 범위 안이다.

## CRITICAL-2 — `buildEvent` 의 `notificationTime` 분기를 빠뜨렸다

`google_calendar_service.dart:138-156` 은 두 갈래다.

```dart
if (todo.notificationTime != null) {
  ... dateTime 1시간 이벤트 ...   // rev.1 §5 는 여기 손대지 않았다
} else {
  ... date 종일 이벤트 ...        // rev.1 §5 가 고치겠다던 곳
}
```

Discovery 3-4 가 *"알림: 시작일에만 — 출장·여행에서 '내일 출발' 을 놓치지 않는 것이 핵심"* 이라고
못박았다. 즉 **이 기능의 주인공인 출장·여행 일정은 거의 항상 `notificationTime` 을 갖는다.**

**시나리오**: 출장 8/21~8/25, 알림 8/20 21:00 → 캘린더에 **8/20 21:00~22:00 1시간 이벤트** 하나.
5일짜리 일정은 어디에도 없다. 이 티켓의 헤드라인 산출물이 헤드라인 시나리오에서 실패한다.

### 조치 — 범위면 알림 유무와 무관하게 종일 분기로 보낸다

```dart
if (todo.startDate != null) {
  // 범위는 본질적으로 종일 사건이다.
  // 알림은 앱 로컬 알림이 담당하므로 캘린더 이벤트의 시각과 무관하다.
  ... 종일 분기 ...
} else if (todo.notificationTime != null) {
  ... 기존 1시간 이벤트 ...
} else {
  ... 기존 종일 ...
}
```

**rev.1 의 "고칠 테스트가 없다" 선언을 부분 철회한다.**
`buildEvent` 기존 8건 중 **시간 지정 이벤트 2건은 "`startDate == null` 일 때만" 으로 한정**해야 한다.
나머지 6건은 그대로 통과한다.

## MAJOR-1 — `dateOnly` 를 둘로 나눈다

rev.1 은 `dateOnly` 하나에 상반된 요구를 걸었다.
§5 는 Google `date` 필드용(현재 `DateTime.utc`)이고, 리스크 표는 "로컬 기준" 이라고 썼다.

Dart 에서 `DateTime.utc(2025,8,21) == DateTime(2025,8,21)` 은 **false** 다 (`isUtc` 까지 비교).
하나로 만들면 기존 테스트 4건이 즉시 깨진다.

```dart
DateTime dateOnlyLocal(DateTime d) => DateTime(d.year, d.month, d.day);        // 비교·키 생성
DateTime dateOnlyUtc(DateTime d)   => DateTime.utc(d.year, d.month, d.day);    // Google date 전용
```

## MAJOR-2 — 기간 열거에 `Duration(days: 1)` 누적 금지 (DST)

`todosByDateProvider` 는 기간 내 모든 날짜 **키를 열거**한다. 비교가 아니라 열거다.

**시나리오**: 웹 배포판을 미국 타임존 브라우저에서 연다. 범위가 2025-03-09(미 서머타임 시작)를 포함한다.
`DateTime(2025,3,9).add(Duration(days:1))` → `2025-03-09 23:00` → 정규화하면 **다시 3/9**.
`while (cursor <= end)` 면 **커서가 전진하지 않아 무한 루프 → 앱 정지.**

한국은 DST 가 없지만 이 앱은 웹으로 배포되고 브라우저 타임존은 통제할 수 없다.

```dart
for (var i = 0; ; i++) {
  final day = DateTime(start.year, start.month, start.day + i); // 오버플로 자동 정규화
  if (day.isAfter(end)) break;
  ...
}
```

`occursOn` 도 `Duration` 없이 정규화된 `DateTime` 3개의 대소 비교로만 구현한다.

## MAJOR-3 — 백업/복원이 `startDate` 를 조용히 버린다

`backup_service.dart:235` 직렬화 목록에 `startDate` 가 없고, `:194` 복원도 `dueDate` 만 넘긴다.

**시나리오**: 범위 일정 3건 → 백업 → 기기 교체 → 복원 → **전부 하루짜리로 되살아난다.**
오류도 경고도 없다. 사용자는 복원이 성공했다고 믿는다.

Discovery §5 의 제외 목록에 백업이 없다. **의도적 제외가 아니라 누락이다.** 범위에 포함한다.
구 버전 백업 파일에 키가 없을 때 null 로 떨어지는지도 테스트한다.

## MAJOR-4 — 컬럼 존재 플래그를 없앤다

리뷰어 지적이 정확하다. 플래그는 **두 상태를 구분하지 못한다**:
(A) 컬럼이 없다 / (B) 아직 한 번도 fetch 하지 않았다.
행이 0건이면 `_todoFromJson` 이 호출조차 되지 않는다.
rev.1 의 *"컬럼이 없으면 지울 것도 없다"* 는 (A) 에서만 참이다. **논리적으로 닫히지 않는다.**

### 채택안 — 플래그 대신 **명시적 해제 경로**

| 경로 | 처리 |
|---|---|
| `createTodo` | `startDate != null` 일 때만 키 포함 (rev.1 유지, 무상태) |
| `updateTodo` | `startDate != null` 일 때만 키 포함 |
| **범위 해제** | 전용 메서드 `clearStartDate(int todoId)` 로 `'start_date': null` 전송 |

폼은 `existingTodo.startDate != null && 새 값 == null` 일 때만 `clearStartDate` 를 부른다.
**이 경로는 사용자가 범위를 만든 적이 있을 때만 도달하므로 컬럼 존재가 보장된다.**
숨은 상태가 없고, 조건이 코드에 드러나며, 마이그레이션 미실행 시에도 기존 기능이 깨지지 않는다.

> 리뷰어는 "update 를 무조건 포함하고 마이그레이션을 선행 조건으로 집행" 을 권했다.
> 그쪽이 더 단순하지만 마이그레이션을 잊으면 **모든 할 일 수정이 실패**한다.
> 사용자가 "충돌 없이 진행" 을 명시적으로 요구했으므로, 실패 반경을 새 기능에 가두는 쪽을 택한다.
> **이 판단은 2라운드 리뷰에서 재검토 대상이다.**

## MAJOR-5 — 목록·상세에 기간을 표시한다

`todo_detail_content.dart:147-151` 과 `custom_todo_item.dart:204` 는 `dueDate` 하나만 보여준다.
범위를 등록해도 목록에는 "8월 25일" 로만 보이고, 기간을 확인할 유일한 방법이 캘린더 화면이다.
→ **"등록이 됐나?" 하고 다시 폼을 여는 행동**을 유발한다. 이 티켓의 출발점이 정확히 그것이었다.

`isRanged` 게터를 이미 만들므로 두 곳에 `if (todo.isRanged) '8/21 ~ 8/25'` 를 넣는다. 비용이 거의 없다.

## MINOR 반영

| # | 조치 |
|---|---|
| 1 | 날짜 매칭 중복은 **2곳이 아니라 4곳**이다. `widget_service.dart:574`(홈 위젯)와 `calendar_widget_window.dart:1015`(Windows) 는 **의도적 제외**로 명시한다. rev.1 의 "한 곳으로 모은다" 서술을 "4곳 중 2곳을 통합한다" 로 정정 |
| 2 | 검증 게이트에 `dart run build_runner build --delete-conflicting-outputs` 추가. `TodoRepository.createTodo` 시그니처 변경으로 mockito 생성물이 깨진다 |
| 3 | 마이그레이션 파일명을 `20260821000001_add_start_date.sql` 로. `20260821_add_google_event_id.sql` 과 버전이 충돌한다 |
| 4 | 진행 중 범위 일정이 종료일 기준으로 정렬돼 하단에 밀린다. 기능 결함은 아니므로 **미해결로 기록** |
| 5 | `showDateRangePicker` 는 양끝이 자정이라 범위 일정은 자동으로 "종일" 로 렌더링된다. **의도된 동작으로 명시** |

## SUGGESTION 반영

- `occursOn` 을 엔티티에 두는 판단은 **승인받았다.** doc 주석에 의미(양끝 포함, 로컬 날짜 기준)를 못박는다
- **Drift `TodoRepositoryImpl` 결정**: 배선되지 않은 죽은 코드다(`database_provider.dart:59-62`).
  인터페이스 변경 때문에 컴파일은 고쳐야 한다. **`startDate` 를 받아 Drift 컬럼에 저장하도록 최소 구현**하고,
  삭제 여부는 별도 티켓으로 넘긴다. 조용히 무시하면 죽은 코드에 결함이 하나 더 생긴다
- `export_service.dart` 는 범위를 종료일 한 칸으로만 내보낸다. **미해결로 기록** (표시 문제, 데이터 손실 아님)
- 반복 차단을 **양방향**으로 정의한다. 또한 `calendar_widget_window.dart:2084` 가 두 번째 편집 경로다 →
  **Windows 편집 다이얼로그는 기간을 노출하지 않는다** 고 못박는다
- **범위 길이 상한 366일**. 실수로 10년 범위를 만들면 `todosByDateProvider` 에 3,650개 엔트리가 생긴다

## 테스트 목록 보강 (리뷰어 지적 4건 + 1)

rev.1 의 테스트 설계는 "하위호환 회귀를 실제로 잡는가" 에 부분적으로 **아니오** 였다.

1. **범위 해제 왕복** — 설정 → 해제 → 재조회 시 `startDate == null`.
   이게 있었다면 CRITICAL-1 이 즉시 잡혔다. **가장 아픈 누락**
2. **범위 + 알림 조합** — `startDate != null && notificationTime != null` 일 때 종일 이벤트가 나오는지.
   이게 없어서 CRITICAL-2 가 통과했다
3. **DST 경계** — 2025-03-08~03-12 를 미 타임존에서 열거해도 무한 루프가 없고 5일이 나오는지
4. **백업 왕복** — 범위 일정 백업 → 복원 시 기간 보존. 구 버전 파일(키 없음)은 null
5. **payload 키 검증을 가능하게 하는 리팩터링** — 현재 `insert({...})` 에 맵 리터럴이 인라인이라
   테스트 불가다. DTA-3-1 의 `buildEvent`/`routeEventWrite` 와 같은 패턴으로
   `@visibleForTesting static Map<String, dynamic> buildTodoPayload(...)` 를 분리한다

## 갱신된 검증 게이트

| 단계 | 명령 | 기준 |
|---|---|---|
| 코드 생성 | `dart run build_runner build --delete-conflicting-outputs` | 성공 (mockito 재생성) |
| 정적 분석 | `flutter analyze` | error 0, warning 0 |
| 전체 | `flutter test` | 실패 0 |
| CI 범위 / 브라우저 | | 실패 0 |
| 빌드 | `flutter build web --release` | 성공 |
| 변이 검증 | `occursOn` 단일 비교 되돌리기 / `end.date` 되돌리기 | 각각 테스트 사망 확인 |

---

# 개정 (rev.3) — 2라운드 리뷰 반영, 착수 가능

- 개정일: 2026-08-21
- 근거: `critic` 2라운드 — **조건부 승인**. CRITICAL 2건 닫힘 확인, 새 CRITICAL 없음
- 승격 조건 8건을 전부 반영했다. **rev.1·rev.2 와 충돌하면 rev.3 가 우선한다.**

## 1. MAJOR-4 재확정 — 전용 메서드를 폐기하고 **단일 쓰기**로

rev.2 의 `clearStartDate` 전용 메서드를 **철회한다.** 리뷰어 지적이 타당하다.

### 철회 이유 — 논리는 닫았지만 원자성을 깼다

범위 해제 저장 = `updateTodo`(키 없음) + `clearStartDate`(별도 요청) = **두 번의 비원자적 쓰기.**

> **시나리오**: 기간을 해제하고 저장한다. `updateTodo` 는 성공하고 네트워크가 끊겨
> `clearStartDate` 가 실패한다. 화면은 하루짜리로 갱신된다(로컬 엔티티는 null).
> DB 에는 `start_date` 가 남는다. **다음 앱 실행 시 범위가 되살아난다.**
> 오류는 이미 지나갔고 사용자는 자기가 해제한 것을 봤다.

부수 비용도 확인됐다. 선례로 든 `updateGoogleEventId` 는 **리포지토리 인터페이스에 없다**
(`supabase_datasource.dart:244` 정의 → `google_calendar_provider.dart:240` 호출).
같은 모양으로 만들면 호출자가 `todo_form_dialog`(프레젠테이션 위젯)가 되어
데이터소스를 직접 잡아야 한다. 레이어를 위젯에서 관통하는 것이고,
살려 두기로 한 `TodoRepositoryImpl`(Drift)에는 대응 메서드가 없어 두 구현의 능력이 갈라진다.

`updateGoogleEventId` 는 *파생 데이터*를 *인프라 프로바이더*가 쓰는 것이라 성격이 다르다.
`startDate` 는 일반 저장의 일부인 **사용자 입력 도메인 데이터**다. 선례가 적용되지 않는다.

### 채택 — 플래그 인자로 의도를 전달한다

```dart
Future<void> updateTodo(Todo todo, {bool clearStartDate = false});
```
```dart
// buildTodoPayload 안에서
if (todo.startDate != null) {
  payload['start_date'] = todo.startDate!.toUtc().toIso8601String();
} else if (clearStartDate) {
  payload['start_date'] = null;   // 명시적 해제
}
// 둘 다 아니면 키 자체가 없다 — 마이그레이션 미실행 봉쇄 효과 동일
```

| | rev.1 플래그 | rev.2 전용 메서드 | **rev.3 채택** |
|---|---|---|---|
| 마이그레이션 미실행 시 기존 기능 보호 | ✅ | ✅ | ✅ |
| 숨은 상태 없음 | ❌ | ✅ | ✅ |
| 논리적으로 닫힘 | ❌ | ✅ | ✅ |
| **쓰기 원자성** | ✅ | ❌ | ✅ |
| **리포지토리 추상 유지** | ✅ | ❌ | ✅ |
| **`buildTodoPayload` 로 테스트 가능** | ❌ | ❌ | ✅ |

마지막 행이 결정적이다. 아래 3번으로 이어진다.

폼은 `existingTodo.startDate != null && 새 값 == null` 일 때 `clearStartDate: true` 를 넘긴다.
`updateTodo` 는 인터페이스에 이미 있으므로 **Drift 구현도 자연히 따라온다.**

## 2. 폼은 `copyWith` 에 `startDate:` 를 **항상 명시 전달**한다

sentinel 은 "인자 생략" 과 "null 전달" 을 구분한다. 따라서 조건부로 인자를 **빼면**
`_unset` 이 전달되어 옛 값이 살아남는다 — **CRITICAL-1 이 그대로 재현된다.**

```dart
// 금지
if (_isRanged) copyWith(startDate: _selectedStartDate)
// 필수 — 범위가 아니면 명시적으로 null 을 넘긴다
copyWith(startDate: _isRanged ? _selectedStartDate : null)
```

## 3. 테스트 1(범위 해제 왕복)을 구성 가능한 형태로 재서술

rev.2 의 *"재조회 시 `startDate == null`"* 은 Supabase 클라이언트 페이크를 요구하는데
이 저장소에 그런 인프라가 없다. 또 해제 판단이 `todo_form_dialog._save()` — 위젯 테스트가
없는 StatefulWidget 메서드 — 에 놓여 **이 기능의 가장 취약한 판단이 테스트 불가능**했다.
CRITICAL-1 이 처음 통과했던 구조와 동일하다.

1번 채택안이 이를 해소한다. 해제가 payload 결정이 되므로 `buildTodoPayload` 로 직접 단언한다.

```dart
expect(buildTodoPayload(todoWithRange), containsPair('start_date', isNotNull));
expect(buildTodoPayload(todoWithoutRange), isNot(contains('start_date')));
expect(buildTodoPayload(todoWithoutRange, clearStartDate: true),
       containsPair('start_date', null));
```
엔티티 레벨 `copyWith(startDate: null)` 단위 테스트도 함께 둔다.

## 4. 테스트 3(DST)을 구성 가능하게 — 순수 함수 분리 + TZ 명령

Dart 의 로컬 타임존은 **프로세스 시작 시 `TZ` 로 결정되고 테스트 중 바꿀 수 없다.**
rev.2 의 서술대로면 KST 에서 자명하게 통과하는 테스트로 퇴화해 MAJOR-2 가 미검증으로 남는다.

```dart
/// [start] 부터 [end] 까지의 날짜를 열거한다. 양끝 포함, 로컬 날짜 기준.
///
/// Duration 누적을 쓰지 않는다. DST 경계에서 하루가 23시간이 되어
/// 커서가 전진하지 못하고 무한 루프에 빠진다.
List<DateTime> enumerateDays(DateTime start, DateTime end) {
  final result = <DateTime>[];
  for (var i = 0; ; i++) {
    // 순회는 스스로를 지킨다. 폼 검증을 거치지 않는 유입 경로가 있다
    // (백업 복원, 대시보드 직접 수정, 구버전 앱).
    if (i > 366) break;
    final day = DateTime(start.year, start.month, start.day + i);
    if (day.isAfter(end)) break;
    result.add(day);
  }
  return result;
}
```

게이트 표에 **별도 명령**으로 못박는다:
```
TZ=America/New_York flutter test test/unit/utils/date_range_test.dart
```

## 5. `buildEvent` 분기를 `todo.isRanged` 로

rev.2 는 `if (todo.startDate != null)` 로 썼는데, `startDate != null && dueDate == null` 이면
종일 분기의 `dateOnlyUtc(todo.dueDate!)` 가 null assertion 으로 죽는다.
`buildEvent` 는 `@visibleForTesting` public static 이라 테스트가 직접 호출한다.
`isRanged` 를 쓰면 rev.1 미해결 #1 의 방어 방침과도 일관된다. 공짜다.

## 6. 번역 키 5개를 변경 목록에 포함

`assets/translations/{ko,en}.json` 에 `date_range`·`period` 계열 키가 **하나도 없다.**
**검증 게이트가 이걸 못 잡는다** — easy_localization 은 키가 없으면 키 문자열을 그대로
렌더링하므로 `flutter analyze` 도 `flutter test` 도 통과한다.

| 키 | 용도 |
|---|---|
| `use_date_range` | 기간 토글 라벨 |
| `date_range_recurrence_blocked` | 반복 차단 사유 |
| `date_range_format` | 기간 표시 (`{} ~ {}`) |
| `date_range_invalid` | 시작일 > 종료일 |
| `date_range_too_long` | 366일 초과 |

ko/en 양쪽에 추가하고 **기존 파일 서식(섹션 구분 빈 줄)을 보존한다.**
(DTA-3-1 에서 JSON 을 통째로 다시 써 diff 가 125줄로 부푼 전례가 있다.)

## 7. 변이 검증에 `buildEvent` 분기 순서 추가

이 플랜이 변이 검증을 중시하면서 정작 **이번에 발견된 최악의 결함(CRITICAL-2)에는 변이가 없었다.**

| 변이 | 기대 |
|---|---|
| `occursOn` 을 `dueDate` 단일 비교로 되돌림 | 캘린더 테스트 사망 |
| `end.date` 를 `startDay + 1일` 로 되돌림 | 범위 테스트 사망 |
| **`buildEvent` 분기 순서를 rev.1 로 되돌림**(`notificationTime` 먼저) | **테스트 2 사망** |
| **`enumerateDays` 를 `Duration` 누적으로 되돌림** | **TZ 명령 사망** |

## 8. 해소 확인 — §6 "알림" 은 코드 변경 불필요

리뷰어가 확인했다. `todo_form_dialog.dart:663` 의 `_selectNotificationTime` 은
`initialDate: _selectedNotificationTime ?? DateTime.now()` 로, 알림 시각은 `dueDate` 에서
파생되지 않는 **독립 절대값**이다. 사용자가 고른 시각에 그대로 예약된다
(`todo_providers.dart:222` `scheduledDate: notificationTime`).

Discovery 3-4 의 "시작일에만" 은 **이미 자동 충족**이다.
rev.1 §6 의 "예약 지점을 확인한다" 는 **확인 완료 — 변경 없음** 으로 닫는다.

## 9. 수용한 잔여 비용

- **sentinel 은 컴파일 타임 타입 안전성을 버린다.** 매개변수가 `Object?` 가 되어
  `copyWith(startDate: 'oops')` 가 컴파일되고 런타임에 터진다.
  패턴의 알려진 비용이며 doc 주석에 명시한다
- **진행 중 범위 일정이 종료일 기준으로 정렬돼 하단에 밀린다** (rev.2 MINOR-4). 미해결
- **`export_service` 는 범위를 종료일 한 칸으로만 내보낸다.** 표시 문제, 미해결
- **홈 위젯·Windows 위젯은 기간 중 범위 일정을 보여주지 않는다.** 의도적 제외

## 갱신된 검증 게이트

| 단계 | 명령 | 기준 |
|---|---|---|
| 코드 생성 | `dart run build_runner build --delete-conflicting-outputs` | 성공 |
| 정적 분석 | `flutter analyze` | error 0, warning 0 |
| 전체 | `flutter test` | 실패 0 |
| **DST** | `TZ=America/New_York flutter test test/unit/utils/date_range_test.dart` | 실패 0 |
| CI 범위 / 브라우저 | | 실패 0 |
| 빌드 | `flutter build web --release` | 성공 |
| 변이 검증 | 위 4건 | 각각 사망 확인 |
| 번역 | ko/en 키 집합 일치 + 신규 5키 존재 | 확인 |
