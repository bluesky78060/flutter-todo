# iOS 설정 완료 체크리스트

iOS 앱 배포 전 필수 설정 항목들입니다.

## 📋 완료된 설정 ✅

### 1. 프로젝트 기본 설정
- ✅ **Bundle Identifier**: `kr.bluesky.dodo`
  - 위치: [ios/Runner.xcodeproj/project.pbxproj](ios/Runner.xcodeproj/project.pbxproj)
- ✅ **App Display Name**: DoDo
  - 위치: [ios/Runner/Info.plist](ios/Runner/Info.plist:7-8)
- ✅ **버전 관리**: Flutter pubspec.yaml과 자동 동기화
  - `MARKETING_VERSION`: `$(FLUTTER_BUILD_NAME)`
  - `CURRENT_PROJECT_VERSION`: `$(FLUTTER_BUILD_NUMBER)`

### 2. 앱 아이콘
- ✅ **모든 크기 아이콘 생성 완료**
  - 위치: [ios/Runner/Assets.xcassets/AppIcon.appiconset/](ios/Runner/Assets.xcassets/AppIcon.appiconset/)
  - 1024x1024 (App Store), 180x180, 120x120, 87x87, 80x80, 76x76, 60x60, 58x58, 40x40, 29x29, 20x20
- ✅ **iPad 아이콘 포함**

### 3. 권한 설정 (Info.plist)
- ✅ **알림 권한** (NSUserNotificationsUsageDescription)
  ```xml
  <string>할 일 알림을 보내기 위해 알림 권한이 필요합니다.</string>
  ```
- ✅ **사진 라이브러리 권한** (NSPhotoLibraryUsageDescription)
  ```xml
  <string>파일을 업로드하기 위해 사진 라이브러리 접근 권한이 필요합니다.</string>
  ```
- ✅ **카메라 권한** (NSCameraUsageDescription)
  ```xml
  <string>파일을 업로드하기 위해 카메라 접근 권한이 필요합니다.</string>
  ```

### 4. 딥링크 설정
- ✅ **커스텀 URL Scheme** (CFBundleURLTypes)
  ```xml
  <key>CFBundleURLSchemes</key>
  <array>
    <string>kr.bluesky.dodo</string>
  </array>
  ```
  - OAuth 콜백: `kr.bluesky.dodo://oauth-callback`

### 5. Background Modes
- ✅ **백그라운드 작업 활성화** (UIBackgroundModes)
  ```xml
  <array>
    <string>fetch</string>
    <string>remote-notification</string>
  </array>
  ```

### 6. AppDelegate 설정
- ✅ **Deep Links 처리** (AppDelegate.swift)
  - `application:open:url:options:`
- ✅ **Universal Links 처리** (AppDelegate.swift)
  - `application:continue:userActivity:restorationHandler:`
  - 위치: [ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift:14-30)

### 7. Podfile 설정
- ✅ **iOS 14.0 이상 타겟**
  ```ruby
  platform :ios, '14.0'
  ```
- ✅ **SQLite3 경고 처리**
  - Warning 억제 설정 완료
  - 위치: [ios/Podfile](ios/Podfile:39-54)

---

## ⚠️ 배포 전 필수 설정 항목

### 1. Google OAuth Client ID 설정

**현재 상태**: 플레이스홀더 값
```xml
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID_HERE</string>
```

**설정 필요**:
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택 → **APIs & Services** → **Credentials**
3. **Create Credentials** → **OAuth 2.0 Client ID**
4. Application type: **iOS**
5. Bundle ID: `kr.bluesky.dodo` 입력
6. 생성된 Client ID를 복사

**Info.plist 업데이트**:
```xml
<key>GIDClientID</key>
<string>123456789-abcdefghijklmnop.apps.googleusercontent.com</string>
```

**위치**: [ios/Runner/Info.plist](ios/Runner/Info.plist:72-73)

---

### 2. Supabase Associated Domains 설정

**현재 상태**: 플레이스홀더 값
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:your-supabase-project.supabase.co</string>
</array>
```

**설정 필요**:
1. Supabase 프로젝트의 **Project URL** 확인
   - 예: `https://abcdefghijklmnop.supabase.co`
2. Project ID 추출: `abcdefghijklmnop`

**Info.plist 업데이트**:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:abcdefghijklmnop.supabase.co</string>
</array>
```

**Xcode에서 추가 설정**:
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. **Runner** 프로젝트 선택
3. **Signing & Capabilities** 탭
4. **+ Capability** 버튼 클릭
5. **Associated Domains** 추가
6. **Domains** 섹션에 추가:
   - `applinks:abcdefghijklmnop.supabase.co`

**위치**: [ios/Runner/Info.plist](ios/Runner/Info.plist:75-78)

---

### 3. Apple Developer Account 설정

#### 필수 요구사항
- ✅ Apple Developer Program 가입 ($99/년)
- ✅ App Store Connect 접근 권한

#### Xcode Signing 설정
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. **Runner** 프로젝트 선택 → **Signing & Capabilities**
3. 설정:
   ```
   ✅ Automatically manage signing (권장)
   Team: [본인 Apple Developer 팀 선택]
   Bundle Identifier: kr.bluesky.dodo (자동 입력됨)
   ```

#### Capabilities 추가 확인
다음 Capabilities가 활성화되어야 합니다:
- [ ] **Associated Domains** (Supabase Deep Link용)
- [ ] **Push Notifications** (알림용)
- [ ] **Background Modes** (백그라운드 알림용)

---

## 🔧 빌드 전 설정

### 1. CocoaPods 설치
```bash
cd ios
pod install
cd ..
```

### 2. 빌드 테스트
```bash
# 시뮬레이터에서 테스트
flutter run -d <ios-simulator-id>

# 릴리즈 빌드 (서명 없이)
flutter build ios --release --no-codesign
```

### 3. Archive 및 배포
1. Xcode에서 **Product** → **Archive**
2. Organizer → **Distribute App**
3. **App Store Connect** 선택
4. 업로드 완료

---

## 📝 배포 전 최종 체크리스트

### 코드 설정
- [ ] Google OAuth Client ID를 실제 값으로 변경
- [ ] Supabase Associated Domains를 실제 값으로 변경
- [ ] Info.plist의 모든 플레이스홀더 확인

### Xcode 설정
- [ ] Apple Developer 계정 로그인
- [ ] Team 선택 완료
- [ ] Automatically manage signing 활성화
- [ ] Associated Domains Capability 추가
- [ ] Push Notifications Capability 추가
- [ ] Background Modes Capability 추가

### 빌드 테스트
- [ ] 시뮬레이터에서 앱 실행 확인
- [ ] 실제 기기에서 테스트 완료
- [ ] Google 로그인 테스트 (실제 기기)
- [ ] Kakao 로그인 테스트 (실제 기기)
- [ ] 알림 기능 테스트 (실제 기기)
- [ ] 딥링크 동작 확인

### App Store Connect
- [ ] 앱 등록 완료
- [ ] 스크린샷 준비 (필수 크기)
  - 6.7" (1290 x 2796)
  - 6.5" (1242 x 2688)
- [ ] 앱 설명 작성 (한글/영문)
- [ ] 개인정보처리방침 URL 준비
- [ ] 지원 URL 준비
- [ ] 연령 등급 설정
- [ ] 가격 및 배포 지역 설정

### 문서 및 버전
- [ ] 버전 번호 확인 (예: 1.0.5)
- [ ] 빌드 번호 확인 (예: 15)
- [ ] RELEASE_NOTES.md 업데이트
- [ ] VERSION_HISTORY.md 업데이트 (선택)

---

## 🚀 빌드 명령어

### 빌드 스크립트 사용 (권장)
```bash
# 기본 버전으로 빌드
./scripts/build_ios.sh

# 커스텀 버전으로 빌드
./scripts/build_ios.sh 1.0.6 16
```

### 수동 빌드
```bash
flutter build ios \
  --release \
  --build-name=1.0.6 \
  --build-number=16 \
  --no-codesign
```

---

## 📚 관련 문서

- [IOS_SETUP_GUIDE.md](IOS_SETUP_GUIDE.md) - Apple Developer 계정 설정 및 인증서 생성
- [VERSION_MANAGEMENT.md](VERSION_MANAGEMENT.md) - 플랫폼별 버전 관리
- [IOS_NOTIFICATION_GUIDE.md](IOS_NOTIFICATION_GUIDE.md) - iOS 알림 설정 상세 가이드

---

## ⚡ 빠른 참조

### Info.plist 설정 위치
```bash
# 파일 열기
open ios/Runner/Info.plist

# 또는 Xcode에서
open ios/Runner.xcworkspace
# Navigator에서 Runner > Info.plist 선택
```

### 설정해야 할 두 가지 항목
1. **Line 73**: `YOUR_GOOGLE_CLIENT_ID_HERE` → 실제 Client ID
2. **Line 77**: `your-supabase-project.supabase.co` → 실제 Project URL

### 빌드 전 확인
```bash
# pubspec.yaml 버전 확인
grep "^version:" pubspec.yaml

# Info.plist에서 플레이스홀더 확인
grep -E "YOUR_|your-" ios/Runner/Info.plist
```

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2025-11-16
**작성자**: Claude Code
