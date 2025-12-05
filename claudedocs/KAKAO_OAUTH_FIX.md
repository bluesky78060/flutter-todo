# 카카오 OAuth 로그인 구현 및 수정 내역

## 날짜: 2025-12-05

### 문제
카카오 OAuth 로그인이 Android에서 작동하지 않음

### 원인
Android `AndroidManifest.xml`에 Kakao SDK가 요구하는 `AuthCodeHandlerActivity`가 누락됨

### 해결 과정

#### 1. Kakao 문서 분석
- 참고 문서: https://developers.kakao.com/docs/latest/ko/kakaologin/android#before-you-begin-type
- Kakao OAuth를 위해서는 `AuthCodeHandlerActivity`를 AndroidManifest.xml에 추가해야 함

#### 2. AndroidManifest.xml 수정
```xml
<!-- Kakao Login AuthCodeHandler Activity -->
<activity
    android:name="com.kakao.sdk.auth.AuthCodeHandlerActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:host="oauth"
              android:scheme="kakaoc60f7lf25b58df96dedbb8b06a4003ef" />
    </intent-filter>
</activity>
```

#### 3. 카카오톡 앱 로그인으로 변경
사용자 요청에 따라 웹 기반 로그인에서 카카오톡 앱 로그인으로 변경:

**login_screen.dart** (line 101):
```dart
authScreenLaunchMode: LaunchMode.externalApplication, // 카카오톡 앱 우선 사용
```

**AndroidManifest.xml**에 KakaoTalk 패키지 쿼리 추가:
```xml
<queries>
    <!-- Kakao Talk package for login -->
    <package android:name="com.kakao.talk" />
</queries>
```

### 동작 방식
1. **카카오톡 설치됨**: 카카오톡 앱이 자동으로 열려 로그인
2. **카카오톡 미설치**: 웹 브라우저로 자동 전환하여 계정 로그인

### 빌드 정보
- **버전**: 1.0.17+49
- **빌드 타입**: Release APK
- **파일 크기**: 160.8MB
- **빌드 위치**:
  - APK: `build/app/outputs/flutter-apk/app-release.apk`
  - AAB: `build/app/outputs/bundle/release/app-release.aab`

### 테스트 완료
✅ Release APK 빌드 성공
✅ 디바이스 설치 완료
✅ 앱 실행 확인

### 주의사항
- Google Play Console 현재 업로드 버전: 1.0.16+48
- 다음 빌드는 반드시 빌드 번호 49 이상 사용 필요

### Debug Symbols Strip 경고 해결 시도

#### 시도한 해결 방법
1. **NDK 버전 명시**: `android/app/build.gradle.kts`에 `ndkVersion = "28.2.13676358"` 추가
2. **Debug Symbol Level 변경**: `debugSymbolLevel = "NONE"` → `debugSymbolLevel = "FULL"`
3. **Keep Debug Symbols 제거**: `keepDebugSymbols += "**/*.so"` 라인 삭제

#### 결과
- Flutter 3.x의 알려진 이슈로 현재 해결 불가
- AAB 빌드 시 경고는 표시되지만 업로드 및 배포에는 문제 없음
- APK 빌드는 경고 없이 정상 작동

#### 권장사항
- 테스트용: APK 사용 (빌드 시간 단축, 경고 없음)
- 프로덕션 배포: AAB 사용 (Play Console 최적화 지원)
- 경고는 무시 가능 (앱 기능에 영향 없음)