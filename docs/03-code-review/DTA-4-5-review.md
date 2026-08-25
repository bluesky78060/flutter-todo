# DTA-4-5 코드 리뷰 — iOS workmanager 채널 오류 배너

**대상 커밋**: `830bf6a` → `16b0ff0` → `76e50c6` → `a1bb0b0`
**분류**: 플랫폼 통합 회귀 + 사용자 노출 오류 (2중 이상)
**결론**: **통과** — 4라운드 독립 리뷰 후

---

## 근본 원인

`samsung_device_utils.dart`의 `shouldUseWorkManager()`에 플랫폼 가드가 없었다. 인과 사슬:

1. `isSamsungDevice()`는 non-Android에서 `false` (그 함수엔 가드가 있었다)
2. 그래서 `Permission.ignoreBatteryOptimizations` 검사로 떨어지는데, 그것은 **Android 전용 권한**이라 iOS에서는 절대 granted가 되지 않는다
3. `!isGranted`가 항상 참이 되어 **`true`를 반환**했다
4. iOS 알림이 표준 로컬 알림 대신 WorkManager 경로로 갔고, `PlatformException(channel-error, ...WorkmanagerHostApi.initialize)` 배너가 사용자에게 노출됐다

배제된 가설(근거 있음): Dart↔네이티브 버전 불일치(Pigeon 채널명 8개 완전 일치), 플러그인 미등록, `pod install` 미실행, 초기화 타이밍, 프레임워크 누락.

---

## 라운드별 발견

| 라운드 | 발견 | 성격 |
|---|---|---|
| 1 | HIGH 2 | **둘 다 거짓 주석** — `processing` 백그라운드 모드 불필요, `initialize()` 멱등 주장 |
| 2 | HIGH 3 | iOS 경로 무동작 2건(taskName 불일치, `setPluginRegistrantCallback` 부재) + **거짓 주석** 1건 |
| 3 | HIGH 3 | **지어낸 근거** 1건, **변이에서 살아남는 무의미한 테스트** 1건, 초안 잔존 모순 주석 1건 |
| 4 | HIGH 1 | **계층 경계 넘는 단정** — `isScheduledByUniqueName()` 처방 |

**네 라운드 연속 "주장이 사실과 다름"이 나왔다.** 기능 결함은 2라운드가 마지막이었고, 이후는 전부 서술의 정확성 문제였다.

### 3라운드 HIGH-A — 가장 심각했던 것

2차 커밋이 *"플러그인이 `setTaskCompleted(success: false)`로 보고하고 iOS가 백그라운드 예산을 깎는다"*고 적고 **"플러그인 소스로 전부 확인했다"**고 주장했다. 소스는 반대다:

```swift
operation.completionBlock = { task.setTaskCompleted(success: !operation.isCancelled) }  // 취소 여부만
worker.performBackgroundRequest { _ in semaphore.signal() }                             // Dart 반환값 버려짐
```

식별자 매핑만 확인하고 그 뒤 결과를 상상해 붙인 것이다. 수정의 정당성 자체는 남는다 — 분기가 없으면 지오펜스 핸들러가 **아예 호출되지 않는다**. 참인 이유로 교체하고 틀렸던 주장을 주석에 남겼다.

### 4라운드 HIGH — 같은 메커니즘의 다섯 번째

3차 커밋이 *"iOS에서 등록을 확인하려면 `isScheduledByUniqueName()`을 쓰라"*고 처방했다. Swift 쪽(`WorkmanagerPlugin.swift:246-255`)에는 구현이 있지만 **Dart federated shim이 그 앞에서 `UnsupportedError`를 던진다**(`workmanager_apple.dart:129-131`).

리뷰어가 재발 메커니즘을 정확히 짚었다:

> asserting Dart-visible behavior from native source alone; the federated plugin's Dart shim is the layer that keeps getting skipped

---

## 회귀 테스트 — 두 번 가짜였다

**1차**: 가드를 제거해도 `+5 통과`. 테스트 환경에 `permission_handler` 채널이 없어 예외 → `catch` → `false`로 빠졌다. **"가드가 있어서 false"가 아니라 "예외가 나서 false"**였다. 채널을 모킹해 실기기 조건(denied)을 재현하니 변이가 죽였다.

**2차**: 그런데 `shouldUseWorkManager` **하나만** 변이 검증하고 나머지 셋을 안 돌렸다. 3라운드 리뷰어가 `isSamsungDevice()` 테스트도 같은 이유로 살아남는 것을 찾았다. 두 채널(`device_info`, `system_properties`)을 추가 모킹해 **false를 만들 수 있는 것이 플랫폼 가드뿐이도록** 만들었다.

최종 변이 검증 — 4라운드 리뷰어가 독립 재현:

| 변이 | 주장 | 재현 |
|---|---|---|
| `shouldUseWorkManager` 가드 제거 | `+3 -2` | **`+3 -2`** ✓ |
| `isSamsungDevice` 가드 제거 | `+4 -1` | **`+4 -1`** ✓ |
| `isIgnoringBatteryOptimizations` `true→false` | `+4 -1` | **`+4 -1`** ✓ |
| `requestBatteryOptimizationExemption` `true→false` | `+4 -1` | **`+4 -1`** ✓ |
| 변이 없음 / 복원 후 | `+5` | **`+5` 양쪽** ✓ |

---

## 리뷰어가 독립 확인한 것

- **`processing` 제거 근거 정확** — `registerPeriodicTask` → `schedulePeriodicTask` → `BGAppRefreshTaskRequest`. 필요한 모드는 이미 있던 `fetch`이고, 저장소에 `BGProcessingTask` 사용처 0건
- **`_initFuture` 캐싱 패턴 건전** — 의심한 4가지 각도(실패 후 재시도 경합, 두 상태 불일치, `Future.wait` unhandled exception, 동기 반환 전환) 전부 문제 없음. `catch`의 `_initFuture = null`을 `rethrow` **앞에** 둔 순서가 정확 — 뒤였으면 재시도가 영구히 막혔다
- **AppDelegate 호출 순서** 상류 정본 예제와 라인 단위 일치, retain cycle 없음
- **Android 회귀 없음** — 추가한 disjunct는 Android가 emit하지 않는 문자열
- **mock 정확성** — 채널명·메서드가 네이티브 핸들러(`MainActivity.kt`)와 일치, `Permission._(16)` 정확. 통과시키려 맞춘 것이 아님
- **커밋 메시지 수치 전부 재현** — `+247 ~4`, `117 info`, `:393 prefer_const`

---

## 분리 발행

**DTA-4-6 (P2)** — `_handleGeofenceTask`가 `// For now, just return success`로 아무 일도 하지 않는 빈 스텁. `true`를 반환하므로 상위 어디에서도 감지하지 못한다. 즉 **주기적 지오펜스 체크는 어느 플랫폼에서도 동작한 적이 없다.** DTA-4-5가 선행 조건 둘(디스패처 라우팅, `setPluginRegistrantCallback`)을 갖췄다.

부수 확인 사항도 함께 넘겼다 — iOS는 `frequency`·`inputData`를 무시하고 submit 실패도 삼키므로, 배터리 적응형 간격과 실패 감지 모두 Android에서만 실효가 있다.

---

## 검증 증거

```
flutter analyze     117 issues (전부 info) — 변경 파일 신규 이슈 0건
                    잔여 1건은 geofence_settings_screen.dart:400 기존 prefer_const (편집 hunk 밖)
flutter test        +247 ~4: All tests passed!   (기존 +242 + 신규 5)
변이 검증            네 가드 전부 죽음
release 빌드         Runner.app (53.7MB) 실기기 설치 완료
```

**사용자 실기기 확인**: 배너 소멸("배너 안 떠"), 기존 범위 일정 기능 정상.
