# API Keys Security Guide

## 작성일: 2025-11-20

## 개요

이 문서는 API 키를 안전하게 관리하고, GitHub에 노출되지 않도록 하는 방법을 설명합니다.

## 🚨 중요: API 키 노출 시 조치사항

### 1. 즉시 조치 (긴급)

API 키가 GitHub에 노출되었다면 **즉시 다음 조치를 취하세요**:

#### Google Maps API 키 무효화

1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials) 접속
2. 노출된 API 키 삭제
3. 새로운 API 키 발급
4. **Application restrictions** 설정:
   - HTTP referrers (web sites) 선택
   - 허용할 도메인 추가:
     - `localhost:8080/*` (개발 환경)
     - `yourdomain.com/*` (프로덕션 환경)
5. **API restrictions** 설정:
   - Restrict key 선택
   - Maps JavaScript API, Geocoding API만 활성화

#### Naver API 키 무효화

1. [Naver Cloud Console](https://console.ncloud.com/naver-service/application) 접속
2. 노출된 애플리케이션 삭제 또는 키 재발급
3. Web 서비스 URL 제한 설정

### 2. 환경변수 시스템 구성

이 프로젝트는 환경변수 기반 API 키 관리를 사용합니다.

## 환경변수 시스템 구조

```
프로젝트 루트/
├── .env                      # 실제 API 키 (절대 커밋 금지!)
├── .env.example              # API 키 템플릿 (커밋 가능)
├── web/
│   ├── index.html            # 생성된 파일 (절대 커밋 금지!)
│   └── index.template.html   # 템플릿 파일 (커밋 가능)
└── scripts/
    └── inject_env.sh         # 환경변수 주입 스크립트
```

## 초기 설정 방법

### 1단계: .env 파일 생성

```bash
# .env.example을 복사하여 .env 파일 생성
cp .env.example .env

# .env 파일을 편집기로 열어서 실제 API 키 입력
# 예: nano .env, vim .env, code .env
```

### 2단계: .env 파일에 실제 API 키 입력

```bash
# Google Maps API Key
GOOGLE_MAPS_API_KEY=AIzaSyC_YOUR_ACTUAL_API_KEY_HERE

# Naver Maps API Keys
NAVER_MAPS_CLIENT_ID=your_actual_naver_maps_id
NAVER_LOCAL_SEARCH_CLIENT_ID=your_actual_local_search_id
NAVER_LOCAL_SEARCH_CLIENT_SECRET=your_actual_secret
```

### 3단계: 환경변수 주입 스크립트 실행

개발 서버 실행 전에 **반드시** 스크립트를 실행하세요:

```bash
# 프로젝트 루트에서 실행
./scripts/inject_env.sh

# 성공 메시지 확인:
# 🔧 Injecting environment variables into web/index.html
# 📝 Replacing placeholders...
# ✅ Environment variables injected successfully!
```

### 4단계: Flutter 실행

```bash
# 웹 개발 서버 실행
flutter run -d chrome --web-port=8080

# 또는 빌드
flutter build web
```

## 자동화 (선택사항)

### Git Hooks 설정

`.git/hooks/pre-commit` 파일 생성:

```bash
#!/bin/bash
# Pre-commit hook to ensure index.html is not committed

if git diff --cached --name-only | grep -q "^web/index.html$"; then
    echo "❌ Error: web/index.html should not be committed!"
    echo "💡 This file contains API keys and is auto-generated."
    echo "   Only commit web/index.template.html"
    exit 1
fi

exit 0
```

실행 권한 부여:

```bash
chmod +x .git/hooks/pre-commit
```

### VS Code 작업 자동화

`.vscode/tasks.json` 추가:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Inject Environment Variables",
      "type": "shell",
      "command": "./scripts/inject_env.sh",
      "problemMatcher": []
    },
    {
      "label": "Flutter Run Web with Env",
      "type": "shell",
      "command": "./scripts/inject_env.sh && flutter run -d chrome --web-port=8080",
      "problemMatcher": [],
      "dependsOn": ["Inject Environment Variables"]
    }
  ]
}
```

## .gitignore 설정

다음 항목이 `.gitignore`에 포함되어 있는지 확인하세요:

```
# Environment files
.env
.env.local
.env.production

# Web build artifacts with secrets
web/index.html
```

## 파일별 커밋 여부

| 파일 | 커밋 여부 | 이유 |
|------|----------|------|
| `.env` | ❌ 금지 | 실제 API 키 포함 |
| `.env.example` | ✅ 필수 | 템플릿 (키 없음) |
| `web/index.html` | ❌ 금지 | 생성된 파일 (키 포함) |
| `web/index.template.html` | ✅ 필수 | 템플릿 (플레이스홀더만) |
| `scripts/inject_env.sh` | ✅ 필수 | 환경변수 주입 스크립트 |

## Git History에서 키 제거

### ⚠️ 주의사항

이 작업은 **매우 위험**하며 **force push**가 필요합니다. 팀원과 협의 후 진행하세요.

### BFG Repo-Cleaner 사용 (권장)

```bash
# 1. BFG 설치 (macOS)
brew install bfg

# 2. 저장소 클론 (미러)
git clone --mirror https://github.com/username/repo.git repo-mirror.git
cd repo-mirror.git

# 3. API 키가 포함된 파일 제거
bfg --delete-files index.html

# 4. Git history 정리
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 5. Force push
git push --force

# 6. 일반 저장소 다시 클론
cd ..
rm -rf repo-mirror.git
git clone https://github.com/username/repo.git
```

### git filter-branch 사용 (수동)

```bash
# 특정 파일을 history에서 완전히 제거
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch web/index.html" \
  --prune-empty --tag-name-filter cat -- --all

# Force push
git push origin --force --all
```

## 팀원 온보딩 가이드

새로운 팀원이 프로젝트를 시작할 때:

### 1단계: 저장소 클론

```bash
git clone https://github.com/username/repo.git
cd repo
```

### 2단계: 환경 설정

```bash
# .env 파일 생성
cp .env.example .env

# .env 파일 편집 (팀 관리자에게 실제 API 키 요청)
```

### 3단계: 환경변수 주입 및 실행

```bash
# 환경변수 주입
./scripts/inject_env.sh

# Flutter 실행
flutter run -d chrome --web-port=8080
```

## CI/CD 환경 설정

### GitHub Actions

`.github/workflows/build.yml`:

```yaml
name: Build Web

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2

    - name: Create .env file
      run: |
        echo "GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}" > .env
        echo "NAVER_MAPS_CLIENT_ID=${{ secrets.NAVER_MAPS_CLIENT_ID }}" >> .env
        echo "NAVER_LOCAL_SEARCH_CLIENT_ID=${{ secrets.NAVER_LOCAL_SEARCH_CLIENT_ID }}" >> .env
        echo "NAVER_LOCAL_SEARCH_CLIENT_SECRET=${{ secrets.NAVER_LOCAL_SEARCH_CLIENT_SECRET }}" >> .env

    - name: Inject environment variables
      run: ./scripts/inject_env.sh

    - name: Build web
      run: flutter build web --release
```

**GitHub Secrets 설정**:
1. Repository Settings → Secrets → Actions
2. 각 API 키를 Secret으로 추가

## 보안 체크리스트

- [ ] `.env` 파일이 `.gitignore`에 포함됨
- [ ] `web/index.html`이 `.gitignore`에 포함됨
- [ ] `.env.example`만 커밋됨 (실제 키 없음)
- [ ] `web/index.template.html`만 커밋됨 (플레이스홀더만)
- [ ] Google API 키에 HTTP referrer 제한 설정
- [ ] Naver API 키에 서비스 URL 제한 설정
- [ ] Pre-commit hook 설정 (선택사항)
- [ ] 팀원들에게 보안 가이드 공유

## 문제 해결

### 문제: "GOOGLE_MAPS_API_KEY not set in .env"

**해결**:
```bash
# .env 파일 존재 확인
ls -la .env

# .env 파일 내용 확인 (키가 실제로 입력되어 있는지)
cat .env

# .env.example에서 복사
cp .env.example .env
# 그 다음 실제 API 키 입력
```

### 문제: "web/index.template.html not found"

**해결**:
```bash
# 저장소 최신 상태로 pull
git pull origin main

# 템플릿 파일 확인
ls -la web/index.template.html
```

### 문제: API 키가 여전히 작동하지 않음

**해결**:
1. Google Cloud Console에서 API 활성화 확인
2. API 키 제한 설정 확인 (localhost 포함)
3. 브라우저 캐시 지우기
4. `./scripts/inject_env.sh` 재실행
5. Flutter 재시작

## 참고 자료

- [Google Cloud Console - API Keys](https://console.cloud.google.com/apis/credentials)
- [Naver Cloud Console](https://console.ncloud.com/naver-service/application)
- [Git Filter-Branch Documentation](https://git-scm.com/docs/git-filter-branch)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

---

**작성**: Claude Code Assistant
**최종 수정**: 2025-11-20
