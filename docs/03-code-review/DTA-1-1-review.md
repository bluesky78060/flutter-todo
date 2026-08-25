# 코드 리뷰 — DTA-1-1: analyze warning 15건 정리

- 작성일: 2026-08-18
- 티켓: `DTA-1-1` (`185d9877-e708-4168-9634-cc9d92cf7b2a`)
- 독립 리뷰어: **Codex CLI (OpenAI)** — Claude와 다른 계열 모델
- 리뷰 라운드: **1회 반려 → 선행 티켓 완료로 해소**
- 최종 판정: **승인** (DTA-1-2 완료로 반려 사유 소멸)

## 라운드 1 — 코드는 전부 통과, CI 게이트만 반려

리뷰어는 **코드 변경 5건을 전부 타당하다고 확인**했다. 유일한 반려 사유는
`flutter_test.yml`의 analyze 게이트 복원이었다.

| 변경 | 리뷰어 판정 |
|---|---|
| `statistics_screen.dart` 미사용 `ref.watch` 제거 | ✅ 문제없음 — `_OverallProgressCard`는 private이고 부모 `StatisticsScreen`이 이미 `isDarkModeProvider`를 구독하므로 테마 변경 시 다시 빌드된다. 카드 출력도 테마와 무관 |
| `_MiniStatRow`, `_StreakCard`, `_StreakItem` 삭제 | ✅ 참조 전무. streak **계산값은 삭제되지 않았고 `_InsightsCard`에서 계속 사용**된다 |
| `position ?? 999999` → `position` | ✅ `Todo.position`은 non-nullable(기본값 0)이라 기존 분기는 도달 불가 |
| `if (todo.description != null)` 제거 | ✅ 렌더링 동일. `description`은 non-nullable이고 빈 문자열이어도 기존 조건이 항상 참이라 `SizedBox`와 빈 `Text`가 렌더링됐다 |
| analyze 게이트 복원 | ❌ **반려** |

### 반려 사유

> 배경 설명대로 error 2건이 아직 남아 있다면 `flutter analyze`는 실패하고,
> 이 변경만 먼저 병합될 경우 CI가 즉시 실패합니다.
> analyze 게이트 복원은 올바른 방향이지만 **DTA-1-2 수정과 원자적으로 병합**하거나,
> DTA-1-2를 먼저 병합한 뒤 이 변경을 랜딩해야 합니다.

`flutter analyze`의 종료 코드를 실측해 확인했다: **exit 1**. 리뷰어 지적이 정확했다.

## 해소

AI PM에 티켓 의존을 등록했다 (`DTA-1-1` → `DTA-1-2`).
DTA-1-2를 선행 완료해 **analyze error를 2 → 0으로 만든 뒤** 이 티켓을 마무리했다.
문서상 약속이 아니라 실제로 조건을 충족시켰다.

## 변경 상세

### 미사용 import 6건
| 파일 | import |
|---|---|
| `lib/presentation/utils/layout_builders_utils.dart:27` | `nav_item.dart` |
| `lib/core/services/google_calendar_service.dart:4` | `googleapis_auth` |
| `test/widget/progress_card_test.dart:6,7` | `easy_localization`, `easy_localization_loader` |
| `test/widget/custom_todo_item_test.dart:7,8` | 동일 2건 |

### 미사용 선언 5건
- `lib/main.dart:22` — `show` 목록의 `kDebugMode`
- `lib/presentation/screens/statistics_screen.dart:564` — 지역변수 `isDarkMode`
- `lib/presentation/widgets/naver_map_platform.web.dart:58` — `static int _requestCounter`
  (증가시키는 코드가 없는 죽은 스캐폴딩. 짝인 `_pendingSearches`도 `remove`만 호출될 뿐
  등록하는 코드가 없어 사실상 미구현 경로다)
- `statistics_screen.dart` — `_MiniStatRow`, `_StreakCard`, `_StreakItem`

> **`_StreakCard`를 지우면 `_StreakItem`이 연쇄적으로 미참조가 된다.**
> 3개 클래스 약 150줄이 함께 사라졌다. streak **UI**가 통째로 없어진 것이며,
> streak **계산 로직**은 남아 `_InsightsCard`에서 계속 쓰인다.

### dead code 3건 + 항상 참인 조건 1건
- `todo_grouping_utils.dart:95,96` — `?? 999999` 제거
- `theme_preview_screen.dart:517` — `!= null` 조건 제거 (본문은 유지해 렌더링 보존)

### CI 게이트 (플랜 조건 C3)
```yaml
# 변경 전 — 이중으로 무력화되어 analyze 결과가 CI를 전혀 막지 못했다
run: flutter analyze || true
continue-on-error: true
# 변경 후
run: flutter analyze
```

이게 없으면 warning을 0으로 만들어도 CI가 회귀를 잡지 못해 같은 상태로 되돌아간다.

## 검증 결과

| 항목 | 결과 |
|---|---|
| `flutter analyze` | ✅ **warning 15 → 0**, error 2 → 0 (DTA-1-2 포함), 총 141 → 117건 (전부 info) |
| `flutter analyze` 종료 코드 | ✅ **0** — CI 게이트 통과 가능 |
| `flutter test` | ✅ 137 통과 / 4 skip / 0 실패 — 회귀 없음 |
| `flutter test --coverage test/unit/ test/widget/` | ✅ 128/128 |
| `flutter build web --release` | ✅ `✓ Built build/web` |

## 리뷰의 한계 (기록)

> 로컬에서는 Flutter SDK 캐시의 `engine.stamp` 쓰기 권한 오류로 analyze/test 실행 결과를
> 확인하지 못했습니다.

리뷰어는 수치를 독립 재현하지 못했다. 위 수치는 오케스트레이터 측정값이다.

## 남은 사항

- 리뷰어 지적: streak 관련 **계산 필드와 문서 주석**은 남아 있어 후속 정리가 필요하다.
  UI만 지웠으므로 `_InsightsCard`가 쓰는 부분 외에는 죽은 계산이 있을 수 있다.
- info 117건(대부분 `prefer_const_constructors`)은 이번 범위 밖이다.
