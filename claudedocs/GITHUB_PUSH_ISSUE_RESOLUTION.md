# GitHub Push 문제 해결 가이드

**날짜**: 2025-11-13
**문제**: HTTP 400 에러로 인한 push 실패
**상태**: 해결 방안 제시

## 발생한 문제

### 에러 메시지
```bash
$ git push origin main
error: RPC failed; HTTP 400 curl 22 The requested URL returned error: 400
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
Everything up-to-date
```

### 현재 상태
```
Branch: main
Commits ahead: 8
Files changed: 50 files
Changes: +8,323 insertions, -900 deletions
```

### 커밋 목록
```
1a04326 docs: Add local CI workflow validation report
ae2215d docs: Add comprehensive testing and CI/CD completion report
aef2602 test: Add TodoActions integration tests (137 total tests)
d0582f0 ci: Add GitHub Actions workflows for automated testing
ecf73ca feat: Integrate recurring todo dialogs into UI workflows
ba231c9 feat: Add recurring todo series management dialogs and logic
ebae2dd feat: Implement recurring todo instance auto-generation
78def8f feat: Integrate recurrence settings into todo form dialog
```

## 원인 분석

### 1. Push 크기 제한
- GitHub HTTP push 제한: 일반적으로 ~100MB
- 현재 변경사항: 50개 파일, 8,323 라인 추가
- 테스트 파일 포함 (mock 파일 등 큰 파일)

### 2. 네트워크 문제
- 큰 커밋 8개를 한 번에 push
- 네트워크 타임아웃 가능성

### 3. GitHub API 제한
- Rate limiting
- Repository 설정 문제

## 해결 방안

### 방안 1: SSH 사용 (권장) ⭐

HTTP 대신 SSH를 사용하면 더 큰 파일을 push할 수 있습니다.

```bash
# 1. SSH 키 생성 (이미 있으면 Skip)
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. SSH 키를 GitHub에 추가
# - ~/.ssh/id_ed25519.pub 내용 복사
# - GitHub → Settings → SSH and GPG keys → New SSH key

# 3. Remote URL을 SSH로 변경
git remote set-url origin git@github.com:bluesky78060/flutter-todo.git

# 4. Push 재시도
git push origin main
```

### 방안 2: 커밋을 나누어 Push

```bash
# 각 커밋을 개별적으로 push
for commit in $(git log origin/main..main --reverse --format="%H"); do
  git push origin $commit:main
  sleep 2  # 네트워크 안정성을 위한 지연
done
```

### 방안 3: HTTP 버퍼 크기 증가

```bash
# HTTP buffer 크기 증가
git config http.postBuffer 524288000  # 500MB

# 압축 레벨 조정
git config core.compression 0

# Push 재시도
git push origin main
```

### 방안 4: Fetch 후 Fast-Forward

```bash
# 1. 최신 상태 fetch
git fetch origin

# 2. Origin과 비교
git log origin/main..main

# 3. Fast-forward push
git push --force-with-lease origin main
```

**⚠️ 주의**: `--force-with-lease`는 안전하지만 신중하게 사용

### 방안 5: GitHub CLI 사용

```bash
# GitHub CLI 설치 (macOS)
brew install gh

# 인증
gh auth login

# Repository 확인
gh repo view bluesky78060/flutter-todo

# Force push (최후 수단)
gh repo sync
```

## 즉시 실행 가능한 해결책

### Step 1: SSH 설정 확인

```bash
# SSH 키 존재 여부 확인
ls -la ~/.ssh/id_*.pub

# 있으면 내용 출력
cat ~/.ssh/id_ed25519.pub
```

### Step 2: SSH Remote 설정

```bash
# 현재 remote 확인
git remote -v

# SSH로 변경
git remote set-url origin git@github.com:bluesky78060/flutter-todo.git

# 확인
git remote -v
```

### Step 3: SSH Push 시도

```bash
# SSH로 push
git push origin main

# 성공 시 Actions 탭 확인
# https://github.com/bluesky78060/flutter-todo/actions
```

## 대체 워크플로우

Push가 계속 실패하는 경우, GitHub 웹 인터페이스를 사용할 수 있습니다:

### 옵션 A: GitHub Desktop

```bash
# GitHub Desktop 사용
# 1. GitHub Desktop 설치
# 2. Repository를 GitHub Desktop에서 열기
# 3. "Push origin" 버튼 클릭
```

### 옵션 B: 새 Branch로 PR

```bash
# 1. 새 브랜치 생성
git checkout -b push/ci-cd-setup

# 2. 브랜치 push (성공률 높음)
git push origin push/ci-cd-setup

# 3. GitHub에서 PR 생성
# 4. PR merge하면 main에 반영
```

## 현재 시점에서의 권장사항

### 즉시 실행: SSH 설정

```bash
# 1. Remote를 SSH로 변경
git remote set-url origin git@github.com:bluesky78060/flutter-todo.git

# 2. Push
git push origin main

# 3. 실패 시 다음 단계로
```

### Plan B: 새 브랜치로 Push

```bash
# 1. 새 브랜치
git checkout -b feature/ci-cd-and-testing

# 2. Push
git push origin feature/ci-cd-and-testing

# 3. GitHub에서 PR 생성
# 4. Merge
```

### Plan C: 로컬에서 CI 계속 실행

이미 로컬에서 CI 워크플로우가 검증되었으므로:

```bash
# 로컬에서 CI 실행 스크립트 생성
cat > .ci-local.sh << 'EOF'
#!/bin/bash
echo "=== Running Local CI ==="
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --coverage test/unit/ test/widget/ test/integration/
echo "=== CI Complete ==="
EOF

chmod +x .ci-local.sh
./.ci-local.sh
```

## GitHub Actions는 어떻게 되나요?

### Push가 성공하면:

1. **자동 실행**: `.github/workflows/flutter_test.yml` 자동 실행
2. **결과 확인**: Actions 탭에서 실시간 로그 확인
3. **커버리지**: Codecov 업로드 및 리포트 생성

### Push가 실패하면:

- **로컬 CI**: 이미 검증 완료 ✅
- **품질 보증**: 137 tests passing ✅
- **GitHub Actions**: Push 성공 시점에 자동 실행

## 다음 단계

### 1. SSH 설정 (가장 효과적)

```bash
git remote set-url origin git@github.com:bluesky78060/flutter-todo.git
git push origin main
```

### 2. 성공 시

- GitHub Actions 확인: https://github.com/bluesky78060/flutter-todo/actions
- 커버리지 리포트 다운로드
- Branch Protection Rules 설정

### 3. 실패 시

- Plan B 실행 (새 브랜치)
- 또는 사용자에게 상황 설명

## 결론

**문제**: HTTP 400 에러로 push 실패
**원인**: 큰 변경사항 (50 files, +8,323 lines)
**해결**: SSH 사용 또는 브랜치 push

**현재 상태**:
- ✅ CI/CD 파이프라인 구축 완료
- ✅ 137개 테스트 작성 완료
- ✅ 로컬 CI 검증 완료
- ⏳ GitHub push 대기 중

**다음 액션**: SSH remote 설정 후 push 재시도

---

**작성**: Claude Code
**날짜**: 2025-11-13
**상태**: 해결 방안 제시 완료
