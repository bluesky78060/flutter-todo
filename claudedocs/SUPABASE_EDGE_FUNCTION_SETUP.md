# Supabase Edge Function 배포 가이드

**목적**: 네이버 Local Search API CORS 우회를 위한 서버리스 프록시 배포

---

## 📋 필요한 이유

네이버 Local Search API는 **브라우저에서 직접 호출 시 CORS 에러**가 발생합니다:
```
Access to fetch at 'https://openapi.naver.com/v1/search/local.json'
has been blocked by CORS policy
```

**해결 방법**: Supabase Edge Function을 프록시로 사용
- 웹 브라우저 → Supabase Edge Function → 네이버 API
- Edge Function은 서버 사이드이므로 CORS 제한 없음

---

## 🚀 1단계: Supabase CLI 설치

### Mac (Homebrew)
```bash
brew install supabase/tap/supabase
```

### Windows
```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### Linux
```bash
brew install supabase/tap/supabase
```

또는 공식 문서: https://supabase.com/docs/guides/cli

---

## 🔐 2단계: Supabase 로그인

```bash
# Supabase에 로그인
supabase login

# 브라우저가 열리면 인증
```

---

## 📦 3단계: Edge Function 배포

프로젝트 루트 디렉토리에서:

```bash
# Edge Function 배포
supabase functions deploy naver-search --project-ref <your-project-ref>
```

**프로젝트 ref 찾기**:
1. [Supabase Dashboard](https://app.supabase.com/) 접속
2. 프로젝트 선택
3. Settings → General → Reference ID 복사

**예시**:
```bash
supabase functions deploy naver-search --project-ref bulwfcsyqgsvmbadhlye
```

---

## 🔑 4단계: 환경변수 설정

Edge Function에 네이버 API 키를 환경변수로 설정:

```bash
# 환경변수 설정
supabase secrets set \
  NAVER_LOCAL_SEARCH_CLIENT_ID=quSL_7O8Nb5bh6hK4Kj2 \
  NAVER_LOCAL_SEARCH_CLIENT_SECRET=raJroLJaYw \
  --project-ref <your-project-ref>
```

**또는 Supabase Dashboard에서**:
1. [Supabase Dashboard](https://app.supabase.com/) 접속
2. 프로젝트 선택
3. **Edge Functions** → **naver-search** 선택
4. **Secrets** 탭
5. 다음 변수 추가:
   - `NAVER_LOCAL_SEARCH_CLIENT_ID`: `quSL_7O8Nb5bh6hK4Kj2`
   - `NAVER_LOCAL_SEARCH_CLIENT_SECRET`: `raJroLJaYw`

---

## ✅ 5단계: 배포 확인

### 로컬 테스트 (선택사항)

```bash
# 로컬에서 Edge Function 실행
supabase functions serve naver-search --env-file .env

# 다른 터미널에서 테스트
curl -X POST http://localhost:54321/functions/v1/naver-search \
  -H "Content-Type: application/json" \
  -d '{"query":"스타벅스","display":5}'
```

### 배포된 Function 테스트

```bash
# SUPABASE_URL 확인
cat .env | grep SUPABASE_URL

# 또는 Supabase Dashboard → Settings → API → Project URL

# 테스트 요청
curl -X POST https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-search \
  -H "Content-Type: application/json" \
  -d '{"query":"스타벅스","display":5}'
```

**예상 응답**:
```json
{
  "items": [
    {
      "title": "스타벅스 강남점",
      "address": "서울특별시 강남구...",
      "mapx": "127123456",
      "mapy": "37123456"
    }
  ]
}
```

---

## 🔧 6단계: Flutter 앱 재배포

Edge Function이 배포되면 Flutter 웹 앱을 다시 배포:

```bash
# 1. 환경변수 주입
./scripts/inject_env.sh

# 2. 웹 빌드
flutter build web --release --base-href /flutter-todo/

# 3. Git push (GitHub Actions가 자동 배포)
git push origin main
```

---

## 🧪 테스트

배포 후 웹 앱에서:

1. https://bluesky78060.github.io/flutter-todo/ 접속
2. "새 할 일" 버튼 클릭
3. 장소 입력 필드에서 "스타벅스" 검색
4. 브라우저 콘솔(F12) 확인:
   - ✅ `🔍 Calling Supabase Edge Function: https://...`
   - ✅ `✅ Found 10 results`
   - ❌ CORS 에러 없음

---

## 🔍 트러블슈팅

### 문제 1: "Function not found"
```
Error: Function naver-search not found
```

**해결**:
```bash
# Function 목록 확인
supabase functions list --project-ref <your-project-ref>

# 다시 배포
supabase functions deploy naver-search --project-ref <your-project-ref>
```

### 문제 2: "API credentials not configured"
```json
{"error": "API credentials not configured", "items": []}
```

**해결**:
- Supabase Dashboard → Edge Functions → naver-search → Secrets 확인
- `NAVER_LOCAL_SEARCH_CLIENT_ID`, `NAVER_LOCAL_SEARCH_CLIENT_SECRET` 설정 확인

### 문제 3: Edge Function 로그 확인

```bash
# 실시간 로그 보기
supabase functions logs naver-search --project-ref <your-project-ref>

# 또는 Dashboard에서:
# Edge Functions → naver-search → Logs 탭
```

### 문제 4: CORS 에러 여전히 발생
```
Access-Control-Allow-Origin 에러
```

**원인**: Edge Function이 아직 배포되지 않았거나, Flutter 앱이 이전 버전 캐시 사용 중

**해결**:
1. Edge Function 배포 확인 (curl 테스트)
2. 브라우저 강력 새로고침 (Cmd+Shift+R 또는 Ctrl+Shift+R)
3. 시크릿 모드에서 테스트

---

## 📊 비용

Supabase Edge Functions 무료 티어:
- **500,000 invocations/month** 무료
- 초과 시: $0.000002 per invocation

일반적인 Todo 앱 사용량으로는 **완전 무료** 범위 내에서 사용 가능합니다.

---

## 🔗 관련 문서

- [Supabase Edge Functions 공식 문서](https://supabase.com/docs/guides/functions)
- [SEARCH_FIX_DEPLOYMENT.md](SEARCH_FIX_DEPLOYMENT.md) - 검색 기능 배포 수정 내역
- [Naver Local Search API 문서](https://developers.naver.com/docs/serviceapi/search/local/local.md)

---

## 📝 Edge Function 코드 위치

- **Function 코드**: `supabase/functions/naver-search/index.ts`
- **Flutter 호출 코드**: `lib/core/services/location_service.dart` (393-418번 줄)
- **환경변수 주입**: `web/index.template.html`, `scripts/inject_env.sh`

---

**마지막 업데이트**: 2025-11-23
**상태**: ⚠️ Edge Function 배포 대기 중
**다음 단계**: Supabase CLI로 Edge Function 배포
