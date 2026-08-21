# 코드 리뷰 — DTA-1-3: CLAUDE.md 버전 기재 갱신

- 작성일: 2026-08-18
- 티켓: `DTA-1-3` (`6986f998-cd68-45dd-bafd-138967ed5dfb`)
- 변경 파일: `CLAUDE.md` (문서 전용, 런타임 영향 없음)
- 독립 리뷰어: **Codex CLI (OpenAI)** — Claude와 다른 계열 모델
- 리뷰 라운드: **3회** (반려 → 반려 → 승인)
- 최종 판정: **승인**

> `gemini` CLI는 `GOOGLE_CLOUD_PROJECT` 미설정으로 실행 불가하여 Codex로 대체했다.
> 실행하지 않은 검증은 기재하지 않았다.

## 라운드 1 — 반려 (지적 5건)

| # | 심각도 | 지적 |
|---|---|---|
| 1 | 중요 | `1.0.17+66`을 "Android/iOS 공통 기본값"이라 서술. 실제 빌드 스크립트 기본값은 다름 |
| 2 | 중요 | `Latest Uploaded to Play Store`를 단정형으로 두고 괄호로만 미검증 표기 |
| 3 | 중요 | 수동 빌드 예시에 `--build-number=66` 하드코딩 — 바로 위 "Play Console 최신 번호 먼저 확인" 규칙과 모순 |
| 4 | 보통 | 기존 "1.0.17+56 AAB 빌드 완료" 기록을 근거 없이 삭제 |
| 5 | 보통 | iOS 마지막 업로드 재확인 위치를 Play Console로 안내 (App Store Connect여야 함) |

### 지적 1 사실 검증 (오케스트레이터)

```
scripts/build_android.sh:20  DEFAULT_VERSION="1.0.10"
scripts/build_android.sh:21  DEFAULT_BUILD_NUMBER="34"
scripts/build_ios.sh:17      DEFAULT_VERSION="1.0.5"
scripts/build_ios.sh:18      DEFAULT_BUILD_NUMBER="15"
```

지적이 정확하다. `pubspec.yaml`의 `1.0.17+66`은 인자 없는 `flutter build`에만 적용되고,
`build_android.sh`를 인자 없이 실행하면 `1.0.10+34`가 빌드된다. **두 값을 혼동하면 안 된다.**

## 라운드 2 — 반려 (해소 3 / 미해소 1 / 신규 1)

- 해소: 1, 2, 5
- **신규 결함**: 지적 3을 고치며 넣은 플레이스홀더가 셸에서 유효하지 않음
  ```bash
  BUILD_NUMBER=<Play Console 확인 후 입력>   # '<'가 리다이렉션으로 파싱되어 실행 시 오류
  ```
  → 문서의 코드블록을 그대로 복사해 실행하면 깨진다. 리뷰어가 잡지 않았으면 그대로 나갔을 결함이다.
- **미해소**: 지적 4. "현재 `build/`에 산출물이 없다"는 것은
  "과거에 빌드가 완료되지 않았다"는 근거가 되지 못한다는 반박. 타당하다.
- 추가: `build/app/outputs/bundle/release/`는 "비어 있다"가 아니라 **디렉터리 자체가 존재하지 않는다**

## 라운드 3 — 승인

| 지적 | 조치 | 검증 |
|---|---|---|
| 3 (신규) | `BUILD_NUMBER=67` 예시값 + "그대로 쓰지 말 것" 주석 | `bash -n` 문법 검사 통과 |
| 4 | "과거 문서상 기록"으로 보존. 삭제하지 않음 | — |
| 추가 | "`build/app/` 디렉터리 자체가 존재하지 않아 확인 불가"로 정정 | `ls -d build/app` → No such file or directory |

`build/` 하위 실제 내용: `native_assets`, `test_cache`, `unit_test_assets`, `web` — `app`은 없다.

## 최종 변경 요약

1. `Current Version` `1.0.17+56` → `1.0.17+66` (pubspec.yaml과 일치)
2. `Latest Uploaded` → `Last Known Play Store Upload`로 격하 + 미검증 명시
3. pubspec 값과 빌드 스크립트 기본값의 차이를 명시적으로 구분
4. iOS 확인처를 App Store Connect로 정정
5. "+56 AAB 빌드 완료"를 과거 기록으로 보존하되 현재 확인 불가 사유 병기
6. 수동 빌드 예시를 변수화하고 하드코딩 번호를 예시값으로 격하
7. 3곳에 중복되던 "현재 상황" 블록을 1곳으로 통합

## 검증 결과

| 항목 | 명령 | 결과 |
|---|---|---|
| 빌드 | `flutter build web --release` | ✅ `✓ Built build/web` (39.6s) |
| 정적 분석 | `flutter analyze` | ✅ 141건 — 변경 전후 동일 (error 2 / warning 15 / info 124) |
| 단위 테스트 | `flutter test test/unit/` | ✅ 95 통과 / 0 실패 — 변경 전과 동일 |
| 셸 스니펫 | `bash -n` | ✅ 문법 유효 |

문서 전용 변경이므로 analyze/test 수치가 변하지 않는 것이 정상이며, 실제로 변하지 않았다.

## 남은 사항 (이 티켓 범위 밖)

- `Last Known Play Store Upload: 1.0.17+53`은 **여전히 미검증**이다.
  Play Console 접근 권한이 있는 사람이 확인해야 하며, 문서에도 그렇게 적었다.
