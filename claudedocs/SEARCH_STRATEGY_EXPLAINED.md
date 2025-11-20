# 검색 전략 설명 (Search Strategy Explanation)

## 문제: 지명 검색은 되는데 주소 검색이 안되는 이유

### 원인

**Naver Local Search API는 지명(장소명) 검색만 지원합니다.**

- ✅ **지원**: "스타벅스", "카페", "병원", "편의점" 등 업체명/장소명
- ❌ **미지원**: "서울시 중구 세종대로 124" 등 주소

### 테스트 결과

```bash
# 지명 검색 - 성공
curl -X POST 'http://localhost:3000/search' \
  -H 'Content-Type: application/json' \
  -d '{"query":"스타벅스","display":5}'
# → 결과: 5개의 스타벅스 매장 반환

# 주소 검색 - 실패
curl -X POST 'http://localhost:3000/search' \
  -H 'Content-Type: application/json' \
  -d '{"query":"서울시 중구 세종대로 124","display":5}'
# → 결과: items: [] (빈 배열)
```

## 해결 방법: 다단계 검색 전략

모바일 앱([location_service.dart](../lib/core/services/location_service.dart:362-417))과 동일한 **5단계 검색 전략** 구현:

### 웹 구현 (3단계)

**파일**: [naver_map_bridge.js](../web/naver_map_bridge.js:162-277)

```javascript
window.searchNaverPlaces = async function(query) {
  // Strategy 1: Naver Local Search (지명 검색)
  let results = await searchNaverLocalAPI(query);
  if (results.length > 0) return results;

  // Strategy 2: Google Geocoding (주소 검색)
  results = await searchGoogleGeocoding(query);
  if (results.length > 0) return results;

  // Strategy 3: First word only (복합 검색 - "카페 강남" → "카페")
  const firstWord = query.split(/\s+/)[0];
  if (firstWord !== query) {
    results = await searchNaverLocalAPI(firstWord);
    if (results.length > 0) return results;
  }

  return []; // No results found
};
```

### 전략별 상세 설명

#### Strategy 1: Naver Local Search API (via Proxy)

**목적**: 장소명/업체명 검색
**대상**: "스타벅스", "카페", "편의점", "병원" 등

**동작**:
1. 프록시 서버(`http://localhost:3000/search`)로 요청
2. 프록시가 Naver API 호출
3. 결과를 WGS84 좌표로 변환
4. HTML 태그 제거 후 반환

**예시**:
```javascript
// 입력: "스타벅스"
// 출력: [
//   {
//     name: "스타벅스 한국프레스센터점",
//     address: "서울특별시 중구 세종대로 124 (태평로1가)",
//     latitude: 37.5672475,
//     longitude: 126.9780493,
//     category: "카페,디저트>카페"
//   },
//   ...
// ]
```

#### Strategy 2: Google Geocoding API

**목적**: 주소 → 좌표 변환
**대상**: "서울시 중구 세종대로 124", "강남구 테헤란로 152" 등

**동작**:
1. Google Maps Geocoder 사용
2. 주소를 좌표로 변환
3. `formatted_address`를 name과 address로 사용

**예시**:
```javascript
// 입력: "서울시 중구 세종대로 124"
// 출력: [
//   {
//     name: "대한민국 서울특별시 중구 세종대로 124",
//     address: "대한민국 서울특별시 중구 세종대로 124",
//     roadAddress: "대한민국 서울특별시 중구 세종대로 124",
//     latitude: 37.5672,
//     longitude: 126.9780,
//     category: "street_address"
//   }
// ]
```

**중요**: Google Geocoding은 **청구 계정이 필요하지 않습니다**. Maps JavaScript API만 로드되면 사용 가능합니다.

#### Strategy 3: First Word Only

**목적**: 복합 검색어에서 주요 키워드 추출
**대상**: "카페 강남", "스타벅스 서울역" 등

**동작**:
1. 공백으로 검색어 분리
2. 첫 단어만 추출
3. Naver Local Search로 재검색

**예시**:
```javascript
// 입력: "카페 강남"
// → 첫 단어: "카페"
// → Naver Local Search: "카페"
// 출력: 카페 검색 결과 반환
```

## 모바일 구현 (5단계)

**파일**: [lib/core/services/location_service.dart](../lib/core/services/location_service.dart:362-417)

모바일은 더 많은 전략을 사용합니다:

1. **Strategy 1**: Exact query (정확한 검색어)
2. **Strategy 2**: Retry with slight delay (약간의 지연 후 재시도)
3. **Strategy 3**: First word only (첫 단어만)
4. **Strategy 4**: Without numbers (숫자 제거)
5. **Strategy 5**: Geocoding API (주소 검색)

웹에서는 Strategy 2와 4를 제외하고 핵심 전략만 구현했습니다.

## API 비교

### Naver Local Search API

| 항목 | 내용 |
|------|------|
| **용도** | 업체/장소 검색 |
| **예시** | 스타벅스, 카페, 병원 |
| **엔드포인트** | `https://openapi.naver.com/v1/search/local.json` |
| **인증** | `X-Naver-Client-Id`, `X-Naver-Client-Secret` |
| **좌표** | Naver 포맷 (× 10,000,000) → WGS84 변환 필요 |
| **CORS** | ❌ 브라우저 직접 호출 불가 → 프록시 필요 |
| **주소 검색** | ❌ 지원 안함 |

### Google Geocoding API

| 항목 | 내용 |
|------|------|
| **용도** | 주소 → 좌표 변환 |
| **예시** | 서울시 중구 세종대로 124 |
| **방법** | `google.maps.Geocoder()` |
| **인증** | Maps JavaScript API 키 필요 |
| **좌표** | WGS84 (변환 불필요) |
| **CORS** | ✅ 브라우저 직접 호출 가능 |
| **지명 검색** | ⚠️ 제한적 (주소 위주) |

## 검색 흐름도

```
사용자 입력: "스타벅스"
    ↓
Strategy 1: Naver Local Search
    ↓
✅ 결과 있음 → 반환

---

사용자 입력: "서울시 중구 세종대로 124"
    ↓
Strategy 1: Naver Local Search
    ↓
❌ 결과 없음
    ↓
Strategy 2: Google Geocoding
    ↓
✅ 결과 있음 → 반환

---

사용자 입력: "카페 강남"
    ↓
Strategy 1: Naver Local Search ("카페 강남")
    ↓
❌ 결과 없음
    ↓
Strategy 2: Google Geocoding ("카페 강남")
    ↓
❌ 결과 없음
    ↓
Strategy 3: First word ("카페")
    ↓
✅ 결과 있음 → 반환
```

## 테스트

### 테스트 페이지

**파일**: `/tmp/test_address_search.html`

5가지 테스트 케이스:
1. **지명 검색**: "스타벅스" (Strategy 1 사용)
2. **주소 검색**: "서울시 중구 세종대로 124" (Strategy 2 사용)
3. **주소 검색**: "강남구 테헤란로 152" (Strategy 2 사용)
4. **복합 검색**: "카페 강남" (Strategy 3 사용)
5. **전체 주소**: "서울특별시 종로구 사직로 161" (Strategy 2 사용)

**실행**:
```bash
open /tmp/test_address_search.html
```

### 수동 테스트

```bash
# 프록시 서버 실행 확인
lsof -i :3000

# Flutter 웹 앱 실행
cd /Users/leechanhee/todo_app
flutter run -d chrome

# 테스트 순서:
# 1. 할 일 추가 버튼 클릭
# 2. 위치 선택 필드 클릭
# 3. 검색 테스트:
#    - "스타벅스" 입력 → Naver 결과 확인
#    - "서울시 중구 세종대로 124" 입력 → Google 결과 확인
#    - "카페 강남" 입력 → 첫 단어 검색 결과 확인
```

## 프로덕션 고려사항

### 1. API 키 보안

현재는 개발용으로 API 키가 코드에 노출되어 있습니다:
- Google API 키: `web/index.html`에 하드코딩
- Naver API 키: 프록시 서버에 하드코딩

**프로덕션 해결책**:
```javascript
// 환경 변수 사용
const GOOGLE_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const NAVER_CLIENT_ID = process.env.NAVER_CLIENT_ID;
```

### 2. 프록시 서버 배포

로컬 프록시(`localhost:3000`)는 개발용입니다.

**프로덕션 옵션**:

1. **Supabase Edge Function** (권장)
   ```bash
   supabase functions deploy naver-search
   ```
   - 파일: `supabase/functions/naver-search/index.ts`
   - 비용: Free tier 포함
   - 자동 HTTPS, 스케일링

2. **Vercel Serverless Function**
   ```bash
   vercel deploy
   ```

3. **AWS Lambda / Google Cloud Functions**

**배포 후 수정**:
```javascript
// naver_map_bridge.js
const response = await fetch('https://your-project.supabase.co/functions/v1/naver-search', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer <anon-key>'
  },
  body: JSON.stringify({ query: query, display: 10 })
});
```

### 3. Google Geocoding 할당량

Google Geocoding API는 무료 할당량이 있습니다:
- **무료**: 월 $200 크레딧 (약 28,500 요청)
- **초과 시**: $5.00 per 1,000 requests

**최적화 방법**:
- 검색 결과 캐싱 (LocalStorage/IndexedDB)
- Debounce 적용 (사용자 입력 완료 후 검색)
- Naver API 우선 사용 (Strategy 1 먼저)

### 4. 에러 핸들링

현재는 빈 배열(`[]`)을 반환합니다. 프로덕션에서는 더 명확한 피드백이 필요합니다:

```javascript
// 개선된 에러 처리
try {
  results = await searchNaverLocalAPI(query);
  if (results.length > 0) return { source: 'naver', results };
} catch (error) {
  console.error('Naver API error:', error);
  // Continue to next strategy instead of failing
}

try {
  results = await searchGoogleGeocoding(query);
  if (results.length > 0) return { source: 'google', results };
} catch (error) {
  console.error('Google API error:', error);
  // Show user-friendly message
  throw new Error('검색 서비스가 일시적으로 사용 불가합니다.');
}
```

## 요약

### 문제
- Naver Local Search API는 **지명만 검색**
- **주소 검색은 지원 안함**

### 해결책
- **3단계 검색 전략** 구현:
  1. Naver Local Search (지명)
  2. Google Geocoding (주소)
  3. First word only (복합)

### 결과
- ✅ 지명 검색: "스타벅스" → Naver API
- ✅ 주소 검색: "서울시 중구 세종대로 124" → Google Geocoding
- ✅ 복합 검색: "카페 강남" → 첫 단어로 Naver API

### 파일
- [web/naver_map_bridge.js](../web/naver_map_bridge.js:162-277) - 검색 로직
- [naver_proxy.py](../naver_proxy.py) - 프록시 서버
- [lib/core/services/location_service.dart](../lib/core/services/location_service.dart:362-417) - 모바일 참조

### 테스트
- `/tmp/test_address_search.html` - 테스트 페이지
- `flutter run -d chrome` - 실제 앱 테스트
