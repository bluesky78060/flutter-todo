# Google Places API (New) 설정 가이드

## 오류 메시지
```
INVALID_ARGUMENT: Error in searchByText: API key not valid. Please pass a valid API key.
```

## 원인
**Places API (new)**는 기존 Places API와는 **별도의 API**입니다. 활성화가 필요합니다.

## 해결 방법

### 1. Google Cloud Console 접속
[https://console.cloud.google.com/](https://console.cloud.google.com/)

### 2. Places API (new) 활성화

1. 왼쪽 메뉴: **"API 및 서비스" → "라이브러리"**
2. 검색창에 **"Places API (new)"** 입력
   - ⚠️ 주의: **"Places API"**가 아니라 **"Places API (new)"**를 찾아야 함!
3. **"Places API (new)"** 클릭
4. **"사용 설정"** 버튼 클릭

### 3. API 키 제한사항 확인

1. **"API 및 서비스" → "사용자 인증 정보"**
2. API 키 `AIzaSyCXsP-ZD0AucY0rDZIfEEjHGnOEVs2H80` 클릭
3. **"API 제한사항"** 섹션 확인:
   - **"키를 제한하지 않음"** 선택 (테스트용 권장)
   - 또는 다음 API들을 명시적으로 허용:
     - ✅ Maps JavaScript API
     - ✅ **Places API (new)** ← 중요!
     - ✅ Geocoding API
     - ✅ Places API (기존)

### 4. 대시보드에서 확인

**"API 및 서비스" → "대시보드"**에서 다음이 모두 활성화되어 있어야 합니다:

- ✅ Maps JavaScript API
- ✅ **Places API (new)**
- ✅ Places API
- ✅ Geocoding API

## 두 가지 Places API 비교

| 특징 | Places API (기존) | Places API (new) |
|------|------------------|------------------|
| **이름** | Places API | Places API (new) |
| **상태** | Legacy (유지보수만) | 권장 |
| **메서드** | PlacesService.textSearch() | Place.searchByText() |
| **사용 방법** | 바로 사용 가능 | google.maps.importLibrary() 필요 |
| **새 고객** | 2025년 3월 1일부터 불가 | 가능 |

## 활성화 후 대기 시간

- API 활성화 후 **최대 5분** 대기
- 브라우저 캐시 삭제 (Cmd+Shift+Delete)
- 시크릿 모드에서 테스트

## 문제가 계속되면

### 옵션 1: 새 API 키 생성

1. **"사용자 인증 정보" → "사용자 인증 정보 만들기" → "API 키"**
2. 생성된 키 복사
3. 다음 파일들 업데이트:
   - `/Users/leechanhee/todo_app/android/local.properties`
   - `/Users/leechanhee/todo_app/web/index.html`
   - `/Users/leechanhee/todo_app/web/naver_map_bridge.js`

### 옵션 2: 기존 API로 돌아가기 (AutocompleteService 사용)

Places API (new)가 작동하지 않으면 기존 AutocompleteService를 사용:

```javascript
// 기존 방식
const service = new google.maps.places.AutocompleteService();
service.getPlacePredictions({
  input: query,
  language: 'ko',
  componentRestrictions: { country: 'kr' }
}, callback);
```

## 현재 상태 확인

Google Cloud Console → "API 및 서비스" → "대시보드"에서:

```
✅ 활성화됨: Maps JavaScript API
✅ 활성화됨: Places API (new)  ← 이것이 보여야 함!
✅ 활성화됨: Geocoding API
```

만약 **"Places API (new)"**가 목록에 없다면 아직 활성화되지 않은 것입니다.
