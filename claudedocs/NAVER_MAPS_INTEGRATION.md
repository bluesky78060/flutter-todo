# Naver Maps 통합 완료 보고서

## 📋 프로젝트 개요
Flutter Todo 앱에서 **모바일(Android/iOS)**과 **웹** 모두에서 Naver Maps를 사용하도록 통합했습니다. 한국 주소 지원 개선을 위해 Naver Maps SDK와 Reverse Geocoding API를 통합했습니다.

## 🔧 주요 변경 사항

### 1. **Naver Cloud Platform 설정**

#### 모바일 (Android/iOS)
- ✅ NCP 애플리케이션 생성 (Client ID: `rzx12utf2x`)
- ✅ Maps API 활성화
- ✅ **Reverse Geocoding API 활성화**
- ✅ Android 패키지명 등록:
  - `kr.bluesky.dodo` (프로덕션)
  - `kr.bluesky.dodo.debug` (디버그)

#### 웹
- ✅ NCP 애플리케이션 생성 (Client ID: `quSL_7O8Nb5bh6hK4Kj2`)
- ✅ Web Dynamic Map 서비스 활성화
- ✅ Local Search API 활성화 (장소 검색)
- ✅ Web 서비스 URL 등록:
  - `https://bluesky78060.github.io`
  - `http://localhost`
  - `http://127.0.0.1`

### 2. **Android 빌드 설정**

#### `android/local.properties`
```properties
NAVER_CLIENT_ID=rzx12utf2x
NAVER_CLIENT_SECRET=TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C
```

#### `android/app/build.gradle.kts`
```kotlin
// Naver Maps Client ID from local.properties
val naverClientId = localProperties.getProperty("NAVER_CLIENT_ID") ?: ""
manifestPlaceholders["NAVER_CLIENT_ID"] = naverClientId
```

#### `android/app/src/main/AndroidManifest.xml`
```xml
<!-- Naver Map SDK Client ID -->
<meta-data
    android:name="com.naver.maps.map.NCP_KEY_ID"
    android:value="${NAVER_CLIENT_ID}" />
```

### 3. **Flutter 코드 변경**

#### `lib/main.dart` - SDK 초기화 (⚠️ 가장 중요!)
```dart
// Android에서는 새로운 초기화 방법 사용 - 이것이 핵심!
if (!kIsWeb) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android: 새로운 초기화 방법 (필수!)
    await FlutterNaverMap().init(clientId: 'rzx12utf2x');
    logger.d('✅ Naver Maps SDK initialized for Android with FlutterNaverMap().init()');
  } else {
    // iOS: 기존 방법 유지
    await NaverMapSdk.instance.initialize(clientId: 'rzx12utf2x');
    logger.d('✅ Naver Maps SDK initialized for iOS');
  }
}
// 웹은 index.html에서 SDK 로드
```

#### `web/index.html` - 웹 SDK 로드
```html
<!-- Naver Maps SDK -->
<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpClientId=quSL_7O8Nb5bh6hK4Kj2&submodules=geocoder"></script>

<!-- Naver Maps Bridge -->
<script src="naver_map_bridge.js"></script>
```

#### `web/naver_map_bridge.js` - JavaScript 브리지
```javascript
// Naver Maps 초기화 및 제어를 위한 JavaScript 브리지
window.initNaverMap = function(divId, centerLat, centerLng, zoom) { ... }
window.searchNaverPlaces = async function(query) { ... }
window.updateNaverMapOverlays = function(divId, lat, lng, radiusMeters) { ... }
window.moveNaverMapCamera = function(divId, lat, lng) { ... }
```

#### `lib/presentation/widgets/naver_map_platform.web.dart` - 웹용 Dart 브리지
```dart
/// Web-specific Naver Map widget using JavaScript SDK
class NaverMapWeb extends StatefulWidget {
  // JavaScript 브리지를 통해 Naver Maps 제어

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    // Naver Local Search API 호출
    final jsPromise = js.context.callMethod('searchNaverPlaces', [query]);
    // ...
  }
}
```

#### `lib/presentation/widgets/location_picker_dialog.dart`
```dart
NaverMap(
  options: NaverMapViewOptions(
    initialCameraPosition: NCameraPosition(
      target: initialPosition,
      zoom: 15.0,
    ),
    locationButtonEnable: false,
    indoorEnable: true,
    consumeSymbolTapEvents: false,
  ),
  onMapReady: (controller) async {
    _mapController = controller;
    if (_selectedLocation != null) {
      await _updateMapOverlays();
    }
  },
  onMapTapped: _onMapTap,
)
```

#### `lib/core/services/location_service.dart` - Reverse Geocoding
```dart
// Naver Reverse Geocoding API
final url = Uri.parse(
  'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc'
  '?coords=$longitude,$latitude'
  '&orders=roadaddr,addr'
  '&output=json',
);

final response = await http.get(
  url,
  headers: {
    'X-NCP-APIGW-API-KEY-ID': 'rzx12utf2x',
    'X-NCP-APIGW-API-KEY': 'TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C',
  },
);
```

## 🐛 문제 해결 과정

### 1. **401 Unauthorized 에러**
- **원인**: 여러 설정 문제가 복합적으로 발생
  1. 잘못된 meta-data 이름 사용
  2. Geocoding API 대신 Reverse Geocoding API 필요
  3. **Android 전용 초기화 메서드 필요** ⭐

- **해결책**:
  1. `com.naver.maps.map.NCP_KEY_ID` 사용 (NCP 콘솔 키)
  2. Reverse Geocoding API 활성화
  3. **Android용 `FlutterNaverMap().init()` 메서드 사용** (가장 중요!)

### 2. **디버그 빌드 인증 실패**
- **원인**: 디버그 패키지명 미등록
- **해결책**: NCP 콘솔에 `kr.bluesky.dodo.debug` 추가 등록

### 3. **최종 해결 - 커뮤니티 솔루션**
- **출처**: [NCloud Forums Topic 468](https://www.ncloud-forums.com/topic/468/)
- **핵심 해결책**: Android 환경에서는 `NaverMapSdk.instance.initialize()` 대신 `FlutterNaverMap().init()` 메서드 사용
- **이유**: Flutter Naver Map 패키지의 최신 버전에서 Android 초기화 방식이 변경됨

## 📱 구현된 기능

### 위치 선택 다이얼로그
- ✅ Naver Maps 표시
- ✅ 지도 탭으로 위치 선택
- ✅ 현재 위치 가져오기
- ✅ 반경 조절 (50m ~ 1000m)
- ✅ 선택 위치에 마커 표시
- ✅ 반경 원형 오버레이 표시
- ✅ 한국어 주소 자동 입력

### Reverse Geocoding
- ✅ Naver API 우선 사용 (한국 주소 정확도 높음)
- ✅ Google Geocoding 폴백 지원
- ✅ 주소 자동 완성

### 주소 검색 (2025-11-19 추가)

#### 모바일 (Android/iOS)
- ✅ **5단계 검색 전략 구현**:
  1. Naver Local Search - 일반 키워드 검색 (장소명, 업체명)
  2. Naver Local Search - 주소 형식 검색 (지번, 도로명 주소)
  3. Naver Local Search - 유사 주소 검색 (공백 제거)
  4. **Google Geocoding** - 주소 → 좌표 변환 (일반 주소)
  5. Naver Reverse Geocoding - 좌표 → 한국어 주소 변환
- ✅ **Naver Geocoding API 401 에러 해결**:
  - 원인: Naver Geocoding API는 서버 사이드 전용
  - 해결: Google Geocoding API (`geocoding` 패키지) 사용으로 전환
  - 장점: 모바일 앱에서 직접 호출 가능, API 키 불필요

#### 웹 (2025-11-20 추가)
- ✅ **Naver Local Search API + Geocoding API 통합**:
  1. Naver Local Search API - 장소명/업체명 검색
  2. Naver Geocoding API - 주소 → 좌표 변환
  3. WGS84 좌표 변환 (Naver 좌표계 → 표준 좌표계)
- ✅ **웹 전용 JavaScript 브리지 구현**:
  - `searchNaverPlaces()` - Naver API 직접 호출
  - CORS 문제 없이 클라이언트 사이드 API 사용

## 📊 테스트 결과

### 모바일
- ✅ Android 디바이스 정상 작동 확인 (Samsung Galaxy A31)
- ✅ 401 에러 해결
- ✅ 지도 렌더링 성공
- ✅ 위치 선택 기능 정상
- ✅ Reverse Geocoding 정상
- ✅ 5단계 검색 전략 정상 작동

### 웹
- ✅ Chrome 브라우저 정상 작동
- ✅ Naver Maps SDK 로드 성공
- ✅ JavaScript 브리지 정상 작동
- ✅ 장소 검색 API 연동 완료
- ✅ 지도 클릭/마커/반경 표시 정상

## 🚀 향후 개선 사항
1. iOS 빌드 테스트 및 검증
2. 위치 기반 알림 기능 구현
3. 저장된 위치 목록 관리 기능
4. 오프라인 지도 캐싱 고려
5. 웹 버전 성능 최적화
6. 웹 검색 결과 정확도 개선

## 📝 주의 사항

### ⚠️ 가장 중요한 포인트
1. **Android 초기화**: 반드시 `FlutterNaverMap().init()` 사용
   - `NaverMapSdk.instance.initialize()`는 Android에서 작동하지 않음!

2. **API 서비스 선택**: Reverse Geocoding API 활성화 필요
   - Geocoding API가 아닌 Reverse Geocoding API 선택

3. **패키지명 등록**: 디버그/릴리즈 패키지명 모두 NCP 등록 필요
   - `kr.bluesky.dodo`
   - `kr.bluesky.dodo.debug`

### 기타 고려사항
- **API 키 보안**: 프로덕션 빌드 시 API 키 난독화 고려
- **API 할당량**: Naver API 일일 할당량 모니터링 필요
- **플랫폼별 분기**: iOS와 Android 초기화 방법 다름

## 🔗 참고 자료
- [Flutter Naver Map 패키지](https://pub.dev/packages/flutter_naver_map)
- [Naver Cloud Platform Console](https://console.ncloud.com/)
- [Naver Maps API 문서](https://api.ncloud-docs.com/docs/ai-naver-mapsmobile)
- **[문제 해결 출처 - NCloud Forums](https://www.ncloud-forums.com/topic/468/)** ⭐

## 📈 트러블슈팅 타임라인

### Phase 1: Naver Maps 통합 (2024-11-18)
1. **초기 문제 발견**: 401 Unauthorized 에러
2. **첫 번째 시도**: meta-data 이름 수정 → 실패
3. **두 번째 시도**: API 서비스 변경 (Geocoding → Reverse Geocoding) → 부분 해결
4. **세 번째 시도**: 디버그 패키지명 추가 → 여전히 실패
5. **최종 해결**: 커뮤니티 포럼에서 Android 초기화 방법 변경 발견 → **성공!** ✅

### Phase 2: 주소 검색 API 전환 (2025-11-19)
1. **문제 발견**: Naver Local Search가 주소 검색 미지원 (0 results)
2. **첫 번째 시도**: Naver Geocoding API 추가 (Strategy 5) → 401 에러
3. **원인 분석**:
   - Naver Geocoding API는 서버 사이드 전용
   - API 키와 패키지명 등록이 정확해도 모바일 앱에서 직접 호출 불가
4. **최종 해결**:
   - Google Geocoding (`geocoding` 패키지) 사용으로 전환
   - Naver Reverse Geocoding 추가로 한국어 주소 확보
   - 5단계 폴백 전략 완성 → **성공!** ✅
5. **테스트 검증**: 에뮬레이터 및 실제 디바이스 (SM A315N) 정상 작동 확인

### Phase 3: 웹 Naver Maps 통합 (2025-11-20)
1. **문제 발견**: Google Maps가 한국에서 제대로 작동하지 않음
2. **첫 번째 시도**: Google Maps JavaScript API 구현 → 사용자 피드백
3. **방향 전환**:
   - 사용자 요구사항: "구글맵은 한국에서 잘 안되, 네이버 맵으로 해줘"
   - Google Maps → Naver Maps 전환 결정
4. **구현 과정**:
   - `web/index.html`: Naver Maps SDK 로드
   - `web/naver_map_bridge.js`: JavaScript 브리지 작성
   - `naver_map_platform.web.dart`: Dart ↔ JavaScript 통신
   - 장소 검색 API 통합 (Local Search + Geocoding)
5. **최종 결과**: 웹에서 Naver Maps 정상 작동 → **성공!** ✅

---

**작업 완료일**:
- Phase 1 (Naver Maps 모바일): 2024년 11월 18일
- Phase 2 (주소 검색 모바일): 2025년 11월 19일
- Phase 3 (Naver Maps 웹): 2025년 11월 20일

**작업자**: Claude & 이찬희
**상태**: ✅ 완료 (모바일 + 웹)
**핵심 해결책 출처**:
- Phase 1: [NCloud Forums Topic 468](https://www.ncloud-forums.com/topic/468/)
- Phase 2: Google Geocoding API 전환 (`geocoding` 패키지)
- Phase 3: JavaScript 브리지 패턴 + Naver Local Search API