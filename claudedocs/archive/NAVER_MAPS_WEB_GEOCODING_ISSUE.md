# 네이버 지도 Web Geocoding API 문제 분석 및 해결 방안

## 📋 현재 상황

### 확인된 사실
1. ✅ **Client ID `rzx12utf2x`가 올바르게 설정됨** (모바일과 웹 공통 사용)
2. ✅ **NCP 콘솔에서 모든 API 활성화됨**:
   - Dynamic Map ✓
   - Geocoding ✓
   - Reverse Geocoding ✓
3. ✅ **파라미터 이름 수정 완료**: `ncpClientId` → `ncpKeyId`

### 핵심 문제 발견
**JavaScript SDK의 `geocoder` 서브모듈은 Web 환경에서 작동하지 않음!**

```javascript
// 현재 코드 (작동 안 함)
naver.maps.Service.geocode({
  query: query
}, function(status, response) {
  // 항상 빈 응답 반환
});
```

## 🔍 원인 분석

### 1. Geocoding API는 별도의 REST API
- **Dynamic Map (JavaScript SDK)**: URL 파라미터로 인증 (`ncpKeyId=rzx12utf2x`)
- **Geocoding API (REST)**: **HTTP 헤더**로 인증
  ```
  X-NCP-APIGW-API-KEY-ID: <Client ID>
  X-NCP-APIGW-API-KEY: <Client Secret>
  ```

### 2. JavaScript SDK의 geocoder는 Web에서 제한적
- `naver.maps.Service.geocode()`는 내부적으로 REST API 호출
- **Web 환경에서는 CORS 문제**로 제대로 작동하지 않음
- 모바일 앱에서는 정상 작동

### 3. Web에서 REST API 직접 호출 불가
```javascript
// 브라우저에서는 CORS 에러 발생
fetch('https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode', {
  headers: {
    'X-NCP-APIGW-API-KEY-ID': 'rzx12utf2x',
    'X-NCP-APIGW-API-KEY': '<secret>'
  }
});
// ❌ CORS policy: No 'Access-Control-Allow-Origin' header
```

## 💡 해결 방안

### Option 1: 백엔드 프록시 서버 (권장)
**장점**: 안전하고 확실한 방법
**단점**: 추가 인프라 필요

```dart
// Flutter Web Backend (Firebase Functions, Cloud Functions 등)
Future<List<Place>> searchPlaces(String query) async {
  final response = await http.post(
    Uri.parse('https://your-backend/api/geocode'),
    body: {'query': query},
  );
  // Backend에서 Naver Geocoding API 호출
}
```

**Backend 코드 예시** (Node.js):
```javascript
// Firebase Functions or any backend
app.post('/api/geocode', async (req, res) => {
  const { query } = req.body;

  const response = await fetch(
    `https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=${query}`,
    {
      headers: {
        'X-NCP-APIGW-API-KEY-ID': process.env.NAVER_CLIENT_ID,
        'X-NCP-APIGW-API-KEY': process.env.NAVER_CLIENT_SECRET
      }
    }
  );

  const data = await response.json();
  res.json(data);
});
```

### Option 2: Naver Local Search API 사용 (현재 구현)
**장점**: 추가 백엔드 불필요, 장소 검색에 적합
**단점**: 주소 검색은 제한적

현재 [naver_map_bridge.js](../web/naver_map_bridge.js)의 `searchLocalAPI()` 함수가 이미 구현되어 있습니다:
```javascript
// 이미 구현됨 (197-258줄)
async function searchLocalAPI(query) {
  const response = await fetch(
    `https://openapi.naver.com/v1/search/local.json?query=${query}`,
    {
      headers: {
        'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2', // ⚠️ 이 부분 확인 필요
        'X-Naver-Client-Secret': 'raJroLJaYw'
      }
    }
  );
}
```

**⚠️ 주의**: 현재 Local Search API에 사용 중인 Client ID (`quSL_7O8Nb5bh6hK4Kj2`)가 유효한지 확인 필요.

### Option 3: JavaScript SDK의 geocoder 완전히 제거
**현재 코드 변경 사항**:
1. `searchGeocodingAPI()` 함수 제거 (260-301줄)
2. Local Search API만 사용
3. Web에서는 장소 이름 검색에만 집중

## 🎯 권장 해결 방법

### 단기 (즉시 적용 가능)
1. **JavaScript SDK의 geocoder 사용 중단**
2. **Naver Local Search API만 사용**
3. Web에서는 "장소 이름" 검색에 집중 (예: "스타벅스", "서울시청")
4. "주소" 검색은 모바일 앱에서만 지원

### 장기 (추가 개발 필요)
1. **백엔드 프록시 서버 구축** (Firebase Functions 등)
2. Flutter Web에서 백엔드 API 호출
3. 백엔드에서 Naver Geocoding REST API 호출
4. Web에서도 주소 검색 완벽 지원

## 📝 필요한 확인 사항

### 1. Local Search API Client ID 확인
현재 코드에 하드코딩된 Client ID:
```javascript
'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2'
'X-Naver-Client-Secret': 'raJroLJaYw'
```

**질문**: 이 Client ID가 유효한가요?
- 만약 유효하면: 그대로 사용
- 만약 무효하면: `rzx12utf2x` 같은 유효한 Client ID로 교체 필요

### 2. Web 서비스 URL 등록 확인
NCP 콘솔에서 `rzx12utf2x` Application의 **Web 서비스 URL** 섹션 확인:
- [ ] `http://localhost` 등록됨
- [ ] `http://127.0.0.1` 등록됨
- [ ] `https://bluesky78060.github.io` 등록됨

**등록 방법**: [NAVER_MAPS_VERIFICATION_STEPS.md](NAVER_MAPS_VERIFICATION_STEPS.md) 참조

### 3. Geocoding API vs Local Search API 선택
- **Geocoding API**: 주소 → 좌표 (예: "서울시 종로구 세종대로 209" → 37.57, 126.98)
- **Local Search API**: 장소 이름 → 정보 (예: "스타벅스" → 여러 매장 목록)

**Web 플랫폼에서는 Local Search API만 사용 가능** (브라우저 CORS 제한)

## 🚀 즉시 적용 가능한 코드 수정

### 변경 전 (현재)
```javascript
// searchNaverPlaces()
// Strategy 1: Local Search API (정상 작동)
// Strategy 2: Geocoding API (작동 안 함 - 제거 필요)
```

### 변경 후 (권장)
```javascript
window.searchNaverPlaces = async function(query) {
  console.log(`🔍 searchNaverPlaces called: query="${query}"`);

  if (!query || query.trim().length === 0) {
    console.error('❌ Empty search query');
    return Promise.reject('Empty search query');
  }

  try {
    // Web에서는 Local Search API만 사용
    console.log('🔍 Naver Local Search API (장소 검색)');
    const results = await searchLocalAPI(query);

    if (results.length > 0) {
      console.log(`✅ Found ${results.length} results`);
      return results;
    }

    console.log('⚠️ No results found');
    return [];
  } catch (error) {
    console.error('❌ Error in search:', error);
    return Promise.reject(error.message);
  }
};

// searchGeocodingAPI() 함수 삭제
```

## 📚 참고 자료

- [Naver Local Search API 문서](https://developers.naver.com/docs/serviceapi/search/local/local.md)
- [Naver Geocoding API 문서](https://api.ncloud-docs.com/docs/ai-naver-mapsgeocoding-geocode)
- [네이버 지도 JavaScript SDK v3](https://navermaps.github.io/maps.js.ncp/docs/)
- [CORS 문제 해결 방법](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

## ✅ 다음 단계

1. **즉시**: JavaScript SDK의 geocoder 제거, Local Search API만 사용
2. **확인**: Local Search API의 Client ID 유효성 확인
3. **확인**: NCP 콘솔의 Web 서비스 URL 등록 상태 확인
4. **장기**: 백엔드 프록시 서버 구축하여 Geocoding API 완벽 지원

---

**요약**: Web 환경에서는 브라우저 CORS 제한으로 인해 Geocoding REST API를 직접 호출할 수 없습니다. 현재는 Local Search API만 사용하고, 완벽한 주소 검색이 필요하면 백엔드 프록시 서버 구축이 필요합니다.
