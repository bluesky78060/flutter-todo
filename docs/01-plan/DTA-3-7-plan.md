# DTA-3-7 플랜 — iOS 위젯에서 완료 처리

방향: [DTA-3-7-direction.md](../00-discovery/DTA-3-7-direction.md)

## 흐름

```
[위젯 동그라미 탭]
      ↓  Button(intent: CompleteTodoIntent(todoId:))
[CompleteTodoIntent.perform]              ← 위젯 익스텐션 프로세스
      ↓  SharedDataManager.completeTodo(id:)
   ├─ 슬롯에서 제거하고 뒤를 당김        → 즉시 사라져 보임
   ├─ pending_syncs 에 "id:true" 추가
   ├─ pending_widget_refresh = true
   └─ 오늘 항목이면 완료 카운트 +1
      ↓  WidgetCenter.reloadAllTimelines()
[위젯 다시 그림]                          ← 여기까지 앱 없이

      … 사용자가 앱을 다시 열면 …

[todo_list_screen.didChangeAppLifecycleState(.resumed)]   ← 이미 있음
      ↓
[WidgetSyncService.processPendingSyncs]                   ← 이미 있음 (수정)
      ↓  로컬 Drift DB + Supabase
[checkAndRefreshWidget → widgetService.updateWidget()]    ← 이미 있음
      ↓  다음 10건을 새로 채움
```

## 변경 파일

### 신규

| 파일 | 역할 |
| --- | --- |
| `ios/TodoWidgets/WidgetSlotStore.swift` | 슬롯 배열 조작 **순수 함수**. Foundation 만 의존 → 단독 실행 검증 가능 |
| `ios/TodoWidgets/CompleteTodoIntent.swift` | AppIntent + UserDefaults 접근 |
| `lib/core/widget/widget_pending_sync.dart` | `pending_syncs` 파싱 (순수 함수) |
| `test/unit/widget/widget_pending_sync_test.dart` | 위 테스트 |

순수 로직을 굳이 따로 뺀 이유: **위젯 익스텐션 코드는 테스트 타깃이 없다.**
UserDefaults 를 직접 만지는 함수로 두면 실기기 말고는 확인할 방법이 없다.
배열만 받아 배열을 돌려주게 만들면 `swift` 로 그 파일을 그대로 실행해 볼 수 있다.

### 수정

| 파일 | 변경 |
| --- | --- |
| `ios/TodoWidgets/SharedData.swift` | `getProgressCounts()`, `storageSlot(forTodoId:)` 추가 / `getTodayTodos()` 삭제 |
| `ios/TodoWidgets/TodoListWidget.swift` | 동그라미 → `Button(intent:)`. 소스를 `getIncompleteTodos()` 로. 카운트는 저장값 사용 |
| `ios/TodoWidgets/TodoDetailWidget.swift` | 동그라미 → `Button(intent:)`. 시간 배지 `displayTime` 사용 (DTA-3-6 잔여) |
| `lib/core/services/widget_sync_service.dart` | `parsePendingSyncs` 사용 + **목표 상태 확인 후 반영** |

## 핵심 판단 세 가지

### 1. 배열 인덱스가 아니라 id 로 슬롯을 찾는다

`getTodos()` 는 빈 칸을 건너뛰고(`continue`), 위젯은 거기서 다시 미완료만 거른다.
그래서 **화면의 N번째 항목과 저장소의 N번 칸이 다르다.** Android 는
`todo_index` 를 넘기는데, 그쪽은 필터가 없어 우연히 맞아떨어질 뿐이다.

→ `storageSlot(forTodoId:)` 로 `todo_N_id` 를 훑어 찾는다.

### 2. `toggleCompletion` 은 목표 상태를 모른다

`pending_syncs` 의 `"7:true"` 는 "완료로 만들어라"이지 "뒤집어라"가 아니다.
기존 코드는 값을 파싱해 놓고 쓰지 않은 채 `toggleCompletion` 을 불렀다.
이미 완료된 할 일이면 **미완료로 되돌아간다.**

→ 반영 전에 현재 상태를 읽어 같으면 건너뛴다. 못 찾으면 건드리지 않는다.

### 3. 진행률은 오늘 항목일 때만 올린다

`todo_completed_count` / `todo_total_count` 는 Flutter 가 **오늘 기준**으로 센 값이다.
미래 일정을 완료했다고 완료 수를 올리면 `3/2` 가 나온다.

→ `todo_N_group == "today"` 일 때만, 그것도 `min(..., total)` 로 올린다.

## 검증 계획

| 대상 | 방법 | 자동 |
| --- | --- | --- |
| `parsePendingSyncs` | `flutter test` | ✅ |
| `WidgetSlotStore` | `cat WidgetSlotStore.swift checks.swift \| swift -` + 변이 검증 | ✅ |
| Swift 컴파일 | `flutter build ios --profile` | ✅ |
| 전체 회귀 | `flutter analyze` / `flutter test` | ✅ |
| **탭 → 완료 → 사라짐** | 실기기 | ❌ |
| **앱 재진입 시 DB 반영** | 실기기 | ❌ |

마지막 둘은 사용자 확인이 필요하다. 리뷰 문서에 명시한다.

## 하지 않는 것

- 위젯에서 Supabase 직접 PATCH (방향 문서 결정 1 참조)
- 완료 → 미완료 되돌리기
- `TodoCalendarWidget` 의 완료 처리
- Android 쪽 정리 (성공 PATCH 후 로컬 DB 미갱신 문제는 별도 티켓감)
