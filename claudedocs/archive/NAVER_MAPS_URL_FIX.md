# 네이버 지도 API 인증 오류 해결 가이드

## 문제 원인

**Web 서비스 URL 등록 방식이 잘못됨** - 네이버 클라우드 플랫폼 공식 가이드에 따르면:

> "서비스 URL은 **포트번호 및 URI를 제외한 호스트 도메인만을 등록**해야 합니다."

## ❌ 잘못된 등록 방식 (현재)

```
http://localhost:8888  ← 포트 번호 포함 (잘못됨)
http://127.0.0.1:8888  ← 포트 번호 포함 (잘못됨)
http://localhost:3000  ← 포트 번호 포함 (잘못됨)
https://bluesky78060.github.io/flutter-todo/  ← URI 경로 포함 (잘못됨)
```

## ✅ 올바른 등록 방식

```
http://localhost       ← 포트 번호 제외
http://127.0.0.1       ← 포트 번호 제외
https://bluesky78060.github.io  ← 경로 제외 (도메인만)
```

## 📝 수정 절차

### 1. 네이버 클라우드 플랫폼 콘솔 접속
- URL: https://console.ncloud.com/maps/application
- 로그인 후 Maps > Application으로 이동

### 2. 애플리케이션 수정
- 사용 중인 애플리케이션 (Client ID: rzx12utf2x) 클릭
- "Web 서비스 URL" 섹션으로 이동

### 3. URL 수정
기존 URL들을 **모두 삭제**하고 다음과 같이 재등록:

```
http://localhost
http://127.0.0.1
https://bluesky78060.github.io
```

**주의사항:**
- 포트 번호 (`:8888`, `:3000`) 절대 포함하지 말 것
- URI 경로 (`/flutter-todo`, `/oauth-callback`) 절대 포함하지 말 것
- 프로토콜 (`http://`, `https://`)은 반드시 포함

### 4. 저장 및 확인
- "저장" 버튼 클릭
- 설정이 즉시 반영됨 (별도 빌드 불필요)

## 🧪 테스트 방법

### 1. 테스트 페이지 확인
```bash
# 브라우저에서 열기
http://localhost:8888/naver_map_test.html
```

- 지도가 정상적으로 표시되고 사라지지 않아야 함
- 콘솔에 인증 오류가 없어야 함

### 2. Flutter 웹 앱 확인
현재 실행 중인 Flutter 웹 앱을 **완전히 재시작** (Hot Reload 불가):

```bash
# 기존 프로세스 종료 후 재시작
flutter run -d chrome
```

## 📚 참고 자료

- [네이버 클라우드 플랫폼 공식 포럼 - Web Dynamic Map API 인증 오류](https://www.ncloud-forums.com/topic/131/)
- [네이버 지도 API v3 공식 문서](https://navermaps.github.io/maps.js.ncp/docs/)
- [네이버 클라우드 플랫폼 Maps 가이드](https://guide.ncloud-docs.com/docs/maps-overview)

## ✅ 체크리스트

- [ ] 네이버 클라우드 플랫폼 콘솔에서 URL 수정 완료
- [ ] 포트 번호 및 URI 경로 제거 확인
- [ ] 테스트 페이지에서 지도 정상 표시 확인
- [ ] Flutter 웹 앱 재시작 및 지도 표시 확인
- [ ] 콘솔에 인증 오류 없는지 확인

## 🔧 추가 수정 사항

### 1. `&submodules=geocoder` 추가 (이미 완료 ✅)

**테스트 페이지** (`/tmp/naver_map_test.html`):
```html
<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpClientId=rzx12utf2x&submodules=geocoder"></script>
```

**Flutter 웹 앱** (`/Users/leechanhee/todo_app/web/index.html`):
```html
<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpClientId=rzx12utf2x&submodules=geocoder"></script>
```

### 2. 인증 실패 핸들러 (이미 완료 ✅)

테스트 페이지에 `window.navermap_authFailure` 핸들러가 추가되어 인증 실패 시 명확한 오류 메시지를 제공합니다.

## 🚨 예상 결과

URL 수정 후:
- ✅ 지도가 정상적으로 렌더링됨
- ✅ 타일이 사라지지 않음
- ✅ 콘솔에 인증 오류 없음
- ✅ 모든 포트 (8888, 랜덤 포트 등)에서 작동

## ❓ 여전히 문제가 발생한다면

1. **브라우저 캐시 삭제**: 개발자 도구 > Network > "Disable cache" 체크
2. **시크릿 모드에서 테스트**: 브라우저 캐시 영향 배제
3. **Client ID 재확인**: 네이버 클라우드 플랫폼 콘솔에서 Client ID가 `rzx12utf2x`인지 확인
4. **서비스 활성화 확인**: Maps > Application에서 "Dynamic Map" 서비스가 활성화되어 있는지 확인
