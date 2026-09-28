# DTA-1-10 코드 리뷰 — 저장소 위생 정리

일자: 2026-09-28
대상: `.gitignore` 보강 + `android/build/reports/problems/problems-report.html` 추적 해제

## 배경

`git status` 가 도구 부산물(`.omc/`, `graft/`, `docs/.pdca-status.json` 등 21개 항목)로
덮여 진짜 변경이 안 보이는 상태였다. 그 속에 실제로 손봐야 할 것 둘이 섞여 있었다 —
삭제된 앱 아이콘과, 패키지 개명 후 남은 죽은 `MainActivity.kt`.

## 변경 내역

| # | 항목 | 처리 | diff 에 남는가 |
| --- | --- | --- | --- |
| 1 | `assets/icon/app_icon.jpg` | 복구 (`git checkout --`) | 아니오 — HEAD 와 같아짐 |
| 2 | `kr/bluesky/todo_app/MainActivity.kt` | 삭제 | 아니오 — 미추적이었음 |
| 3 | `android/build/.../problems-report.html` | `git rm --cached` | 예 (663줄 삭제) |
| 4 | `.gitignore` | 규칙 추가 | 예 |

1·2 가 diff 에 안 남는 것이 이 티켓의 검증상 약점이다. 리뷰어가 대조할 대상이 없어
원본 주장을 따로 받아 독립 재구성해야만 검증된다. 앞으로 미추적 파일을 지울 때는
티켓에 `ls`/`cat` 출력을 먼저 남긴다.

## 검증 레인

### 빌드·테스트

| 레인 | 결과 |
| --- | --- |
| `flutter build apk --debug` | exit 0, `app-debug.apk` 129.8MB (336.9s) |
| `flutter analyze` | `No issues found!` |
| `flutter test` | 267 통과 / 4 skip / 0 실패 |

죽은 `MainActivity.kt` 를 지운 뒤에도 `assembleDebug` 가 통과한 것이 그 클래스가
실제로 쓰이지 않았다는 실행 증거다.

### 1라운드 — `code-reviewer` (Opus)

CRITICAL 0 / MAJOR 0 / MINOR 2 / SUGGESTION 3. 판정 **COMMENT**(차단 없음).

네 주장 모두 독립 검증됨. 특히 `MainActivity.kt` 는 `build.gradle.kts` 의
namespace·applicationId, `AndroidManifest.xml:28` 의 `.MainActivity` 해석,
저장소 전체 `kr.bluesky.todo_app` grep 을 교차해 Android 쪽 참조 0건을 확인했다.

아이콘 복구 판단에는 내가 못 본 근거가 하나 더 있었다 — `pubspec.yaml:198` 이
`assets/icon/` 을 asset 목록에 선언하고 있어, **디렉터리가 비면 `flutter build` 가
"unable to find directory entry" 로 실패한다.** 저장소의 다른 아이콘들은 대체재가
아니라 이 jpg 에서 생성된 산출물이다.

반영한 지적:

- **MINOR-1** — `.omc/` 통짜 무시가 `.omc/skills/**` 를 삼킨다. 글로벌 CLAUDE.md 가
  이것을 "의도적 커밋 대상 예외" 로 명시한다. **gitignore 는 상위 디렉터리가 제외되면
  하위를 negation 으로 되살릴 수 없다** — `.omc/` + `!.omc/skills/` 는 동작하지 않고
  `.omc/*` + `!.omc/skills/` 여야 한다.
- **MINOR-2** — `android/.gradle/` 은 `android/.gitignore:2` 의 `/.gradle` 이 이미
  잡는 죽은 규칙이었다. 분류도 틀렸다(빌드 산출물이 아니라 데몬/캐시 상태).
- SUGGESTION 중 `graft/` → `graft/.cache/` 좁히기를 함께 반영했다. 같은 종류의
  조용한 손실 위험이고 비용이 한 줄이다.

미반영(후속): `linux/CMakeLists.txt:10` 의 `APPLICATION_ID "kr.bluesky.todo_app"` —
`MainActivity.kt` 와 같은 계열의 개명 잔해다. `linux/` 는 배포 대상이 아니라
당장 영향이 없어 이 티켓 밖에 둔다.

### 2라운드 — 수정본 재리뷰 (`code-reviewer`, Opus)

1라운드 지적을 고친 것은 리뷰어가 아니라 작성자이고, **수정본은 아무도 검토하지 않은
새 코드다.** CRITICAL 0 / MAJOR 0 / MINOR 1 / SUGGESTION 1. 판정 **COMMENT**.

1라운드 수정 두 건은 실측으로 정확함이 확인됐다(깊이 5의 `.omc/skills/**` 까지 살아나고,
무시 대상 11종은 하나도 새지 않음).

반영한 지적:

- **MINOR** — 1라운드를 고치는 과정에서 **매칭 깊이가 조용히 줄었다.** gitignore 패턴은
  내부에 슬래시가 있으면 `.gitignore` 위치에 앵커된다. 원래의 `.omc/` · `graft/` 는
  어느 깊이에서든 매칭했지만 `.omc/*` · `graft/.cache/` 는 저장소 루트만 매칭한다.
  패턴 문법의 부작용이지 의식적 선택이 아니었으므로 `**/` 를 붙여 되돌렸다.

미반영: `graft/.cache/` 를 `graft/` 로 되돌리라는 SUGGESTION(LOW). graft 가 `.cache`
밖에 쓰기 시작하면 `git status` 가 더러워지는 것은 맞다. 그러나 그쪽 실패는 **눈에
보이고**, 반대로 `graft/` 통짜 무시의 실패는 커밋해야 할 파일이 **조용히 사라지는**
것이다. 보이는 실패를 고른다. graft 의 산출 경로가 계약으로 보장되는지는 확인하지
않았다 — **재 보지 않았다.**

### 검증 방법에 대한 함정 (2라운드가 밟아 기록해 둔 것)

`git check-ignore` 단독으로는 결론이 틀린다. `.omc/skills` 디렉터리가 워킹트리에
없으면 git 이 이를 파일로 보고, 후행 슬래시가 붙은 `!.omc/skills/`(디렉터리 전용
패턴)를 적용하지 못해 **IGNORED 를 낸다.** negation 이 깨진 것이 아닌데 깨진 것처럼
보인다. gitignore 검증은 **실제 파일을 만들어 `git status -uall` 로 트리를 순회**시켜야
한다. 2라운드와 최종 확인 모두 그렇게 했다.

## 실측 — `git check-ignore` 로 확인한 것

| 경로 | 기대 | 결과 |
| --- | --- | --- |
| `.omc/skills/foo/SKILL.md` (깊이 5까지) | 커밋 가능 | 무시 안 됨 ✓ |
| `.omc/project-memory.json` · `.omc/state/**` · `.omc/sessions/**` · `.omc/plans/**` · `.omc/notepad.md` · `.omc/.hidden*` | 무시 | 무시됨 ✓ |
| 중첩 `sub/.omc/**` · `packages/app/.omc/**` | 무시 | 무시됨 ✓ |
| `graft/.cache/x.json` (중첩 포함) | 무시 | 무시됨 ✓ |
| `graft/config.toml` | 보임 | 보임 ✓ |
| `docs/00-discovery` ~ `docs/03-code-review` | 추적 유지 | 추적됨 ✓ |
| `android/build/` · `android/app/build/` | 무시 | 무시됨 ✓ |
| `android/.gradle/` | 무시 (중첩 규칙이 잡음) | `android/.gitignore:2` ✓ |

새로 무시하기로 한 경로 전부에 대해 `git ls-files` 로 추적 중인 파일이 0개임을
먼저 확인했다. **이미 추적 중인 파일을 `.gitignore` 에 넣으면 무시가 안 걸리고
조용히 남는다** — 이 티켓이 막으려던 바로 그 실패 방식이다.

## 최종 규칙

```gitignore
android/build/
android/app/build/

**/.omc/*
!**/.omc/skills/
**/graft/.cache/
docs/.bkit-memory.json
docs/.pdca-status.json
```

`!**/.omc/skills/` 는 반드시 `**/.omc/*` **뒤에** 와야 한다. 순서가 뒤집히면
조용히 동작하지 않는다.
