# 코드 리뷰 — DTA-2-2: 방치된 테스트 파일 정리

- 작성일: 2026-08-18
- 티켓: `DTA-2-2` (`9bbd9fa3-6800-4b21-bec2-df06c51b490c`)
- 변경 파일: `test/widget_test.dart`(삭제), `test/app_integration_test.dart`, `test/integration/todo_integration_test.dart`
- 독립 리뷰어: **Codex CLI (OpenAI)** — Claude와 다른 계열 모델
- 리뷰 라운드: **1회**
- 최종 판정: **승인**

## 처리 원칙 — 조사 없는 skip 금지 (플랜 조건 C5)

플랜 리뷰에서 "조사 전 격리는 부채를 고착시킨다"는 지적을 받아,
**7건 전부 원인을 먼저 규명한 뒤** 삭제/수정/skip을 결정했다.
결과적으로 3개 파일이 서로 다른 처리를 받았다.

## 1. `test/widget_test.dart` — 삭제 (1건)

```dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('0'), findsOneWidget);      // 이 앱에 카운터는 없다
  await tester.tap(find.byIcon(Icons.add));
```

`flutter create`가 생성하는 템플릿 테스트가 그대로 남아 있었다.
이 앱에 카운터 위젯은 존재하지 않으므로 **고칠 대상 자체가 없다.** 삭제가 유일한 정답이다.

리뷰어 확인: "앱과 무관한 Flutter 기본 카운터 테스트. 삭제 적절."

## 2. `test/integration/todo_integration_test.dart` — 실제 수정 (2건)

### 원인: production 시그니처 변경이 테스트에 반영되지 않음

실패 메시지가 원인을 정확히 드러냈다.

```
No matching calls. All calls: MockNotificationService.scheduleNotification(
  {id: 42, title: todo_reminder, body: Test Todo, scheduledDate: ..., priority: medium})
```

production 호출부 (`lib/presentation/providers/todo_providers.dart:219-225`, `733-739`):

```dart
await notificationService.scheduleNotification(
  id: todoId,
  title: 'todo_reminder'.tr(),
  body: title,
  scheduledDate: notificationTime,
  priority: priority ?? 'medium',   // ← 테스트에 없던 인자
);
```

두 가지가 어긋나 있었다.

| 항목 | 테스트 기대 | 실제 |
|---|---|---|
| `title` | `'할일 알림'` (번역 결과) | `'todo_reminder'` (번역 키) |
| `priority` | 인자 자체가 없음 | `'medium'` |

`title`이 키로 오는 이유는 이 테스트 파일이 `EasyLocalization`을 초기화하지 않아
`.tr()`이 번역하지 않고 키를 그대로 돌려주기 때문이다.
`priority`는 production에 나중에 추가된 파라미터인데 테스트가 따라가지 않았다.

`when(...)` 스텁 2곳에 `priority: anyNamed('priority')`를 추가하고,
`verify(...)` 2곳을 실제 호출에 맞춰 고쳤다. 근거를 주석으로 남겼다.

### 리뷰어 확인

> `priority` 추가는 검증력을 약화시키지 않습니다. stub은 호출을 허용하고,
> `verify`는 실제 값 `'medium'`을 정확히 검사합니다.
> `title: 'todo_reminder'`는 이 테스트가 EasyLocalization 없이 실행된다는 전제에서는 올바릅니다.

단, **번역 결과 자체(`'할일 알림'`)는 이제 아무 테스트도 검증하지 않는다.** 별도 위젯 테스트가 필요하다.

## 3. `test/app_integration_test.dart` — skip (4건)

그룹명이 `DoDo App Integration Tests (Disabled)`인데 `skip:`이 없어
**이름만 비활성화이고 실제로는 계속 실행되며 4건이 실패하고 있었다.**

### 고칠 수 있는지 실제로 시험했다

skip을 결정하기 전에 probe 테스트를 작성해 2단계로 확인했다.

| 단계 | 조치 | 결과 |
|---|---|---|
| 1차 | 원인 확인 | `MyApp`이 `context.localizationDelegates`(`main.dart:451`) 호출 → `EasyLocalization` 조상이 없어 `Null check operator used on a null value` |
| 2차 | DTA-2-1의 `_MapAssetLoader`로 `EasyLocalization` 감싸 1차 원인 제거 | `ProviderException: Tried to use a provider that is in error state` — `main()`이 하는 **Supabase 초기화가 없어** 관련 provider가 error 상태 |

즉 **순수 위젯 테스트로는 복구 불가능**하며, 파일 헤더에 원저자가 적어둔
*"require platform plugins (Supabase, SharedPreferences, etc.)"* 가 실측으로 확인됐다.

이름뿐이던 비활성화를 `skip:`으로 코드에 반영하고, **사유와 제거 조건을 함께 명시**했다.

```dart
group('DoDo App Integration Tests (Disabled)', skip:
    'DTA-2-2: Supabase 등 플랫폼 플러그인 초기화가 필요해 순수 위젯 테스트로 실행 불가. '
    'integration_test 패키지로 이관하거나 MyApp 초기화를 mock 가능하게 리팩터링해야 해제 가능.',
    () {
```

리뷰어 확인: *"현재 테스트 하네스에서 정당합니다. 다만 4건의 앱 초기화 검증이 사라졌으므로 기술 부채가 남습니다."*
**이 부채는 인정하고 기록한다. 해소된 것이 아니다.**

## 가짜 초록 방지 보고 (플랜 조건 C5)

| 구분 | 건수 | 대상 |
|---|---|---|
| **실제 수정으로 통과** | **2** | `todo_integration_test.dart` |
| **삭제** | **1** | `widget_test.dart` (템플릿 잔존물, 고칠 대상 없음) |
| **skip** | **4** | `app_integration_test.dart` (사유 + 제거 조건 명시, 복구 불가 실증) |

`flutter test` 전체가 초록이 된 것은 **7건 중 2건만 실제로 고쳤기 때문**이며,
1건은 삭제, 4건은 격리한 결과다. 이 수치를 합산해 "전부 해결"이라고 말하지 않는다.

## 리뷰어가 새로 제기한 리스크

DTA-2-1의 변경에 대한 것으로, 이번 티켓에서 조치하지 않았다.

1. `reschedule_dialog_test.dart`의 `dart:io` + 프로젝트 루트 상대 경로 의존 —
   `flutter test --platform chrome`에서는 컴파일 불가. 현재 웹 타깃 테스트를 쓰지 않아 실질 영향 없음
2. `_MapAssetLoader`가 `path`를 무시하고 언어 코드만으로 맵을 반환 —
   잘못된 번역 asset 경로를 검출하지 못함

## 리뷰의 한계 (기록)

> 로컬에서 `flutter test`를 재실행하려 했으나 Flutter SDK의 `engine.stamp` 권한 오류로
> 실행하지 못했습니다. 따라서 제시된 137 통과 / 4 skip 수치는 독립 재현하지 못했습니다.

**리뷰어는 테스트 수치를 독립적으로 재현하지 못했다.** 아래 수치는 오케스트레이터 측정값이다.

## 검증 결과

| 항목 | 명령 | 결과 |
|---|---|---|
| 전체 | `flutter test` | ✅ **137 통과 / 4 skip / 0 실패** (수정 전 126 통과 / 16 실패) |
| CI 범위 | `flutter test --coverage test/unit/ test/widget/` | ✅ 128/128 |
| 대상 파일 | `flutter test test/integration/todo_integration_test.dart` | ✅ 9/9 |
| 정적 분석 | `flutter analyze` | ✅ 141건, 변경 전후 동일 |
| 빌드 | `flutter build web --release` | ✅ `✓ Built build/web` |
