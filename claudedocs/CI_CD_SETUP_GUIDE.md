# CI/CD Setup Guide

GitHub Actions를 사용한 자동화된 테스트 및 커버리지 리포팅 설정 가이드

**작성일**: 2025-11-13
**현재 테스트**: 128개
**현재 커버리지**: 17-18%

## 설정된 워크플로우

### 1. Flutter Tests Workflow (`.github/workflows/flutter_test.yml`)

**실행 시점**:
- `main` 브랜치에 push할 때
- Pull Request가 생성되거나 업데이트될 때

**주요 기능**:
- ✅ Flutter 3.24.0 설치 및 캐싱
- ✅ 의존성 설치 (`flutter pub get`)
- ✅ 코드 생성 (`build_runner`)
- ✅ 정적 분석 (`flutter analyze`)
- ✅ 테스트 실행 (unit + widget tests)
- ✅ 커버리지 리포트 생성 (lcov + HTML)
- ✅ Codecov 업로드
- ✅ PR에 커버리지 코멘트 자동 추가

**결과물**:
- `coverage/lcov.info` - 커버리지 데이터
- `coverage/html/` - HTML 리포트 (30일 보관)
- Codecov 대시보드 업데이트
- PR 코멘트에 커버리지 요약

### 2. Coverage Threshold Check (`.github/workflows/coverage_threshold.yml`)

**실행 시점**:
- Pull Request가 생성되거나 업데이트될 때

**주요 기능**:
- ✅ 최소 커버리지 임계값 검증 (15%)
- ✅ main 브랜치 대비 커버리지 변화 추적
- ✅ 커버리지 감소 경고 (0.5% 이상)
- ✅ 커버리지 증가 축하 메시지

**임계값 설정**:
```yaml
Minimum threshold: 15%
Warning decrease: -0.5%
Current baseline: 17-18%
```

## GitHub Repository 설정

### 1. Branch Protection Rules

**설정 경로**: Settings → Branches → Add rule

**권장 설정**:
```yaml
Branch name pattern: main

Require status checks to pass before merging:
  ✅ Require branches to be up to date
  Required checks:
    - test (Run Tests and Generate Coverage)
    - coverage-check (Check Coverage Threshold)

Require pull request reviews:
  ✅ Require approvals: 1
  ✅ Dismiss stale reviews when new commits are pushed

Other settings:
  ✅ Require linear history (optional)
  ✅ Include administrators (권장)
```

### 2. Codecov Integration (Optional)

**설정 방법**:
1. https://codecov.io/ 방문
2. GitHub 계정으로 로그인
3. Repository 추가
4. Codecov token을 GitHub Secrets에 추가 (선택사항)

**GitHub Secrets 설정** (Settings → Secrets and variables → Actions):
```
CODECOV_TOKEN: <your-codecov-token>
```

**참고**: Public repository는 token 없이도 작동합니다.

### 3. Actions Permissions

**설정 경로**: Settings → Actions → General

**권장 설정**:
```yaml
Actions permissions:
  ✅ Allow all actions and reusable workflows

Workflow permissions:
  ✅ Read and write permissions
  ✅ Allow GitHub Actions to create and approve pull requests
```

## 로컬에서 CI 검증

CI가 성공할지 미리 확인하는 방법:

### 전체 CI 시뮬레이션
```bash
# 1. 의존성 설치
flutter pub get

# 2. 코드 생성
dart run build_runner build --delete-conflicting-outputs

# 3. 정적 분석
flutter analyze

# 4. 테스트 실행 (커버리지 포함)
flutter test --coverage test/unit/ test/widget/

# 5. 커버리지 HTML 생성 (선택사항)
# macOS: brew install lcov
# Ubuntu: sudo apt-get install lcov
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
```

### 커버리지 임계값 검증
```bash
# 현재 커버리지 확인
lcov --summary coverage/lcov.info

# 출력 예:
# Summary coverage rate:
#   lines......: 17.8% (1400 of 7865 lines)
```

## 워크플로우 사용 예시

### Scenario 1: 새로운 기능 추가

```bash
# 1. Feature 브랜치 생성
git checkout -b feature/new-feature

# 2. 코드 작성 + 테스트 추가
# ... coding ...

# 3. 로컬에서 테스트 실행
flutter test test/unit/ test/widget/

# 4. 커밋 및 푸시
git add .
git commit -m "feat: Add new feature with tests"
git push origin feature/new-feature

# 5. GitHub에서 Pull Request 생성
# → CI가 자동 실행됨
# → 테스트 결과 및 커버리지가 PR에 코멘트로 추가됨

# 6. 모든 체크가 통과하면 Merge
```

### Scenario 2: 버그 수정

```bash
# 1. 버그 재현 테스트 작성
# test/unit/bug_reproduction_test.dart

# 2. 테스트 실패 확인
flutter test test/unit/bug_reproduction_test.dart

# 3. 버그 수정
# lib/...

# 4. 테스트 통과 확인
flutter test

# 5. PR 생성
# → CI가 자동으로 모든 테스트 실행
# → 커버리지가 유지되거나 증가했는지 확인
```

### Scenario 3: 리팩토링

```bash
# 1. 현재 테스트 모두 통과 확인
flutter test

# 2. 리팩토링 수행
# lib/...

# 3. 테스트 여전히 통과하는지 확인
flutter test

# 4. PR 생성
# → Coverage Threshold Check가 커버리지 감소 경고
# → -0.5% 이상 감소 시 경고 (but not fail)
```

## 커버리지 리포트 읽는 법

### GitHub Actions Artifacts

**위치**: Actions → 워크플로우 실행 → Artifacts

**다운로드**:
1. `coverage-report` artifact 다운로드
2. 압축 해제
3. `index.html` 열기

**리포트 구조**:
```
coverage/html/
├── index.html           # 전체 요약
├── lib/
│   ├── core/
│   │   ├── utils/
│   │   │   └── recurrence_utils.dart.gcov.html  # 100% 커버리지 ✅
│   │   └── services/
│   │       └── recurring_todo_service.dart.gcov.html  # ~90% 커버리지
│   ├── data/
│   │   └── repositories/
│   │       └── todo_repository_impl.dart.gcov.html  # ~95% 커버리지
│   └── presentation/
│       └── widgets/
│           └── custom_todo_item.dart.gcov.html  # ~95% 커버리지
```

**색상 코드**:
- 🟢 **녹색**: 테스트됨 (실행된 라인)
- 🔴 **빨간색**: 테스트 안 됨 (실행 안 된 라인)
- ⚪ **회색**: 실행 불가능 (주석, 선언 등)

### Codecov Dashboard

**URL**: https://codecov.io/gh/[username]/[repo]

**주요 메트릭**:
- **Overall Coverage**: 전체 프로젝트 커버리지
- **Diff Coverage**: PR에서 추가/변경된 코드의 커버리지
- **Trend**: 커버리지 변화 추이 그래프
- **Sunburst**: 파일별 커버리지 시각화

## 문제 해결

### 1. 워크플로우가 실행되지 않음

**원인**: Actions permissions 부족

**해결**:
```
Settings → Actions → General
→ Allow all actions and reusable workflows
```

### 2. PR 코멘트가 추가되지 않음

**원인**: Write permissions 부족

**해결**:
```
Settings → Actions → General → Workflow permissions
→ Read and write permissions 선택
→ Allow GitHub Actions to create and approve pull requests 체크
```

### 3. Codecov 업로드 실패

**원인**: Token 미설정 (private repo)

**해결**:
```
Codecov에서 token 복사
→ Settings → Secrets → Actions → New repository secret
→ Name: CODECOV_TOKEN
→ Value: <your-token>
```

### 4. 테스트가 로컬에서는 통과하지만 CI에서 실패

**원인**: 환경 차이 (Flutter 버전, 의존성 버전)

**해결**:
```bash
# 로컬에서 CI 환경 재현
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

### 5. Coverage 임계값 실패

**원인**: 새 코드에 테스트 없음

**해결**:
```bash
# 커버되지 않은 코드 확인
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 빨간색으로 표시된 라인에 대한 테스트 추가
```

## 향후 개선 사항

### 1. 추가 워크플로우
- **Build Workflow**: APK/AAB 자동 빌드
- **Lint Workflow**: 코드 스타일 검증
- **Deploy Workflow**: 자동 배포 (Play Store, TestFlight)

### 2. 고급 커버리지 설정
- **Differential Coverage**: PR에서 변경된 코드만 100% 커버리지 요구
- **Coverage Badges**: README에 커버리지 뱃지 추가
- **Slack Notifications**: 커버리지 변화 알림

### 3. 성능 최적화
- **Cache Dependencies**: Flutter SDK 및 Pub 캐시
- **Matrix Testing**: 여러 Flutter 버전 동시 테스트
- **Parallel Jobs**: 테스트 병렬 실행

## 커버리지 목표

```
Current:  [=================........................] 18% / 40%
Goal:     [========================================] 40-50%

Phase 1 (Complete): Core business logic - 100% ✅
Phase 2 (Future): Widget integration tests - Target +10-15%
Phase 3 (Future): Screen E2E tests - Target +10-15%
```

## 참고 자료

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Codecov Documentation](https://docs.codecov.com/)
- [LCOV Documentation](http://ltp.sourceforge.net/coverage/lcov.php)

---

**작성**: Claude Code
**날짜**: 2025-11-13
**상태**: CI/CD 파이프라인 구축 완료 ✅
