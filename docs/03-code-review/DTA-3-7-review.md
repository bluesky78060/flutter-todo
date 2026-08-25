# DTA-3-7 코드 리뷰 — iOS 위젯에서 완료 처리

일자: 2026-08-23

## 검증 레인

| 레인 | 수행자 | 결과 |
| --- | --- | --- |
| 1. 품질·정합성 | `code-reviewer` (Claude Opus, 별도 컨텍스트) | **REQUEST CHANGES** — CRITICAL 1, MAJOR 3, MINOR 5, SUGGESTION 4 |
| 2. 다른 계열 모델 독립 리뷰 | **수행 못 함** (아래) | — |
| 3. 적대적 검증 | `critic` (Claude Opus) + 변이 검증 12건 | **REJECT** — CRITICAL 3, MAJOR 4 |

### 레인 2 — 실행하지 못했습니다

규칙이 요구하는 "다른 계열 모델의 독립 diff 리뷰"를 이번에도 수행하지 못했습니다.
글로벌 규칙의 지시대로 **기록을 믿지 않고 그 자리에서 한 줄 프롬프트를 실제로
실행해** 확인했습니다.

```
$ codex exec --skip-git-repo-check "Reply with exactly: CODEX_OK"
ERROR: You've hit your usage limit. … try again at Sep 10th, 2026 4:57 PM.

$ gemini -p "Reply with exactly: GEMINI_OK"
This account requires setting the GOOGLE_CLOUD_PROJECT or GOOGLE_CLOUD_PROJECT_ID env var.

$ which antigravity
antigravity not found
```

대신 같은 Claude 계열의 별도 컨텍스트 두 레인(`code-reviewer`, `critic`)으로
채웠습니다. **모델 다양성이라는 원래 목적은 충족되지 않았습니다.** 이 한계를
숨기지 않고 적어 둡니다.

## 두 레인이 독립적으로 같은 결론에 도달한 항목

이것이 이번 리뷰의 핵심입니다. 서로 다른 프롬프트를 받은 두 리뷰어가
**같은 세 지점**을 짚었습니다.

### 1. [CRITICAL] `setAppGroupId` 를 부르지 않아 첫 진입에서 아무 일도 안 일어남

`home_widget` 의 `groupId` 는 **프로세스 단위 static** 이고, nil 이면
`getWidgetData` 가 `FlutterError(-7)` 을 던집니다
(`home_widget-0.8.1/ios/Classes/HomeWidgetPlugin.swift`).

저장소의 다른 iOS 접근 지점 10곳은 전부 먼저 부르는데 `WidgetSyncService` 만
빠져 있었습니다. `widget_service` 가 먼저 부를 것이라 기대할 수도 없습니다 —
그쪽은 `setAppGroupId` 전에 Supabase 왕복을 먼저 하므로 이 코드가 앞섭니다.

**게다가 그 실패 catch 가 `pending_syncs` 를 지우고 있었습니다.**
읽지 못한 것뿐인데 큐를 날리는 코드였습니다.

→ 두 메서드 첫머리에 `setAppGroupId`. 읽기 실패 catch 에서 **큐를 지우지 않음**.

### 2. [CRITICAL] 큐를 무조건 비워 완료가 영구히 사라짐

`processPendingSyncs` 는 루프가 끝나면 성공·실패를 가리지 않고
`saveWidgetData('pending_syncs', '')` 를 했습니다.

여기에 제가 몰랐던 사실이 겹칩니다 — **`todoRepositoryProvider` 는
`SupabaseTodoRepository` 를 돌려줍니다.** Drift 용 `TodoRepositoryImpl` 은
todo 경로 어디에도 등록되어 있지 않습니다(`database_provider.dart:59-62`,
직접 확인). 즉 이 반영은 **네트워크 호출**입니다.

재현: 비행기 모드에서 위젯 완료 → 위젯에서 사라짐 → 앱 진입 → 반영 실패 →
큐 삭제 → 네트워크 복구 후 **할 일이 미완료로 되살아남**. 사용자는 완료했다고
믿고 있습니다.

위젯 지연 큐를 두는 이유 자체가 "그 순간 네트워크를 못 쓴다"이므로,
**실패 확률이 가장 높은 경로에서 손실이 나는** 구조였습니다.

→ 성공한 것만 큐에서 빼고 나머지는 남깁니다. 무한 증가를 막는 상한(50)을 둡니다.

### 3. [CRITICAL/MAJOR] `decideSync` 가드는 제가 주장한 일을 하지 못함

이것이 가장 아픈 지적입니다. 저는 **"완료가 되돌아가는 것을 막는다"** 고 적고
테스트까지 붙였는데, `critic` 이 그 주장을 깼습니다.

가드는 `getTodoById` 로 읽고 `toggleCompletion` 으로 씁니다. 그 사이에
왕복이 **세 번** 더 있습니다 — `todo_providers.dart:614` 의 재조회,
`supabase_datasource.dart` 의 read-modify-write. 그 창 안에서 값이 바뀌면
여전히 뒤집힙니다. 가드는 창을 좁혔을 뿐 닫지 못했습니다.

→ **근본 원인은 `toggleCompletion` 이 뒤집기라는 것**이었습니다.
`setCompletion(id, value)` 를 저장소 계층에 추가해 **멱등 set** 으로 바꿨습니다.
읽지 않고 목표 값을 그대로 씁니다. TOCTOU 자체가 사라지고, 재시도에도 안전합니다.

`decideSync` 는 이제 불필요해져 **삭제**했습니다. 테스트도 큐 수명 관리
(`formatPendingSyncs`, `capPendingSyncs`)로 교체했습니다.

## 그 외 반영한 지적

| 심각도 | 내용 | 조치 |
| --- | --- | --- |
| MAJOR | `TodoItem.id` 의 `?? "\(i)"` 폴백 — `todo_3_id` 가 없으면 슬롯 번호 `"3"` 이 id 가 되어 **진짜 id 3번 할 일이 완료됨** | 폴백 제거. id 없는 슬롯은 목록에서 제외 |
| MAJOR | 콜드 스타트에서 `_updateHomeWidget()` 과 `_processPendingSyncs()` 가 서로를 기다리지 않아, 반영 전 데이터가 슬롯 60개를 덮어써 **완료한 항목이 되살아남** | 순서대로 실행 (`_syncWidgetOnStartup`) |
| MAJOR | `updateWidget()` 이 조회 실패를 빈 목록으로 바꿔 **오프라인에서 홈 위젯이 통째로 비워짐** | 실패 시 위젯 쓰기를 건너뜀 |
| MAJOR | 재진입 가드 없음 — initState 지연 콜백과 `resumed` 가 겹치면 이중 반영 | `_inFlight` 가드 |
| MAJOR | 탭 영역이 글리프 크기(16~18pt) — HIG 최소 44pt 미달. 빗나가면 **위젯 전체의 앱 열기**로 떨어져 기능 목적과 정반대 | 44pt + `contentShape`, 음수 여백으로 배치 유지 |
| MINOR | `checkAndRefreshWidget` 이 갱신 성공 전에 플래그를 내림 → 실패 시 위젯이 영영 안 채워짐 | 성공 후 내림 |
| SUGGESTION | 한 갱신 안에서 `DateTime.now()` 를 4번 따로 읽어 자정 경계에 어긋남 | `now` 하나로 통일 |
| — | 주석이 "로컬 DB 와 Supabase 양쪽에 반영" 이라 적혀 있으나 **로컬 DB 쓰기는 없음** | Dart·Swift 주석 정정 |

## 반영하지 않은 지적과 그 이유

**`critic` MINOR-4 — "overdue 항목을 완료해도 진행률이 안 오른다"**
지적이 맞지 않습니다. `_getTodayTodos` 는 `dueDate == today` 만 세므로
overdue 는 애초에 분모에 없습니다. 올리면 `completed > total` 이 됩니다.
현재 동작이 옳습니다.

## 별도 티켓으로 넘기는 것

| 내용 | 근거 |
| --- | --- |
| 슬롯 10칸을 **단일 JSON 키**로 저장 | 앱·익스텐션의 60키 비원자적 쓰기 경쟁을 구조적으로 없앤다. 지금은 `pending_widget_refresh` 로 자가 치유되므로 급하지 않다 |
| Swift 테스트 타깃 | `WidgetSlotStore` 를 테스트 가능하게 만들어 놓고 CI 에는 못 붙였다. 지금은 `swift` 단독 실행으로 검증한다 |
| `NotFoundFailure` 분리 | 삭제된 할 일과 네트워크 실패를 구분하면 큐에서 확실히 뺄 수 있다. 지금은 구분 불가라 남기는 쪽을 택했다 |
| `parseDateString` 이 새 라벨(`"8/25 09:00"`, `"~8/25"`)을 못 읽음 | 두 위젯 모두 `displayTime` 을 우선하므로 현재 무해. 나중에 `dueDate` 기반 필터를 넣으면 조용히 깨진다 |
| Android `WidgetActionReceiver` 정합성 | PATCH 성공 시 큐를 지워 **로컬 DB 가 갱신되지 않음**. 진행률에 클램프도 없어 `3/2` 가 가능 |
| 위젯 익스텐션 `IPHONEOS_DEPLOYMENT_TARGET = 26.2` | 두 리뷰어 모두 의도적 선택인지 물었다. 사실이면 위젯을 쓸 수 있는 기기가 매우 적다 |

## 자동 검증 결과 (2라운드 후)

| 항목 | 결과 |
| --- | --- |
| `flutter analyze` | **error 0 / warning 0** |
| `flutter test` | **242 통과 / 4 skip** |
| `flutter build ios --profile` | ✅ (출력 확인 — **exit code 만 보면 안 됨**, 1라운드에서 실패인데 0을 반환했다) |
| Swift `WidgetSlotStore` 단독 실행 | 16/16 |
| **변이 검증** | **12건 전부 사망** (Swift 4, Dart 8) |

변이 상세:

| 변이 | 사망 |
| --- | --- |
| Swift `hasPrefix(id)` — 접두사 경계 제거 | 1 |
| Swift `append(nil)` 제거 — 길이 미보존 | 2 |
| Swift 범위 가드 제거 | 크래시 (exit 133) |
| Swift 중복 제거 삭제 | 1 |
| Dart 첫 항목이 이기게 | 2 |
| Dart 콜론 개수 가드 제거 | 1 |
| Dart `true` 판정 완화 | 1 |
| Dart 미발견 가드 제거 *(1라운드, 해당 코드 삭제됨)* | 1 |
| Dart 동일상태 가드 제거 *(1라운드, 해당 코드 삭제됨)* | 2 |
| Dart 최신 대신 오래된 것 남김 | 1 |
| Dart 상한 조기반환 제거 | 1 |
| Dart 구분자 `:` → `=` | 2 |

## 자동 검증이 닿지 않는 범위

실기기 확인 기록: [DTA-3-7-manual-check.md](DTA-3-7-manual-check.md)

사용자가 확인한 것은 **"위젯에서 완료가 된다"** 까지입니다(2026-08-23).
2라운드 수정은 그 확인 **이후**에 들어갔으므로 재확인이 필요합니다.
특히 탭 영역 44pt 변경은 레이아웃에 영향을 줄 수 있습니다.

## 판정

두 레인의 지적 중 CRITICAL 3건, MAJOR 4건을 모두 반영했습니다.
남은 것은 별도 티켓으로 분리했습니다.
