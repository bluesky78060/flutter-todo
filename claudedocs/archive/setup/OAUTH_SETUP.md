# OAuth 설정 가이드

## ⚠️ 중요: Supabase 대시보드 설정 필수

### 1. Redirect URLs 설정
Supabase Dashboard → Authentication → URL Configuration

다음 URL을 **Redirect URLs**에 추가하세요:

```
kr.bluesky.dodo://oauth-callback
```

### 2. Google OAuth 설정
Dashboard → Authentication → Providers → Google

- **Enable Google provider** 체크
- **Client ID** 입력 (Google Cloud Console에서 발급)
- **Client Secret** 입력

### 3. Kakao OAuth 설정
Dashboard → Authentication → Providers → Kakao

- **Enable Kakao provider** 체크
- **Client ID** 입력 (Kakao Developers에서 발급)
- **Client Secret** 입력

## Android 설정 (완료됨)

### AndroidManifest.xml
```xml
<data android:scheme="kr.bluesky.dodo"/>
```

### oauth_redirect.dart
```dart
const redirectUrl = 'kr.bluesky.dodo://oauth-callback';
```

## 테스트 방법

### 실제 기기에서 테스트 (권장)
1. APK 다운로드: http://172.20.10.3:9000
2. 앱 설치
3. Google 또는 Kakao 로그인 시도
4. 브라우저가 열리고 로그인 진행
5. 로그인 완료 후 자동으로 앱으로 돌아와야 함

### 에뮬레이터 제한사항
- Google Play Services가 없는 에뮬레이터에서는 소셜 로그인이 작동하지 않을 수 있음
- **권장**: 실제 기기에서 테스트

## 현재 상태

✅ MainActivity.kt 생성됨
✅ AndroidManifest.xml에 deep link 설정됨
✅ oauth_redirect.dart에 올바른 scheme 설정됨
✅ Release APK 빌드 완료 (63.3MB)

⚠️ Supabase Dashboard에 redirect URL 추가 필요
⚠️ 에뮬레이터는 제한적, 실제 기기 테스트 권장
