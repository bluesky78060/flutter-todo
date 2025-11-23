# Naver Maps 배포 환경 디버깅 가이드

**작성일**: 2025-11-20
**배포 URL**: https://bluesky78060.github.io/flutter-todo/
**사용 API**: Naver Maps only (Google Maps 사용 안 함)

---

## ✅ 확인된 정상 상태

- ✅ Naver Maps Client ID: `rzx12utf2x` 정상 주입됨
- ✅ `naver_map_bridge.js` 파일 존재
- ✅ `index.html`에 Naver Maps SDK 로딩 스크립트 포함

---

## 🔍 가능한 원인 (Naver Maps 전용)

### 1. Naver Cloud Platform 서비스 URL 미등록

**증상**:
- 브라우저 콘솔: `401 Unauthorized` 또는 CORS 에러
- 지도가 로드되지 않거나 빈 화면

**확인 방법**:
```
배포 사이트 접속 → F12 → Console 탭
에러 메시지 확인:
- "Naver Maps 401 Unauthorized"
- "Access-Control-Allow-Origin"
```

**해결 방법**:
1. [Naver Cloud Platform Console](https://console.ncloud.com/naver-service/application) 접속
2. Application 목록에서 해당 앱 선택
3. **Web Dynamic Map** 탭 선택
4. **서비스 URL** 섹션:
   ```
   현재 등록된 URL 확인:
   - http://localhost:8080 (로컬 개발용)

   추가 필요:
   - https://bluesky78060.github.io
   ```
5. "서비스 URL 추가" 클릭
6. `https://bluesky78060.github.io` 입력 후 저장

**중요**:
- `http://` vs `https://` 구분됨
- 도메인만 입력 (경로 포함 안 함)
- 와일드카드 지원 안 됨

---

### 2. API Client ID 타입 불일치

**증상**:
- 지도 영역이 보이지만 타일이 로드되지 않음
- 콘솔 에러: "Invalid Client ID"

**확인 사항**:
현재 사용 중인 Client ID: `rzx12utf2x`

이 ID가 **Web Dynamic Map용 Client ID**인지 확인:
1. Naver Cloud Platform Console 접속
2. Application 선택
3. **인증 정보** 탭:
   - "Web Dynamic Map Client ID": `rzx12utf2x` 확인
   - ⚠️ "Mobile Dynamic Map" ID와 혼동 주의

**잘못된 경우**:
- Mobile Dynamic Map ID를 사용하면 웹에서 작동 안 함
- 올바른 Web Dynamic Map Client ID로 교체 필요

---

### 3. base-href로 인한 리소스 로딩 실패

**증상**:
- 콘솔: `naver_map_bridge.js` 404 Not Found
- 경로: `https://bluesky78060.github.io/naver_map_bridge.js` (잘못됨)
- 올바른 경로: `https://bluesky78060.github.io/flutter-todo/naver_map_bridge.js`

**확인 방법**:
```
F12 → Network 탭 → Ctrl+R (새로고침)
naver_map_bridge.js 요청 확인:
- Status: 404? → 경로 문제
- Status: 200? → 정상
```

**현재 설정**:
```html
<!-- index.html -->
<base href="/flutter-todo/">
<script src="naver_map_bridge.js"></script>
<!-- 실제 요청 URL: /flutter-todo/naver_map_bridge.js (정상) -->
```

**만약 404 에러 발생 시**:
`<base>` 태그가 올바르게 적용되지 않음. 절대 경로로 변경:
```html
<script src="/flutter-todo/naver_map_bridge.js"></script>
```

---

### 4. Naver Maps SDK 버전 호환성

**증상**:
- 지도는 로드되지만 geocoder가 작동하지 않음
- 콘솔: "naver.maps.Service is not a constructor"

**확인**:
```html
<!-- 현재 로딩 스크립트 -->
<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpKeyId=rzx12utf2x&submodules=geocoder"></script>
```

**체크포인트**:
- ✅ `submodules=geocoder` 포함되어 있음
- ✅ v3 API 사용 중

**만약 geocoder 에러 발생 시**:
```javascript
// naver_map_bridge.js에서 확인
if (typeof naver === 'undefined' || !naver.maps.Service) {
  console.error('Naver Maps geocoder not loaded');
}
```

---

### 5. Flutter 웹 플랫폼 감지 문제

**증상**:
- 앱은 로드되지만 지도 영역이 아예 없음
- 모바일 위젯만 보임

**확인**:
```dart
// lib/presentation/widgets/location_picker_dialog.dart
// kIsWeb 체크가 제대로 작동하는지 확인
```

**디버깅**:
배포 사이트에서 브라우저 콘솔에 입력:
```javascript
// Naver Maps 객체 존재 확인
console.log(typeof naver !== 'undefined' ? 'Naver Maps loaded' : 'Naver Maps NOT loaded');

// Geocoder 서비스 확인
console.log(typeof naver !== 'undefined' && naver.maps.Service ? 'Geocoder available' : 'Geocoder NOT available');
```

---

## 🛠️ 단계별 디버깅 프로세스

### Step 1: 브라우저 콘솔 확인

배포 사이트 접속:
```
https://bluesky78060.github.io/flutter-todo/
```

**F12 → Console 탭**에서 확인:

```javascript
// 1. Naver Maps 로드 확인
console.log('Naver Maps:', typeof naver !== 'undefined');

// 2. Geocoder 서비스 확인
console.log('Geocoder:', typeof naver !== 'undefined' && naver.maps.Service);

// 3. Bridge 함수 확인
console.log('searchNaverLocal:', typeof searchNaverLocal);
console.log('reverseGeocode:', typeof reverseGeocode);
```

**예상 출력**:
```
Naver Maps: true
Geocoder: true
searchNaverLocal: function
reverseGeocode: function
```

**만약 false가 나오면**:
→ 해당 리소스 로딩 실패

---

### Step 2: Network 탭 확인

**F12 → Network 탭 → 페이지 새로고침**

확인할 리소스:
```
✓ maps.js?ncpKeyId=rzx12utf2x      (Status: 200)
✓ naver_map_bridge.js              (Status: 200)
✗ 401 Unauthorized                 (서비스 URL 미등록)
✗ 404 Not Found                    (경로 문제)
```

---

### Step 3: Naver Cloud Console 확인

1. **Application 선택**
2. **Web Dynamic Map 탭**
3. **서비스 URL 섹션**:
   ```
   등록된 URL 확인:
   ☑ https://bluesky78060.github.io
   ☑ http://localhost:8080
   ```

**없으면 추가!**

---

### Step 4: 로컬 테스트

```bash
# 1. 로컬 빌드
./scripts/inject_env.sh
flutter build web --release --base-href /flutter-todo/

# 2. 로컬 서버 실행
cd build/web
python3 -m http.server 8080

# 3. 브라우저 접속
http://localhost:8080/flutter-todo/
```

**로컬에서 지도가 보이면**:
→ 문제는 배포 환경 설정 (서비스 URL 등록)

**로컬에서도 안 보이면**:
→ 코드 또는 API 키 문제

---

## ✅ 체크리스트

### Naver Cloud Platform 설정
- [ ] Application 생성됨
- [ ] Web Dynamic Map API 활성화
- [ ] Client ID 발급: `rzx12utf2x`
- [ ] 서비스 URL 등록:
  - [ ] `https://bluesky78060.github.io`
  - [ ] `http://localhost:8080`

### 코드 설정
- [ ] `web/index.template.html`에 Naver Maps SDK 로딩
- [ ] `ncpKeyId` 파라미터 사용 (ncpClientId 아님)
- [ ] `submodules=geocoder` 포함
- [ ] `naver_map_bridge.js` 파일 존재
- [ ] `kIsWeb` 체크로 웹 플랫폼 감지

### GitHub Actions 빌드
- [ ] `NAVER_MAPS_CLIENT_ID` Secret 설정
- [ ] `inject_env.sh` 스크립트 실행 성공
- [ ] `build/web/index.html`에 Client ID 주입 확인
- [ ] `build/web/naver_map_bridge.js` 복사됨

### 배포 확인
- [ ] GitHub Pages 활성화
- [ ] `gh-pages` 브랜치 존재
- [ ] 배포 URL 접속 가능
- [ ] 콘솔 에러 없음
- [ ] Network 탭에서 모든 리소스 200 OK

---

## 🎯 가장 가능성 높은 원인

**Naver Cloud Platform 서비스 URL 미등록**

대부분의 경우, 배포 환경에서 지도가 안 보이는 이유는:
1. Naver Cloud에 `https://bluesky78060.github.io` 등록 안 됨
2. 브라우저 콘솔에 401 Unauthorized 에러 표시

**즉시 확인**:
1. https://console.ncloud.com/naver-service/application
2. Application → Web Dynamic Map
3. 서비스 URL에 `https://bluesky78060.github.io` 추가

---

## 📞 다음 단계

배포 사이트에서 **브라우저 콘솔 (F12 → Console)**을 확인하고:

1. **에러 메시지 복사**
2. **Network 탭에서 실패한 요청 확인**
3. **에러 내용 공유**

그러면 정확한 원인을 파악하고 해결할 수 있습니다!

---

**최종 업데이트**: 2025-11-20
**테스트 URL**: https://bluesky78060.github.io/flutter-todo/
