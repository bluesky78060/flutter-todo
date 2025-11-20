# 모바일 네이버 지도 아키텍처 분석 (Mobile Naver Maps Architecture Analysis)

## 📋 개요 (Overview)

이 문서는 Flutter Todo 앱의 모바일 플랫폼(Android/iOS)에서 네이버 지도 및 장소 검색이 어떻게 설계되고 구현되었는지 분석합니다.

**분석 날짜**: 2025-11-20
**플랫폼**: Android, iOS (모바일 전용)
**주요 패키지**: `flutter_naver_map`, `http`, `geolocator`, `geocoding`

---

## 🏗️ 아키텍처 개요 (Architecture Overview)

### 핵심 구성 요소 (Core Components)

```
Mobile Architecture (모바일 아키텍처)
├── LocationService (위치 서비스)
│   ├── Naver Local Search API (장소 검색) ✅
│   ├── Naver Reverse Geocoding API (역지오코딩) ✅
│   ├── Google Geocoding (폴백 지오코딩) ✅
│   └── Geolocator (현재 위치, 지오펜싱)
│
├── LocationPickerDialog (위치 선택 다이얼로그)
│   ├── flutter_naver_map (Native Flutter SDK) ✅
│   ├── Map Controller (지도 컨트롤러)
│   ├── Marker & Circle Overlays (마커 및 반경 표시)
│   └── Search UI (검색 인터페이스)
│
└── flutter_naver_map SDK
    └── Native Android/iOS SDK Wrapper
```

---

## 🔑 핵심 차이점: 모바일 vs 웹 (Key Differences: Mobile vs Web)

| 항목 | 모바일 (Mobile) | 웹 (Web) |
|------|----------------|----------|
| **지도 SDK** | `flutter_naver_map` (Native SDK) | JavaScript SDK v3 (naver_map_bridge.js) |
| **장소 검색** | `LocationService._searchLocalAPI()` (HTTP) | `searchNaverPlaces()` (JavaScript) |
| **역지오코딩** | Naver Reverse Geocoding API (HTTP) | Google Geocoding (CORS 제한) |
| **좌표 변환** | 서버에서 WGS84로 변환 후 반환 | JavaScript에서 mapx/mapy 변환 |
| **CORS 제약** | ❌ 없음 (네이티브 HTTP 호출) | ✅ 있음 (브라우저 보안) |
| **Client ID** | `rzx12utf2x` (공통) | `rzx12utf2x` (공통) |
| **인증 방식** | HTTP Headers (모든 API) | URL 파라미터 (Map) + Headers (Search) |

**핵심 인사이트**: 모바일은 네이티브 HTTP 클라이언트를 사용하므로 CORS 제한이 없어 모든 Naver API를 자유롭게 호출할 수 있습니다.

---

## 📂 주요 파일 분석 (Key Files Analysis)

### 1. LocationService ([lib/core/services/location_service.dart](../lib/core/services/location_service.dart))

**역할**: 모든 위치 관련 작업의 중앙 허브

#### 1.1 장소 검색 아키텍처 (Place Search Architecture)

```dart
// 진입점 (Entry Point)
Future<List<PlaceSearchResult>> searchPlaces(String query)

// 5단계 검색 전략 (5-Stage Search Strategy)
Strategy 1: 직접 검색 (Direct Search)
  → _searchLocalAPI(query)

Strategy 2: 지역 접두사 추가 (Region Prefix)
  → _searchLocalAPI("서울 $query"), _searchLocalAPI("부산 $query"), ...
  → 조건: query에 "로", "길", "가" 포함 (주소 패턴)

Strategy 3: 상세 지역 조합 (Detailed Region Combinations)
  → _searchLocalAPI("봉화 문단길"), _searchLocalAPI("봉화군 문단길"), ...
  → 조건: 특정 주소 패턴 감지 (예: "문단길")

Strategy 4: 숫자 제거 후 검색 (Remove Numbers)
  → _searchLocalAPI(query.replaceAll(RegExp(r'\d+'), ''))

Strategy 5: Google Geocoding API (Fallback)
  → _searchGeocodingAPI(query)
  → geocoding 패키지 사용 (Google Geocoding)
```

**전략적 설계 의도**:
- 사용자가 "스타벅스", "서울시청", "문단길15" 등 다양한 형태로 검색하더라도 결과를 찾도록 설계
- Naver Local Search API가 실패해도 Google Geocoding으로 폴백
- 주소와 장소를 구분하여 최적화된 검색 전략 적용

#### 1.2 Naver Local Search API 호출 (line 420-503)

```dart
Future<List<PlaceSearchResult>> _searchLocalAPI(String query) async {
  final url = Uri.parse(
    'https://openapi.naver.com/v1/search/local.json'
    '?query=${Uri.encodeComponent(query)}'
    '&display=10'
    '&start=1'
    '&sort=random',
  );

  final response = await http.get(
    url,
    headers: {
      'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2',      // ⚠️ 주의!
      'X-Naver-Client-Secret': 'raJroLJaYw',
    },
  );

  // WGS84 좌표 변환
  final mapx = int.tryParse(item['mapx']?.toString() ?? '');
  final mapy = int.tryParse(item['mapy']?.toString() ?? '');

  if (mapx != null && mapy != null) {
    longitude = mapx / 10000000.0;  // Naver 좌표 → WGS84
    latitude = mapy / 10000000.0;
  }
}
```

**⚠️ 발견된 문제**:
- **Client ID 불일치**: 현재 `quSL_7O8Nb5bh6hK4Kj2` 사용 중
- **Web과 다른 Client ID**: Web은 `rzx12utf2x` 사용
- **Client Secret도 다름**: `raJroLJaYw` vs Web의 `TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C`

**질문**: 모바일용 Client ID (`quSL_7O8Nb5bh6hK4Kj2`)가 아직 유효한가요?
- 유효하다면: 현재 그대로 사용 가능
- 무효하다면: `rzx12utf2x`로 통일 필요

**좌표 변환 로직**:
- Naver API는 좌표를 `10^7` 배로 곱한 정수로 반환
- 예: mapx=1269780000 → 126.9780 (WGS84 경도)
- 웹과 동일한 변환 공식 사용

#### 1.3 Naver Reverse Geocoding API (line 120-253)

```dart
Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
  // 웹 플랫폼은 CORS 때문에 Google Geocoding 사용
  if (kIsWeb) {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    // ...
    return addressParts.join(', ');
  }

  // 모바일은 Naver Reverse Geocoding API 사용
  final url = Uri.parse(
    'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc'
    '?coords=$longitude,$latitude'
    '&orders=roadaddr,addr'
    '&output=json',
  );

  final response = await http.get(
    url,
    headers: {
      'X-NCP-APIGW-API-KEY-ID': 'rzx12utf2x',                    // ✅ 올바른 Client ID
      'X-NCP-APIGW-API-KEY': 'TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C',  // ✅ 올바른 Secret
    },
  );

  // Naver 주소 데이터 파싱
  final region = result['region'];
  final land = result['land'];

  // "서울 종로구 세종대로 209" 형태로 조합
  addressParts.add(region['area1']['name']);  // 서울
  addressParts.add(region['area2']['name']);  // 종로구
  addressParts.add(region['area3']['name']);  // 세종대로
  addressParts.add(land['number1']);          // 209
}
```

**핵심 차이점**:
- **모바일**: Naver Reverse Geocoding API → 정확한 한국 주소
- **웹**: Google Geocoding → CORS 제한으로 인해 Naver API 사용 불가
- **인증**: `rzx12utf2x` Client ID 사용 (웹과 동일)

**폴백 전략**:
- Naver API 실패 시 → Google Geocoding으로 자동 전환
- 두 API 모두 실패 시 → `null` 반환

#### 1.4 Google Geocoding Fallback (line 507-583)

```dart
Future<List<PlaceSearchResult>> _searchGeocodingAPI(String query) async {
  // geocoding 패키지 사용 (Google Geocoding API)
  final locations = await locationFromAddress(query);

  for (final location in locations) {
    final placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    // 주소 조합: street, locality, administrativeArea 등
    final addressParts = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ].where((part) => part != null && part.isNotEmpty).join(' ');
  }
}
```

**사용 시나리오**:
- Naver Local Search API가 결과를 찾지 못했을 때
- 5단계 검색 전략의 마지막 단계로 실행
- 주소 검색에 특화 (예: "서울시 종로구 세종대로 209")

---

### 2. LocationPickerDialog ([lib/presentation/widgets/location_picker_dialog.dart](../lib/presentation/widgets/location_picker_dialog.dart))

**역할**: 지도 기반 위치 선택 UI

#### 2.1 플랫폼별 지도 위젯 (Platform-Specific Map Widget)

```dart
// Web 플랫폼 (line 447-464)
if (kIsWeb)
  NaverMapWeb(
    initialCenter: initialPosition,
    initialZoom: 15.0,
    onMapTap: (latLng) {
      setState(() {
        _selectedLocation = latLng;
      });
      _updateAddress(latLng.latitude, latLng.longitude);
    },
    onMapReady: (webMapState) {
      _webMapState = webMapState;  // JavaScript 브리지 상태 저장
      if (_selectedLocation != null) {
        _updateWebMapOverlays();
      }
    },
  )

// Mobile 플랫폼 (line 466-485)
else
  NaverMap(
    options: NaverMapViewOptions(
      initialCameraPosition: NCameraPosition(
        target: initialPosition,
        zoom: 15.0,
      ),
      locationButtonEnable: false,
      indoorEnable: true,
    ),
    onMapReady: (controller) async {
      _mapController = controller;  // Native 컨트롤러 저장
      if (_selectedLocation != null) {
        await _updateMapOverlays();
      }
    },
    onMapTapped: _onMapTap,
  ),
```

**핵심 차이점**:
- **웹**: `NaverMapWeb` (JavaScript SDK 래퍼) → `_webMapState` 저장
- **모바일**: `NaverMap` (Native Flutter SDK) → `_mapController` 저장
- **컨트롤러 타입**: Web은 `dynamic`, Mobile은 `NaverMapController`

#### 2.2 장소 검색 로직 (line 85-154)

```dart
Future<void> _searchPlaces(String query) async {
  setState(() {
    _isSearching = true;
  });

  List<PlaceSearchResult> results;

  // 플랫폼별 검색 전략
  if (kIsWeb) {
    // Web: JavaScript 브리지 호출
    final webResults = await NaverMapWeb.searchPlaces(query);
    results = webResults.map((item) => PlaceSearchResult(
      name: item['name'] as String,
      address: item['address'] as String,
      latitude: item['latitude'] as double,
      longitude: item['longitude'] as double,
    )).toList();
  } else {
    // Mobile: LocationService 사용 (5단계 검색 전략)
    results = await _locationService.searchPlaces(query);
  }

  setState(() {
    _searchResults = results;
    _isSearching = false;
  });
}
```

**플랫폼별 검색 흐름**:
```
Mobile 검색 흐름:
User Input → _searchPlaces()
  → LocationService.searchPlaces()
    → Strategy 1-5 (Naver Local Search + Google Geocoding)
      → HTTP 직접 호출 (CORS 제한 없음)
        → PlaceSearchResult 리스트 반환

Web 검색 흐름:
User Input → _searchPlaces()
  → NaverMapWeb.searchPlaces()
    → JavaScript 브리지 (naver_map_bridge.js)
      → searchNaverPlaces() JavaScript 함수
        → Naver Local Search API (CORS 허용된 도메인에서만)
          → Promise → Dart Future 변환
            → PlaceSearchResult 리스트 반환
```

#### 2.3 마커 및 반경 표시 (Marker & Circle Overlays)

```dart
// Mobile: Native SDK Overlays (line 256-285)
Future<void> _updateMapOverlays() async {
  if (_selectedLocation == null || _mapController == null) return;

  _markers.clear();
  _circles.clear();

  // 마커 생성
  final marker = NMarker(
    id: 'selected',
    position: _selectedLocation!,
  );
  _markers.add(marker);

  // 반경 원 생성
  final circle = NCircleOverlay(
    id: 'radius',
    center: _selectedLocation!,
    radius: _radius,
    color: AppColors.primaryBlue.withOpacity(0.2),
    outlineColor: AppColors.primaryBlue,
    outlineWidth: 2,
  );
  _circles.add(circle);

  // 지도에 추가
  await _mapController!.clearOverlays();
  await _mapController!.addOverlayAll(_markers);
  await _mapController!.addOverlayAll(_circles);
}

// Web: JavaScript 브리지 호출 (line 287-293)
void _updateWebMapOverlays() {
  if (_selectedLocation == null || _webMapState == null) return;

  // JavaScript 함수 호출: updateNaverMapOverlays()
  _webMapState.updateOverlays(_selectedLocation!, _radius);
}
```

**핵심 차이점**:
- **모바일**: Native SDK의 `NMarker`, `NCircleOverlay` 클래스 사용
- **웹**: JavaScript 브리지를 통해 `updateNaverMapOverlays()` 호출
- **성능**: 모바일은 네이티브 렌더링, 웹은 HTML Canvas 렌더링

---

### 3. Platform-Specific Implementation

#### 3.1 Mobile Stub ([lib/presentation/widgets/naver_map_platform.dart](../lib/presentation/widgets/naver_map_platform.dart))

```dart
/// Stub implementation for non-web platforms
/// 웹이 아닌 플랫폼에서는 이 파일이 사용됨
class NaverMapWeb extends StatelessWidget {
  // ...

  @override
  Widget build(BuildContext context) {
    // 모바일에서는 호출되지 않음
    return const Center(
      child: Text('NaverMapWeb is only available on web platform'),
    );
  }

  /// Search for places - stub implementation
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    throw UnsupportedError('searchPlaces is only available on web platform');
  }
}
```

**역할**: 웹 전용 코드를 모바일에서 컴파일할 때 타입 호환성 제공
**실제 사용**: 모바일에서는 절대 실행되지 않음 (조건부 import 덕분)

#### 3.2 Web Implementation ([lib/presentation/widgets/naver_map_platform.web.dart](../lib/presentation/widgets/naver_map_platform.web.dart))

```dart
/// Web-specific Naver Map widget using JavaScript SDK
class NaverMapWeb extends StatefulWidget {
  // ...

  /// Search for places using Naver Local Search API
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    // JavaScript 브리지 함수 호출
    final jsPromise = js.context.callMethod('searchNaverPlaces', [query]);

    // Promise → Dart Future 변환
    final completer = Completer<List<Map<String, dynamic>>>();
    js.context['Promise'].callMethod('resolve', [jsPromise]).callMethod('then', [
      js.allowInterop((result) {
        // JavaScript 배열 → Dart List 변환
        final List<Map<String, dynamic>> results = [];
        for (var i = 0; i < result.length; i++) {
          results.add({
            'name': result[i]['name'],
            'address': result[i]['address'],
            'latitude': result[i]['latitude'],
            'longitude': result[i]['longitude'],
          });
        }
        completer.complete(results);
      }),
    ]);

    return completer.future;
  }
}
```

**핵심 기술**:
- `dart:js` 패키지로 JavaScript 함수 호출
- JavaScript Promise를 Dart Future로 변환
- `js.allowInterop`로 Dart 콜백을 JavaScript에 전달

---

## 🔍 모바일 설계의 핵심 장점 (Key Advantages of Mobile Design)

### 1. CORS 제약 없음 (No CORS Restrictions)

```
모바일 네이티브 HTTP 호출:
App → Flutter http 패키지
  → Android HttpURLConnection / iOS URLSession
    → Naver API 서버
      → 200 OK (모든 API 정상 작동)

웹 브라우저 HTTP 호출:
Browser → fetch() API
  → Preflight OPTIONS 요청
    → CORS 검증 실패 ❌
      → Access-Control-Allow-Origin 헤더 없음
```

**결과**: 모바일은 Naver의 모든 REST API를 제약 없이 호출 가능

### 2. 완전한 API 접근 (Full API Access)

| API | 모바일 | 웹 |
|-----|--------|-----|
| **Naver Local Search** | ✅ 직접 호출 가능 | ✅ CORS 허용된 도메인에서만 |
| **Naver Reverse Geocoding** | ✅ 정확한 한국 주소 | ❌ CORS 차단 (Google 폴백) |
| **Naver Geocoding** | ✅ 주소 → 좌표 변환 | ❌ CORS 차단 |
| **Naver Dynamic Map** | ✅ Native SDK | ✅ JavaScript SDK |

### 3. 5단계 검색 전략 (5-Stage Search Strategy)

모바일만의 강력한 검색 로직:
1. 직접 검색
2. 지역 접두사 추가 (17개 시도)
3. 상세 지역 조합 (특정 패턴)
4. 숫자 제거 후 검색
5. Google Geocoding 폴백

**웹의 검색 로직**:
- Strategy 1: Naver Local Search API
- Strategy 2: ~~Naver Geocoding API~~ (CORS 차단으로 제거됨)

### 4. 정확한 한국 주소 (Accurate Korean Addresses)

```
Naver Reverse Geocoding (모바일):
좌표 → "서울특별시 종로구 세종대로 209"

Google Geocoding (웹 폴백):
좌표 → "209 Sejong-daero, Jongno-gu, Seoul, South Korea"
```

---

## ⚠️ 발견된 문제점 (Issues Found)

### 1. Client ID 불일치 (Client ID Mismatch)

**현재 상태**:
```dart
// Web (naver_map_bridge.js)
'X-Naver-Client-Id': 'rzx12utf2x',
'X-Naver-Client-Secret': 'TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C',

// Mobile (location_service.dart:433)
'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2',  // ⚠️ 다른 Client ID
'X-Naver-Client-Secret': 'raJroLJaYw',

// Mobile Reverse Geocoding (location_service.dart:170)
'X-NCP-APIGW-API-KEY-ID': 'rzx12utf2x',  // ✅ 웹과 동일
'X-NCP-APIGW-API-KEY': 'TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C',
```

**문제**:
- Local Search API는 다른 Client ID 사용
- Reverse Geocoding API는 올바른 Client ID 사용
- 일관성 부족

**해결 방안**:
1. **Option A**: `quSL_7O8Nb5bh6hK4Kj2`가 유효한지 확인
   - 유효하면 → 현재 그대로 사용
   - 무효하면 → `rzx12utf2x`로 교체 필요

2. **Option B**: 모든 API를 `rzx12utf2x`로 통일 (권장)
   - 웹과 모바일 모두 동일한 Client ID 사용
   - 관리 및 디버깅 용이

### 2. 웹-모바일 검색 전략 차이 (Web-Mobile Search Strategy Gap)

**모바일**: 5단계 검색 전략 (매우 강력)
**웹**: 1단계 검색만 (Naver Local Search만)

**권장 사항**:
- 웹에서도 Strategy 4 (숫자 제거) 추가 가능
- JavaScript 브리지에 검색 전략 로직 이식

---

## 📊 비교 요약표 (Comparison Summary)

| 항목 | 모바일 (Mobile) | 웹 (Web) |
|------|----------------|----------|
| **지도 SDK** | flutter_naver_map (Native) | JavaScript SDK v3 |
| **장소 검색** | 5단계 전략 (Naver + Google) | 1단계 (Naver만) |
| **역지오코딩** | Naver API (정확한 한국 주소) | Google (CORS 제한) |
| **CORS 제약** | ❌ 없음 | ✅ 있음 |
| **Client ID** | 혼합 (`quSL_...` + `rzx12utf2x`) | 통일 (`rzx12utf2x`) |
| **검색 정확도** | 🟢 매우 높음 (다단계 전략) | 🟡 보통 (단일 전략) |
| **주소 정확도** | 🟢 높음 (Naver 한국 주소) | 🟡 보통 (Google 영문 주소) |
| **구현 복잡도** | 🟡 중간 (Native SDK) | 🔴 높음 (JavaScript 브리지) |
| **성능** | 🟢 우수 (네이티브 렌더링) | 🟡 보통 (Canvas 렌더링) |

---

## 💡 설계 인사이트 (Design Insights)

### 1. 플랫폼별 최적화 전략 (Platform-Specific Optimization)

```
모바일 설계 철학:
- Native SDK 활용 → 최고의 성능과 사용자 경험
- 모든 Naver API 접근 → 정확한 한국 주소 및 장소 검색
- 다단계 검색 전략 → 어떤 형태의 입력도 처리

웹 설계 철학:
- JavaScript SDK + 브리지 → 브라우저 호환성
- CORS 제한 회피 → 허용된 API만 사용
- Google 폴백 → Naver API 실패 시 대체
```

### 2. 검색 전략의 우수성 (Excellence of Search Strategy)

모바일의 5단계 검색 전략은 매우 잘 설계되어 있습니다:

1. **사용자 입력 유연성**: "스타벅스", "서울 스타벅스", "문단길15" 모두 처리
2. **점진적 확장**: 실패할 때마다 검색 범위 확대
3. **폴백 메커니즘**: Naver API 실패 시 Google로 자동 전환
4. **성능 최적화**: 첫 번째 성공 시 즉시 반환

### 3. 코드 재사용성 (Code Reusability)

```dart
// LocationPickerDialog.dart
if (kIsWeb) {
  results = await NaverMapWeb.searchPlaces(query);
} else {
  results = await _locationService.searchPlaces(query);
}
```

**장점**:
- 플랫폼별 구현을 추상화
- UI 코드는 플랫폼 독립적
- 플랫폼별 최적화 가능

---

## 🎯 권장 사항 (Recommendations)

### 1. Client ID 통일 (Unify Client ID)

**현재 문제**:
```dart
// location_service.dart:433
'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2',  // 다른 ID
```

**권장 변경**:
```dart
// location_service.dart:433
'X-Naver-Client-Id': 'rzx12utf2x',  // 웹과 통일
'X-Naver-Client-Secret': 'TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C',
```

**장점**:
- 웹-모바일 일관성
- 단일 NCP 프로젝트 관리
- 디버깅 및 모니터링 용이

### 2. 웹 검색 전략 강화 (Enhance Web Search Strategy)

모바일의 Strategy 4 (숫자 제거)를 웹에도 추가:

```javascript
// naver_map_bridge.js
window.searchNaverPlaces = async function(query) {
  // Strategy 1: Direct search
  let results = await searchLocalAPI(query);
  if (results.length > 0) return results;

  // Strategy 2: Remove numbers (NEW!)
  const queryWithoutNumbers = query.replace(/\d+/g, '').trim();
  if (queryWithoutNumbers !== query && queryWithoutNumbers.length > 0) {
    results = await searchLocalAPI(queryWithoutNumbers);
    if (results.length > 0) return results;
  }

  return [];
};
```

### 3. 에러 핸들링 개선 (Improve Error Handling)

```dart
// location_service.dart에 타임아웃 추가
final response = await http.get(
  url,
  headers: {...},
).timeout(
  const Duration(seconds: 10),
  onTimeout: () {
    throw TimeoutException('Naver API timeout');
  },
);
```

---

## 📝 결론 (Conclusion)

### 모바일 아키텍처의 강점 (Mobile Architecture Strengths)

1. ✅ **완전한 API 접근**: CORS 제약 없이 모든 Naver API 사용 가능
2. ✅ **정확한 한국 주소**: Naver Reverse Geocoding으로 정확한 주소 제공
3. ✅ **강력한 검색**: 5단계 검색 전략으로 다양한 입력 처리
4. ✅ **네이티브 성능**: Flutter Native SDK로 최고의 지도 성능
5. ✅ **견고한 폴백**: Naver API 실패 시 Google로 자동 전환

### 개선이 필요한 부분 (Areas for Improvement)

1. ⚠️ **Client ID 통일**: Local Search API도 `rzx12utf2x` 사용 권장
2. ⚠️ **웹-모바일 일관성**: 웹 검색 전략을 모바일 수준으로 강화
3. ⚠️ **에러 핸들링**: 타임아웃 및 재시도 로직 추가

### 최종 평가 (Final Assessment)

모바일 네이버 지도 통합은 **매우 잘 설계**되어 있으며, 웹 플랫폼의 제약(CORS)을 완벽히 회피한 우수한 아키텍처입니다.

**핵심 교훈**:
- 플랫폼 특성에 맞는 최적화 전략 (Native SDK vs JavaScript SDK)
- 다단계 폴백 메커니즘으로 높은 신뢰성 확보
- 플랫폼별 API 제약을 이해하고 적절히 대응

---

**문서 작성자**: Claude (AI Assistant)
**분석 기준 코드**: 2025-11-20 현재 코드베이스
**참조 파일**:
- [location_service.dart](../lib/core/services/location_service.dart)
- [location_picker_dialog.dart](../lib/presentation/widgets/location_picker_dialog.dart)
- [naver_map_platform.dart](../lib/presentation/widgets/naver_map_platform.dart)
- [naver_map_platform.web.dart](../lib/presentation/widgets/naver_map_platform.web.dart)
- [naver_map_bridge.js](../web/naver_map_bridge.js)
