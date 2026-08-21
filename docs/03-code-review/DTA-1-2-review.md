# 코드 리뷰 — DTA-1-2: 레거시 웹 API 이관

- 작성일: 2026-08-18
- 티켓: `DTA-1-2` (`e7d579ec-dddf-406a-bb92-81ec407d061f`)
- 독립 리뷰어: **Codex CLI (OpenAI)** — Claude와 다른 계열 모델
- 리뷰 라운드: **4회** (반려 → 반려 → 반려 → 승인)
- 최종 판정: **승인**

## 범위가 2배로 늘었다 — 플랜 리뷰 C1의 지적이 맞았다

티켓 최초 기술은 2개 파일이었다. 플랜 리뷰에서 Codex가 "전수 조사가 안 됐다"고 지적해
확인한 결과 **4개 파일**이었고, 코드 리뷰 1라운드에서 **3곳이 더** 드러났다.

| 발견 시점 | 파일 | 사용 형태 |
|---|---|---|
| 최초 티켓 | `lib/core/config/supabase_config_web.dart` | `dart:js_util`, `dart:html` **직접 import** |
| 최초 티켓 | `lib/core/services/web_notification_service.dart` | `dart:html`, `dart:js` **직접 import** |
| 플랜 리뷰 C1 | `lib/core/services/location_service.dart` | 조건부 import 대상 + 조건 |
| 플랜 리뷰 C1 | `lib/presentation/widgets/naver_map_platform.web.dart` | `dart:html` **직접 import** |
| **코드 리뷰 R1** | `lib/core/services/notification_service.dart:9` | **`dart.library.html` 조건만 사용** |
| **코드 리뷰 R1** | `lib/presentation/widgets/location_picker_dialog.dart:38` | **`dart.library.html` 조건만 사용** |
| **코드 리뷰 R1** | `lib/data/datasources/local/app_database.dart:5` | **`dart.library.html` 조건만 사용** |

마지막 3개는 **`dart:html`을 import 하지 않고 조건으로만 쓰기 때문에**
`grep "dart:html"` 에 걸리지 않았다. 조건부 import는 `dart.library.*` 조건도 함께 조사해야 한다.

## 라운드 1 — 반려

### [P1] Wasm에서 웹 구현이 선택되지 않음 (치명)

> `dart.library.html`은 Wasm에서 웹 구현 선택 기준으로 사용할 수 없습니다.
> Wasm에서는 stub/base 구현이 선택됩니다.

리뷰어가 짚은 실제 결과:
- 웹 알림 → `web_notification_service_stub.dart`가 선택되어 **동작하지 않음**
- Naver Map → `NaverMapWeb is only available...` placeholder 표시
- Drift DB → `connection.dart`의 `UnsupportedError` 발생

`supabase_config.dart`와 `location_service.dart`만 고친 것은 불충분했다.
**이관의 명분이 Wasm 대응인데 정작 Wasm에서 앱이 깨지는 상태였다.**

### [P2] JS 콜백 경계의 예외 처리

`dart:html`의 `onMessage.listen`은 Stream/Zone 경로를 타서 콜백 예외가 JS 경계 밖으로
새지 않았다. `package:web` + `.toJS` 콜백은 그렇지 않다.

### [P3] `dartify()` 후 숫자 캐스팅이 Wasm에서 깨짐

Wasm에서 JS number의 `dartify()` 결과는 `double`이다.
`data['requestId'] as int`는 값이 `1`이어도 `TypeError`가 난다.

**조치**: 조건 3곳 전부 `dart.library.js_interop`으로 변경, 콜백 본문 전체 `try/catch`,
`(data['lat'] as num).toDouble()` / `(data['requestId'] as num).toInt()` 정규화.

## 라운드 2 — 반려

P1~P3는 해소됐으나 새 결함:

> `_setupMessageListener()`에서 등록한 `_onBridgeMessage.toJS` 콜백을 `dispose()`에서
> `removeEventListener`하지 않습니다. **특히 `.toJS`를 매번 새로 생성하므로 제거하려면
> JS 콜백을 필드에 보관해야 합니다.**

`window`가 State를 계속 참조해 누수가 생기고, 폐기된 위젯의 `onMapReady`/`onMapTap`이
계속 호출된다. (원래 `dart:html` 코드도 구독을 해제하지 않던 **기존 누수**지만,
`.toJS` 특성상 이관 시점에 구조적으로 고쳐야 했다.)

**조치**: `JSFunction? _messageListener` 필드에 보관 → `dispose()`에서 동일 객체로 해제,
`_onBridgeMessage` 진입부에 `if (!mounted) return;` 가드, 알림 클릭 콜백의 `close()`를 `try` 안으로.

## 라운드 3 — 반려

> `_registerViewFactory()`의 `Future.delayed()`가 `dispose()`에서 취소되지 않습니다.
> 자동 종료 타이머의 `notification.close()`는 여전히 `try/catch` 밖입니다.

**조치**: 지연 콜백 진입부 `mounted` 가드, 자동 종료 `close()` `try/catch`.

## 라운드 4 — 승인

> `dart:html` → `package:web` 변환 및 JS 값 변환은 일관됨.
> 메시지 리스너 등록/해제도 dispose와 함께 처리됨.
> 알림 생성, 클릭 시 focus/close, 자동 close 동작은 기존 의미를 유지함.

## 이관 상세

| 레거시 | 이관 후 | 비고 |
|---|---|---|
| `js_util.getProperty` | `dart:js_interop_unsafe`의 `getProperty` | `JSAny`로 받고 `is JSObject`로 좁히면 `invalid_runtime_check_with_js_interop_types` 린트 → `getProperty<JSObject?>`로 직접 수신 |
| `html.Notification` | `web.Notification` | — |
| `Notification.supported` | `web.window.has('Notification')` | `package:web`에 대응물 없음. 리뷰어 확인: 기존 SDK도 `!!(window.Notification)`이라 사실상 동등 |
| `Notification.requestPermission()` | `.requestPermission().toDart` → `.toDart` | `JSPromise<JSString>`이라 **두 번** 변환 |
| `js.JsObject(ctor, [...])` | `web.Notification(title, web.NotificationOptions(...))` | 동적 생성자 호출은 `dart:js_interop`에 대응물이 없어 1:1 치환 불가 |
| `js.allowInterop` | `.toJS` | — |
| `html.DivElement()` | `web.document.createElement('div') as web.HTMLDivElement` | — |
| `html.window.onMessage.listen` | `addEventListener('message', ...toJS)` | `window.onmessage` 대입은 지도 인스턴스가 둘 이상일 때 서로 덮어씀 |
| `event.data` (자동 변환) | `event.data.dartify()` | `package:web`은 `JSAny`를 그대로 넘김 |
| `postMessage(map, '*')` | `postMessage(map.jsify(), '*'.toJS)` | 리뷰어 확인: 중첩 구조가 `naver_map_bridge.js`의 `{channel, type, payload}` 계약과 일치 |
| `dart.library.html` 조건 | `dart.library.js_interop` 조건 | **Wasm 대응의 핵심** |

`lib/core/services/location_service_web_stub.dart`는 삭제했다.
`window.ENV` 접근 로직이 `supabase_config_web.dart`와 **완전히 중복**되어 있었고,
이관하면서 후자를 재사용하도록 통합했다.

`pubspec.yaml`에 `web: ^1.1.1` 추가.

## analyze가 못 잡고 빌드가 잡은 결함

```
lib/core/services/web_notification_service.dart:183:55:
Error: Tear-offs of external extension type interop member 'close' are disallowed.
      Timer(const Duration(seconds: 10), notification.close);
```

`flutter analyze`는 통과했으나 `dart2js`가 거부했다.
**js_interop 이관에서 analyze 통과는 충분조건이 아니다.** 빌드 게이트가 필수다.

## 런타임 검증 (플랜 조건 C6) — 실제 키 없이 수행

플랜 rev.1은 "실제 Supabase 키 필요"를 미해결로 남겼으나, 플랜 리뷰 C6의 제안대로
**고유 sentinel**로 대체해 비밀값 없이 검증했다.

`test/web/window_env_web_test.dart` 신규 작성 — **실제 Chrome에서 실행**:

| 경로 | 기대 | 결과 |
|---|---|---|
| `window.ENV` 부재 | `null` (하드코딩 fallback으로 내려감) | ✅ |
| `window.ENV`는 있으나 키 없음 | `null` | ✅ |
| 값 있음 (`SENTINEL_SUPABASE_URL_7f3a`) | sentinel 그대로 반환 | ✅ |
| 빈 문자열 | `null` 취급 | ✅ |

이 경로는 **깨져도 앱이 fallback으로 조용히 동작해 티가 나지 않는다.**
그래서 `flutter_test.yml`에 `flutter test --platform chrome test/web/` 단계를 추가해
CI에서 못박았다.

## Wasm 상태 — 정확히

이관 후 Wasm dry run 결과, **프로젝트 코드는 findings에서 전부 사라졌다.**
다만 Wasm 빌드가 가능해진 것은 아니다. 서드파티 3개가 여전히 막고 있다.

```
package:fl_location_web/fl_location_web.dart      - dart:html unsupported
package:universal_html/src/_sdk/html.dart          - dart:html unsupported
package:universal_html/src/_sdk_html_additions.dart - dart:html unsupported
image-4.5.4/lib/src/exif/ifd_directory.dart        - avoid_double_and_int_checks lint violation (x2)
```

**"Wasm 대응 완료"가 아니라 "우리 쪽 차단 요인 제거"가 정확한 표현이다.**

## 검증 결과

| 항목 | 명령 | 결과 |
|---|---|---|
| 정적 분석 | `flutter analyze` | ✅ **error 0 / warning 0** (이전 error 2 / warning 15) |
| 웹 빌드 | `flutter build web --release` | ✅ `✓ Built build/web` |
| VM 전체 | `flutter test` | ✅ 137 통과 / 4 skip / 0 실패 |
| **브라우저** | `flutter test --platform chrome test/web/` | ✅ **4/4** (실제 Chrome) |
| CI 범위 | `flutter test --coverage test/unit/ test/widget/` | ✅ 128/128 |
| 레거시 잔존 | `grep -rn "dart:html\|dart:js_util\|dart:js'" lib/` | ✅ 주석 외 없음 |
| 조건부 import | `grep -rn "dart.library.html" lib/` | ✅ 주석 외 없음 |

## 리뷰의 한계 (기록)

리뷰어는 4라운드 내내 로컬 Flutter SDK 캐시(`engine.stamp`) 쓰기 권한 오류로
`flutter analyze` / `flutter test`를 **직접 실행하지 못했다.**
최종 판정은 오케스트레이터가 제시한 analyze/build 결과를 전제로 내려졌다.

## 수동 확인이 남은 항목

**웹 알림은 자동 검증이 불가능하다.** 브라우저 권한 상호작용이 필요하다.
아래는 사용자가 직접 확인해야 한다.

- [ ] 권한 거부 상태에서 알림을 요청했을 때
- [ ] 권한 허용 후 알림이 실제로 표시되는지
- [ ] 알림 클릭 시 창이 포커스되고 알림이 닫히는지
- [ ] 10초 후 자동으로 닫히는지
- [ ] Naver 지도가 렌더되고 탭 좌표가 전달되는지 (`naver_map_bridge.js` 연동)
