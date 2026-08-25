# DTA-3-7 방향 — iOS 위젯에서 완료 처리

작성: 2026-08-23

사용자 요청: **"위젯에서 완료 가능하도록 해줘"**

## 조사 결과 — 티켓 설명의 추정 중 틀린 것

티켓은 "Flutter 쪽은 받을 준비가 되어 있다"고만 적었는데, **실제로는 그보다 훨씬
많이 준비되어 있었다.** Android 가 이미 같은 기능을 하고 있고, 그 규약이 그대로
남아 있다.

| 조각 | 상태 | 위치 |
| --- | --- | --- |
| 완료 요청 큐 형식 `"id:true,id:false"` | 있음 | `WidgetActionReceiver.markForSync` |
| 큐를 비우며 DB·Supabase 에 반영 | 있음 | `WidgetSyncService.processPendingSyncs` |
| `pending_widget_refresh` 플래그 처리 | 있음 | `WidgetSyncService.checkAndRefreshWidget` |
| 앱 재진입 시 위 둘 호출 | 있음 | `todo_list_screen.dart:103-118` |
| 슬롯 당기기(완료 항목 제거) | Android 만 | `WidgetActionReceiver.removeCompletedItemFromWidget` |
| **iOS AppIntent** | **없음** | — |

즉 빠진 것은 **iOS 쪽 한 조각**이다. 새 규약을 만들 필요가 없다.

추가 확인:

- `ios/Runner.xcodeproj` 의 `TodoWidgets` 는 Xcode 16 의 **동기화 폴더**
  (`PBXFileSystemSynchronizedRootGroup`)다. 폴더에 `.swift` 를 넣으면 자동으로
  타깃에 들어간다. pbxproj 를 손댈 필요가 없다.
- 위젯 익스텐션의 `IPHONEOS_DEPLOYMENT_TARGET` 은 **26.2**. `Button(intent:)`
  는 iOS 17+ 이므로 하위 분기가 필요 없다.
- `SWIFT_VERSION = 5.0` — strict concurrency 미적용.

## 결정

### 1. 서버 반영 시점 — 앱 재진입 시 (즉시 아님)

두 가지 길이 있었다.

**(A) 위젯에서 바로 Supabase PATCH** — Android 가 하는 방식.
`supabase_access_token` 을 App Group 에 넣어 두고 익스텐션이 직접 HTTP 를 친다.

**(B) 큐에 넣고 앱이 처리** ← **채택**

(B)를 고른 이유:

1. **접근 토큰을 위젯 익스텐션에 두지 않는다.** App Group 의 UserDefaults 는
   암호화되지 않고 기기 백업에 그대로 실린다. 없어도 되는 곳에 토큰 사본을
   늘리지 않는 편이 낫다.
2. **이미 검증된 경로를 재사용한다.** Supabase 쓰기·로컬 DB 반영·반복 일정
   재생성이 전부 `TodoActions.toggleCompletion` 에 붙어 있다. Swift 로 옮기면
   그중 일부만 흉내 내게 된다.
3. **(A)의 알려진 결함을 물려받지 않는다.** Android 는 PATCH 가 성공하면
   `pending_syncs` 를 지운다. 그러면 **로컬 Drift DB 는 갱신되지 않은 채로 남는다.**
   서버와 로컬이 갈라진다.

사용자가 체감하는 차이는 좁다. 위젯은 누르는 즉시 반응하고, 앱을 열면 이미
완료되어 있다. **다른 기기·웹에서 볼 때만** 앱을 다시 열기 전까지 미완료로 보인다.

즉시 반영이 필요하면 (A)를 얹을 수 있다. 그때도 (B)는 실패 시 대비로 남는다.

### 2. 되돌리기(완료 → 미완료)는 넣지 않는다

위젯은 완료한 항목을 목록에서 **빼기** 때문에 되돌릴 대상이 화면에 없다.
큐 형식은 `false` 를 이미 표현할 수 있으므로 나중에 열 수 있다.

### 3. 대상 위젯

`TodoListWidget`, `TodoDetailWidget` 두 곳. `TodoCalendarWidget` 은 날짜별
요약이라 완료 단위가 맞지 않아 제외.

## 함께 닫는 DTA-3-6 잔여 결함

DTA-3-6 에서 놓친 것 두 가지가 이 작업의 전제조건이라 함께 고친다.
**목록에 안 뜨는 항목은 완료할 수도 없다.**

1. `TodoDetailWidget` 의 시간 배지가 아직 `formatTime(dueDate)` 였다.
   `TodoListWidget` 만 고쳤고 이쪽을 빠뜨렸다 — `12:00 AM` 이 그대로 남아 있었다.
2. `TodoListWidget` 이 `getTodayTodos()` 로 오늘만 걸렀다. 제목은 "다가오는 일정"
   으로 바꿔 놓고 소스는 오늘 필터였다. 게다가 그 필터는 **표시용 문자열을 되파싱**
   해 날짜를 복원하므로, DTA-3-6 이 라벨을 `"8/25 09:00"` 로 바꾼 순간
   파싱이 실패해 항목이 통째로 사라진다.

## 검증 한계 (미리 밝혀 둠)

위젯 탭 동작은 **실기기에서만** 확인된다. 자동 검증이 닿는 범위는:

- Dart: `parsePendingSyncs` 단위 테스트
- Swift: 슬롯 조작 순수 함수를 `swift` 로 단독 실행 검증
- 컴파일: `flutter build ios --profile`

닿지 않는 범위: 탭이 실제로 인텐트를 부르는지, 위젯이 즉시 다시 그려지는지.
