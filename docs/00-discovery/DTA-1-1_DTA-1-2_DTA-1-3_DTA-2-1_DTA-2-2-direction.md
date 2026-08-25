# Discovery — 앱 상태 점검 후속 정리 (DTA-1-1, DTA-1-2, DTA-1-3, DTA-2-1, DTA-2-2)

- 작성일: 2026-08-18
- 프로젝트: DoDo Todo App (Flutter) / 코드 `DTA`
- 상태: **Discovery Q&A 생략 — 사용자 명시 승인**

## 생략 근거 (중요)

본 문서는 7개 카테고리 Discovery Q&A를 **수행한 기록이 아니라, 수행하지 않았다는 기록**이다.

2026-08-18 세션에서 사용자에게 진행 방식을 질의한 결과, 선택지 중
**"Discovery 생략 승인 후 진행"** 을 명시적으로 선택했다. 사유는 본 작업 묶음이
신규 기능 설계가 아니라 **이미 관측된 정적 분석 결과와 테스트 실패를 되돌리는 정리 작업**이라
방향 탐색의 여지가 없기 때문이다.

`plan-review-guard.sh` 훅을 통과시키기 위해 수행하지 않은 문답을 지어내지 않았다.
훅이 요구하는 것은 산출물의 존재이지만, 기록의 진실성이 더 중요하다.

## 확정된 방향 (사용자 선택 기준)

사용자는 아래 4개 항목을 처리 대상으로 선택했고, 여기에 이미 발행된 DTA-1-1을 더해 5건이다.

| 티켓 | 내용 | 우선순위 |
|---|---|---|
| DTA-2-1 | `reschedule_dialog_test` 9건 실패 수정 | 1 |
| DTA-2-2 | 방치된 테스트 파일 정리 (7건 실패) | 2 |
| DTA-1-2 | 레거시 웹 API 이관 (`dart:html`/`dart:js`/`dart:js_util`) | 2 |
| DTA-1-1 | `flutter analyze` warning 15건 정리 | 3 |
| DTA-1-3 | CLAUDE.md 버전 기재 갱신 | 4 |

## 관측된 사실 (플랜의 전제)

측정 환경: Flutter 3.38.4 / Dart 3.10.3, macOS darwin-arm64, 브랜치 `bluesky78060/check-app-status` (origin/main과 동일 커밋)

1. **로컬 환경 결손 (선복구 완료)** — `.env`와 `web/index.html` 부재로 `flutter test`/`flutter build`가
   `Failed to build asset bundle`, `This project is not configured for the web`로 즉시 실패했다.
   둘 다 `.gitignore` 대상(49행, 71행)이며 CI는 secrets로 생성하므로 코드 결함이 아니다.
   `.env` 생성 + `scripts/inject_env.sh` 실행으로 복구했다.
2. **`flutter test` 전체: 126 통과 / 16 실패** — 전부 기존 실패이며 이번 환경 복구와 무관하다.
3. **CI 범위 불일치 (핵심 리스크)** — `flutter_test.yml`은 `reschedule_dialog_test.dart`를
   *"due to EasyLocalization issues in CI"* 주석과 함께 의도적으로 제외해 초록이지만,
   `coverage_threshold.yml:35`는 `flutter test --coverage test/unit/ test/widget/`를
   `|| true` 없이 실행해 그 파일을 다시 포함한다. 로컬 재현 결과 **119 통과 / 9 실패**.
   이 워크플로는 `pull_request` → main 트리거 전용이라 `gh run list` 기준 **한 번도 실행된 적이 없다**.
   즉 main으로 PR을 여는 순간 처음 돌면서 곧바로 실패한다.
4. **`flutter analyze` 141건** — error 2 (웹 전용 레거시 API), warning 15, info 124(대부분 `prefer_const_constructors`).
5. **문서 불일치** — CLAUDE.md는 `1.0.17+56`, 실제 `pubspec.yaml`은 `1.0.17+66`.

## 제약

- 동작 변경 금지: DTA-1-1은 순수 정리 작업으로 런타임 동작이 바뀌면 안 된다.
- DTA-1-2는 웹 전용 코드 경로를 건드리므로 웹 빌드 성공 확인이 필수 게이트다.
- `docs/`는 Google OAuth 검증용 정적 페이지가 있는 디렉터리다. 다만 `deploy.yml`의
  `publish_dir`은 `./build/web`이므로 본 워크플로 문서가 배포물에 섞이지는 않는다.
