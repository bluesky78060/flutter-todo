# Flutter Web 위치 검색 기능 테스트 가이드

## ✅ 구현 완료 사항

### 1. 코드 수정 완료
- ✅ `lib/presentation/widgets/location_picker_dialog.dart` (Line 368-369)
  - `if (!kIsWeb)` 조건 제거 → 웹에서도 검색바 표시
  
- ✅ `web/naver_map_bridge.js` (Line 162-209)
  - 멀티 전략 검색 구현:
    - Strategy 1: Naver Local Search API (지명)
    - Strategy 2: Google Geocoding API (주소)
    - Strategy 3: First word extraction (복합 검색어)

- ✅ Proxy 서버 실행 중
  - `naver_proxy.py` on port 3000
  - PID: 77953
  - CORS 우회 정상 작동

### 2. 서비스 상태
```bash
# Proxy 서버 확인
lsof -i :3000
# Python  77953 leechanhee  (RUNNING)

# Flutter Web 확인
lsof -i :8080
# (RUNNING on port 8080)

# Proxy 테스트
curl -X POST 'http://localhost:3000/search' \
  -H 'Content-Type: application/json' \
  -d '{"query":"스타벅스","display":2}'
# (✅ 정상 응답)
```

## 📝 수동 테스트 절차

### Step 1: 앱 접속 및 로그인
1. 브라우저 시크릿 모드 열기 (Cmd+Shift+N)
2. http://localhost:8080 접속
3. 로그인 (이메일/비밀번호 또는 OAuth)
4. **1분 대기** (완전한 로그인을 위해)

### Step 2: 할 일 추가 다이얼로그 열기
1. 로그인 후 할 일 페이지에서
2. 오른쪽 상단 **파란색 "+" 버튼** 클릭
3. "할 일 추가" 다이얼로그 열림

### Step 3: 위치 선택 다이얼로그 열기
1. "위치 선택" 필드 클릭
2. 지도와 검색바가 있는 다이얼로그 열림
3. **✅ 검색바가 보이면 성공!**

### Step 4: 검색 기능 테스트

#### 테스트 1: 지명 검색 (Naver Local Search)
**입력**: `스타벅스`

**예상 결과**:
- 브라우저 콘솔(F12)에 아래 로그 출력:
  ```
  🔍 searchNaverPlaces called: query="스타벅스"
  🔍 Strategy 1: Naver Local Search (exact query)
     → Naver Local Search: "스타벅스"
     → Found 10 items
     ✓ Valid results: 10
  ✅ Strategy 1 success: 10 results
  ```
- 지도에 스타벅스 매장 마커 표시
- 검색 결과 목록 표시

#### 테스트 2: 주소 검색 (Google Geocoding)
**입력**: `서울시 중구 세종대로 124`

**예상 결과**:
- 브라우저 콘솔에 아래 로그 출력:
  ```
  🔍 searchNaverPlaces called: query="서울시 중구 세종대로 124"
  🔍 Strategy 1: Naver Local Search (exact query)
     → Naver Local Search: "서울시 중구 세종대로 124"
     → Found 0 items
  🔍 Strategy 2: Google Geocoding (address search)
  🔍 Google Geocoding - Geocoding: "서울시 중구 세종대로 124"
  ✅ Strategy 2 success: 1 results
  ```
- 지도에 해당 주소 마커 표시
- 검색 결과 1개 표시 (대한민국 프레스센터)

#### 테스트 3: 복합 검색어 (First Word Extraction)
**입력**: `카페 강남`

**예상 결과**:
- 브라우저 콘솔에 아래 로그 출력:
  ```
  🔍 searchNaverPlaces called: query="카페 강남"
  🔍 Strategy 1: Naver Local Search (exact query)
     → Found 0 items
  🔍 Strategy 2: Google Geocoding (address search)
     (no results)
  🔍 Strategy 3: First word only "카페"
     → Naver Local Search: "카페"
     → Found 10 items
  ✅ Strategy 3 success: 10 results
  ```
- "카페"로 검색한 결과 표시

## 🔍 브라우저 콘솔 확인 방법

1. F12 키로 개발자 도구 열기
2. "Console" 탭 선택
3. 검색 시 실시간 로그 확인

**필터 사용**:
- 콘솔에서 "🔍" 또는 "Strategy"로 필터링
- 검색 관련 로그만 표시됨

## ❌ 문제 발생 시 체크리스트

### 검색바가 안 보이는 경우
- [ ] 브라우저 캐시 삭제 (Cmd+Shift+R 강력 새로고침)
- [ ] location_picker_dialog.dart Line 368-369 확인
- [ ] Flutter Hot Restart (콘솔에서 'R' 입력)

### 검색이 안 되는 경우
- [ ] Proxy 서버 실행 확인: `lsof -i :3000`
- [ ] 브라우저 콘솔에서 에러 메시지 확인
- [ ] naver_map_bridge.js 파일 로드 확인

### CORS 에러가 나는 경우
```bash
# Proxy 서버 재시작
pkill -f naver_proxy.py
python3 /Users/leechanhee/todo_app/naver_proxy.py
```

### 지도가 안 나오는 경우
- [ ] index.html에 Naver Maps SDK 로드 확인
- [ ] 브라우저 콘솔에서 "Naver Maps" 관련 에러 확인
- [ ] 네트워크 탭에서 API 호출 확인

## 📊 성공 기준

✅ **웹에서 검색바가 보임**
✅ **"스타벅스" 검색 → Strategy 1 사용 → 결과 표시**
✅ **"서울시 중구 세종대로 124" 검색 → Strategy 2 사용 → 결과 표시**
✅ **지도에 마커 표시**
✅ **콘솔에 전략별 로그 출력**

## 🔧 현재 서비스 상태

- **Flutter Web**: http://localhost:8080 ✅
- **Naver Proxy**: http://localhost:3000 ✅ (PID: 77953)
- **코드 수정**: 모두 완료 ✅

## 📸 스크린샷 예시 위치

- 로그인 화면: `/tmp/step1-login-page.png`
- 로그인 후: `/tmp/step2-after-1min.png`
- 할 일 목록: 파란색 + 버튼이 오른쪽 상단에 표시됨
- 위치 선택 다이얼로그: 지도와 검색바가 함께 표시됨

## 🎯 다음 단계 (선택사항)

1. **프로덕션 배포 시**: 
   - Proxy를 Supabase Edge Function으로 이동
   - naver_map_bridge.js의 proxy URL 업데이트

2. **추가 기능**:
   - 검색 결과 캐싱
   - 최근 검색어 저장
   - 즐겨찾기 위치
