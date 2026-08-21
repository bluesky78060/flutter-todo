# 플랜 — DTA-3-1: Google Calendar 동기화 미연결 + 종일 이벤트 버그

- 작성일: 2026-08-21
- 선행: `docs/00-discovery/DTA-3-1-direction.md`
- 사용자 확정 사항 (2026-08-21):
  - 중복 방지: **이벤트 ID를 저장해 진짜 중복 방지**
  - 동기화 대상: **마감일이 있는 미완료 할 일**

## 설계 판단 — 이벤트 ID를 어디에 저장할 것인가

사용자는 "이벤트 ID 저장"을 선택했다. **어디에** 저장할지는 내가 정해야 하는데,
선택지에 따라 위험도가 크게 다르다.

| 안 | 장점 | 위험 |
|---|---|---|
| A. Drift(로컬)에만 저장 | 원격 스키마 변경 없음. 기존 사용자에게 아무 영향 없음 | 기기가 바뀌면 매핑을 잃어 중복 발생 |
| B. Drift + Supabase 양쪽 | 기기 간에도 중복 방지 | **`google_event_id` 컬럼이 없는 상태에서 새 빌드가 나가면 `updateTodo`가 전부 실패한다** |

**A를 채택한다.**

B의 위험이 구조적이다. `supabase_datasource.dart:218` 부근의 `updateTodo`는 payload에
컬럼을 통째로 넣어 보내므로, Supabase에 컬럼이 없으면 PostgREST가 거부하고
**할 일 수정이 전부 깨진다.** 사용자가 대시보드에서 SQL을 먼저 실행해야만 하는
배포 순서 의존이 생기는데, 이건 잊어버리기 쉽고 잊으면 앱이 망가진다.

동기화는 보통 한 기기에서 하므로 A로도 실사용 중복은 막힌다.
기기 간 중복 방지가 필요하면 **별도 티켓**에서 SQL 마이그레이션과 함께 처리한다.

> 이 판단은 사용자의 "진짜 중복 방지" 선택을 축소한 것이 아니다.
> 같은 기기에서의 재동기화는 완전히 막힌다. 축소되는 것은 기기 간 시나리오뿐이며,
> 그 대가로 기존 사용자의 데이터가 깨질 위험을 제거한다.

## 변경 목록

### 1. `Todo` 엔티티 — `lib/domain/entities/todo.dart`
`String? googleEventId` 추가. 생성자 · `copyWith` 반영.

### 2. Drift 스키마 — `lib/data/datasources/local/app_database.dart`
```dart
TextColumn get googleEventId => text().nullable()();   // Google Calendar 이벤트 ID
```
- `schemaVersion` **12 → 13**
- `if (from < 13) await migrator.addColumn(todos, todos.googleEventId);`
- 기존 마이그레이션(2~12) 패턴을 그대로 따른다

### 3. 로컬 매핑 — `lib/data/repositories/todo_repository_impl.dart` 및 Drift ↔ Todo 변환부
`googleEventId` 왕복 확인. **Supabase 쪽(`supabase_datasource.dart`)은 건드리지 않는다** (설계 판단 A).

> ⚠️ 원격에서 내려온 Todo는 `googleEventId`가 항상 `null`이다.
> 로컬 값이 원격 동기화로 덮여 사라지지 않는지 확인해야 한다. **이 플랜의 최대 위험 지점.**

### 4. 종일 이벤트 버그 — `lib/core/services/google_calendar_service.dart:150-152`
```dart
// 현재 (버그)
event.start!.date = DateTime.parse(dateStr);
event.end!.date   = DateTime.parse(dateStr);
// 수정
final startDay = DateUtils.dateOnly(todo.dueDate!);
event.start!.date = startDay;
event.end!.date   = startDay.add(const Duration(days: 1));  // end.date 는 exclusive
```
`toIso8601String().split('T')[0]` → `DateTime.parse` 왕복도 제거한다. 불필요하고 타임존 해석이 섞인다.

### 5. `addTodoToCalendar` 반환값 변경
`Future<bool>` → `Future<String?>` (이벤트 ID). 이미 `googleEventId`가 있으면
`events.insert` 대신 `events.update`(patch)를 호출한다.
`update`가 404를 내면(캘린더에서 지워짐) insert로 폴백한다.

### 6. `syncTodosToCalendar` — 대상 필터와 결과 집계
```dart
todos.where((t) => t.dueDate != null && !t.isCompleted)
```
성공/실패/건너뜀 건수를 담은 결과 객체를 돌려준다. 현재는 `int`(성공 수)만 준다.

### 7. UI 연결 — `lib/presentation/screens/settings_screen.dart:854`
스텁을 실제 구현으로 교체한다.
- `todosProvider`에서 할 일을 읽어 필터링
- `googleCalendarProvider.notifier.syncTodos` 호출
- **결과를 스낵바에 표시** (성공 N건 / 실패 M건). 지금은 실패해도 "동기화 중"만 뜬다
- 미연결 상태면 안내

### 8. 번역 키
`assets/translations/ko.json`, `en.json`에 결과 메시지 키 추가.

### 9. 테스트
- `end.date == start.date + 1일` 단위 테스트 (**이 티켓의 핵심 회귀 방지**)
- `notificationTime`이 있으면 `dateTime` 경로를 타는지
- 동기화 필터가 완료 항목과 마감일 없는 항목을 제외하는지
- 기존 `googleEventId`가 있으면 insert가 아니라 update를 부르는지

## 검증 게이트

| 단계 | 명령 | 기준 |
|---|---|---|
| 정적 분석 | `flutter analyze` | error 0, warning 0 (현재 상태 유지) |
| 코드 생성 | `dart run build_runner build --delete-conflicting-outputs` | Drift 코드 재생성 성공 |
| 전체 | `flutter test` | 실패 0 |
| CI 범위 | `flutter test --coverage test/unit/ test/widget/` | 실패 0 |
| 빌드 | `flutter build web --release` | 성공 |

## 자동 검증이 불가능한 부분 (정직하게)

**실제 Google Calendar 연동은 자동 검증할 수 없다.** OAuth 로그인과 실제 캘린더 쓰기가 필요하다.
단위 테스트로 못박을 수 있는 것은 **이벤트 객체가 올바르게 구성되는가**까지다.

사용자 수동 확인 항목:
- [ ] Google Calendar 연결 후 동기화 시 일정이 실제로 등록되는가
- [ ] 알림 시간 **없는** 할 일이 종일 이벤트로 **하루짜리**로 뜨는가 (이번 버그의 핵심)
- [ ] 알림 시간 **있는** 할 일이 1시간 이벤트로 뜨는가
- [ ] 두 번 동기화해도 중복되지 않는가
- [ ] 완료된 할 일이 등록되지 않는가

## 위험

| 위험 | 대응 |
|---|---|
| **원격 동기화가 로컬 `googleEventId`를 덮어씀** | 로컬↔원격 병합 지점을 직접 확인. 덮어쓰면 중복 방지가 무력화된다 |
| Drift 마이그레이션 실패 | 기존 12개 마이그레이션과 동일 패턴(`addColumn`) 사용. nullable이라 기본값 불필요 |
| `events.update` 404 (사용자가 캘린더에서 삭제) | insert 폴백 |
| 대량 동기화 시 API 할당량 | 이번 범위 밖. 건수가 많으면 실패 건수로 드러난다 |

---

# 개정 (rev.2) — 설계 판단 A 철회

- 개정일: 2026-08-21
- 계기: 구현 착수 전 코드 확인 중 **rev.1의 전제가 사실과 다름**을 발견
- **rev.1과 충돌하면 rev.2가 우선한다.**

## 왜 뒤집는가 — todo는 Drift에 저장되지 않는다

rev.1은 "Drift 로컬에만 저장하면 원격 스키마 변경 없이 중복을 막을 수 있다"고 봤다.
**전제가 틀렸다.**

```
lib/presentation/providers/database_provider.dart:58-61
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final dataSource = ref.watch(supabaseTodoDataSourceProvider);
  return SupabaseTodoRepository(dataSource);      // ← Supabase 단독
});
```

`grep -rn "TodoRepositoryImpl(" lib/` 결과: **정의부 한 줄뿐, 인스턴스화 0건.**
Drift 기반 `TodoRepositoryImpl`은 **죽은 코드**다.

CLAUDE.md의 "Dual Repository Pattern" 서술은 todo에 관한 한 현재 코드와 맞지 않는다.
UI가 보는 `Todo` 객체는 전부 `supabase_datasource.dart:349`의 `_todoFromJson`이 만든다.
**Drift에 컬럼을 추가해도 그 값은 어디에도 실리지 않는다.** A안은 무의미하다.

## 대신: Supabase에 저장하되 **결합을 격리한다**

rev.1이 B안의 위험으로 지목한 것 — "컬럼이 없으면 `updateTodo`가 전부 깨진다" — 은
여전히 유효하다. 그래서 **컬럼을 일반 `updateTodo` payload에 넣지 않는다.**

| | rev.1의 B안 | rev.2 채택안 |
|---|---|---|
| 쓰기 방식 | `updateTodo` payload에 `google_event_id` 포함 | **동기화 시에만 타깃 업데이트** `.update({'google_event_id': ...}).eq('id', todoId)` |
| 컬럼 없을 때 | **모든 할 일 수정이 실패** | **캘린더 동기화만 실패**, 나머지 기능 무영향 |
| 읽기 | `_todoFromJson`에서 읽음 | 동일. 키가 없으면 `null` — 안전 |

이렇게 하면 사용자가 SQL을 아직 안 돌렸어도 앱의 나머지가 멀쩡하다.
동기화만 실패하고, 그 실패는 UI에 표시된다(변경 7).

### 사용자가 실행해야 하는 SQL

```sql
ALTER TABLE todos ADD COLUMN IF NOT EXISTS google_event_id TEXT;
```

**이건 내가 대신 실행할 수 없다.** Supabase 대시보드에서 직접 돌려야 하며,
돌리기 전에는 동기화 기능만 동작하지 않는다.

## 변경 목록 수정

- ~~2. Drift 스키마 `schemaVersion` 12 → 13~~ → **철회.** Drift는 todo 경로에 쓰이지 않으므로
  컬럼을 추가할 이유가 없다. 죽은 코드에 마이그레이션을 얹으면 오해만 남긴다
- ~~3. 로컬 매핑~~ → **철회**
- **3'. Supabase 매핑** — `_todoFromJson`에 `googleEventId: json['google_event_id'] as String?` 추가.
  쓰기는 전용 메서드 `updateGoogleEventId(int todoId, String eventId)` 신설
- 나머지(1, 4~9)는 rev.1 그대로

## rev.1의 "최대 위험"은 소멸했다

> ⚠️ 원격에서 내려온 Todo는 `googleEventId`가 항상 `null`이다.
> 로컬 값이 원격 동기화로 덮여 사라지지 않는지 확인해야 한다.

로컬 저장을 하지 않으므로 이 위험 자체가 없어졌다. 단일 저장소(Supabase)만 남는다.

## 새로 드러난 별건 — DTA-3-2로 분리

`_todoFromJson`이 읽는 키 18개와 `updateTodo`가 쓰는 키 17개를 비교한 결과
**`priority`만 쓰기에는 있고 읽기에는 없다.** 우선순위를 바꿔도 재조회하면
기본값 `'medium'`으로 되돌아간다. 이번 티켓 범위 밖이라 `DTA-3-2`로 발행했다.

같은 방식으로 `google_event_id`도 읽기 누락이 나지 않도록, 이번 변경 후
**읽기/쓰기 키 대조를 검증 항목에 넣는다.**
