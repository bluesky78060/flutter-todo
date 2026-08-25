# 플랜 — 앱 상태 점검 후속 정리 (DTA 5건)

- 작성일: 2026-08-18
- 선행 문서: `docs/00-discovery/DTA-1-1_DTA-1-2_DTA-1-3_DTA-2-1_DTA-2-2-direction.md`
- 원칙: **런타임 동작 변경 없음.** 테스트 하네스·정적 분석·문서만 손댄다.
  단 DTA-1-2만 예외적으로 웹 런타임 코드를 건드리므로 별도 게이트를 둔다.

## 실행 순서

리스크가 낮고 검증이 싼 것부터. 각 티켓은 독립 커밋으로 분리한다.

```
DTA-1-3 (문서)  →  DTA-1-1 (lint)  →  DTA-2-2 (방치 테스트)  →  DTA-2-1 (핵심 실패)  →  DTA-1-2 (웹 이관)
    싼 검증                                                                              가장 위험
```

DTA-2-1을 DTA-2-2보다 뒤에 두는 이유: DTA-2-2에서 전체 테스트의 잡음(7건)을 먼저 걷어내야
DTA-2-1의 9건 수정이 실제로 통했는지 신호가 깨끗하게 보인다.

---

## DTA-1-3 — CLAUDE.md 버전 기재 갱신 (우선순위 4)

**문제**: CLAUDE.md `Current Version: 1.0.17+56`, 실제 `pubspec.yaml`은 `1.0.17+66`.
"현재 상황" 블록이 3곳에 중복 서술되어 있고 전부 옛 숫자다.

**변경**: `1.0.17+56` → `1.0.17+66`. 중복 블록은 1곳으로 통합.
**검증**: `grep -c "1.0.17+56" CLAUDE.md` == 0, `grep "^version:" pubspec.yaml`와 일치.
**리스크**: 없음 (문서 전용).

---

## DTA-1-1 — analyze warning 15건 정리 (우선순위 3)

동작 변경이 없는 것과 있을 수 있는 것을 나눈다.

### A. 무해 (단순 삭제)
| 위치 | 내용 |
|---|---|
| `lib/presentation/utils/layout_builders_utils.dart:27` | 미사용 import `nav_item.dart` |
| `lib/core/services/google_calendar_service.dart:4` | 미사용 import `googleapis_auth` |
| `test/widget/progress_card_test.dart:6,7` | 미사용 import 2건 |
| `test/widget/custom_todo_item_test.dart:7,8` | 미사용 import 2건 |
| `lib/main.dart:22` | `show` 목록의 미사용 `kDebugMode` |
| `lib/presentation/screens/statistics_screen.dart:564` | 미사용 지역변수 `isDarkMode` |
| `lib/presentation/widgets/naver_map_platform.web.dart:58` | 미사용 필드 `_requestCounter` |

> `google_calendar_service.dart`의 `googleapis_auth` 삭제 시 주의:
> `extension_google_sign_in_as_googleapis_auth`가 제공하는 확장 메서드의 반환 타입이
> 해당 패키지 타입일 수 있다. 삭제 후 반드시 `flutter analyze`로 새 error가 없는지 확인한다.

### B. 판단 필요
| 위치 | 내용 | 처리 |
|---|---|---|
| `todo_grouping_utils.dart:95,96` | `a.first.position ?? 999999` — `position`이 non-nullable이라 `??` 우변이 죽은 코드 | `?? 999999` 제거. **정렬 결과가 바뀌지 않는지 확인 필요** — 현재도 우변은 실행되지 않으므로 동작 동일 |
| `theme_preview_screen.dart:517` | `if (todo.description != null)` — `description`이 non-nullable | 조건 제거. 단 이 화면은 미리보기용 더미 데이터를 쓰므로 빈 문자열 처리 여부 확인 |
| `statistics_screen.dart:753, 794` | 미참조 private 위젯 `_MiniStatRow`, `_StreakCard` | 삭제. 향후 사용 의도가 있었을 수 있으므로 커밋 메시지에 명시 |

**검증**: `flutter analyze`의 warning 15 → 0. error 수는 2에서 늘지 않을 것. `flutter test` 통과 수 불변.
**리스크**: 낮음. B그룹은 죽은 분기 제거라 동작 동일해야 하지만, 정렬(`todo_grouping_utils`)은
드래그앤드롭 순서에 직접 영향하므로 관련 단위 테스트를 먼저 확인한다.

---

## DTA-2-2 — 방치된 테스트 파일 정리 (7건, 우선순위 2)

| 파일 | 실패 | 판단 |
|---|---|---|
| `test/widget_test.dart` | 1 | Flutter 템플릿 기본 `Counter increments smoke test`. 이 앱에 카운터는 존재하지 않는다. **삭제**가 정답 |
| `test/app_integration_test.dart` | 4 | 그룹명이 `DoDo App Integration Tests (Disabled)`인데 `skip:`이 없어 실제로는 돈다. 작성자 의도는 명백히 비활성화 → **`group(..., skip: true)`로 의도를 코드에 반영**. 삭제하지 않는 이유는 복구 의도가 이름에 남아 있기 때문 |
| `test/integration/todo_integration_test.dart` | 2 | `ProviderException: provider in error state`. 나머지 케이스는 통과하므로 파일 자체는 살아 있다 → **해당 2건만 원인 조사 후 수정**, 불가하면 사유를 적은 `skip`으로 격리 |

**검증**: `flutter test` 실패 16 → 9 (DTA-2-1 몫만 남음).
**리스크**: 낮음. 단 `skip`은 "가짜 완료"가 되기 쉬우므로 **사유 문자열을 반드시 남긴다.**

---

## DTA-2-1 — reschedule_dialog_test 9건 수정 (우선순위 1, 핵심)

### 근본 원인 (조사 완료)

`RescheduleDialog`는 `'reschedule_title'.tr()` 등 **번역 키를 통해서만** 문자열을 만든다
(`lib/presentation/widgets/reschedule_dialog.dart:59,73,79,85,97`).
테스트는 번역된 한국어(`'일정 이월'`, `'오늘로'` …)를 단언한다
(`assets/translations/ko.json:224-227`).

그런데 테스트 `main()`에 `EasyLocalization.ensureInitialized()`가 없다.
로그상 `Load asset from assets/translations`까지 찍히고 멈추며, `pumpAndSettle()`은
실제 파일 I/O를 진행시키지 못하므로 위젯 트리가 로딩 플레이스홀더 상태로 남는다.
그래서 `Dialog`도 `'Show Dialog'` 버튼도 0개로 잡힌다.

이것이 `flutter_test.yml`이 남긴 *"EasyLocalization issues in CI"* 주석의 실체다.
CI에서만 나는 문제가 아니라 로컬에서도 동일하게 실패한다.

### 해결안 (우선순위 순)

1. **1안 (채택 예정)** — `void main()`을 `Future<void> main()`으로 바꾸고
   `TestWidgetsFlutterBinding.ensureInitialized()` 직후
   `await EasyLocalization.ensureInitialized()` 추가.
   필요 시 자산 로드를 실제로 진행시키기 위해 `tester.runAsync()`로 감싼다.
   → 번역 단언을 그대로 유지할 수 있어 테스트의 가치가 보존된다.
2. **2안 (1안 실패 시)** — `EasyLocalization` 래퍼를 걷어내고 단언을 번역 키
   (`'reschedule_title'` 등)로 변경. `progress_card_test.dart`가 이미 쓰는 방식이라
   일관성은 있으나, **번역 누락을 잡아내는 능력을 잃는다.** 차선책으로만 쓴다.

어느 안이든 `pumpAndSettle()` 뒤의 `await tester.pump(); // Extra pump for EasyLocalization`
주석은 근본 원인을 오해한 흔적이므로 제거한다.

### CI 정합성 (이 티켓의 진짜 목적)

수정이 끝나면 `flutter_test.yml`의 의도적 제외를 되돌린다.

```yaml
# 현재 — reschedule_dialog_test.dart를 빼려고 파일을 일일이 나열
flutter test --coverage test/unit/ test/widget/progress_card_test.dart test/widget/custom_todo_item_test.dart
# 목표 — coverage_threshold.yml:35와 동일한 범위
flutter test --coverage test/unit/ test/widget/
```

두 워크플로의 범위를 일치시키는 것이 핵심이다. 지금은 한쪽이 숨기고 다른 쪽이 드러내는데,
드러내는 쪽이 `pull_request` 트리거라 **아직 한 번도 실행된 적이 없어** 아무도 모르고 있다.

**검증**: `flutter test --coverage test/unit/ test/widget/` 실패 0. `flutter test` 전체 실패 0.
**리스크**: 중간. 1안이 안 되면 2안으로 내려가며 이때 검증 강도가 낮아진다는 점을 리뷰에서 명시.

---

## DTA-1-2 — 레거시 웹 API 이관 (우선순위 2, 최고 리스크)

### 대상
| 파일 | 현재 | 이관 후 |
|---|---|---|
| `lib/core/config/supabase_config_web.dart` | `dart:js_util`, `dart:html` | `dart:js_interop`, `package:web` |
| `lib/core/services/web_notification_service.dart` | `dart:html`, `dart:js` (`allowInterop`, `JsObject`) | `dart:js_interop`, `package:web` |

`supabase_config_web.dart`는 `window.ENV`에서 Supabase 자격증명을 읽는다.
`inject_env.sh`가 `index.template.html`에 주입하는 값과 직결되므로, 실패 시
**웹에서 하드코딩 fallback으로 조용히 넘어간다** — 즉 깨져도 티가 안 난다. 가장 조심할 지점.

`web_notification_service.dart`는 `js.JsObject`로 `Notification` 생성자를 직접 호출하고
`onclick`에 `allowInterop` 콜백을 붙인다. `package:web`의 `Notification` 타입으로 바꾸면
생성자·이벤트 핸들러 모두 형태가 달라진다.

### 사전 확인
- `pubspec.yaml`에 `web` 패키지 의존성 추가 필요 여부
- `dart:html`을 쓰는 다른 파일이 더 있는지 전수 조사 (`grep -rn "dart:html\|dart:js" lib/`)

### 검증 (이 티켓만 게이트가 다르다)
1. `flutter analyze` error 2 → 0
2. `flutter build web --release` 성공
3. 빌드 산출물에서 `window.ENV` 경로가 실제로 값을 읽는지 확인
   (`inject_env.sh`로 넣은 더미가 아닌 실제 키 필요 — **사용자 확인 필요 지점**)
4. 웹 알림 동작은 브라우저 권한이 필요해 자동 검증 불가 → **수동 확인 요청 대상**

**리스크**: 높음. 조용히 실패하는 성질 + 자동 검증 한계.
분량이 크면 이 티켓만 분리 PR로 돌리고 나머지 4건을 먼저 랜딩하는 것을 권한다.

---

## 검증 게이트 (전체 공통)

| 단계 | 명령 | 통과 기준 |
|---|---|---|
| 정적 분석 | `flutter analyze` | error 0, warning 0 |
| 단위/위젯 | `flutter test --coverage test/unit/ test/widget/` | 실패 0 (= coverage_threshold.yml 재현) |
| 전체 | `flutter test` | 실패 0 |
| 웹 빌드 | `flutter build web --release` | 성공 (DTA-1-2 한정 필수) |

`.env` / `web/index.html`은 gitignore 대상이므로 커밋에 포함되지 않아야 한다.
커밋 전 `git status`로 확인한다.

## 미해결 / 사용자 확인 필요

1. **DTA-1-2의 실제 웹 검증** — 현재 `.env`의 지도 키가 더미라 `window.ENV` 경로를
   실제 값으로 검증할 수 없다. 실제 키 제공 여부를 확인해야 한다.
2. **`coverage_threshold.yml`이 한 번도 안 돌았다는 사실 자체** — 임계값 15%가
   실제로 만족되는지 아무도 모른다. 테스트를 고친 뒤 커버리지를 실측해야 한다.
3. **의존성 182개 업그레이드 불가 + 1개 discontinued** — 이번 범위 밖이나 별도 티켓 대상.

---

# 개정 (rev.2) — 플랜 리뷰 반영

- 개정일: 2026-08-18
- 근거: `docs/02-review/DTA-1-1_DTA-1-2_DTA-1-3_DTA-2-1_DTA-2-2-plan-review.md` (Codex 독립 리뷰, 조건부 승인)
- **아래 내용이 위 rev.1과 충돌하는 경우 rev.2가 우선한다.**

## 실행 순서 변경

```
rev.1: DTA-1-3 → DTA-1-1 → DTA-2-2 → DTA-2-1 → DTA-1-2
rev.2: DTA-1-3 → DTA-2-1 → DTA-2-2 → DTA-1-1 → DTA-1-2
```

DTA-2-1(EasyLocalization 핵심 원인)을 앞으로 당긴다. DTA-2-2에서 각 테스트를
고칠지/삭제할지/skip할지 판정할 때 DTA-2-1의 해법을 재사용해야 하기 때문이다.
**각 커밋마다** `flutter analyze` + 관련 테스트 + 전체 테스트를 돌린다. 마지막 일괄 검증 금지.

## C1 — DTA-1-2 범위 확대 (2개 → 4개 파일)

| 파일 | 사용 API |
|---|---|
| `lib/core/config/supabase_config_web.dart:1-2` | `dart:js_util`, `dart:html` |
| `lib/core/services/web_notification_service.dart:2-3` | `dart:html`, `dart:js` |
| `lib/core/services/location_service.dart:11,13` | 조건부 import 분기 조건이 `dart.library.js_util` / `dart.library.html` |
| `lib/presentation/widgets/naver_map_platform.web.dart:31` | `dart:html` |

추가 작업:
- `pubspec.yaml`에 `web` 의존성 추가 (현재 없음)
- `location_service.dart`의 조건부 import 분기 조건을 `dart.library.js_interop` 기준으로 재검토
- 단순 import 치환이 아니라 **API별 변환 설계**가 필요:
  `js_util.getProperty/setProperty/callMethod` → `dart:js_interop_unsafe` 검토,
  `allowInterop` → `Function.toJS`,
  `js.JsObject` 동적 생성자 호출은 `package:web`의 정적 타입으로 1:1 치환 불가,
  `dart:html` 이벤트 콜백의 자동 Zone 연결이 `package:web`에서는 보장되지 않음

## C2 — 검증 버전 통일

CI 3개 워크플로 전부 `flutter-version: '3.35.7'` (`flutter_test.yml:21`, `coverage_threshold.yml:19`, `deploy.yml:23`).
로컬은 3.38.4 / Dart 3.10.3. **레거시 웹 API의 deprecation 상태가 버전에 따라 다르므로 DTA-1-2에 직접 영향한다.**

→ 검증 기준 버전을 통일하거나, 불가 시 양쪽에서 각각 측정하고 차이를 완료 보고에 기록한다.

## C3 — analyze를 실제 CI 게이트로 (DTA-1-1 완료 조건에 포함)

```yaml
# .github/workflows/flutter_test.yml:39-41 — 현재 이중으로 무력화됨
- name: Analyze code
  run: flutter analyze || true
  continue-on-error: true
```

`|| true`와 `continue-on-error: true`를 제거한다. 그러지 않으면 warning/error를 고쳐도
CI가 회귀를 잡지 못해 같은 상태로 되돌아간다.

## C4 — DTA-2-1 원인은 "확정"이 아니라 "가설"

rev.1의 "근본 원인 (조사 완료)" 표현을 철회한다.
확인된 사실은 증상(9건 전부 위젯 0개)과 로그 정지 지점(`Load asset from assets/translations`)까지다.
`pumpAndSettle()`이 asset I/O를 진행시키지 못한다는 단정은 로더·바인딩 구현에 따라 달라진다.

실행 절차 — 통과할 때까지 순차 검증하고 **각 단계 결과를 기록**한다:

1. `EasyLocalization.ensureInitialized()` 추가만으로 통과하는가
2. `RootBundleAssetLoader` 명시가 필요한가
3. `tester.runAsync()`가 실제로 필요한가
4. 번역 asset이 테스트 asset bundle에 포함되는가

## C5 — "가짜 초록" 방지

완료 보고에 다음 3개를 **분리 기재**한다. 합계만 적지 않는다.

- 실제 수정으로 통과시킨 테스트 수
- 삭제한 테스트 수 (+ 삭제 사유)
- `skip` 처리한 테스트 수 (+ 사유 + 추적 티켓 + 제거 조건)

`test/integration/todo_integration_test.dart` 2건은 **원인 조사를 선행 의무**로 한다.
조사 없이 skip으로 격리하지 않는다.

## C6 — DTA-1-2 웹 검증에 실제 키 불필요

rev.1의 "실제 Supabase 키 필요 — 사용자 확인 필요" 항목을 **철회**한다.
`window.ENV`에 고유한 dummy sentinel(예: `SENTINEL_SUPABASE_URL_7f3a`)을 주입하면
비밀값 없이 3경로를 전부 검증할 수 있다.

| 경로 | 기대 |
|---|---|
| sentinel 주입됨 | `SupabaseConfig.url`이 sentinel 값을 반환 |
| 키 누락 | 하드코딩 fallback으로 내려감 |
| `window.ENV` 자체 부재 | 예외 없이 fallback |

이 검증이 없으면 `window.ENV` 경로가 깨져도 fallback이 조용히 삼켜 **티가 나지 않는다.**

웹 알림은 자동 검증 불가 → 브라우저 수동 체크리스트로 분리: 권한 거부 / 권한 허용 / 예약 / 취소.

## 갱신된 검증 게이트

| 단계 | 명령 | 통과 기준 |
|---|---|---|
| 정적 분석 | `flutter analyze` | error 0, warning 0 |
| 단위/위젯 | `flutter test --coverage test/unit/ test/widget/` | 실패 0 (coverage_threshold.yml 재현) |
| 전체 | `flutter test` | 실패 0 **+ 수정/삭제/skip 내역 분리 보고** |
| 웹 빌드 | `flutter build web --release` | 성공 (DTA-1-2 필수) |
| 웹 런타임 | dummy sentinel 3경로 | 전부 기대대로 (DTA-1-2 필수) |
| CI 게이트 | `flutter_test.yml`에서 analyze 무력화 제거 | 반영됨 (DTA-1-1 필수) |

## 남은 사용자 확인 필요 항목

1. **C2 버전 통일 방향** — CI를 3.38.4로 올릴지, 로컬을 3.35.7로 맞춰 측정할지
2. **웹 알림 수동 검증** — 브라우저에서 직접 확인해야 하는 항목이라 대행 불가

(rev.1의 "실제 Supabase 키 필요"는 C6으로 해소되어 목록에서 제외)
