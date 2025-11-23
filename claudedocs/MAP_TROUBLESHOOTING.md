# 지도 표시 문제 해결 가이드

**작성일**: 2025-11-20
**배포 URL**: https://bluesky78060.github.io/flutter-todo/

---

## 🔍 문제 진단

### 1. API 키 확인

#### GitHub Actions 빌드에서 주입된 키 확인
```bash
# 로컬 빌드에서 확인
grep -E "(ncpKeyId|maps.googleapis.com)" build/web/index.html
```

**현재 상태**:
- ✅ Naver Maps Client ID: `rzx12utf2x` (정상)
- ❌ Google Maps API Key: `YOUR_NEW_GOOGLE_MAPS_API_KEY` (플레이스홀더)

### 2. 가능한 원인

#### 원인 A: Google Maps API 키가 GitHub Secrets에 올바르게 설정되지 않음
**증상**:
- 배포된 사이트에서 `YOUR_NEW_GOOGLE_MAPS_API_KEY` 그대로 표시
- Google Maps 관련 기능 작동 안 함

**해결책**:
1. [GitHub Secrets](https://github.com/bluesky78060/flutter-todo/settings/secrets/actions) 확인
2. `GOOGLE_MAPS_API_KEY` Secret이 존재하는지 확인
3. 값이 올바른 API 키인지 확인 (플레이스홀더가 아닌)

#### 원인 B: base-href 경로 문제로 스크립트 로드 실패
**증상**:
- 브라우저 콘솔에 404 에러
- `naver_map_bridge.js` 로드 실패

**확인 방법**:
```
배포 사이트 접속 → F12 → Console 탭 → 다음 에러 확인:
- Failed to load resource: naver_map_bridge.js
- 404 Not Found
```

**해결책**:
`index.template.html`에서 스크립트 경로를 절대 경로로 변경:
```html
<!-- 현재 (상대 경로) -->
<script src="naver_map_bridge.js"></script>

<!-- 수정 (절대 경로) -->
<script src="/flutter-todo/naver_map_bridge.js"></script>
```

#### 원인 C: CORS 문제
**증상**:
- 브라우저 콘솔에 CORS 에러
- Naver API 호출 실패

**확인 방법**:
```
Console 탭:
- Access to fetch at '...' from origin '...' has been blocked by CORS policy
```

**해결책**:
- Naver Cloud Platform에서 서비스 URL 등록
- `https://bluesky78060.github.io` 추가

#### 원인 D: API 키 제한 설정 문제
**증상**:
- API는 로드되지만 작동하지 않음
- 콘솔에 "API key is invalid" 또는 "RefererNotAllowedMapError"

**확인 방법**:
```
Console 탭:
- Google Maps: RefererNotAllowedMapError
- Naver Maps: 401 Unauthorized
```

**해결책**:

**Google Maps**:
1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. API 키 선택
3. Application restrictions → HTTP referrers
4. 다음 추가:
   ```
   bluesky78060.github.io/flutter-todo/*
   bluesky78060.github.io/*
   ```

**Naver Maps**:
1. [Naver Cloud Platform](https://console.ncloud.com/naver-service/application)
2. Application 선택
3. 서비스 환경 → Web Dynamic Map
4. 서비스 URL에 추가:
   ```
   https://bluesky78060.github.io
   ```

---

## 🔧 디버깅 단계

### Step 1: 브라우저 개발자 도구 확인

배포 사이트 접속 후:
```
1. F12 → Console 탭 열기
2. 페이지 새로고침
3. 에러 메시지 확인
```

**체크리스트**:
- [ ] Google Maps API 로딩 에러
- [ ] Naver Maps API 로딩 에러
- [ ] naver_map_bridge.js 404 에러
- [ ] CORS 에러
- [ ] API 키 제한 에러

### Step 2: Network 탭 확인

```
F12 → Network 탭
```

**확인 사항**:
- [ ] `maps.googleapis.com` 요청 상태 (200 OK?)
- [ ] `oapi.map.naver.com` 요청 상태 (200 OK?)
- [ ] `naver_map_bridge.js` 로드 상태
- [ ] Response Headers의 CORS 설정

### Step 3: Elements 탭으로 DOM 확인

```
F12 → Elements 탭 → <head> 확인
```

**확인 사항**:
```html
<!-- API 키가 실제 값으로 치환되었는지 -->
<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpKeyId=rzx12utf2x&..."></script>
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyC...&..."></script>
```

### Step 4: 로컬 빌드 테스트

```bash
# 환경변수 주입
./scripts/inject_env.sh

# 웹 빌드
flutter build web --release --base-href /flutter-todo/

# 로컬 서버 실행
cd build/web
python3 -m http.server 8000

# 브라우저에서 접속
http://localhost:8000/flutter-todo/
```

**확인**:
- 로컬에서 지도가 표시되는가?
- YES → GitHub Pages 설정 문제
- NO → 코드 또는 API 키 문제

---

## 🛠️ 해결 방법

### 수정 1: Google Maps API 키 업데이트

#### GitHub Secrets 업데이트
1. [Secrets 페이지](https://github.com/bluesky78060/flutter-todo/settings/secrets/actions) 접속
2. `GOOGLE_MAPS_API_KEY` 찾기
3. "Update" 클릭
4. 새 API 키 입력 (플레이스홀더 아님)
5. "Update secret" 클릭

#### 로컬 .env 파일 업데이트
```bash
# .env 파일 편집
code .env

# GOOGLE_MAPS_API_KEY 값 변경
GOOGLE_MAPS_API_KEY=AIzaSyC_YOUR_ACTUAL_KEY_HERE

# 저장 후 재빌드
./scripts/inject_env.sh
flutter build web --release --base-href /flutter-todo/
```

### 수정 2: 스크립트 경로 수정 (base-href 문제)

`web/index.template.html` 수정:

```html
<!-- Before -->
<script src="naver_map_bridge.js"></script>

<!-- After -->
<script src="naver_map_bridge.js"></script>
<!-- 또는 절대 경로 -->
<script src="/flutter-todo/naver_map_bridge.js"></script>
```

**참고**: Flutter가 자동으로 `--base-href`를 처리하므로 상대 경로로 충분할 수 있습니다.

### 수정 3: API 키 HTTP Referrer 설정

#### Google Maps
```
Google Cloud Console → API Credentials → 해당 API 키:

Application restrictions:
☑ HTTP referrers (web sites)

Website restrictions:
+ bluesky78060.github.io/*
+ bluesky78060.github.io/flutter-todo/*
+ localhost:8080/*
```

#### Naver Maps
```
Naver Cloud Platform → Application → Web Dynamic Map:

서비스 URL:
+ https://bluesky78060.github.io
+ http://localhost:8080
```

### 수정 4: 배포 후 캐시 클리어

```bash
# 새 커밋으로 배포 트리거
git commit --allow-empty -m "chore: Force redeploy to clear cache"
git push origin main

# GitHub Actions 완료 후
# 브라우저에서 Hard Refresh:
# - Windows/Linux: Ctrl + Shift + R
# - Mac: Cmd + Shift + R
```

---

## ✅ 검증 체크리스트

### 배포 전
- [ ] `.env` 파일에 실제 Google API 키 설정
- [ ] `./scripts/inject_env.sh` 실행 성공
- [ ] `build/web/index.html`에서 API 키 확인
- [ ] 로컬 테스트 (`python3 -m http.server`)

### GitHub Secrets
- [ ] `GOOGLE_MAPS_API_KEY` Secret 존재
- [ ] `NAVER_MAPS_CLIENT_ID` Secret 존재
- [ ] `NAVER_LOCAL_SEARCH_CLIENT_ID` Secret 존재
- [ ] `NAVER_LOCAL_SEARCH_CLIENT_SECRET` Secret 존재

### API 키 설정
- [ ] Google API 키 HTTP referrer 제한 설정
- [ ] Naver API 서비스 URL 등록
- [ ] API 활성화 (Maps JavaScript API, Geocoding API)

### 배포 후
- [ ] GitHub Actions 빌드 성공
- [ ] 배포 사이트 접속 가능
- [ ] 브라우저 콘솔 에러 없음
- [ ] 지도 정상 표시
- [ ] 위치 검색 기능 작동

---

## 🔗 관련 문서

- [API_KEYS_SECURITY.md](API_KEYS_SECURITY.md) - API 키 보안 가이드
- [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) - 배포 체크리스트
- [NAVER_MAPS_INTEGRATION.md](NAVER_MAPS_INTEGRATION.md) - Naver Maps 통합 가이드

---

## 📞 추가 지원

### 일반적인 에러 메시지

**"RefererNotAllowedMapError"**:
→ Google Cloud Console에서 HTTP referrer 설정 확인

**"InvalidKeyMapError"**:
→ API 키가 잘못되었거나 만료됨

**"Naver Maps 401 Unauthorized"**:
→ Naver Cloud에서 서비스 URL 등록 확인

**"naver_map_bridge.js:1 Failed to load resource: the server responded with a status of 404"**:
→ 파일이 `build/web/` 디렉토리에 복사되었는지 확인
→ `web/naver_map_bridge.js` 파일 존재 확인

---

**최종 업데이트**: 2025-11-20
**테스트 URL**: https://bluesky78060.github.io/flutter-todo/
