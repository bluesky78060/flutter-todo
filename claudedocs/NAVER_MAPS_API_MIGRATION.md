# 네이버 지도 API - 현재 상태 및 향후 계획

## ✅ 현재 상태 (2025-11-20)

### 웹 플랫폼
- **사용 중인 Client ID**: `quSL_7O8Nb5bh6hK4Kj2`
- **API 타입**: Naver Cloud Platform (NCP) - 신규 VPC 환경
- **서비스**: Web Dynamic Map, Local Search API
- **상태**: ✅ 정상 작동

### 모바일 플랫폼 (Android/iOS)
- **사용 중인 Client ID**: `rzx12utf2x`
- **API 타입**: 구버전 API (AI NAVER API)
- **서비스**: Mobile Dynamic Map, Reverse Geocoding API
- **상태**: ✅ 정상 작동 (당분간 유지 가능)

## 📌 과거 문제 (해결됨)

브라우저 Console에서 다음 경고 메시지가 표시되었습니다:

> **신규 Maps API 전환 안내**
>
> AI NAVER API 상품에서 제공되던 **지도 API 서비스는 점진적으로 종료될 예정**에 있습니다.
> 신규 클라이언트 아이디 발급받아 사용 부탁드립니다.

## 🔧 해결 완료

웹 플랫폼은 이미 신규 NCP API (`quSL_7O8Nb5bh6hK4Kj2`)로 전환 완료했습니다.

## 📋 향후 할 일

### 모바일 API 전환 (우선순위: 중)

모바일용 Client ID (`rzx12utf2x`)는 구버전 API이지만, 네이버가 정확한 종료 일정을 공지하기 전까지는 계속 사용 가능합니다.

**전환 필요 시점**:
1. 네이버에서 공식 종료 공지가 나올 때
2. 기능이 작동하지 않기 시작할 때
3. 여유가 있을 때 미리 대비

### 모바일 API 전환 방법 (필요 시)

#### 옵션 1: 신규 NCP API로 전환 (권장)

1. **네이버 클라우드 플랫폼 콘솔** 접속
   - URL: https://console.ncloud.com/naver-service/application

2. **새로운 Application 등록**
   - Mobile Dynamic Map 서비스 선택
   - Android 패키지명 등록: `kr.bluesky.dodo`, `kr.bluesky.dodo.debug`
   - iOS Bundle ID 등록 (필요 시)

3. **새 Client ID 발급받기**
   - 신규 NCP용 Client ID 획득

4. **Flutter 앱에 적용**
   - `android/local.properties`의 `NAVER_CLIENT_ID` 업데이트
   - `lib/main.dart`의 초기화 코드 Client ID 변경
   - 테스트 후 확인

#### 옵션 2: 현재 상태 유지 (안전)

구버전 API가 실제로 종료되기 전까지는 현재 상태 유지:
- ✅ 모바일: 계속 정상 작동
- ✅ 웹: 이미 신규 API 사용 중
- ⚠️ 네이버 공지사항 주기적 확인 필요

## 🎯 권장 액션 플랜

### 단기 (현재 ~ 1개월)
- ✅ **아무 조치 불필요** - 현재 상태 유지
- ✅ 웹은 이미 신규 API 사용 중
- ✅ 모바일도 정상 작동 중

### 중기 (1~3개월)
- 📋 네이버 공지사항 주기적 확인
- 📋 구버전 API 종료 일정 파악
- 📋 여유가 있을 때 모바일도 신규 API로 전환 검토

### 장기 (3개월 이상)
- 🔄 모바일 API를 신규 NCP로 전환 (필요 시)
- 🔧 iOS 빌드 테스트 및 검증
- 📊 API 사용량 모니터링

## 🔗 참고 링크

- **공지사항**: https://www.ncloud.com/support/notice/all/1930
- **변경 가이드**: https://navermaps.github.io/maps.js.ncp/docs/tutorial-2-Getting-Started.html
- **VPC 콘솔**: https://console.ncloud.com/
- **Maps 서비스**: https://www.ncloud.com/product/applicationService/maps

## 📊 현재 상태 요약

| 플랫폼 | Client ID | API 타입 | 상태 | 조치 필요 |
|--------|-----------|----------|------|-----------|
| **웹** | `quSL_7O8Nb5bh6hK4Kj2` | 신규 NCP | ✅ 정상 | ❌ 없음 |
| **모바일** | `rzx12utf2x` | 구버전 | ✅ 정상 | ⚠️ 나중에 |

## 💡 결론

### 웹
✅ **이미 해결 완료!**
- 2025년 11월 20일 신규 NCP API로 전환 완료
- Naver Maps 정상 작동 (JavaScript SDK)
- 장소 검색 API 연동 완료

### 모바일
⏳ **당분간 현재 상태 유지**
- 구버전 API 아직 정상 작동 중
- 네이버 종료 공지 시까지 유지 가능
- 필요 시 신규 API로 전환 (30분 정도 소요)

---

**요약**: 웹은 이미 최신 API 사용 중이고, 모바일은 구버전이지만 문제없이 작동 중입니다. 네이버에서 정식 종료 공지가 나오면 그때 모바일도 전환하면 됩니다!
