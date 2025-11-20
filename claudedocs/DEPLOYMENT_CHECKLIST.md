# GitHub Pages 배포 체크리스트

**작성일**: 2025-11-20
**목적**: API 키 보안 강화 후 GitHub Pages 배포 완료하기

---

## ✅ 완료된 작업

1. **환경변수 시스템 구현** (커밋: 16726a7)
   - `.env`, `.env.example` 생성
   - `web/index.template.html` 템플릿 생성
   - `scripts/inject_env.sh` 자동 주입 스크립트 생성
   - `.gitignore`에 `web/index.html` 추가
   - Git 추적에서 `web/index.html` 제거

2. **GitHub Actions 워크플로우 업데이트** (커밋: 5bbeef2)
   - 환경변수 주입 단계 추가
   - API 키 Secrets 참조 추가

3. **보안 문서 작성** (커밋: d99a170)
   - [claudedocs/API_KEYS_SECURITY.md](API_KEYS_SECURITY.md) 생성
   - GitHub Secrets 설정 가이드 추가

4. **웹 빌드 완료**
   - `build/web/` 디렉토리에 릴리스 빌드 생성
   - `--base-href /flutter-todo/` 적용

---

## 🚨 긴급 작업 (지금 바로!)

### 1. Google Maps API 키 무효화 및 재발급

**노출된 키**: `AIzaSyCkSHhBYt8VGnq7F89CKEYXhjdZl2p8qK4`

#### 1.1 노출된 키 삭제
1. [Google Cloud Console - API Credentials](https://console.cloud.google.com/apis/credentials) 접속
2. 노출된 API 키 찾기
3. **삭제** 또는 **비활성화**

#### 1.2 새 API 키 생성
1. "CREATE CREDENTIALS" → "API key" 클릭
2. 새 API 키 복사 (예: `AIzaSyC_NEW_KEY_HERE`)

#### 1.3 API 키 제한 설정 (중요!)

**Application restrictions**:
- "HTTP referrers (web sites)" 선택
- 다음 도메인 추가:
  ```
  localhost:8080/*
  127.0.0.1:8080/*
  bluesky78060.github.io/flutter-todo/*
  ```

**API restrictions**:
- "Restrict key" 선택
- 다음 API만 활성화:
  - ✅ Maps JavaScript API
  - ✅ Geocoding API
  - ✅ Places API (필요시)

#### 1.4 로컬 환경 업데이트
```bash
# .env 파일 편집
nano .env  # 또는 code .env

# GOOGLE_MAPS_API_KEY 값을 새로 발급받은 키로 교체
GOOGLE_MAPS_API_KEY=AIzaSyC_NEW_KEY_HERE

# 저장 후 환경변수 주입
./scripts/inject_env.sh

# 웹 빌드
flutter build web --release --base-href /flutter-todo/
```

---

## 🔑 GitHub Secrets 설정 (필수!)

### 2.1 GitHub 저장소 설정
1. https://github.com/bluesky78060/flutter-todo 접속
2. **Settings** → **Secrets and variables** → **Actions** 이동
3. **"New repository secret"** 클릭

### 2.2 추가할 Secrets

| Secret 이름 | 값 | 우선순위 |
|------------|-----|---------|
| `GOOGLE_MAPS_API_KEY` | 새로 발급받은 Google Maps API 키 | 🔴 **필수** |
| `NAVER_MAPS_CLIENT_ID` | `rzx12utf2x` | 🔴 **필수** |
| `NAVER_LOCAL_SEARCH_CLIENT_ID` | `quSL_7O8Nb5bh6hK4Kj2` | 🔴 **필수** |
| `NAVER_LOCAL_SEARCH_CLIENT_SECRET` | `raJroLJaYw` | 🔴 **필수** |
| `SUPABASE_URL` | (기존 값 확인) | 🟡 선택 |
| `SUPABASE_ANON_KEY` | (기존 값 확인) | 🟡 선택 |
| `SENTRY_DSN` | (선택사항) | 🟢 선택 |

### 2.3 각 Secret 추가 방법
```
1. Secret 이름 입력: GOOGLE_MAPS_API_KEY
2. Secret 값 입력: AIzaSyC_NEW_KEY_HERE
3. "Add secret" 클릭
4. 위 표의 모든 Secret에 대해 반복
```

---

## 📦 GitHub Actions 배포 트리거

Secrets 설정 완료 후:

### 3.1 자동 배포 트리거 (권장)
```bash
# 더미 커밋으로 워크플로우 트리거
git commit --allow-empty -m "chore: Trigger deployment with updated API keys"
git push origin main
```

### 3.2 수동 배포 트리거 (대안)
1. https://github.com/bluesky78060/flutter-todo/actions 접속
2. "Deploy to GitHub Pages" 워크플로우 선택
3. "Run workflow" → "Run workflow" 클릭

### 3.3 배포 상태 확인
1. **Actions 탭**에서 워크플로우 진행 상태 확인
2. ✅ 모든 단계 성공 확인:
   - Setup Flutter
   - Create .env file
   - Install dependencies
   - **Inject environment variables** ← 새로 추가된 단계
   - Build web
   - Deploy to GitHub Pages

---

## 🌐 배포 완료 후 확인

### 4.1 배포 URL 접속
**URL**: https://bluesky78060.github.io/flutter-todo/

### 4.2 기능 테스트
- [ ] 페이지 로드 확인
- [ ] Google Maps API 로딩 확인 (콘솔에 API 에러 없음)
- [ ] Naver Maps API 로딩 확인
- [ ] 위치 검색 기능 테스트
- [ ] 로그인 기능 테스트 (Supabase 연동)

### 4.3 콘솔 에러 확인
브라우저 개발자 도구 (F12) → Console 탭:
```
✅ 정상: Google Maps API loaded successfully
✅ 정상: Naver Maps SDK loaded
❌ 에러: Google Maps JavaScript API error (키 문제)
```

---

## 📋 전체 작업 플로우 요약

```mermaid
graph TD
    A[1. Google 키 무효화] --> B[2. 새 Google 키 발급]
    B --> C[3. 로컬 .env 업데이트]
    C --> D[4. GitHub Secrets 설정]
    D --> E[5. 더미 커밋 & Push]
    E --> F[6. GitHub Actions 자동 배포]
    F --> G[7. 배포 완료 확인]
    G --> H[8. 기능 테스트]
```

---

## ⚠️ 주의사항

### API 키 노출 방지
- ✅ `.env` 파일은 **절대 커밋하지 않음**
- ✅ `web/index.html`은 **절대 커밋하지 않음**
- ✅ GitHub에 푸시하기 전 `git status`로 확인
- ✅ 실수로 커밋한 경우 즉시 키 무효화

### Git History 정리 (선택사항)
현재 구현으로 **앞으로는** API 키가 커밋되지 않지만, **과거 커밋**에는 여전히 노출된 키가 남아있습니다.

Git 히스토리에서 완전히 제거하려면:
- [claudedocs/API_KEYS_SECURITY.md](API_KEYS_SECURITY.md)의 "Git History에서 키 제거" 섹션 참조
- BFG Repo-Cleaner 또는 git filter-branch 사용
- **위험**: Force push 필요, 팀원과 협의 후 진행

---

## 🔗 관련 문서

- [API_KEYS_SECURITY.md](API_KEYS_SECURITY.md) - API 키 보안 가이드
- [.github/workflows/deploy.yml](../.github/workflows/deploy.yml) - 배포 워크플로우
- [scripts/inject_env.sh](../scripts/inject_env.sh) - 환경변수 주입 스크립트

---

## 📞 문제 발생 시

### 워크플로우 빌드 실패
```bash
# 로컬에서 빌드 테스트
./scripts/inject_env.sh
flutter build web --release --base-href /flutter-todo/

# 빌드 로그 확인
cat build/web/index.html | grep -E "(ncpKeyId|maps.googleapis.com)"
```

### API 키 로딩 에러
- Google Cloud Console에서 HTTP referrer 설정 확인
- API restrictions에서 필요한 API 활성화 확인
- GitHub Secrets에 올바른 키 값 입력 확인

### Secrets 누락 에러
```
Error: Context access might be invalid: GOOGLE_MAPS_API_KEY
```
→ GitHub 저장소 Settings에서 해당 Secret 추가 필요

---

**최종 업데이트**: 2025-11-20
**커밋**: d99a170
