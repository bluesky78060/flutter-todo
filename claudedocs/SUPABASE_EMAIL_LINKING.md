# Supabase 이메일 계정 연동 설정 가이드

## 현재 구현 상태

### Windows 위젯 이메일 로그인
- **파일**: `lib/platforms/windows/widget_login_screen.dart`
- **구현**: 이메일/패스워드를 통한 로그인
- **메서드**: `client.auth.signInWithPassword()`

### Auth 플로우
1. Windows 위젯 → `authActions.login(email, password)`
2. AuthActions → `authRepositoryProvider.login()`
3. SupabaseAuthRepository → `dataSource.login()`
4. SupabaseAuthDataSource → `client.auth.signInWithPassword()`

## Supabase 이메일 연동 설정 확인 방법

### 1. Supabase Dashboard 접속
1. [Supabase Dashboard](https://app.supabase.com)에 로그인
2. 프로젝트 선택
3. **Authentication** → **Providers** 메뉴로 이동

### 2. 이메일 연동 설정 확인

#### Email Provider 설정
- **Email** 섹션에서 다음 설정 확인:
  - ✅ **Enable Email Provider**: 활성화되어 있어야 함
  - ✅ **Enable Email Confirmations**: 이메일 인증 필요 여부

#### Account Linking 설정
**Authentication** → **Settings** → **Auth Providers** 에서:

1. **Allow new users to sign up**:
   - 새로운 사용자 가입 허용 여부

2. **Link accounts with matching emails** (중요! 🔴):
   - **활성화**: 같은 이메일로 SNS 로그인과 이메일 로그인 시 자동으로 같은 계정으로 연결
   - **비활성화**: 같은 이메일이라도 다른 계정으로 생성됨

## 권장 설정

### 같은 이메일로 연동하려면:

1. **Supabase Dashboard** → **Authentication** → **Settings**
2. **Security** 섹션에서:
   ```
   ✅ One account per email address
   ```
   이 옵션을 활성화하면:
   - Google로 `user@example.com` 로그인 후
   - 같은 `user@example.com`으로 이메일/패스워드 로그인 시도 시
   - 자동으로 같은 계정으로 연결됨

### 추가 보안 설정:
```
✅ Secure email change
✅ Secure password change
```

## 현재 코드 분석

### 이메일 로그인 (Windows 위젯)
```dart
// widget_login_screen.dart
await authActions.login(
  _emailController.text.trim(),
  _passwordController.text,
);
```

### OAuth 로그인 (Google/Kakao)
```dart
// login_screen.dart
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google, // 또는 .kakao
  redirectTo: redirectUrl,
);
```

## 테스트 시나리오

### 시나리오 1: SNS → 이메일 로그인
1. Google/Kakao로 `test@example.com` 계정 로그인
2. 로그아웃
3. Windows 위젯에서 같은 `test@example.com`으로 이메일/패스워드 로그인 시도

### 시나리오 2: 이메일 → SNS 로그인
1. Windows 위젯에서 `test@example.com`으로 회원가입
2. 로그아웃
3. Google/Kakao로 같은 `test@example.com` 로그인 시도

## 예상 결과

### "One account per email" 활성화 시:
- ✅ 두 시나리오 모두 같은 계정으로 로그인됨
- ✅ 사용자 데이터(할 일 목록) 공유됨
- ✅ `user.id` (UUID)가 동일함

### "One account per email" 비활성화 시:
- ❌ 각각 다른 계정으로 생성됨
- ❌ 할 일 목록이 분리됨
- ❌ 다른 `user.id`를 가짐

## 추가 고려사항

### 1. 패스워드 설정
- OAuth로 먼저 가입한 사용자가 이메일 로그인을 하려면 패스워드 설정 필요
- "Forgot Password" 기능으로 패스워드 설정 가능

### 2. 메타데이터 동기화
- OAuth 로그인 시: `avatar_url`, `display_name` 등 추가 정보 제공
- 이메일 로그인 시: 기본 정보만 제공
- 계정 연동 시 메타데이터가 병합됨

### 3. 보안 고려사항
- 이메일 인증 활성화 권장
- Rate limiting 설정으로 무차별 대입 공격 방지

## 구현 권장사항

### 1. 통합 로그인 화면
Windows 위젯에도 OAuth 로그인 옵션 추가 고려:
```dart
// OAuth 버튼 추가
ElevatedButton.icon(
  icon: Icon(Icons.g_mobiledata),
  label: Text('Google로 로그인'),
  onPressed: () => _signInWithOAuth(OAuthProvider.google),
)
```

### 2. 계정 연결 상태 표시
프로필 화면에서 연결된 로그인 방법 표시:
- ✅ 이메일/패스워드
- ✅ Google
- ✅ Kakao

### 3. 에러 처리 개선
```dart
// 이미 다른 방법으로 가입된 이메일 처리
if (error.contains('User already registered')) {
  showDialog('이미 다른 방법으로 가입된 이메일입니다. SNS 로그인을 시도해보세요.');
}
```

## 결론

현재 코드는 이메일 연동을 지원하도록 구현되어 있으며, Supabase Dashboard에서 **"One account per email address"** 설정이 활성화되어 있다면 같은 이메일로 SNS 로그인과 이메일 로그인이 자동으로 연동됩니다.

설정 확인 후 테스트를 진행하여 정상 작동 여부를 검증하시기 바랍니다.