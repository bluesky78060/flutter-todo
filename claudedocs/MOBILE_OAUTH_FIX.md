# 모바일 OAuth 로그인 문제 해결 기록

## 문제 상황

### 증상
- **Android 모바일에서 Google OAuth 로그인이 실패**
- 웹 브라우저는 정상 작동
- 로그인 시도 후 앱이 "로그인 페이지로 다시 리디렉션"되는 현상 발생

### 발생 시점
- 2025년 11월 24일
- 앱 버전: 1.0.3+15
- 테스트 기기: Samsung Galaxy A31 (SM-A315N), Android

## 원인 분석

### 1. OAuth Redirect URL 설정 문제

**문제점:**
```dart
// ❌ 잘못된 설정 (lib/core/config/oauth_redirect.dart)
class OAuthRedirect {
  static String getRedirectUrl() {
    if (kIsWeb) {
      return '${Uri.base.origin}/oauth-callback';  // 웹: 동적 URL
    }
    // ❌ 모바일: 하드코딩된 URL이 Supabase 설정과 불일치
    return 'https://todo-kr-bluesky.vercel.app/oauth-callback';
  }
}
```

**근본 원인:**
- 모바일 앱에서 사용하는 redirect URL이 Supabase Dashboard에 등록된 URL과 달랐음
- Supabase는 정확히 등록된 redirect URL만 허용
- 웹은 동적 URL 생성으로 자동 매칭되지만, 모바일은 하드코딩된 URL로 인해 불일치 발생

### 2. 개발 모드 설정 혼동

**문제점:**
```dart
// ❌ 개발 모드가 활성화되어 있었음 (lib/core/config/dev_config.dart)
class DevConfig {
  static const bool enableLocalDevMode = true;  // ❌ 실제 인증을 우회
}
```

**부작용:**
- 실제 OAuth 플로우가 실행되지 않음
- 인증 없이 앱 접근 가능 (테스트 모드)
- 실제 사용자 인증이 필요한 기능 테스트 불가

## 해결 방법

### 1단계: OAuth Redirect URL 수정

**수정 내용:**
```dart
// ✅ 수정된 설정 (lib/core/config/oauth_redirect.dart)
class OAuthRedirect {
  static String getRedirectUrl() {
    if (kIsWeb) {
      return '${Uri.base.origin}/oauth-callback';
    }
    // ✅ Supabase에 등록된 정확한 URL 사용
    return 'https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/callback';
  }
}
```

**변경 이유:**
- Supabase의 표준 콜백 URL 형식 사용
- `https://{project-ref}.supabase.co/auth/v1/callback` 형식은 Supabase가 자동으로 처리
- 별도의 커스텀 redirect URL 등록 불필요

### 2단계: 개발 모드 비활성화

**수정 내용:**
```dart
// ✅ 수정된 설정 (lib/core/config/dev_config.dart)
class DevConfig {
  static const bool enableLocalDevMode = false;  // ✅ 실제 인증 활성화
}
```

### 3단계: 앱 재빌드 및 배포

**실행 명령:**
```bash
# 기존 Flutter 프로세스 종료
killall -9 flutter dart

# 앱 강제 종료
~/Library/Android/sdk/platform-tools/adb -s RF9NB0146AB shell am force-stop kr.bluesky.dodo

# 디버그 빌드 및 설치
flutter run -d RF9NB0146AB --debug
```

## 검증 결과

### 성공 로그 확인
```
I/flutter: 🐛 🔐 Auth stream update: AuthChangeEvent.initialSession, session=true
I/flutter: 🐛 ✅ User loaded from repository: 734415437
I/flutter: 🐛 🔔 AuthNotifier: Auth state changed from false to true
I/flutter: 🐛    ✅ Authenticated - redirecting to todos
```

### 테스트 시나리오
1. ✅ Google OAuth 로그인 성공
2. ✅ 사용자 세션 유지 확인
3. ✅ Todo 목록 로드 성공
4. ✅ 앱 재시작 후에도 로그인 상태 유지

## 교훈 및 권장사항

### 1. OAuth Redirect URL 관리

**Best Practices:**
- **웹**: 동적 URL 생성 사용 (`Uri.base.origin`)
- **모바일**: Supabase 표준 콜백 URL 사용
  ```dart
  // 권장 형식
  'https://{project-ref}.supabase.co/auth/v1/callback'
  ```
- **Supabase Dashboard**: 배포 환경별 URL 미리 등록
  - 개발: `http://localhost:*`
  - 스테이징: `https://staging.example.com/oauth-callback`
  - 프로덕션: `https://example.com/oauth-callback`

### 2. 개발 모드 관리

**개발 워크플로우:**
```dart
// UI 테스트 시에만 활성화
DevConfig.enableLocalDevMode = true;   // UI 레이아웃, 애니메이션 테스트

// OAuth/인증 테스트 시 비활성화
DevConfig.enableLocalDevMode = false;  // 실제 로그인 플로우 테스트
```

### 3. 디버깅 팁

**문제 재현 시 확인 사항:**
1. `oauth_redirect.dart`의 URL이 Supabase Dashboard와 일치하는가?
2. `dev_config.dart`의 `enableLocalDevMode`가 `false`인가?
3. Supabase Dashboard의 "Authentication > URL Configuration"에서:
   - Redirect URLs 목록 확인
   - Site URL 설정 확인
4. Android 로그 확인:
   ```bash
   adb logcat | grep -E "(OAuth|Supabase|Auth|Error)"
   ```

### 4. 플랫폼별 OAuth 처리

**Flutter Supabase SDK의 동작 방식:**
- **웹**: `window.location` 기반 리디렉션
- **Android/iOS**:
  - Deep linking 자동 처리
  - Supabase 표준 콜백 URL 사용 권장
  - `supabase_flutter` 패키지가 자동으로 세션 복원

**코드 예시:**
```dart
// ✅ 권장: 플랫폼별 자동 처리
final response = await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
  // Supabase SDK가 플랫폼에 맞는 redirect URL 자동 사용
);

// ❌ 비권장: 수동 redirect URL 지정 (불일치 발생 가능)
final response = await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'https://custom-url.com/callback',  // 위험!
);
```

## 관련 파일

- `lib/core/config/oauth_redirect.dart` - OAuth redirect URL 설정
- `lib/core/config/dev_config.dart` - 개발 모드 설정
- `lib/presentation/providers/auth_providers.dart` - 인증 로직
- `lib/core/router/app_router.dart` - 라우팅 및 인증 가드

## 참고 문서

- [Supabase Flutter OAuth 가이드](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Flutter Deep Linking](https://docs.flutter.dev/ui/navigation/deep-linking)
- `CLAUDE.md` - 프로젝트 개발 가이드

## 마지막 업데이트

- **날짜**: 2025-11-24
- **작성자**: Claude Code
- **상태**: ✅ 해결 완료
- **테스트**: Samsung Galaxy A31 (Android) 검증 완료
