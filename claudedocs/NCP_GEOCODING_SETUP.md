# NCP Geocoding API 설정 가이드

## 문제 상황

현재 **Naver Developer API**의 credentials를 사용하고 있지만, **Geocoding은 NCP에서만 제공**됩니다.

**현재 사용 중인 API**:
- Naver Maps (NCP): `rzx12utf2x` ✅
- Naver Developer Search API: `quSL_7O8Nb5bh6hK4Kj2` / `raJroLJaYw` ✅
- NCP Geocoding: ❌ 없음!

## 해결 방법

### 1. NCP Console에서 Geocoding API 활성화

1. **NCP Console 접속**:
   - https://console.ncloud.com/
   - 로그인

2. **Services → AI·Application Service → Maps**:
   - 왼쪽 메뉴에서 **Maps** 클릭

3. **Application 등록**:
   - 이미 Maps 애플리케이션이 있다면 그것 사용
   - 없다면 **+ Application 등록** 클릭

4. **Geocoding API 추가**:
   - Application 상세 페이지
   - **서비스 선택** 섹션에서
   - **Geocoding** 체크
   - **저장**

5. **인증 정보 확인**:
   ```
   Client ID: (Maps용과 동일할 수 있음)
   Client Secret: (Maps용과 동일할 수 있음)
   ```

### 2. NCP API 인증 방식

NCP Geocoding API는 **헤더 방식**을 사용합니다:
```
X-NCP-APIGW-API-KEY-ID: <Client ID>
X-NCP-APIGW-API-KEY: <Client Secret>
```

**Edge Function 코드 수정 필요**!

현재 코드는 Naver Developer 방식 (`X-Naver-Client-Id`)을 사용하고 있습니다.

### 3. Edge Function 수정

`supabase/functions/naver-geocode/index.ts` 수정:

```typescript
// 변경 전 (현재):
headers: {
  'X-Naver-Client-Id': NAVER_CLIENT_ID,
  'X-Naver-Client-Secret': NAVER_CLIENT_SECRET,
}

// 변경 후 (NCP 방식):
headers: {
  'X-NCP-APIGW-API-KEY-ID': NAVER_CLIENT_ID,
  'X-NCP-APIGW-API-KEY': NAVER_CLIENT_SECRET,
}
```

### 4. Credentials 업데이트

NCP Console에서 받은 새 credentials로:

**로컬 .env**:
```bash
# NCP Geocoding용 (Maps와 동일할 수 있음)
NAVER_GEOCODING_CLIENT_ID=<NCP에서_받은_ID>
NAVER_GEOCODING_CLIENT_SECRET=<NCP에서_받은_SECRET>
```

**Supabase Secrets**:
```bash
~/bin/supabase secrets set \
  NAVER_GEOCODING_CLIENT_ID=<새_ID> \
  NAVER_GEOCODING_CLIENT_SECRET=<새_SECRET> \
  --project-ref bulwfcsyqgsvmbadhlye
```

---

## 옵션 2: Kakao Maps Geocoding 사용

NCP 설정이 복잡하다면 **Kakao Maps**를 대안으로 사용 가능:

### 장점
- 무료 할당량: 월 300,000건
- 간단한 설정
- 한국 주소 지원 우수

### 설정 방법

1. **Kakao Developers 접속**:
   - https://developers.kakao.com/
   - 로그인 → 내 애플리케이션

2. **앱 키 확인**:
   - REST API 키 복사

3. **플랫폼 추가**:
   - 플랫폼 → Web 플랫폼 등록
   - 사이트 도메인: `https://bluesky78060.github.io`

4. **Geocoding API 호출**:
   ```
   GET https://dapi.kakao.com/v2/local/search/address.json?query=문단길 15
   Header: Authorization: KakaoAK <REST_API_KEY>
   ```

---

## 옵션 3: Google Maps Geocoding 사용

이미 Google Maps API 키가 있으므로 가장 빠른 해결책:

### 장점
- 이미 API 키 있음
- 무료 할당량: 월 $200 크레딧
- 안정적인 서비스

### 설정 방법

1. **Google Cloud Console**:
   - https://console.cloud.google.com/
   - 기존 프로젝트 선택

2. **Geocoding API 활성화**:
   - APIs & Services → Library
   - "Geocoding API" 검색
   - **Enable** 클릭

3. **API 키 확인**:
   - APIs & Services → Credentials
   - 기존 API 키 사용 가능

4. **Edge Function 수정**:
   ```typescript
   const geocodeUrl = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(query)}&key=${GOOGLE_API_KEY}&language=ko&region=kr`
   ```

---

## 권장 사항

**즉시 해결**: **Google Maps Geocoding 사용** (이미 API 키 있음)

**장기적**: NCP Geocoding 설정 (Naver 생태계 통합)

다음 섹션에서 Google Maps Geocoding으로 빠르게 전환하는 방법을 안내합니다.