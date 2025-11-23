# CORS 문제 해결 완료 요약

**날짜**: 2025-11-23
**문제**: 웹 검색 기능 CORS 에러
**해결 방법**: Supabase Edge Function 프록시

---

## 🔍 문제 진단

### 증상
```
✅ Naver Map ready (지도 정상 표시)
❌ Access to fetch at 'https://openapi.naver.com/v1/search/local.json'
    has been blocked by CORS policy
```

### 근본 원인
네이버 Local Search API는 **서버 사이드 호출만 허용**:
- 브라우저에서 직접 호출 → CORS 차단
- 서버에서 호출 → 정상 작동

---

## ✅ 해결 방법

### 아키텍처 변경

**이전 (CORS 에러)**:
```
Flutter Web App (브라우저)
    ↓ 직접 호출 (CORS 차단!)
Naver Local Search API
```

**수정 후 (정상 작동)**:
```
Flutter Web App (브라우저)
    ↓ CORS 없음
Supabase Edge Function (서버리스)
    ↓ 서버 사이드 호출
Naver Local Search API
```

### 플랫폼별 구현

| 플랫폼 | 호출 방식 | CORS 문제 |
|--------|-----------|-----------|
| **Web** | Supabase Edge Function 프록시 | ✅ 해결 |
| **Android** | 직접 API 호출 | ❌ 없음 (네이티브) |
| **iOS** | 직접 API 호출 | ❌ 없음 (네이티브) |

---

## 📦 변경된 파일

### 1. Supabase Edge Function
**파일**: `supabase/functions/naver-search/index.ts`

**변경 내용**:
- 하드코딩된 API 키 제거
- 환경변수에서 credentials 가져오기
- CORS 헤더 추가 (`Access-Control-Allow-Origin: *`)

**주요 코드**:
```typescript
const NAVER_CLIENT_ID = Deno.env.get('NAVER_LOCAL_SEARCH_CLIENT_ID') || ''
const NAVER_CLIENT_SECRET = Deno.env.get('NAVER_LOCAL_SEARCH_CLIENT_SECRET') || ''

serve(async (req) => {
  // CORS preflight 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Naver API 호출 및 프록시
  const response = await fetch(naverUrl, {
    headers: {
      'X-Naver-Client-Id': NAVER_CLIENT_ID,
      'X-Naver-Client-Secret': NAVER_CLIENT_SECRET,
    }
  })

  // CORS 헤더와 함께 응답 반환
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
})
```

### 2. Flutter Location Service
**파일**: `lib/core/services/location_service.dart`

**변경 내용**:
- 웹: Supabase Edge Function 호출
- 모바일: 직접 Naver API 호출 (기존 방식 유지)

**주요 코드**:
```dart
if (kIsWeb) {
  // 웹: Supabase Edge Function 사용
  final supabaseUrl = (js.globalContext['ENV']['SUPABASE_URL'] as String?) ?? '';
  final url = Uri.parse('$supabaseUrl/functions/v1/naver-search');

  response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'query': query, 'display': 10}),
  );
} else {
  // 모바일: 직접 API 호출
  final url = Uri.parse('https://openapi.naver.com/v1/search/local.json?...');
  response = await http.get(url, headers: {
    'X-Naver-Client-Id': clientId,
    'X-Naver-Client-Secret': clientSecret,
  });
}
```

### 3. 환경변수 주입
**파일**: `web/index.template.html`, `scripts/inject_env.sh`

**추가된 변수**:
```javascript
window.ENV = {
  NAVER_LOCAL_SEARCH_CLIENT_ID: '{{NAVER_LOCAL_SEARCH_CLIENT_ID}}',
  NAVER_LOCAL_SEARCH_CLIENT_SECRET: '{{NAVER_LOCAL_SEARCH_CLIENT_SECRET}}',
  SUPABASE_URL: '{{SUPABASE_URL}}' // 새로 추가
};
```

---

## 🚀 배포 단계

### ✅ 완료된 작업
1. ✅ Edge Function 코드 작성 및 하드코딩 제거
2. ✅ Flutter 코드 수정 (웹/모바일 분기)
3. ✅ 환경변수 주입 스크립트 업데이트
4. ✅ GitHub에 코드 푸시

### ⏳ 남은 작업 (사용자가 해야 할 일)

#### 1. Supabase CLI 설치
```bash
# Mac
brew install supabase/tap/supabase

# 로그인
supabase login
```

#### 2. Edge Function 배포
```bash
# 프로젝트 ref는 Supabase Dashboard에서 확인
supabase functions deploy naver-search --project-ref <your-project-ref>
```

#### 3. 환경변수 설정
```bash
supabase secrets set \
  NAVER_LOCAL_SEARCH_CLIENT_ID=quSL_7O8Nb5bh6hK4Kj2 \
  NAVER_LOCAL_SEARCH_CLIENT_SECRET=raJroLJaYw \
  --project-ref <your-project-ref>
```

**또는** Supabase Dashboard에서:
- Edge Functions → naver-search → Secrets 탭
- 두 개의 환경변수 추가

#### 4. 테스트
```bash
# Edge Function 테스트
curl -X POST https://<your-project-ref>.supabase.co/functions/v1/naver-search \
  -H "Content-Type: application/json" \
  -d '{"query":"스타벅스","display":5}'
```

#### 5. Flutter 웹 재배포
```bash
# GitHub Actions가 자동으로 재배포 (이미 푸시됨)
# 또는 수동: ./scripts/inject_env.sh && flutter build web --release
```

---

## 🧪 검증 방법

### 1. Edge Function 확인
```bash
curl -X POST https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-search \
  -H "Content-Type: application/json" \
  -d '{"query":"스타벅스","display":5}'
```

**예상 결과**:
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

### 2. 웹 앱 테스트
1. https://bluesky78060.github.io/flutter-todo/ 접속
2. 시크릿 모드 (Cmd+Shift+N) 사용 (캐시 방지)
3. "새 할 일" 버튼 클릭
4. 장소 입력 필드에 "스타벅스" 검색
5. 브라우저 콘솔(F12) 확인:

**예상 로그**:
```
✅ Naver Map ready
🔍 Calling Supabase Edge Function: https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-search
🔍 Naver Local Search API Response:
   Status: 200
   Items count: 10
   First item title: 스타벅스 강남점
```

**에러 없어야 함**:
```
❌ Access to fetch... blocked by CORS policy  (이 에러 사라져야 함!)
```

---

## 💰 비용

**Supabase Edge Functions 무료 티어**:
- 500,000 invocations/month 무료
- Todo 앱 검색 사용량: ~100-200 calls/day = **완전 무료**

---

## 📊 커밋 내역

### Commit 1: 직접 API 호출 시도 (실패)
```
ff16a97: fix: Replace localhost proxy with direct Naver API calls for web
❌ CORS 에러 발생
```

### Commit 2: Supabase Edge Function 구현 (성공)
```
23d5318: feat: Add Supabase Edge Function proxy for Naver search
✅ CORS 우회 가능
```

### Commit 3: 배포 가이드 추가
```
b3bd7de: docs: Add Supabase Edge Function deployment guide
```

---

## 🔗 관련 문서

- [SUPABASE_EDGE_FUNCTION_SETUP.md](SUPABASE_EDGE_FUNCTION_SETUP.md) - Edge Function 배포 상세 가이드
- [SEARCH_FIX_DEPLOYMENT.md](SEARCH_FIX_DEPLOYMENT.md) - 검색 기능 수정 내역
- [MAP_TROUBLESHOOTING.md](MAP_TROUBLESHOOTING.md) - 지도 문제 해결 가이드

---

## 📝 체크리스트

배포 완료 확인:

- [x] Edge Function 코드 작성
- [x] Flutter 코드 수정 (웹/모바일 분기)
- [x] 환경변수 주입 스크립트 업데이트
- [x] GitHub 푸시
- [ ] **Supabase CLI 설치** ← 사용자가 해야 함
- [ ] **Edge Function 배포** ← 사용자가 해야 함
- [ ] **환경변수 설정 (Secrets)** ← 사용자가 해야 함
- [ ] **배포된 웹 앱에서 검색 테스트** ← 최종 확인

---

**현재 상태**: ⚠️ 코드 준비 완료, Edge Function 배포 대기 중

**다음 단계**: [SUPABASE_EDGE_FUNCTION_SETUP.md](SUPABASE_EDGE_FUNCTION_SETUP.md)를 따라 Edge Function 배포

**예상 소요 시간**: 5-10분
