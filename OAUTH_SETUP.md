# OAuth 로그인 설정 가이드

## 1. Google OAuth 설정

### 1.1 Google Cloud Console 설정

1. **Google Cloud Console 접속**
   - https://console.cloud.google.com 접속
   - 프로젝트 선택 또는 새 프로젝트 생성

2. **OAuth 동의 화면 구성**
   - 좌측 메뉴: `API 및 서비스` → `OAuth 동의 화면`
   - User Type: `외부` 선택
   - 앱 정보 입력:
     - 앱 이름: `Todo App`
     - 사용자 지원 이메일: 본인 이메일
     - 개발자 연락처 정보: 본인 이메일

3. **OAuth 클라이언트 ID 생성**
   - 좌측 메뉴: `API 및 서비스` → `사용자 인증 정보`
   - `+ 사용자 인증 정보 만들기` → `OAuth 클라이언트 ID`
   - 애플리케이션 유형: `웹 애플리케이션`
   - 이름: `Todo App Web Client`
   - 승인된 리디렉션 URI:
     ```
     https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/callback
     ```
   - `만들기` 클릭
   - 생성된 **클라이언트 ID**와 **클라이언트 보안 비밀번호** 복사

### 1.2 Supabase 설정

1. **Supabase 대시보드 접속**
   - https://supabase.com/dashboard
   - 프로젝트 선택

2. **Google Provider 활성화**
   - `Authentication` → `Providers` → `Google`
   - `Enabled` 토글 ON
   - `Client ID` 입력 (Google Cloud Console에서 복사한 값)
   - `Client Secret` 입력 (Google Cloud Console에서 복사한 값)
   - `Save` 클릭

### 1.3 코드에 Client ID 추가

`lib/presentation/screens/login_screen.dart` 파일에서:

```dart
const webClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID'; // 여기에 실제 Client ID 입력
```

위 부분을 Google Cloud Console에서 복사한 Client ID로 교체하세요.

---

## 2. Kakao OAuth 설정

### 2.1 Kakao Developers 설정

1. **Kakao Developers 접속**
   - https://developers.kakao.com 접속
   - 로그인 후 `내 애플리케이션` → `애플리케이션 추가하기`

2. **앱 설정**
   - 앱 이름: `Todo App`
   - 사업자명: 본인 이름
   - 앱 생성

3. **플랫폼 설정**
   - 좌측 메뉴: `플랫폼` → `Web 플랫폼 등록`
   - 사이트 도메인: `https://fascinating-peony-8bbb51.netlify.app`

4. **Redirect URI 설정**
   - 좌측 메뉴: `카카오 로그인` → `활성화 설정` ON
   - `Redirect URI 등록` 클릭
   - Redirect URI:
     ```
     https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/callback
     ```

5. **REST API 키 복사**
   - 좌측 메뉴: `앱 키`
   - `REST API 키` 복사

6. **Client Secret 생성 (선택)**
   - 좌측 메뉴: `카카오 로그인` → `보안` → `Client Secret` 생성

### 2.2 Supabase 설정

1. **Supabase 대시보드 접속**
   - https://supabase.com/dashboard
   - 프로젝트 선택

2. **Kakao Provider 활성화**
   - `Authentication` → `Providers` → `Kakao`
   - `Enabled` 토글 ON
   - `Client ID` 입력 (Kakao REST API 키)
   - `Client Secret` 입력 (Kakao에서 생성한 Client Secret, 선택사항)
   - `Save` 클릭

---

## 3. 테스트

### 3.1 로컬 테스트

```bash
cd /Users/leechanhee/Dropbox/Mac/Downloads/todo_app
flutter run -d chrome
```

### 3.2 프로덕션 테스트

1. 빌드 및 배포:
   ```bash
   flutter build web --release
   ```

2. Netlify Drop에 `build/web` 폴더 업로드

3. 배포된 URL에서 테스트:
   - https://fascinating-peony-8bbb51.netlify.app

---

## 4. 문제 해결

### Google 로그인 오류

**오류**: `No Access Token found`
- Google Cloud Console에서 Client ID가 올바르게 설정되었는지 확인
- 리디렉션 URI가 정확한지 확인

**오류**: `popup_closed_by_user`
- 정상적인 동작 (사용자가 팝업을 닫음)

### Kakao 로그인 오류

**오류**: `redirect_uri_mismatch`
- Kakao Developers에서 Redirect URI가 정확히 설정되었는지 확인
- Supabase URL이 올바른지 확인

**오류**: `invalid_client`
- REST API 키가 올바르게 입력되었는지 확인

---

## 5. 보안 참고사항

1. **Client Secret 보호**
   - Client Secret은 절대 공개 저장소에 커밋하지 마세요
   - 환경 변수로 관리하세요

2. **리디렉션 URI**
   - 승인된 리디렉션 URI만 사용하세요
   - 와일드카드(`*`)는 사용하지 마세요

3. **테스트 계정**
   - 프로덕션 배포 전 테스트 계정으로 충분히 테스트하세요

---

## 6. 참고 문서

- [Supabase Auth - Google](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase Auth - Kakao](https://supabase.com/docs/guides/auth/social-login/auth-kakao)
- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Flutter Web 배포](https://docs.flutter.dev/deployment/web)
