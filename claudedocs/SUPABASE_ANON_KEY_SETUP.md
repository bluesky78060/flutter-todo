# Supabase Anon Key 설정 가이드

**날짜**: 2025-11-23
**문제**: 401 Unauthorized 에러로 주소 검색 실패
**원인**: SUPABASE_ANON_KEY가 .env 파일과 GitHub Secrets에 누락됨

---

## 문제 진단

### 에러 로그
```
POST https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-geocode 401 (Unauthorized)
```

### 원인 분석
1. `.env` 파일에 `SUPABASE_URL`과 `SUPABASE_ANON_KEY`가 없음
2. `web/index.html`에 빈 문자열로 주입됨:
   ```javascript
   window.ENV = {
     SUPABASE_URL: '',
     SUPABASE_ANON_KEY: ''
   };
   ```
3. Flutter 앱이 Supabase Edge Function 호출 시 인증 헤더 없이 요청
4. Supabase가 401 Unauthorized 반환

---

## 해결 방법

### 1. 로컬 개발 환경 (.env 파일)

`.env` 파일에 다음 내용 추가:

```bash
# Supabase Configuration
SUPABASE_URL=https://bulwfcsyqgsvmbadhlye.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bHdmY3N5cWdzdm1iYWRobHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA2MTczMTQsImV4cCI6MjA0NjE5MzMxNH0.y0C_KthWJNLVe-i_olxrOAV5lBHY_YoR9oOPVXjWKpA
```

**참고**: Supabase anon key는 공개 키로, 클라이언트 사이드에서 사용하도록 설계되었습니다. RLS(Row Level Security) 정책으로 데이터 접근을 제어합니다.

### 2. GitHub Actions Secrets

**GitHub Repository → Settings → Secrets and variables → Actions**에서 다음 secrets 추가:

1. `SUPABASE_URL`
   - Value: `https://bulwfcsyqgsvmbadhlye.supabase.co`

2. `SUPABASE_ANON_KEY`
   - Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bHdmY3N5cWdzdm1iYWRobHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA2MTczMTQsImV4cCI6MjA0NjE5MzMxNH0.y0C_KthWJNLVe-i_olxrOAV5lBHY_YoR9oOPVXjWKpA`

### 3. GitHub Actions 워크플로우 확인

`.github/workflows/deploy.yml` 파일에서 환경 변수 주입 부분 확인:

```yaml
- name: Inject environment variables
  env:
    GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}
    NAVER_MAPS_CLIENT_ID: ${{ secrets.NAVER_MAPS_CLIENT_ID }}
    NAVER_LOCAL_SEARCH_CLIENT_ID: ${{ secrets.NAVER_LOCAL_SEARCH_CLIENT_ID }}
    NAVER_LOCAL_SEARCH_CLIENT_SECRET: ${{ secrets.NAVER_LOCAL_SEARCH_CLIENT_SECRET }}
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
  run: |
    sed -e "s|{{GOOGLE_MAPS_API_KEY}}|${GOOGLE_MAPS_API_KEY}|g" \
        -e "s|{{NAVER_MAPS_CLIENT_ID}}|${NAVER_MAPS_CLIENT_ID}|g" \
        -e "s|{{NAVER_LOCAL_SEARCH_CLIENT_ID}}|${NAVER_LOCAL_SEARCH_CLIENT_ID}|g" \
        -e "s|{{NAVER_LOCAL_SEARCH_CLIENT_SECRET}}|${NAVER_LOCAL_SEARCH_CLIENT_SECRET}|g" \
        -e "s|{{SUPABASE_URL}}|${SUPABASE_URL}|g" \
        -e "s|{{SUPABASE_ANON_KEY}}|${SUPABASE_ANON_KEY}|g" \
        web/index.template.html > web/index.html
```

---

## Supabase Anon Key 정보

### 키 위치
Supabase Dashboard → Project Settings → API

### 키 종류
1. **anon (public) key**:
   - 클라이언트 사이드에서 사용
   - 공개 가능 (코드에 포함 가능)
   - RLS 정책으로 데이터 접근 제어

2. **service_role key**:
   - 서버 사이드에서만 사용
   - 절대 공개 금지
   - 모든 RLS 정책 우회

### 보안 고려사항
- **anon key**는 클라이언트에 노출되어도 안전 (RLS로 보호)
- **service_role key**는 절대 클라이언트에 노출 금지
- Edge Functions는 환경변수에서 Naver API 키 사용 (서버 사이드)
- 클라이언트는 Edge Functions 호출 시 anon key로 인증

---

## 테스트

### 1. 로컬 테스트

```bash
# 환경변수 주입
./scripts/inject_env.sh

# web/index.html 확인
grep -A 5 "window.ENV" web/index.html
# SUPABASE_URL과 SUPABASE_ANON_KEY가 올바르게 주입되었는지 확인

# 웹 앱 실행
flutter run -d chrome

# 브라우저 콘솔에서 확인
console.log(window.ENV.SUPABASE_URL);
console.log(window.ENV.SUPABASE_ANON_KEY);
```

### 2. Edge Function 직접 테스트

```bash
curl -X POST https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-geocode \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bHdmY3N5cWdzdm1iYWRobHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA2MTczMTQsImV4cCI6MjA0NjE5MzMxNH0.y0C_KthWJNLVe-i_olxrOAV5lBHY_YoR9oOPVXjWKpA" \
  -d '{"query":"문단길 15"}'
```

**예상 응답**:
```json
{
  "addresses": [
    {
      "roadAddress": "서울특별시 강남구 문단길 15",
      "jibunAddress": "서울특별시 강남구 논현동 123",
      "x": "127.1234567",
      "y": "37.1234567"
    }
  ]
}
```

### 3. 배포된 웹 앱 테스트

GitHub Actions가 배포 완료 후:

1. https://bluesky78060.github.io/flutter-todo/ 접속 (시크릿 모드)
2. "문단길 15" 검색
3. 브라우저 콘솔(F12) 확인:

**예상 로그**:
```
🔍 Strategy 1: Direct "문단길 15"
   Items count: 0
🔍 Strategy 2: Google Geocoding "문단길 15"
🗺️ Calling Naver Geocode Edge Function for address: "문단길 15"
🗺️ Naver Geocode API Response:
   Status: 200
   Addresses count: 1
   📍 서울특별시 강남구 문단길 15 at (37.xxx, 127.xxx)
✅ Found 1 results with Geocoding
```

---

## 관련 파일

### 수정된 파일
- `.env` - Supabase 설정 추가
- `.env.example` - 템플릿 업데이트
- `web/index.template.html` - 이미 SUPABASE_URL, SUPABASE_ANON_KEY 플레이스홀더 포함
- `scripts/inject_env.sh` - 이미 Supabase 변수 치환 로직 포함

### 관련 문서
- [ADDRESS_SEARCH_FIX.md](ADDRESS_SEARCH_FIX.md) - 주소 검색 기능 구현
- [CORS_FIX_SUMMARY.md](CORS_FIX_SUMMARY.md) - CORS 문제 해결

---

## 체크리스트

- [x] `.env`에 SUPABASE_URL, SUPABASE_ANON_KEY 추가
- [x] `.env.example` 업데이트
- [x] 로컬에서 환경변수 주입 및 빌드
- [ ] **GitHub Secrets에 SUPABASE_URL, SUPABASE_ANON_KEY 추가** ← 필수!
- [ ] **GitHub Actions 재실행으로 배포**
- [ ] **배포된 웹에서 주소 검색 테스트**

---

**현재 상태**: 로컬 빌드 완료, GitHub Secrets 설정 필요

**다음 단계**: GitHub Secrets 추가 → 코드 푸시 → Actions 자동 배포 → 테스트

**예상 소요 시간**: 5분
