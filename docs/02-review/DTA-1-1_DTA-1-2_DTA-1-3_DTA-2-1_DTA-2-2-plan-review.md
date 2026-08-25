# 플랜 리뷰 — 앱 상태 점검 후속 정리 (DTA 5건)

- 작성일: 2026-08-18
- 대상: `docs/01-plan/DTA-1-1_DTA-1-2_DTA-1-3_DTA-2-1_DTA-2-2-plan.md`
- 독립 리뷰어: **Codex CLI (OpenAI, provider=openai, 42,755 tokens)** — Claude와 다른 계열 모델
- 오케스트레이터 2차 검증: Claude Opus 5 (지적 사항 전건 코드 대조)
- **전체 판정: 조건부 승인** — 아래 6개 선결 조건 반영 후 착수

> `gemini` CLI는 `GOOGLE_CLOUD_PROJECT` 미설정으로 실행 불가하여 Codex로 대체했다.
> 목적은 특정 벤더가 아니라 *Claude와 다른 계열 모델의 독립 시각*이며 그 목적은 달성되었다.
> 실행하지 않은 검증을 적지 않았다.

## 항목별 판정

| # | 항목 | Codex 판정 |
|---|---|---|
| 1 | 목표 명확성 | 승인 |
| 2 | 범위 적절성 | **수정 필요** |
| 3 | 리스크 식별 | **수정 필요** |
| 4 | 산출물 구체성 | **수정 필요** |
| 5 | 기술적 타당성 | **수정 필요** |
| 6 | 테스트 전략 | **수정 필요** |
| 7 | 실행 순서 | **수정 필요** |

## 오케스트레이터 사실 검증 (전건 코드 대조)

Codex의 지적을 하나씩 실제 저장소에 대조한 결과 **전부 사실로 확인**되었다.

### ✅ R1. DTA-1-2 범위 누락 — 2개 파일이 아니라 4개 (확인됨)

`grep -rn "dart:html\|dart:js_util\|dart:js'" lib/` 결과:

| 파일 | 사용 |
|---|---|
| `lib/core/config/supabase_config_web.dart:1-2` | `dart:js_util`, `dart:html` |
| `lib/core/services/web_notification_service.dart:2-3` | `dart:html`, `dart:js` |
| `lib/core/services/location_service.dart:11,13` | 조건부 import — `dart.library.js_util`, `dart.library.html` |
| `lib/presentation/widgets/naver_map_platform.web.dart:31` | `dart:html` |

플랜은 앞의 2개만 적었다. `location_service.dart`는 조건부 import 기준 자체가
`dart.library.js_util` / `dart.library.html`이라 이관 시 **분기 조건도 함께 바꿔야 한다**
(Codex 지적대로 `dart.library.js_interop` 검토 대상).
`pubspec.yaml`에 `web:` 의존성은 **없다** — 추가 필요.

### ✅ R2. CI/로컬 Flutter 버전 불일치 (확인됨)

3개 워크플로 전부 `flutter-version: '3.35.7'`로 고정:
`flutter_test.yml:21`, `coverage_threshold.yml:19`, `deploy.yml:23`.
로컬 측정 환경은 3.38.4 / Dart 3.10.3.

**레거시 웹 API의 deprecation 상태가 버전에 따라 달라지므로 이 불일치는 DTA-1-2에 직접 영향한다.**
로컬에서만 나는 analyze error 2건이 CI에서는 안 날 수 있고, 그 역도 가능하다.
플랜은 이 갭을 인지하지 못했다.

### ✅ R3. `flutter analyze`가 CI 게이트가 아님 (확인됨)

```yaml
# .github/workflows/flutter_test.yml:39-41
- name: Analyze code
  run: flutter analyze || true
  continue-on-error: true
```

이중으로 무력화되어 있다. 즉 **DTA-1-1/DTA-1-2를 고쳐도 CI는 회귀를 잡지 못한다.**
플랜의 "검증 게이트 — 정적 분석: error 0, warning 0"은 로컬에서만 의미가 있다.

### ✅ R4. EasyLocalization 원인 단정이 과함 (타당한 지적)

플랜은 "`pumpAndSettle()`은 실제 파일 I/O를 진행시키지 못한다"고 **단정**했으나,
이는 로더 구현과 테스트 바인딩에 따라 달라지는 사안이다.
원인 후보로 두고 다음을 순차 검증해야 한다:
`ensureInitialized()`만으로 되는지 → `RootBundleAssetLoader` 명시가 필요한지 →
`tester.runAsync()`가 실제로 필요한지 → 번역 asset이 테스트 번들에 포함되는지.

증상(9건 전부 위젯 0개)과 로그(`Load asset from assets/translations`에서 정지)는
확인된 사실이나, **메커니즘은 아직 가설이다.** 플랜의 "근본 원인 (조사 완료)" 표현은 부정확하다.

### ✅ R5. 실제 Supabase 키를 요구할 필요 없음 (플랜의 미해결 항목이 해소됨)

플랜은 "DTA-1-2의 실제 웹 검증에 실제 키가 필요 — 사용자 확인 필요"로 남겼으나,
Codex 지적대로 **고유한 dummy sentinel 값**을 `window.ENV`에 주입하면
읽기 성공 / 키 누락 / fallback 세 경로를 비밀값 없이 전부 검증할 수 있다.
비밀값을 요구하지 않는 편이 안전하기까지 하다. **사용자 확인 필요 항목에서 제거한다.**

`window.ENV` fallback이 환경변수 누락을 조용히 삼키는 성질(플랜도 지적)은
이 sentinel 검증으로만 드러난다.

### ✅ R6. skip / 삭제로 인한 "가짜 초록" 위험 (타당한 지적)

플랜의 완료 기준 "`flutter test` 실패 0"은
**실제 수정으로 0이 된 경우와 삭제·skip으로 0이 된 경우를 구분하지 못한다.**
글로벌 규칙의 `<failure_mode_guards>` "No fake completion"에 정면으로 걸린다.

또한 DTA-2-2가 `todo_integration_test` 2건에 대해 "원인 조사 후 불가하면 skip"을 허용한 것은
조사 전 격리로 부채를 고착시킬 수 있다. 조사를 선행 의무로 못박아야 한다.

## 선결 조건 (착수 전 플랜 반영 필수)

| # | 조건 |
|---|---|
| C1 | DTA-1-2 대상을 4개 파일로 확대하고 `location_service.dart`의 **조건부 import 분기 조건 변경**을 범위에 포함. `pubspec.yaml`에 `web` 의존성 추가 |
| C2 | 검증 기준 Flutter 버전을 CI(3.35.7)와 통일하거나, 통일 불가 시 **양쪽 버전에서 각각 측정**하고 차이를 기록 |
| C3 | `flutter_test.yml`의 `flutter analyze \|\| true` + `continue-on-error` 제거를 DTA-1-1 완료 조건에 포함 (안 그러면 고쳐도 회귀 방지 못 함) |
| C4 | DTA-2-1의 "근본 원인 (조사 완료)"를 "**가설**"로 격하하고, 4단계 순차 검증을 실행 절차로 명시 |
| C5 | 완료 보고에 **수정으로 통과한 테스트 수 / 삭제한 테스트 수 / skip한 테스트 수**를 분리 기재. 모든 `skip`에 사유 + 추적 티켓 + 제거 조건 명시. `todo_integration_test` 2건은 조사 선행 의무 |
| C6 | DTA-1-2 웹 검증은 실제 키 대신 **dummy sentinel**로 읽기 성공/누락/fallback 3경로 검증. 웹 알림은 브라우저 수동 확인(권한 거부/허용/예약/취소) 체크리스트로 분리 |

## 실행 순서 변경 (Codex 권고 채택)

```
변경 전: DTA-1-3 → DTA-1-1 → DTA-2-2 → DTA-2-1 → DTA-1-2
변경 후: DTA-1-3 → DTA-2-1 → DTA-2-2 → DTA-1-1 → DTA-1-2
```

DTA-2-1(핵심 원인)을 앞으로 당긴다. 그래야 DTA-2-2에서 각 테스트를
"고칠 수 있는 것 / 삭제할 것 / skip할 것"으로 판정할 때 EasyLocalization 해법을 재사용할 수 있다.
각 커밋마다 `analyze` + 관련 테스트 + 전체 테스트를 돌린다 (마지막 일괄 검증 금지).

## 반려하지 않은 이유

7개 항목 중 6개가 "수정 필요"지만 **반려가 아니라 조건부 승인**인 것은,
지적들이 플랜의 방향을 뒤집는 것이 아니라 **범위를 넓히고 검증을 강화하는** 성격이기 때문이다.
목표·접근·커밋 분리 전략은 그대로 유효하다. C1~C6을 반영하면 착수 가능하다.

## 유보 (이번 범위 밖, 별도 티켓 대상)

- 의존성 182개 업그레이드 불가 + 1개 discontinued
- `coverage_threshold.yml`의 15% 임계값이 실제 만족되는지 미측정 (한 번도 실행된 적 없음)
- 번역 문자열 단언 vs 키 단언의 테스트 설계 분리 (Codex 제안)
