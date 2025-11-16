# iOS Xcode 프로젝트 최종 설정 가이드

Apple Developer Console 설정 완료 후 Xcode에서 수행해야 할 작업들입니다.

## 1. Xcode 프로젝트 열기

```bash
cd ios
open Runner.xcworkspace  # ⚠️ .xcodeproj 아님! .xcworkspace 사용 필수
```

## 2. Signing & Capabilities 설정 확인

### 2.1 Signing 설정
1. Xcode에서 **Runner** 프로젝트 선택
2. **Targets → Runner** 선택
3. **Signing & Capabilities** 탭 선택
4. 다음 항목 확인:
   - ✅ **Team**: 본인의 Apple Developer Team 선택
   - ✅ **Bundle Identifier**: `kr.bluesky.dodo` (자동으로 설정됨)
   - ✅ **Automatically manage signing**: 체크 (권장)
   - ✅ **Provisioning Profile**: Xcode Managed Profile (자동 생성)

### 2.2 Capabilities 확인

**필수 Capabilities** (이미 추가되어 있어야 함):

#### Associated Domains
- ✅ **Status**: Enabled
- ✅ **Domains**:
  - `applinks:bulwfcsyqgsvmbadhlye.supabase.co`

#### Background Modes
- ✅ **Status**: Enabled
- ✅ **Modes**:
  - `Background fetch` (체크)
  - `Remote notifications` (체크)

#### Push Notifications (선택사항, 향후 사용)
- Status: Disabled (현재는 불필요)
- 향후 푸시 알림 필요 시 활성화

### 2.3 Capabilities 누락 시 추가 방법

만약 Associated Domains가 없다면:

1. **+ Capability** 버튼 클릭
2. **Associated Domains** 검색 및 추가
3. **Domains** 섹션에서 **+** 버튼 클릭
4. `applinks:bulwfcsyqgsvmbadhlye.supabase.co` 입력

## 3. Info.plist 설정 확인

**Runner/Info.plist** 파일에서 확인:

```xml
<!-- URL Scheme (Custom URL 방식) -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kr.bluesky.dodo</string>
        </array>
    </dict>
</array>

<!-- Google OAuth Client ID -->
<key>GIDClientID</key>
<string>621785374771-2a4meibhjq1lmq4ccon9c5imt0ds9eks.apps.googleusercontent.com</string>

<!-- Associated Domains (Universal Links) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:bulwfcsyqgsvmbadhlye.supabase.co</string>
</array>
```

✅ **이미 모두 설정되어 있음** - 확인만 하시면 됩니다.

## 4. Runner.entitlements 확인

**Runner/Runner.entitlements** 파일 확인:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:bulwfcsyqgsvmbadhlye.supabase.co</string>
</array>
```

✅ **이미 설정되어 있음**

## 5. Apple Developer Console 최종 확인

https://developer.apple.com/account/resources/identifiers/list

### App ID (kr.bluesky.dodo) 확인사항:

1. **Capabilities** 섹션:
   - ✅ Associated Domains (Enabled)
   - ✅ Push Notifications (선택사항)

2. **App ID 수정** (필요 시):
   - App ID 선택 → **Edit** 버튼
   - **Associated Domains** 체크
   - **Save** 클릭

### Provisioning Profile 재생성 (필요 시)

Capabilities를 수정했다면 Provisioning Profile을 재생성해야 합니다:

1. https://developer.apple.com/account/resources/profiles/list
2. 기존 Profile 찾기 (kr.bluesky.dodo 관련)
3. **Edit** → **Generate** 클릭
4. Xcode에서 **Preferences → Accounts → Download Manual Profiles** (자동 관리 사용 시 불필요)

## 6. 테스트 빌드 및 실행

### 6.1 시뮬레이터에서 실행

```bash
# iOS 시뮬레이터 목록 확인
flutter devices

# 시뮬레이터 실행
flutter run -d <simulator-id>
```

### 6.2 실제 기기에서 테스트 (권장)

OAuth 및 Universal Links는 **실제 기기에서만 제대로 작동**합니다.

```bash
# 연결된 기기 확인
flutter devices

# 기기에서 실행
flutter run -d <device-id>
```

### 6.3 Release 빌드 (App Store 제출용)

```bash
# Release 빌드 (코드 서명 없이)
flutter build ios --release --no-codesign

# 이후 Xcode에서 Archive 수행:
# 1. Xcode에서 Runner.xcworkspace 열기
# 2. Product → Archive 선택
# 3. Organizer에서 Distribute App 진행
```

## 7. OAuth 테스트 체크리스트

실제 기기에서 테스트:

- [ ] **Google OAuth 로그인**
  - 앱에서 Google 로그인 버튼 클릭
  - Safari/In-App Browser에서 Google 로그인 페이지 열림
  - 로그인 완료 후 앱으로 자동 복귀
  - 사용자 정보 표시 확인

- [ ] **Kakao OAuth 로그인**
  - 앱에서 Kakao 로그인 버튼 클릭
  - Kakao 로그인 페이지 열림
  - 로그인 완료 후 앱으로 자동 복귀
  - 사용자 정보 표시 확인

- [ ] **Deep Link 동작 확인**
  - Safari에서 `kr.bluesky.dodo://` URL 테스트
  - 앱이 자동으로 열리는지 확인

- [ ] **Universal Link 동작 확인**
  - Safari에서 `https://bulwfcsyqgsvmbadhlye.supabase.co/...` URL 테스트
  - 앱이 자동으로 열리는지 확인 (앱 설치된 경우)

## 8. 문제 해결

### "No profiles for 'kr.bluesky.dodo' were found" 에러

**원인**: Provisioning Profile이 없거나 만료됨

**해결**:
1. Xcode → **Preferences** → **Accounts**
2. Apple ID 선택 → **Download Manual Profiles** 클릭
3. 또는 **Automatically manage signing** 체크로 자동 생성

### OAuth 후 앱으로 돌아오지 않음

**원인**: Associated Domains 설정 누락 또는 URL Scheme 오류

**해결**:
1. **Signing & Capabilities**에서 Associated Domains 확인
2. Info.plist의 CFBundleURLSchemes 확인
3. AppDelegate.swift의 deep link 핸들러 확인

### "Code signing failed" 에러

**원인**: 인증서나 팀 설정 문제

**해결**:
1. **Signing & Capabilities** → Team 선택 확인
2. Xcode → **Preferences** → **Accounts** → **Manage Certificates** 확인
3. 필요 시 새 인증서 생성 (Apple Development)

### Universal Links가 작동하지 않음

**원인**: apple-app-site-association 파일 문제 또는 설정 미스매치

**해결**:
1. Supabase Dashboard에서 Associated Domains 설정 확인
2. 브라우저에서 확인: `https://bulwfcsyqgsvmbadhlye.supabase.co/.well-known/apple-app-site-association`
3. App ID와 Bundle Identifier 일치 여부 확인

## 9. 다음 단계

설정 완료 후:

1. ✅ **버전 업데이트**: pubspec.yaml에서 버전 증가
2. ✅ **Release 빌드**: `flutter build ios --release`
3. ✅ **Xcode Archive**: Product → Archive
4. ✅ **App Store Connect 업로드**: Organizer → Distribute App
5. ✅ **TestFlight 베타 테스트**: 내부 또는 외부 테스터 초대
6. ✅ **App Store 제출**: 리뷰 제출 및 승인 대기

## 참고 문서

- [Apple Developer - Configuring Associated Domains](https://developer.apple.com/documentation/xcode/configuring-an-associated-domain)
- [Supabase - Deep Linking](https://supabase.com/docs/guides/auth/social-login/auth-deep-linking)
- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios/start-integrating)
- [APPLE_IDS_GUIDE.md](APPLE_IDS_GUIDE.md) - Apple ID 생성 가이드
- [IOS_CONFIGURATION_CHECKLIST.md](IOS_CONFIGURATION_CHECKLIST.md) - 전체 체크리스트
