# Universal Links 설정 가이드

iOS Universal Links를 사용하여 OAuth 로그인 후 확인 대화상자 없이 자동으로 앱을 여는 방법입니다.

## 📋 목차

1. [개요](#개요)
2. [현재 상태 vs Universal Links](#현재-상태-vs-universal-links)
3. [필요 사항](#필요-사항)
4. [설정 단계](#설정-단계)
5. [트러블슈팅](#트러블슈팅)

---

## 개요

### Universal Links란?

**Universal Links**는 Apple이 iOS 9부터 제공하는 딥링킹 기술로, 웹 URL과 앱을 자연스럽게 연결합니다.

**작동 방식:**
- 일반적인 HTTPS URL을 클릭했을 때
- 앱이 설치되어 있으면 → 앱이 **자동으로** 열림 (대화상자 없이)
- 앱이 없으면 → Safari에서 웹페이지가 열림

### Custom URL Scheme과의 차이

| 항목 | Custom URL Scheme | Universal Links |
|------|-------------------|-----------------|
| URL 형식 | `com.example.todoapp://` | `https://yourdomain.com/` |
| 확인 대화상자 | ❌ 표시됨 ("앱에서 열겠습니까?") | ✅ 없음 (자동 실행) |
| 사용자 클릭 | ❌ 필요 ("열기" 버튼) | ✅ 불필요 |
| 웹 폴백 | ❌ 없음 | ✅ 앱 없으면 웹페이지 |
| 설정 복잡도 | ✅ 간단함 | ❌ 복잡함 |
| 도메인 필요 | ✅ 불필요 | ❌ 필수 |

---

## 현재 상태 vs Universal Links

### 현재 구현 (Custom URL Scheme) ✅ 작동 중

```dart
// 현재 코드
redirectTo: 'com.example.todoapp://login-callback'
authScreenLaunchMode: LaunchMode.externalApplication
```

**사용자 경험:**
1. Google/Kakao 로그인 완료
2. Safari에서 앱으로 전환
3. **iOS 대화상자 표시**: "'Todo App'에서 열겠습니까?"
4. **사용자가 "열기" 버튼 클릭 필요**
5. 앱 열림 및 로그인 완료

**장점:**
- ✅ 설정이 간단함
- ✅ 추가 웹 서버 설정 불필요
- ✅ 정상 작동 중

**단점:**
- ❌ 수동으로 "열기" 버튼 클릭 필요
- ❌ 한 단계 추가 동작

---

### Universal Links 적용 시 🎯 목표

```dart
// 변경 후 코드
redirectTo: 'https://bluesky78060.github.io/oauth-callback'
// authScreenLaunchMode는 제거 또는 platformDefault
```

**사용자 경험:**
1. Google/Kakao 로그인 완료
2. Safari에서 앱으로 전환
3. **대화상자 없이 자동으로 앱 열림** 🎉
4. 로그인 완료

**장점:**
- ✅ 더 매끄러운 사용자 경험
- ✅ 자동으로 앱 실행
- ✅ SEO 친화적 (검색 엔진 인덱싱)

**단점:**
- ❌ 설정이 복잡함
- ❌ 웹 서버 설정 필요
- ❌ 디버깅 어려움

---

## 필요 사항

### 1. 웹 도메인 (✅ 이미 보유)

다음 중 하나를 사용할 수 있습니다:

- **GitHub Pages**: `bluesky78060.github.io` ✅
- **Netlify**: `fascinating-peony-8bbb51.netlify.app` ✅
- 커스텀 도메인: 선택사항 (별도 구매 불필요)

> **참고**: 새 도메인을 구매할 필요가 없습니다! 이미 가지고 있는 무료 호스팅 도메인으로 충분합니다.

### 2. Apple Developer Team ID

Apple Developer 계정에서 확인:
1. [Apple Developer](https://developer.apple.com/account) 로그인
2. **Membership** 섹션으로 이동
3. **Team ID** 확인 (예: `A1B2C3D4E5`)

### 3. Bundle Identifier

Xcode 프로젝트의 Bundle ID:
- 현재: `com.example.todoapp`
- Xcode에서 확인: Runner → General → Identity → Bundle Identifier

---

## 설정 단계

### 📍 Step 1: apple-app-site-association 파일 생성

#### 1.1 GitHub Pages 사용 시

GitHub Pages 저장소에 파일 추가:

```bash
# GitHub Pages 저장소 클론
cd ~/your-github-pages-repo

# .well-known 디렉토리 생성
mkdir -p .well-known

# apple-app-site-association 파일 생성
cat > .well-known/apple-app-site-association << 'EOF'
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.example.todoapp",
        "paths": [
          "/oauth-callback",
          "/flutter-todo/oauth-callback"
        ]
      }
    ]
  }
}
EOF

# Git에 추가 및 푸시
git add .well-known/apple-app-site-association
git commit -m "Add apple-app-site-association for Universal Links"
git push origin main
```

**파일 구조:**
```
your-github-pages-repo/
├── .well-known/
│   └── apple-app-site-association  (확장자 없음!)
├── index.html
└── ...
```

**중요:**
- 파일명: `apple-app-site-association` (확장자 없이!)
- `YOUR_TEAM_ID`를 실제 Team ID로 교체
- JSON 형식 확인: `python -m json.tool < .well-known/apple-app-site-association`

#### 1.2 Netlify 사용 시

Netlify 프로젝트에 파일 추가:

**파일 구조:**
```
your-netlify-project/
├── public/
│   └── .well-known/
│       └── apple-app-site-association
└── netlify.toml
```

**netlify.toml 설정 (중요!):**
```toml
[[headers]]
  for = "/.well-known/apple-app-site-association"
  [headers.values]
    Content-Type = "application/json"
    Access-Control-Allow-Origin = "*"
```

**apple-app-site-association 파일:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.example.todoapp",
        "paths": ["/oauth-callback"]
      }
    ]
  }
}
```

#### 1.3 파일 접근 확인

브라우저에서 다음 URL에 접근하여 파일이 올바르게 배포되었는지 확인:

- GitHub Pages: `https://bluesky78060.github.io/.well-known/apple-app-site-association`
- Netlify: `https://fascinating-peony-8bbb51.netlify.app/.well-known/apple-app-site-association`

**확인 사항:**
- ✅ HTTP 200 OK 상태
- ✅ JSON 내용이 올바르게 표시됨
- ✅ 리다이렉트 없이 직접 접근 가능
- ✅ HTTPS 프로토콜 사용

---

### 📍 Step 2: iOS 앱 설정

#### 2.1 Runner.entitlements 파일 수정

파일 위치: `ios/Runner/Runner.entitlements`

**현재 내용:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:bluesky78060.github.io</string>
		<string>applinks:fascinating-peony-8bbb51.netlify.app</string>
	</array>
</dict>
</plist>
```

**주의사항:**
- ✅ `applinks:` 접두사 사용
- ❌ `https://` 프로토콜 붙이지 않음
- ❌ 포트 번호 포함하지 않음
- ❌ 경로 포함하지 않음

**예시:**
```
✅ 올바름: applinks:bluesky78060.github.io
❌ 틀림: applinks:https://bluesky78060.github.io
❌ 틀림: applinks:bluesky78060.github.io:443
❌ 틀림: applinks:bluesky78060.github.io/oauth-callback
```

#### 2.2 Xcode 프로젝트 설정 확인

Xcode에서 확인:

1. **Xcode 열기**: `ios/Runner.xcworkspace` 파일 열기
2. **Runner 타겟 선택**: 좌측 네비게이터에서 Runner 선택
3. **Signing & Capabilities 탭**:
   - **Associated Domains** 섹션 확인
   - 도메인이 올바르게 등록되어 있는지 확인

```
Domains:
  - applinks:bluesky78060.github.io
  - applinks:fascinating-peony-8bbb51.netlify.app
```

만약 **Associated Domains**가 없다면:
1. `+ Capability` 버튼 클릭
2. `Associated Domains` 검색 및 추가
3. `+` 버튼으로 도메인 추가

---

### 📍 Step 3: Supabase 설정 변경

#### 3.1 Supabase Dashboard 설정

1. [Supabase Dashboard](https://app.supabase.com) 로그인
2. 프로젝트 선택
3. **Authentication** → **URL Configuration** 이동
4. **Redirect URLs** 섹션에 추가:

**기존 (Custom URL Scheme):**
```
com.example.todoapp://login-callback
```

**추가 (Universal Links):**
```
https://bluesky78060.github.io/oauth-callback
```

또는 Netlify 사용 시:
```
https://fascinating-peony-8bbb51.netlify.app/oauth-callback
```

**최종 Redirect URLs 목록:**
```
com.example.todoapp://login-callback          (기존 - 백업용)
https://bluesky78060.github.io/oauth-callback (Universal Links)
http://localhost:53994/                       (로컬 개발용)
```

> **참고**: 기존 Custom URL Scheme도 유지하여 Universal Links가 실패할 경우 폴백으로 사용할 수 있습니다.

---

### 📍 Step 4: Flutter 코드 수정

#### 4.1 stylish_login_screen.dart 수정

파일: `lib/presentation/screens/stylish_login_screen.dart`

**현재 코드 (Custom URL Scheme):**
```dart
Future<void> _signInWithGoogle() async {
  setState(() => _isLoading = true);

  try {
    final response = await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.todoapp://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!response) {
      throw 'Google 로그인 실패';
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('Google 로그인 실패: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }
}

Future<void> _signInWithKakao() async {
  setState(() => _isLoading = true);

  try {
    final response = await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'com.example.todoapp://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!response) {
      throw 'Kakao 로그인 실패';
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('Kakao 로그인 실패: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }
}
```

**변경 후 코드 (Universal Links):**
```dart
Future<void> _signInWithGoogle() async {
  setState(() => _isLoading = true);

  try {
    final response = await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'https://bluesky78060.github.io/oauth-callback',
      // authScreenLaunchMode 제거 또는 platformDefault 사용
    );

    if (!response) {
      throw 'Google 로그인 실패';
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('Google 로그인 실패: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }
}

Future<void> _signInWithKakao() async {
  setState(() => _isLoading = true);

  try {
    final response = await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'https://bluesky78060.github.io/oauth-callback',
      // authScreenLaunchMode 제거 또는 platformDefault 사용
    );

    if (!response) {
      throw 'Kakao 로그인 실패';
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('Kakao 로그인 실패: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }
}
```

#### 4.2 oauth_redirect.dart 수정 (선택사항)

파일: `lib/core/config/oauth_redirect.dart`

**현재 코드:**
```dart
String? oauthRedirectUrl() {
  if (kIsWeb) {
    final base = Uri.base.removeFragment();
    final origin = '${base.scheme}://${base.authority}';
    final basePath = base.path;
    final normalizedBasePath = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final redirectUrl = '$origin$normalizedBasePath/oauth-callback';

    print('🔗 OAuth Redirect URL (Web): $redirectUrl');
    return redirectUrl;
  }

  // For non-web (iOS/Android/desktop), use deep link URL scheme
  final redirectUrl = 'com.example.todoapp://login-callback';
  print('🔗 OAuth Redirect URL (Mobile): $redirectUrl');
  return redirectUrl;
}
```

**Universal Links 사용 시 변경:**
```dart
String? oauthRedirectUrl() {
  if (kIsWeb) {
    final base = Uri.base.removeFragment();
    final origin = '${base.scheme}://${base.authority}';
    final basePath = base.path;
    final normalizedBasePath = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final redirectUrl = '$origin$normalizedBasePath/oauth-callback';

    print('🔗 OAuth Redirect URL (Web): $redirectUrl');
    return redirectUrl;
  }

  // For iOS/Android, use Universal Links
  final redirectUrl = 'https://bluesky78060.github.io/oauth-callback';
  print('🔗 OAuth Redirect URL (Mobile): $redirectUrl');
  return redirectUrl;
}
```

---

### 📍 Step 5: 앱 재빌드 및 테스트

#### 5.1 앱 완전 삭제 및 재설치

**중요**: Universal Links 설정은 앱 설치 시에만 검증되므로 반드시 재설치가 필요합니다.

```bash
# 1. 기존 앱 완전 삭제
# iOS 시뮬레이터/디바이스에서 앱 길게 눌러서 삭제

# 2. Flutter 빌드 캐시 정리
flutter clean

# 3. iOS 의존성 재설치
cd ios
pod install
cd ..

# 4. 앱 재빌드 및 설치
flutter run -d 34E632B4-BE3E-465F-A7A0-5CA56FDA7B2A
```

#### 5.2 테스트 절차

1. **앱 실행**: 로그인 화면으로 이동
2. **Google/Kakao 로그인 클릭**: Safari로 OAuth 페이지 열림
3. **로그인 완료**: OAuth 인증 완료
4. **결과 확인**:
   - ✅ **성공**: 대화상자 없이 자동으로 앱이 열리고 todos 화면으로 이동
   - ❌ **실패**: 대화상자가 표시되거나 Safari에 머무름

#### 5.3 로그 확인

Flutter 앱 로그:
```
flutter: 🔗 OAuth Redirect URL (Mobile): https://bluesky78060.github.io/oauth-callback
flutter: supabase.supabase_flutter: INFO: handle deeplink uri
flutter: 🔐 Auth stream update: AuthChangeEvent.signedIn, session=true
flutter: ✅ User loaded from repository
flutter: 🚦 Router redirect: location=/, isLoading=false, isAuth=true
flutter:    🏠 Authenticated at root - redirecting to todos
```

iOS 시스템 로그 (Xcode Console):
```
swcd: Received app link: https://bluesky78060.github.io/oauth-callback
swcd: Opening app: com.example.todoapp
```

---

## 트러블슈팅

### ❌ 문제 1: 파일에 접근할 수 없음

**증상:**
- 브라우저에서 `https://yourdomain.com/.well-known/apple-app-site-association`에 접근 시 404 에러

**해결방법:**
```bash
# 파일 존재 확인
ls -la .well-known/apple-app-site-association

# GitHub Pages의 경우 커밋 및 푸시 확인
git status
git push origin main

# GitHub Pages 빌드 확인
# Repository → Actions 탭에서 빌드 상태 확인
```

---

### ❌ 문제 2: JSON 형식 오류

**증상:**
- 파일에 접근 가능하지만 JSON 파싱 에러

**해결방법:**
```bash
# JSON 유효성 검사
python -m json.tool < .well-known/apple-app-site-association

# 또는 온라인 검증기 사용
# https://jsonlint.com/
```

**올바른 JSON 형식:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "A1B2C3D4E5.com.example.todoapp",
        "paths": ["/oauth-callback"]
      }
    ]
  }
}
```

---

### ❌ 문제 3: Team ID가 틀림

**증상:**
- Universal Links가 작동하지 않음
- iOS 시스템 로그에 검증 실패 메시지

**해결방법:**
1. [Apple Developer](https://developer.apple.com/account) 로그인
2. **Membership** → **Team ID** 확인
3. `appID` 형식 확인: `TEAM_ID.BUNDLE_ID`
4. 대소문자 정확히 일치해야 함

**예시:**
```
Team ID: A1B2C3D4E5
Bundle ID: com.example.todoapp
appID: A1B2C3D4E5.com.example.todoapp
```

---

### ❌ 문제 4: 여전히 대화상자가 표시됨

**증상:**
- Universal Links 설정했지만 여전히 "앱에서 열겠습니까?" 대화상자 표시

**해결방법:**

1. **앱 완전 재설치:**
   ```bash
   # 앱 삭제
   # iOS에서 앱 아이콘 길게 누르기 → 삭제

   # 재빌드 및 설치
   flutter clean
   cd ios && pod install && cd ..
   flutter run
   ```

2. **파일 캐싱 확인:**
   - Apple의 CDN이 파일을 캐시할 수 있음
   - 변경사항 반영까지 최대 24시간 소요 가능
   - 파일 수정 후 기다리거나 버전 번호 추가

3. **도메인 검증 확인:**
   ```bash
   # iOS 디바이스 로그 확인 (Xcode)
   # Window → Devices and Simulators → 디바이스 선택 → Open Console
   # 검색어: "swcd"
   ```

4. **Redirect URL 우선순위:**
   - Supabase에서 Universal Links URL이 첫 번째로 등록되어 있는지 확인
   - Custom URL Scheme보다 먼저 시도되도록 순서 조정

---

### ❌ 문제 5: Safari에서 앱으로 전환되지 않음

**증상:**
- OAuth 완료 후 Safari에 머무름
- 앱이 열리지 않음

**해결방법:**

1. **URL 형식 확인:**
   ```dart
   // ✅ 올바른 형식
   redirectTo: 'https://bluesky78060.github.io/oauth-callback'

   // ❌ 틀린 형식
   redirectTo: 'http://bluesky78060.github.io/oauth-callback'  // HTTP (X)
   redirectTo: 'bluesky78060.github.io/oauth-callback'         // 프로토콜 없음 (X)
   ```

2. **paths 매칭 확인:**
   ```json
   // apple-app-site-association
   {
     "applinks": {
       "apps": [],
       "details": [{
         "appID": "YOUR_TEAM_ID.com.example.todoapp",
         "paths": [
           "/oauth-callback",           // ← 이 경로가
           "/flutter-todo/oauth-callback"
         ]
       }]
     }
   }
   ```

   ```dart
   // Flutter 코드와 일치해야 함
   redirectTo: 'https://bluesky78060.github.io/oauth-callback'  // ← 일치!
   ```

3. **Runner.entitlements 도메인 확인:**
   ```xml
   <array>
     <string>applinks:bluesky78060.github.io</string>  <!-- https:// 없이! -->
   </array>
   ```

---

### ❌ 문제 6: 웹페이지로 리다이렉트됨

**증상:**
- Universal Links URL로 이동하지만 Safari에서 웹페이지가 열림
- 앱이 실행되지 않음

**해결방법:**

1. **웹페이지 생성 (선택사항):**

   GitHub Pages에 `oauth-callback/index.html` 생성:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
     <meta charset="UTF-8">
     <title>로그인 중...</title>
     <meta name="viewport" content="width=device-width, initial-scale=1.0">
   </head>
   <body>
     <div style="text-align: center; padding: 50px; font-family: sans-serif;">
       <h1>🔐 로그인 중...</h1>
       <p>앱으로 돌아가는 중입니다.</p>
       <p>자동으로 이동하지 않으면 <a href="com.example.todoapp://login-callback">여기를 클릭</a>하세요.</p>
     </div>
     <script>
       // 폴백: Custom URL Scheme 시도
       window.location.href = 'com.example.todoapp://login-callback';
     </script>
   </body>
   </html>
   ```

2. **앱 설치 확인:**
   - 앱이 설치되어 있는지 확인
   - 앱 재설치 후 다시 테스트

---

### 🔍 디버깅 도구

#### iOS 시스템 로그 확인

1. Xcode 열기
2. **Window** → **Devices and Simulators**
3. iOS 디바이스 선택
4. **Open Console** 클릭
5. 검색어 입력:
   - `swcd` (Shared Web Credentials Daemon)
   - `applinks`
   - `associated-domains`

**예상 로그:**
```
swcd: Validating app link for com.example.todoapp
swcd: Downloading apple-app-site-association from bluesky78060.github.io
swcd: Successfully validated app link
```

---

## 추가 참고 자료

### Apple 공식 문서
- [Universal Links](https://developer.apple.com/ios/universal-links/)
- [Supporting Associated Domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains)

### Supabase 문서
- [Supabase Auth Deep Linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [Flutter Auth Integration](https://supabase.com/docs/guides/auth/social-login/auth-google)

### 커뮤니티 리소스
- [Branch.io Deep Linking Guide](https://help.branch.io/developers-hub/docs/ios-universal-links)
- [Stack Overflow: Universal Links](https://stackoverflow.com/questions/tagged/universal-links)

---

## 요약

### ✅ Custom URL Scheme (현재 방식)

**장점:**
- 설정 간단
- 정상 작동 중
- 추가 인프라 불필요

**단점:**
- "열기" 버튼 클릭 필요

**추천 대상:**
- 빠른 구현이 필요한 경우
- 추가 설정을 원하지 않는 경우
- "열기" 버튼이 문제되지 않는 경우

---

### 🎯 Universal Links (개선 방안)

**장점:**
- 자동으로 앱 실행
- 더 나은 사용자 경험
- SEO 친화적

**단점:**
- 복잡한 설정
- 디버깅 어려움
- 캐싱 이슈 가능

**추천 대상:**
- 최고의 사용자 경험을 원하는 경우
- 이미 웹 도메인이 있는 경우
- 시간을 투자할 수 있는 경우

---

## 결론

현재 **Custom URL Scheme** 방식도 정상적으로 작동하고 있으므로, Universal Links는 선택사항입니다.

**권장사항:**
1. 현재 방식으로 충분하다면 그대로 유지
2. 더 나은 UX를 원한다면 Universal Links 구현
3. 이미 GitHub Pages/Netlify 도메인이 있으므로 추가 비용 없이 구현 가능

**"현제는 이제 최선이네"** - 현재 방식도 훌륭한 솔루션입니다! 🎉
