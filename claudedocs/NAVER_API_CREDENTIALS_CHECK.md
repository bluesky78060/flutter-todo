# Naver API Credentials 확인 및 갱신 가이드

## 문제 상황
- Naver Geocoding API 호출 시 401 Unauthorized 에러 발생
- Edge Function은 정상 작동하지만 Naver API가 credentials를 거부함

## 현재 설정된 Credentials

**로컬 .env 파일**:
```
NAVER_LOCAL_SEARCH_CLIENT_ID=quSL_7O8Nb5bh6hK4Kj2
NAVER_LOCAL_SEARCH_CLIENT_SECRET=raJroLJaYw
```

**Supabase Edge Function Secrets**:
- ✅ 동일한 값으로 설정됨

## 해결 방법

### 1. Naver Cloud Platform에서 Credentials 확인

1. **Naver Cloud Platform 콘솔 접속**:
   - https://console.ncloud.com/

2. **Services → AI·NAVER API → Application**:
   - Geocoding 애플리케이션 선택
   - Client ID와 Client Secret 확인

3. **API 사용 설정 확인**:
   - Geocoding API가 활성화되어 있는지 확인
   - 할당량이 남아있는지 확인

### 2. 새 Credentials 생성 (필요시)

만약 기존 credentials가 만료되었거나 삭제된 경우:

1. **새 애플리케이션 등록**:
   - Naver Cloud Platform → AI·NAVER API
   - **+ 애플리케이션 등록** 클릭

2. **API 선택**:
   - **Maps** → **Geocoding** 체크
   - 서비스 환경: **WEB**
   - WEB 서비스 URL: `https://bulwfcsyqgsvmbadhlye.supabase.co`

3. **Client ID 및 Secret 복사**:
   - 등록 완료 후 표시되는 Client ID, Secret을 메모

### 3. Credentials 업데이트

새 credentials를 받았다면:

#### 로컬 .env 파일 업데이트
```bash
nano /Users/leechanhee/todo_app/.env

# 다음 줄 수정:
NAVER_LOCAL_SEARCH_CLIENT_ID=<새_CLIENT_ID>
NAVER_LOCAL_SEARCH_CLIENT_SECRET=<새_CLIENT_SECRET>
```

#### Supabase Edge Function Secrets 업데이트
```bash
~/bin/supabase secrets set \
  NAVER_LOCAL_SEARCH_CLIENT_ID=<새_CLIENT_ID> \
  NAVER_LOCAL_SEARCH_CLIENT_SECRET=<새_CLIENT_SECRET> \
  --project-ref bulwfcsyqgsvmbadhlye
```

#### Edge Function 재배포
```bash
~/bin/supabase functions deploy naver-geocode \
  --project-ref bulwfcsyqgsvmbadhlye \
  --no-verify-jwt
```

#### GitHub Secrets 업데이트
1. https://github.com/bluesky78060/flutter-todo/settings/secrets/actions
2. `NAVER_LOCAL_SEARCH_CLIENT_ID` 업데이트
3. `NAVER_LOCAL_SEARCH_CLIENT_SECRET` 업데이트

### 4. 테스트

```bash
# Edge Function 직접 테스트
curl -X POST https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-geocode \
  -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"query":"서울특별시 강남구 테헤란로 427"}'

# 예상 결과:
# {"meta":{"totalCount":1,"page":1,"count":1},"addresses":[{"roadAddress":"서울특별시 강남구 테헤란로 427",...}]}
```

## 대안: 다른 Geocoding API 사용

Naver Geocoding이 계속 작동하지 않는 경우:

### 옵션 1: Kakao Maps Geocoding API
- 무료 할당량: 월 300,000건
- 등록: https://developers.kakao.com/

### 옵션 2: Google Maps Geocoding API
- 무료 할당량: 월 $200 크레딧
- 이미 Google Maps API 키 있음

### 옵션 3: OpenStreetMap Nominatim
- 완전 무료
- API 키 불필요
- 한국 주소 지원 가능

## 트러블슈팅

### Q: Client ID와 Secret은 올바른데 401 에러가 발생해요

A: Naver Cloud Platform에서:
1. 서비스 URL이 `https://bulwfcsyqgsvmbadhlye.supabase.co`로 등록되어 있는지 확인
2. Geocoding API가 활성화되어 있는지 확인
3. 할당량이 초과되지 않았는지 확인

### Q: Edge Function 로그는 어디서 확인하나요?

A:
```bash
# Supabase Dashboard에서 확인
https://supabase.com/dashboard/project/bulwfcsyqgsvmbadhlye/functions/naver-geocode

# 또는 CLI로 확인
~/bin/supabase functions logs naver-geocode --project-ref bulwfcsyqgsvmbadhlye
```

### Q: 로컬에서는 작동하는데 배포판에서만 실패해요

A: Edge Function은 서버 측에서 실행되므로:
1. Supabase Secrets가 올바르게 설정되었는지 확인
2. Edge Function이 최신 코드로 배포되었는지 확인
3. Naver Cloud Platform에서 Supabase의 IP를 허용했는지 확인

---

**다음 단계**:
1. Naver Cloud Platform에서 Credentials 확인
2. 올바른 Client ID와 Secret인지 검증
3. 필요시 새 Credentials 생성
4. 위 가이드대로 업데이트 및 재배포