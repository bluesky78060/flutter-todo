# 코드 리뷰 — DTA-3-4: 범위 일정(시작일~종료일) 지원

- 작성일: 2026-08-21
- 티켓: `DTA-3-4` (`454f999d-62ca-47bf-a78a-e89fbd2984f4`)
- 리뷰어: **`critic` 에이전트 (Claude Opus, 별도 컨텍스트)**
- 라운드: **4회** — 플랜 2회(조건부 승인 → 조건부 승인) + 코드 2회(반려 → 승인)
- 최종 판정: **승인**

## ⚠️ 리뷰 한계 — 둘째 레인이 없었다

`~/.claude/rules/ai-pm-ticket.md` 의 3중 검증 중 **둘째 레인(Claude 와 다른 계열 모델)을 수행하지 못했다.**
2026-08-21 실측:

| CLI | 상태 |
|---|---|
| `codex` | 사용 한도 초과 — `try again at Sep 10th, 2026` |
| `gemini` | `GOOGLE_CLOUD_PROJECT` 설정 후에도 `You do not have a valid license (#3501)` |
| `antigravity` | 미설치 |

사용자 승인을 받아 `critic` 에이전트(같은 Claude 계열, 별도 컨텍스트)로 대체했다.
**"다른 시각" 이라는 원래 목적은 온전히 달성되지 않았다.**
적대적 검증 레인은 **변이 검증 6회**로 실제 수행했다.

## CRITICAL 3건 — 전부 착수 전·병합 전에 잡혔다

### CRITICAL-1 (플랜) — `copyWith` 로는 `startDate` 를 null 로 되돌릴 수 없다

`copyWith` 가 전 필드 `x ?? this.x` 이고 편집 저장이 그걸 쓴다.
`copyWith(startDate: null)` → `null ?? this.startDate` → **옛 값이 살아남는다.**

플랜에서 가장 공들인 "범위 해제" 절이 **도달 불가능한 코드**였다.
→ `startDate` 에만 sentinel 패턴 적용.

### CRITICAL-2 (플랜) — `buildEvent` 의 `notificationTime` 분기를 통째로 빠뜨렸다

플랜은 종일 갈래만 고치고 있었다. 그런데 Discovery 가
*"알림: 시작일에만 — 출장에서 '내일 출발' 을 놓치지 않는 것이 핵심"* 이라고 못박았으니
**이 기능의 주인공은 거의 항상 알림을 갖는다.**

> 출장 8/21~8/25 + 알림 8/20 21:00 → 캘린더에 **8/20 21:00~22:00 1시간 이벤트** 하나.
> 5일짜리 일정은 어디에도 없다.

헤드라인 산출물이 헤드라인 시나리오에서 실패할 뻔했다.
→ 분기 순서를 `isRanged` → `notificationTime` → else 로 재구성.

### CRITICAL-3 (코드) — 반복 인스턴스에서 기간 차단 가드가 뚫린다

세 사실이 겹쳤다.

1. `RecurringTodoService:201-208` 이 인스턴스를 만들 때 **`recurrenceRule` 을 넘기지 않는다.**
   인스턴스는 `recurrenceRule == null`, `parentRecurringTodoId != null` 이다
2. 내 가드는 `recurrenceRule` **만** 봤다 → 마스터는 막히고 **인스턴스는 통과**
3. 그 뚫린 경로가 하필 `startDate` 를 버린다.
   `thisOnly` 는 `copyWith` 가 아니라 **직접 생성자**로 새 Todo 를 만들어 sentinel 이 무력화되고,
   반복 분기는 `clearStartDate` 도 넘기지 않는다

> 반복 인스턴스를 열면 "기간으로 설정" 이 **정상으로 켜진다.**
> 8/21~8/25 를 고르고 저장 → 목록엔 "8월 25일" 하루짜리. **오류 메시지 없음.**

**방금 입력한 값이 소리 없이 사라지는 도달 가능한 경로였다.**

원인은 `RecurringTodoService` 를 확인하지 않고 가드를 짠 것이다.
그리고 그 결함이 살아남은 구조적 이유는 **판정이 위젯 안에 있어 테스트할 수 없었기** 때문이다.

→ `canSetDateRange()` 순수 함수로 분리 + 회귀 테스트 5건.
→ `detachedTodo` 에 누락되던 9개 필드 전부 전달.

## 검증받은 설계 판단

리뷰어가 근거까지 확인해 **옳다고 판정**한 것들이다.

| 판단 | 확인 내용 |
|---|---|
| DST 안전성 | `enumerateDays`·`occursOn` 모두 `Duration` 누적 없음. 남은 `Duration` 은 `_exclusiveEnd` 한 곳뿐이고 **UTC** 라 DST 가 없다 |
| `_putStartDate` | create 가 `clearStartDate: false` 고정인 것이 옳다. INSERT 에는 지울 옛 값이 없다 |
| Drift v13 | `_migrateDateTimeColumnsToText` 가 `UPDATE` 만 하고 테이블을 재생성하지 않아 v10→v13 경로가 안전 |
| 객체 공유 | `Todo` 가 불변이고 날짜별로 별도 리스트를 만들어 각각 정렬. `enumerateDays` 가 중복 없는 날짜를 준다 |
| **`googleEventId` 유지** | 걱정과 **반대로 중복을 막는 올바른 방향**. 아래 참조 |
| 범위 확장 | 9개 전부 `todo.X` 순수 전달, 호출 지점 하나. 나눠서 두 번 건드리는 게 더 위험 |
| `occursOn` 상한 | `enumerateDays` 와 경계가 **정확히 일치**(양쪽 `start + 366` 포함). off-by-one 없음 |

### `googleEventId` 유지가 맞는 이유

내가 *"분리된 할 일이 원본 이벤트를 계속 갱신하게 되지 않나"* 를 우려했으나,
**이 앱에는 "원본 이벤트" 가 없다.**

1. `buildEvent` 는 `recurrence` 필드를 **한 번도 설정하지 않는다**(`lib/` 전체에 0건).
   Google Calendar 에 반복 이벤트가 만들어지지 않고 **모든 Todo 가 각자 독립 이벤트**다
2. `thisOnly` 는 복사가 아니라 **같은 행에 대한 UPDATE**(`id: todo.id`)다

따라서 그 행의 `googleEventId` 는 처음부터 자기 자신의 이벤트를 가리켰다.
버리면 다음 동기화에서 `insert` 를 타 **중복이 생긴다.**

## 적대적 검증 — 변이 검증 6회 (실제 수행)

| 변이 | 결과 |
|---|---|
| `enumerateDays` 를 `Duration` 누적으로 | **KST 12/12 통과, `TZ=America/New_York` 에서만 1건 사망** |
| `occursOn` 을 `dueDate` 단일 비교로 | 3건 사망 |
| `buildEvent` 범위 분기 무력화 | 2건 사망 |
| `clearStartDate` 무시 (키 생략) | 1건 사망 |
| sentinel `copyWith` → 일반 `??` | 2건 사망 |
| `canSetDateRange` 를 `recurrenceRule` 만 보도록 | **정확히 인스턴스 테스트 1건 사망** |

**첫 번째가 결정적이다.** 별도 TZ 게이트가 없었으면 앱 정지를 유발하는 결함이
KST 에서 자명하게 통과했을 것이다. 리뷰어의 "구성 불가능한 테스트" 지적이 정확했다.

## 검증 결과

| 항목 | 결과 |
|---|---|
| `flutter analyze` | ✅ error 0 / warning 0 |
| `flutter test` | ✅ **204 통과 / 4 skip / 0 실패** |
| `TZ=America/New_York flutter test test/unit/utils/date_range_test.dart` | ✅ 17/17 |
| CI 범위 | ✅ 195 |
| 브라우저 | ✅ 4/4 |
| `flutter build web --release` | ✅ 성공 |
| 번역 | ✅ ko/en 키 차이 없음(기존 `testing` 제외), **신규 키 중 미사용 0건** |
| 기존 `buildEvent` 17건 | ✅ **수정 없이 통과** — 하위호환 약속 이행 |

## ⚠️ 정정 — 캘린더 중복이 전부 닫힌 것은 아니다

`detachedTodo` 수정으로 **`thisOnly` 경로만** 닫혔다.

`thisAndFuture` 는 미래 인스턴스를 `deleteTodo` 로 지운 뒤 재생성하는데,
`lib/` 전체에 `events.delete` 가 **0건**이다.
지워진 인스턴스의 캘린더 이벤트는 고아로 남고, 재생성된 인스턴스는 새 이벤트를 만든다
→ **사용자 캘린더에 중복.**

DTA-3-1 이전부터 있던 결함이며 이번 수정과 무관하다. **별도 티켓 대상이다.**

## 미해결 — 별도 티켓 대상 (리뷰어 동의)

| 항목 | 성격 |
|---|---|
| `thisAndFuture` 의 캘린더 이벤트 고아·중복 | 기존 결함. `DTA-3-3` 와 함께 처리 |
| `detachedTodo` 에 테스트 0건 | **원래 버그가 살아남은 방식과 동일.** `detachFromSeries` 순수 함수로 빼기 권장 |
| 백업 복원의 `parentRecurringTodoId` 가 옛 ID | 고아 링크. 새 가드와 만나면 그 할 일은 영구히 기간 설정 불가(보수적으로 안전) |
| `todo_providers_backup.dart` / `_optimized.dart` 죽은 코드 복제본 | 참조 0건. 삭제 티켓 권장 |
| `category_repository_impl._mapTodoToEntity` 손실 매퍼 | 기존 결함 |
| 진행 중 범위가 종료일 기준 정렬 | 표시 문제 |
| 홈 위젯 · Windows 위젯 미반영 | Discovery 합의로 제외 |
| `export_service` 가 종료일 한 칸만 | 표시 문제 |

## 사용자 수동 확인 필요

**선행 SQL** (미실행 시 기존 기능은 정상, **범위 일정 생성만** 실패):
```sql
ALTER TABLE todos ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ;
```

- [ ] 폼에서 "기간으로 설정" 토글 → 범위 선택이 되는가
- [ ] 목록·상세에 `8/21 ~ 8/25` 로 보이는가 ("(하루 종일)" 이 두 번 안 나오는가)
- [ ] 캘린더에서 기간 내 **모든 날짜**에 표시되는가
- [ ] 기간을 해제하면 **실제로 해제되는가** (앱 재시작 후에도)
- [ ] **반복 인스턴스**를 열면 기간 토글이 막히는가 (CRITICAL-3)
- [ ] Google Calendar 에 여러 날짜에 걸쳐 등록되는가 (알림이 있어도)
