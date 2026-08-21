# 코드 리뷰 — DTA-2-1: reschedule_dialog_test 9건 실패 수정

- 작성일: 2026-08-18
- 티켓: `DTA-2-1` (`62942091-14d9-4a44-9d71-2e8b3dff181c`)
- 변경 파일: `test/widget/reschedule_dialog_test.dart`, `.github/workflows/flutter_test.yml`
- 독립 리뷰어: **Codex CLI (OpenAI)** — Claude와 다른 계열 모델
- 리뷰 라운드: **2회** (반려 → 승인)
- 최종 판정: **승인**

## 원인 규명 — 가설이 두 번 틀렸다

플랜 리뷰의 조건 C4는 "원인을 확정으로 쓰지 말고 순차 검증하라"고 요구했다. 실제로 **초기 가설은 두 번 틀렸다.**

| 단계 | 가설 | 실측 결과 |
|---|---|---|
| 1 | `EasyLocalization.ensureInitialized()` 누락이 원인 | **부분적으로 맞음.** 단 추가하는 순간 `MissingPluginException(getAll on channel plugins.flutter.io/shared_preferences)`로 **파일 전체가 로드 실패**. `SharedPreferences.setMockInitialValues({})`가 선행돼야 함 |
| 2 | mock + ensureInitialized면 해결 | **틀림.** 첫 테스트만 통과하고 나머지 9건 여전히 실패 |
| 3 | `runAsync()`가 문제였다 (초기 repro의 2번째 테스트가 runAsync를 써서 실패) | **틀림.** 동일 테스트를 A/B/C 3회 반복하는 최소 재현으로 **A만 통과, B·C 실패** 확인 → runAsync가 아니라 **테스트 격리 문제** |
| 4 | `setUp()`에서 매번 재초기화하면 해결 | **틀림.** 여전히 A만 통과 |
| 5 | `runAsync()` + 실제 지연 | 3회 전부 통과 → **채택했으나 리뷰에서 반려됨 (아래)** |
| 6 | 테스트용 `AssetLoader` 주입 | **최종 채택.** 결정적으로 통과 |

3단계의 오판은 초기 repro에서 두 번째 테스트가 실패한 것을 `runAsync` 탓으로 귀속했기 때문이다.
실제로는 **몇 번째 테스트인지**가 변수였다. 반복 재현으로 변수를 분리하지 않았다면 잘못된 결론을 그대로 냈을 것이다.

### 확정된 근본 원인

`EasyLocalization` 위젯은 mount 될 때마다 `assets/translations/*.json`을 **실제 파일 I/O**로 읽는다.
위젯 테스트의 fake async 클럭은 실제 I/O를 진행시키지 못하므로 `pumpAndSettle()`을 아무리 돌려도
로딩이 끝나지 않고, 위젯 트리가 로딩 상태에 머물러 `Dialog`를 포함한 모든 위젯이 0개로 잡힌다.

첫 테스트만 통과한 것은 `ensureInitialized()`가 만든 초기 상태를 재사용했기 때문이며,
두 번째부터는 새 인스턴스가 자체 로드를 시도하다 멈춘다.

이것이 `flutter_test.yml`에 있던 *"Exclude reschedule_dialog_test.dart due to EasyLocalization issues in CI"*
주석의 실체다. **CI 환경 문제가 아니라 로컬에서도 동일하게 재현되는 테스트 하네스 결함이었다.**

## 라운드 1 — 반려

채택안: `runAsync()` 안에서 `pumpWidget` 후 `Future.delayed(50ms)`.

| # | 심각도 | 지적 |
|---|---|---|
| 1 | **주요** | 50ms 고정 지연은 여전히 flaky. 느린 CI·디스크 부하에서 50ms 안에 로딩이 안 끝날 수 있음. "현재 통과했다"는 안정성 증명이 아님 |
| 2 | 보통 | `runAsync()`의 권장 용법은 *실제 작업의 완료 Future를 기다리는 것*이지 임의 시간 대기가 아님 |
| 3 | 사소 | 헬퍼 호출부 4곳에 trailing whitespace |

리뷰어가 제시한 대안 중 **"테스트용 `AssetLoader`로 번역 맵을 사전 로드"** 를 채택했다.

지적 1은 정당하다. 고정 지연은 "지금 이 머신에서 통과"만 보장하며, CI에서 간헐적으로 깨졌을 때
원인 추적이 극히 어려운 종류의 부채다. 애초에 이 티켓이 존재하는 이유가 그런 부채였다.

## 라운드 2 — 승인

`runAsync`와 `Future.delayed`를 **완전히 제거**하고 `_MapAssetLoader`로 교체했다.

```dart
class _MapAssetLoader extends AssetLoader {
  const _MapAssetLoader(this._byLanguageCode);
  final Map<String, Map<String, dynamic>> _byLanguageCode;
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      _byLanguageCode[locale.languageCode];
}
```

핵심은 **마이크로태스크 vs 실제 I/O**다. 이 로더는 이미 메모리에 있는 맵을 반환하므로
그 Future가 마이크로태스크로 완료된다. fake async 클럭은 마이크로태스크를 처리하므로
`pumpAndSettle()`만으로 결정적으로 로딩이 끝난다. 실제 JSON은 `main()`에서 `dart:io`로 한 번만 읽는다.

### 리뷰어 확인 결과

| 항목 | 판정 |
|---|---|
| (a) 고정 지연 의존 제거 | ✅ `Future.delayed`·`runAsync` diff에 없음 |
| (b) 결정성 | ✅ `_MapAssetLoader` 자체는 결정적 |
| (c) `dart:io` 사용 | ✅ VM 위젯 테스트에서 문제 없음 |
| (d) 신규 결함 | ✅ 없음 |

## 수용한 잔여 리스크

리뷰어가 반려 사유는 아니라고 판단했으나 기록해 둔다.

1. **상대 경로 의존** — `_readTranslations()`의 `assets/translations/*.json`은
   `flutter test`를 프로젝트 루트에서 실행한다는 전제에 의존한다. CI 명령과 로컬 관례 모두 루트 실행이라 현재는 안전하다.
2. **`dart:io` 때문에 웹 타깃 불가** — `flutter test --platform chrome`으로 전환하면 컴파일되지 않는다.
   현재 이 프로젝트는 웹 타깃으로 테스트하지 않는다.

## 기존 결함 (이번 변경으로 생긴 것 아님)

리뷰어가 함께 지적한 사항. **이번 티켓에서 고치지 않았다.**

- `renders chevron icons for each option`: `Icon`이 7개 이상인지만 확인하고 chevron인지 검증하지 않음
- `renders all option icons`: `InkWell`이 3개 이상인지만 확인하고 각 옵션과 연결됐는지 확인하지 않음

테스트 이름이 약속하는 검증 수준에 못 미친다. 별도 티켓 대상.

## CI 워크플로 변경

```yaml
# 변경 전 — reschedule_dialog_test.dart 를 빼려고 파일을 일일이 나열
flutter test --coverage test/unit/ test/widget/progress_card_test.dart test/widget/custom_todo_item_test.dart
# 변경 후 — coverage_threshold.yml:35 와 동일 범위
flutter test --coverage test/unit/ test/widget/
```

두 워크플로의 범위 불일치가 해소됐다. 한쪽이 숨기고 다른 쪽이 드러내던 상태가 끝났다.

## 검증 결과

| 항목 | 명령 | 결과 |
|---|---|---|
| 대상 파일 | `flutter test test/widget/reschedule_dialog_test.dart` | ✅ 10/10 통과 |
| **flaky 검사** | 위 명령 **5회 연속** | ✅ run1~run5 전부 PASS |
| CI 범위 | `flutter test --coverage test/unit/ test/widget/` | ✅ **128/128** (수정 전 119 통과 / 9 실패) |
| 전체 | `flutter test` | ⚠️ 135 통과 / 7 실패 — 전원 DTA-2-2 범위 (수정 전 126/16) |
| 정적 분석 | `flutter analyze` | ✅ 141건, 변경 전후 동일 |
| 빌드 | `flutter build web --release` | ✅ `✓ Built build/web` (35.7s) |

### 가짜 초록 방지 보고 (플랜 조건 C5)

| 구분 | 건수 |
|---|---|
| **실제 수정으로 통과시킨 테스트** | **9** |
| 삭제한 테스트 | **0** |
| `skip` 처리한 테스트 | **0** |

이 티켓은 어떤 테스트도 삭제하거나 비활성화하지 않았다. 9건 전부 원인을 고쳐 통과시켰다.

## 이 티켓을 넘어선 발견 — DTA-2-3 신규 발행

테스트를 전부 고쳤는데도 **`coverage_threshold.yml`은 여전히 실패한다.**
실패 지점이 테스트 단계에서 임계값 단계로 옮겨갔을 뿐이다.

```
실측: lines 596/15642 = 3.81%
기준: 15% (미달 시 exit 1)
```

이 워크플로는 `pull_request` → main 트리거 전용이라 `gh run list` 기준 **한 번도 실행된 적이 없다.**
따라서 임계값이 만족된 적도 없다. `DTA-2-3` 티켓으로 분리했고, 임계값 하향/테스트 추가/비활성화 중
어느 쪽을 택할지는 사용자 판단이 필요하다.
