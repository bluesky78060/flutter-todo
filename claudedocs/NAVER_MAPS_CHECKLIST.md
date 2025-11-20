# 네이버 지도 API 인증 실패 완전 체크리스트

URL 수정 후에도 인증 실패가 계속되는 경우, 다음 항목들을 **모두** 확인해야 합니다.

## 🔴 필수 확인 사항

### 1. Client ID 파라미터 이름 확인 ✅

**현재 사용 중** (올바름):
```html
<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpClientId=rzx12utf2x&submodules=geocoder"></script>
```

**잘못된 예시들** (사용 X):
```html
<!-- ❌ 구버전 파라미터 -->
<script src="...maps.js?clientId=rzx12utf2x"></script>

<!-- ❌ 공공기관용 -->
<script src="...maps.js?govClientId=rzx12utf2x"></script>

<!-- ❌ 금융기관용 -->
<script src="...maps.js?finClientId=rzx12utf2x"></script>
```

### 2. Web 서비스 URL 등록 🔧

**네이버 클라우드 플랫폼 콘솔**에서 확인:
- URL: https://console.ncloud.com/maps/application
- 경로: Console > Services > Application Services > Maps > Application

**올바른 등록 방식** (공식 가이드):
```
http://localhost       ← 포트 번호 제외
http://127.0.0.1       ← 포트 번호 제외
https://bluesky78060.github.io  ← 경로 제외
```

**잘못된 등록 방식** (일부 블로그에서 잘못 안내):
```
http://localhost:8888  ← 포트 번호 포함 X
http://127.0.0.1:3000  ← 포트 번호 포함 X
```

**⚠️ 주의**: 일부 오래된 블로그 글에서 `127.0.0.1:포트번호`를 등록하라고 안내하지만,
이는 **공식 가이드와 모순**됩니다. 공식 포럼에서는 명확히 "포트번호 제외"를 명시하고 있습니다.

### 3. 서비스 활성화 상태 확인 🔍

**네이버 클라우드 플랫폼 콘솔**에서 **반드시 확인**:

1. **Application 수정 화면**으로 이동
2. **"Dynamic Map" 서비스가 활성화**되어 있는지 확인
3. 체크박스가 **선택되어 있어야 함**

**❗ 중요**: Dynamic Map이 선택되지 않으면:
- `429 Quota Exceed` 오류 발생
- 또는 인증 실패 오류 발생

### 4. Client ID 값 재확인 📝

네이버 클라우드 플랫폼 콘솔에서:
- Application 목록에서 **실제 Client ID 값** 확인
- 현재 사용 중: `rzx12utf2x`
- HTML/코드에 사용된 값과 **정확히 일치하는지** 확인

### 5. Application 상태 확인 🟢

콘솔에서 확인:
- Application 상태가 **"사용"**으로 되어 있는지
- 정지/삭제 상태가 아닌지
- 이용 가능한 상태인지

## 🧪 테스트 방법

### 1. 브라우저 캐시 완전 삭제

```
1. 브라우저 개발자 도구 열기 (F12)
2. Network 탭 선택
3. "Disable cache" 체크
4. 또는 시크릿 모드에서 테스트
```

### 2. 테스트 페이지 확인

```bash
# 브라우저에서 열기
http://localhost:8888/naver_map_test.html
```

**성공 시**:
- ✅ 지도가 정상적으로 표시됨
- ✅ 타일이 사라지지 않음
- ✅ 콘솔에 "네이버 지도 SDK 로드 성공" 메시지
- ✅ 콘솔에 "지도 생성 성공!" 메시지

**실패 시**:
- ❌ `window.navermap_authFailure` 함수 호출됨
- ❌ 콘솔에 "❌ Naver Maps 인증 실패!" 메시지
- ❌ Alert 창 표시

### 3. 브라우저 콘솔 확인

개발자 도구 > Console 탭에서 확인:
```
✅ 정상: "네이버 지도 SDK 로드 성공"
❌ 오류: "❌ Naver Maps 인증 실패!"
```

## 📊 디버깅 체크리스트

URL 수정 후에도 실패하는 경우, 다음을 **순서대로** 확인:

- [ ] **Step 1**: Client ID 파라미터가 `ncpClientId`인지 확인
- [ ] **Step 2**: Web 서비스 URL에 포트 번호가 **없는지** 확인
- [ ] **Step 3**: Dynamic Map 서비스가 **활성화**되어 있는지 확인
- [ ] **Step 4**: Client ID 값이 **정확한지** 확인 (rzx12utf2x)
- [ ] **Step 5**: Application 상태가 **"사용"**인지 확인
- [ ] **Step 6**: 브라우저 캐시 **완전 삭제** 후 재테스트
- [ ] **Step 7**: 시크릿 모드에서 테스트
- [ ] **Step 8**: URL 변경 후 **5~10분 대기** (설정 반영 시간)

## 🚨 여전히 실패한다면

### 1. 네이버 클라우드 플랫폼 고객 지원

- **포럼**: https://www.ncloud-forums.com/
- **고객센터**: 콘솔 우측 상단 "고객센터" 버튼
- **문의 시 포함 정보**:
  - Client ID: rzx12utf2x
  - 등록한 Web 서비스 URL 목록
  - 발생하는 정확한 오류 메시지
  - 브라우저 콘솔 스크린샷

### 2. Client ID 재발급

마지막 수단으로 **새로운 Application 생성**:
1. 기존 Application 복제 또는 새로 생성
2. Dynamic Map 서비스 활성화
3. Web 서비스 URL 재등록
4. 새로운 Client ID로 교체

## 📚 공식 참고 자료

- [네이버 클라우드 플랫폼 콘솔](https://console.ncloud.com/maps/application)
- [네이버 지도 API v3 공식 문서](https://navermaps.github.io/maps.js.ncp/docs/)
- [공식 포럼 - Web Dynamic Map API 인증 오류](https://www.ncloud-forums.com/topic/131/)
- [네이버 클라우드 Maps 가이드](https://guide.ncloud-docs.com/docs/maps-overview)

## 💡 추가 팁

### URL 변경 후 반영 시간
- 네이버 클라우드 플랫폼에서 URL 변경 시 **즉시 반영**되어야 하지만
- 경우에 따라 **5~10분** 소요될 수 있음
- 변경 후 시간을 두고 재테스트

### localhost vs 127.0.0.1
공식 가이드에 따르면 둘 다 등록해야 함:
- `http://localhost` - localhost 도메인용
- `http://127.0.0.1` - IP 주소 직접 접근용

### HTTPS vs HTTP
- 로컬 개발: `http://localhost` (HTTPS 불필요)
- 프로덕션: `https://도메인` (HTTPS 필수)

## ✅ 최종 확인

모든 설정 후 **양쪽 모두** 테스트:

1. **테스트 페이지**: http://localhost:8888/naver_map_test.html
2. **Flutter 웹 앱**: flutter run -d chrome (완전 재시작)

둘 다 성공하면 문제 해결 완료! 🎉
