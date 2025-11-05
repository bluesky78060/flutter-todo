# Supabase OAuth Deep Link 설정 가이드

## 문제 상황
소셜 로그인(Google, Kakao) 시 Safari 브라우저로 이동하여 로그인 후 앱으로 돌아오지 않는 문제

## 해결 방법: Supabase 대시보드에 Redirect URL 추가

### 1단계: Supabase 대시보드 접속

브라우저에서 다음 URL로 접속:
```
https://supabase.com/dashboard/project/bulwfcsyqgsvmbadhlye/auth/url-configuration
```

또는:
1. https://supabase.com 접속
2. 로그인
3. 프로젝트 `bulwfcsyqgsvmbadhlye` 선택
4. 왼쪽 메뉴에서 **Authentication** 클릭
5. **URL Configuration** 탭 클릭

### 2단계: Redirect URLs 설정

**"Additional Redirect URLs"** 섹션에서:

#### 옵션 1: 특정 경로 지정 (권장)
```
com.example.todoapp://login-callback
```

#### 옵션 2: 와일드카드 사용
```
com.example.todoapp://**
```

**중요**:
- URL 끝에 슬래시(`/`)가 있는지 확인
- 정확히 `com.example.todoapp`를 사용 (대소문자 구분)

### 3단계: 저장

1. **"Save"** 버튼 클릭
2. 설정이 저장되었는지 확인

### 4단계: OAuth Provider 설정 확인

같은 페이지의 **"External OAuth Providers"** 섹션에서:

#### Google OAuth
- **Enabled** 체크 확인
- **Client ID** 입력 확인
- **Client Secret** 입력 확인
- **Redirect URL**에 `com.example.todoapp://login-callback` 포함 확인

#### Kakao OAuth
- **Enabled** 체크 확인
- **Client ID (REST API Key)** 입력 확인
- **Redirect URL**에 `com.example.todoapp://login-callback` 포함 확인

### 5단계: 테스트

1. iOS 시뮬레이터에서 앱 실행
2. Google 또는 Kakao 소셜 로그인 버튼 클릭
3. Safari에서 로그인 진행
4. **자동으로 앱으로 돌아오는지 확인**
5. Todo 리스트 화면으로 이동하는지 확인

## 설정이 제대로 안 되는 경우

### 체크리스트:
- [ ] Supabase 대시보드에 `com.example.todoapp://login-callback` 추가됨
- [ ] Google/Kakao OAuth Provider가 활성화됨
- [ ] Client ID와 Secret이 정확히 입력됨
- [ ] iOS Info.plist에 `com.example.todoapp` URL Scheme 있음
- [ ] Android AndroidManifest.xml에 deep link intent filter 있음

### 디버깅 로그 확인:
앱 실행 시 다음 로그를 확인:
```
🔗 OAuth Redirect URL (Mobile): com.example.todoapp://oauth-callback
```

OAuth 로그인 시도 시:
```
🔐 Auth state changed: AuthChangeEvent.signedIn
✅ User signed in: [user_id]
```

## 추가 도움말

- Supabase 공식 문서: https://supabase.com/docs/guides/auth/native-mobile-deep-linking
- 문제가 계속되면 Supabase 콘솔의 "Logs" 섹션에서 에러 확인
