# 🚨 네이버 지도 인증 실패 - 최종 디버깅 가이드

## 현재 상황 요약

### 테스트 결과
- ❌ Client ID `rzx12utf2x` (DoDo-todo Application): 인증 실패
- ❌ Client ID `kmiocgzgrw` (test Application): 인증 실패

**결론**: **두 개의 서로 다른 Application 모두 인증 실패** → 네이버 클라우드 플랫폼 설정에 공통된 문제 존재

## 🔍 필수 확인 사항

### 1. Application 수정 화면 전체 스크린샷 필요

네이버 클라우드 플랫폼 콘솔에서:

1. **Maps > Application** 이동
2. **"test" Application 클릭**
3. **"수정" 버튼 클릭** (인증정보 팝업 아님!)
4. **전체 페이지 스크린샷** 촬영

**필수 포함 정보**:
- Application 이름
- **API 선택 섹션** (체크박스들)
- **서비스 환경 등록** 섹션
  - Web 서비스 URL 목록 전체
  - Android 앱 패키지 이름
  - iOS Bundle ID

### 2. 확인해야 할 체크박스

**API 선택** 섹션에서 다음 중 **어떤 항목이 체크되어 있는지** 확인:

```
[ ] Mobile Dynamic Map
[ ] Web Dynamic Map
[ ] Dynamic Map (통합)
[ ] Static Map
[ ] Geocoding
[ ] Reverse Geocoding
[ ] Directions 5
[ ] Directions 15
```

**중요**:
- "Mobile Dynamic Map"과 "Web Dynamic Map"이 **별도로 존재**하는지
- 아니면 "Dynamic Map" 하나만 존재하는지

## 🎯 가능한 원인들

### 원인 1: Web Dynamic Map 미활성화
**증상**: "Dynamic Map"만 체크되어 있지만, 실제로는 Mobile용만 활성화됨

**해결**:
- "Web Dynamic Map" 체크박스가 별도로 존재한다면 체크
- 또는 Application 설명에서 "Web JS 이용 시" 조건 확인

### 원인 2: Web 서비스 URL 형식 오류
**확인**: 다음 형식 중 **정확히 어떻게 등록되어 있는지** 스크린샷 필요

**올바른 형식**:
```
http://localhost
http://127.0.0.1
https://bluesky78060.github.io
```

**잘못된 형식** (이 중 하나라도 있으면 문제):
```
http://localhost/
http://localhost:8888
http://127.0.0.1:8888
https://bluesky78060.github.io/
```

### 원인 3: 서비스 활성화 상태 문제
**확인**: Application 목록 화면에서
- "상태" 컬럼이 **"사용"**으로 되어 있는지
- "정지" 또는 다른 상태가 아닌지

### 원인 4: 계정/권한 문제
**확인**:
- 네이버 클라우드 플랫폼 계정이 정상 상태인지
- Maps 서비스 이용 권한이 있는지
- 무료 할당량이 남아 있는지 (0/6,000,000이 아닌지)

### 원인 5: Client ID 복사 오류
**확인**:
- 인증정보 팝업에서 **복사 버튼**을 사용했는지
- 직접 타이핑하지 않았는지
- 공백이나 특수문자가 포함되지 않았는지

## 📋 체크리스트 (순서대로 확인)

### Phase 1: 기본 설정 확인
- [ ] Application 상태가 "사용"임
- [ ] Client ID가 정확함 (복사 버튼 사용)
- [ ] Web 서비스 URL에 슬래시(/)나 포트 번호 없음
- [ ] `http://localhost`, `http://127.0.0.1` 모두 등록됨

### Phase 2: 서비스 활성화 확인
- [ ] "Web Dynamic Map" 또는 "Dynamic Map" 체크됨
- [ ] 체크 후 **저장 버튼** 클릭했음
- [ ] 저장 후 페이지 새로고침하여 설정 유지 확인
- [ ] 5-10분 대기 (설정 반영 시간)

### Phase 3: 브라우저 테스트
- [ ] 브라우저 캐시 완전 삭제
- [ ] 시크릿/프라이빗 모드에서 테스트
- [ ] 다른 브라우저에서도 테스트 (Chrome, Safari, Firefox)
- [ ] 콘솔(F12) Network 탭에서 "validate" 응답 코드 확인

### Phase 4: 네트워크 디버깅
- [ ] 브라우저 개발자 도구 > Network 탭
- [ ] "validatev3" 또는 "maps.js" 검색
- [ ] 응답 코드 확인:
  - 200: 성공
  - 400/403/404: 인증 실패
  - 429: 할당량 초과
- [ ] 응답 본문(Response body) 확인하여 정확한 오류 메시지 확인

## 🔧 고급 디버깅

### Network 탭에서 정확한 오류 확인

1. **브라우저 개발자 도구 열기** (F12)
2. **Network 탭** 선택
3. **테스트 페이지 새로고침**
4. **"validate"** 검색
5. **응답 확인**:

```json
// 성공 시 응답 예시
{
  "result": "ok"
}

// 실패 시 응답 예시
{
  "error": {
    "errorCode": "028",
    "message": "등록된 정보가 일치하지 않습니다"
  }
}
```

### Console 탭에서 상세 오류 확인

```javascript
// 예상되는 오류 메시지들
❌ "Error Code 28: 등록된 정보가 일치하지 않습니다"
❌ "Error Code 429: Quota Exceed"
❌ "Authentication failed"
```

## 💡 임시 해결책

### 옵션 1: 새 Application 생성
모든 설정이 올바른데도 실패한다면:

1. **완전히 새로운 Application 생성**
2. Application 이름: "DoDo-Web-Test"
3. **API 선택**:
   - ✅ Web Dynamic Map (또는 Dynamic Map)
   - ✅ Geocoding
   - ✅ Reverse Geocoding
4. **Web 서비스 URL**:
   - `http://localhost`
   - `http://127.0.0.1`
   - `https://bluesky78060.github.io`
5. **저장 후 10분 대기**
6. **새 Client ID로 테스트**

### 옵션 2: GitHub Pages 전용 설정
Web Dynamic Map이 localhost에서 작동하지 않는다면:

1. **Web 서비스 URL에서 localhost 제거**
2. **GitHub Pages URL만 등록**: `https://bluesky78060.github.io`
3. **Flutter 웹 앱을 GitHub Pages에 배포**
4. **배포된 URL에서 테스트**

## 📞 네이버 클라우드 고객 지원

모든 방법이 실패한다면 **고객 지원 문의** 필수:

**문의처**:
- 포럼: https://www.ncloud-forums.com/
- 콘솔 우측 상단 "고객센터" 버튼

**문의 시 포함 정보**:
```
제목: Web Dynamic Map API 인증 실패 (Error Code 28)

내용:
- Client ID: kmiocgzgrw (test Application)
- 등록한 Web 서비스 URL: http://localhost, http://127.0.0.1
- 선택한 서비스: Dynamic Map
- 오류 메시지: "등록된 정보가 일치하지 않습니다" (Error Code 28)
- 테스트 환경: macOS, Chrome 브라우저, localhost:8888
- 시도한 해결책:
  1. Web 서비스 URL 형식 확인 (포트 번호 제외)
  2. 브라우저 캐시 삭제 및 시크릿 모드 테스트
  3. 10분 이상 대기 후 재테스트
  4. 두 개의 서로 다른 Application으로 테스트 (모두 실패)

첨부 파일:
- Application 수정 화면 스크린샷
- 브라우저 Network 탭 스크린샷 (validate 응답)
- 브라우저 Console 탭 스크린샷 (오류 메시지)
```

## 🎯 다음 단계

**즉시 필요한 정보**:
1. **"test" Application의 전체 수정 화면 스크린샷**
   - 특히 "API 선택" 섹션의 체크박스 상태
   - "서비스 환경 등록" 섹션의 Web 서비스 URL 목록

2. **브라우저 Network 탭 스크린샷**
   - http://localhost:8888/test_new_client_id.html 접속 시
   - "validate" 검색 후 응답 내용

이 정보가 있어야 **정확한 원인**을 파악할 수 있습니다!

---

**중요**: 현재까지 시도한 모든 방법이 실패했다는 것은 **설정이 눈에 보이지 않는 곳에서 잘못되어 있거나**, **네이버 클라우드 플랫폼 서비스 자체에 문제**가 있을 가능성이 높습니다.
