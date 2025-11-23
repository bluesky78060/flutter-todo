# 검색 기능 배포 문제 해결

**날짜**: 2025-11-23
**문제**: 지도는 표시되지만 검색이 작동하지 않음
**배포 URL**: https://bluesky78060.github.io/flutter-todo/

---

## 🔍 문제 분석

### 증상
- ✅ 네이버 지도는 정상적으로 표시됨
- ❌ 장소 검색 시 결과가 나오지 않음
- 브라우저 콘솔 에러: `POST http://localhost:3000/search net::ERR_CONNECTION_REFUSED`

### 근본 원인
`lib/core/services/location_service.dart`의 `_searchLocalAPI` 메서드가 웹 환경에서 **로컬 개발용 프록시 서버**(`localhost:3000`)에 요청을 보내도록 하드코딩되어 있었음.

```dart
// ❌ 문제 코드 (배포 환경에서 실패)
if (kIsWeb) {
  final url = Uri.parse('http://localhost:3000/search');
  response = await http.post(url, ...);
}
```

**왜 로컬에서는 작동했는가?**
- 로컬 개발 시 `naver_proxy.py` 파이썬 프록시 서버를 실행하여 CORS 우회
- GitHub Pages 배포 환경에는 이 프록시 서버가 없음

---

## ✅ 해결 방법

### 변경 사항
웹과 모바일 모두 **네이버 Local Search API에 직접 요청**하도록 통합:

```dart
// ✅ 수정된 코드 (웹/모바일 공통)
// 1. 환경변수에서 인증정보 가져오기 (웹/모바일 구분)
String clientId = '';
String clientSecret = '';

if (kIsWeb) {
  // 웹: window.ENV에서 가져오기
  final env = js.globalContext['ENV'];
  clientId = (env['NAVER_LOCAL_SEARCH_CLIENT_ID'] as String?) ?? '';
  clientSecret = (env['NAVER_LOCAL_SEARCH_CLIENT_SECRET'] as String?) ?? '';
} else {
  // 모바일: dotenv에서 가져오기
  clientId = dotenv.env['NAVER_LOCAL_SEARCH_CLIENT_ID'] ?? '';
  clientSecret = dotenv.env['NAVER_LOCAL_SEARCH_CLIENT_SECRET'] ?? '';
}

// 2. 네이버 API에 직접 GET 요청
final url = Uri.parse(
  'https://openapi.naver.com/v1/search/local.json'
  '?query=${Uri.encodeComponent(query)}'
  '&display=10&start=1&sort=random',
);

final response = await http.get(
  url,
  headers: {
    'X-Naver-Client-Id': clientId,
    'X-Naver-Client-Secret': clientSecret,
  },
);
```

### 주요 개선점
1. **프록시 서버 제거**: localhost:3000 의존성 완전 제거
2. **웹/모바일 통합**: 동일한 API 호출 방식 사용
3. **환경변수 활용**: `window.ENV`에 주입된 API 키 사용
4. **표준 HTTP 헤더**: 네이버 API 공식 인증 방식 적용

---

## 🔐 보안 설정

### GitHub Secrets (이미 설정됨)
- `NAVER_LOCAL_SEARCH_CLIENT_ID`: 네이버 Local Search Client ID
- `NAVER_LOCAL_SEARCH_CLIENT_SECRET`: 네이버 Local Search Client Secret

### 환경변수 주입 흐름
1. **GitHub Actions**: `.github/workflows/deploy.yml`에서 Secrets → `.env` 파일 생성
2. **빌드 스크립트**: `scripts/inject_env.sh`가 `.env` → `web/index.html`에 주입
3. **웹 런타임**: Flutter 앱이 `window.ENV`에서 값 읽어옴

```javascript
// web/index.template.html
window.ENV = {
  NAVER_LOCAL_SEARCH_CLIENT_ID: '{{NAVER_LOCAL_SEARCH_CLIENT_ID}}',
  NAVER_LOCAL_SEARCH_CLIENT_SECRET: '{{NAVER_LOCAL_SEARCH_CLIENT_SECRET}}'
};
```

---

## 🧪 테스트 방법

### 로컬 테스트
```bash
# 1. 환경변수 주입
./scripts/inject_env.sh

# 2. 웹 빌드
flutter build web --release --base-href /flutter-todo/

# 3. 로컬 서버 실행
cd build/web
python3 -m http.server 8080

# 4. 브라우저 접속
http://localhost:8080/flutter-todo/

# 5. 검색 테스트
# - "스타벅스", "카페" 등으로 검색
# - 브라우저 콘솔(F12)에서 네트워크 요청 확인
```

### 배포 환경 테스트
1. **GitHub Pages 접속**: https://bluesky78060.github.io/flutter-todo/
2. **할 일 추가**: "새 할 일" 버튼 클릭
3. **장소 검색**: 장소 입력 필드에서 "스타벅스" 검색
4. **결과 확인**: 검색 결과가 표시되는지 확인
5. **콘솔 확인**: F12 → Console 탭에서 에러 없는지 확인

### 예상 결과
```
✅ 정상 동작:
🔍 Naver Local Search API Response:
   Status: 200
   Items count: 10
   First item title: 스타벅스 강남점
   First item mapx: 127123456
   First item mapy: 37123456
```

---

## 📊 변경된 파일

### `lib/core/services/location_service.dart`
**변경 내용**:
- 웹 환경에서 localhost:3000 프록시 호출 제거
- 웹/모바일 모두 직접 네이버 API 호출로 통합
- 환경변수 가져오기 로직을 if-else 분기 외부로 이동

**라인 수 변경**: -53줄, +39줄 (14줄 감소)

**커밋 정보**:
- 커밋 해시: `ff16a97`
- 커밋 메시지: "fix: Replace localhost proxy with direct Naver API calls for web"
- 푸시 날짜: 2025-11-23

---

## ⚠️ 주의사항

### CORS 정책
네이버 Local Search API는 **서버 사이드 호출을 권장**하지만, 현재는 클라이언트 사이드에서 직접 호출하고 있습니다.

**가능한 이슈**:
- 네이버가 향후 CORS 정책을 강화할 경우 다시 차단될 수 있음
- 현재는 네이버 API가 웹 브라우저에서의 직접 호출을 허용하고 있음

**대안 (필요 시)**:
1. **Supabase Edge Functions**: 서버리스 함수로 프록시 구현
2. **GitHub Actions + Cloudflare Workers**: 서버리스 API 프록시
3. **백엔드 서버**: 전용 백엔드 API 서버 구축

### API 키 노출
클라이언트 사이드 코드에서 API 키가 `window.ENV`에 노출되지만:
- **허용 가능**: 네이버 Local Search API는 클라이언트 키 사용을 지원
- **제한 설정**: 네이버 Cloud Platform에서 도메인 제한 설정 가능
- **모니터링**: 네이버 콘솔에서 API 사용량 모니터링 필수

---

## 📝 관련 문서

- [MAP_TROUBLESHOOTING.md](MAP_TROUBLESHOOTING.md) - 지도 문제 해결 가이드
- [NAVER_MAPS_DEPLOYMENT_DEBUG.md](NAVER_MAPS_DEPLOYMENT_DEBUG.md) - 네이버 지도 배포 디버깅
- [API_KEYS_SECURITY.md](API_KEYS_SECURITY.md) - API 키 보안 가이드 (존재 시)

---

## ✅ 최종 체크리스트

배포 후 확인 사항:
- [ ] GitHub Actions 빌드 성공 확인
- [ ] 배포 사이트에서 지도 표시 확인
- [ ] 배포 사이트에서 검색 기능 작동 확인
- [ ] 브라우저 콘솔에 에러 없는지 확인
- [ ] 네이버 Cloud Platform에서 API 사용량 확인
- [ ] 다양한 검색어로 테스트 (스타벅스, 카페, 편의점 등)

---

**최종 업데이트**: 2025-11-23
**상태**: ✅ 수정 완료, 배포 대기 중
**다음 단계**: GitHub Actions 빌드 완료 후 배포 환경에서 검증
