# Google OAuth iOS Client ID 설정 가이드

iOS 앱에서 Google 로그인을 사용하기 위한 Client ID 설정 방법입니다.

## 목차
1. [Google Cloud Console 설정](#1-google-cloud-console-설정)
2. [iOS Client ID 생성](#2-ios-client-id-생성)
3. [Info.plist 업데이트](#3-infoplist-업데이트)
4. [검증 및 테스트](#4-검증-및-테스트)

---

## 1. Google Cloud Console 설정

### Step 1: Google Cloud Console 접속
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. Google 계정으로 로그인

### Step 2: 프로젝트 선택 또는 생성

#### 기존 프로젝트가 있는 경우:
1. 상단의 **프로젝트 선택** 드롭다운 클릭
2. 현재 사용 중인 프로젝트 선택 (예: "DoDo Todo App")

#### 새 프로젝트 생성하는 경우:
1. 상단의 **프로젝트 선택** 드롭다운 클릭
2. **새 프로젝트** 클릭
3. 프로젝트 정보 입력:
   ```
   프로젝트 이름: DoDo Todo App
   위치: 조직 없음 (개인 프로젝트)
   ```
4. **만들기** 클릭

---

## 2. iOS Client ID 생성

### Step 1: OAuth 동의 화면 설정 (최초 1회)

1. 좌측 메뉴 → **API 및 서비스** → **OAuth 동의 화면**
2. User Type 선택:
   - **외부** (일반 사용자용) 선택
   - **만들기** 클릭

3. **앱 정보** 입력:
   ```yaml
   앱 이름: DoDo
   사용자 지원 이메일: 본인 이메일
   앱 로고: (선택사항)
   앱 도메인:
     - 애플리케이션 홈페이지: https://your-domain.com (있는 경우)
     - 개인정보처리방침: https://your-domain.com/privacy (필수)
     - 서비스 약관: https://your-domain.com/terms (선택)
   승인된 도메인: (비워두기)
   개발자 연락처 정보: 본인 이메일
   ```

4. **저장 후 계속** 클릭

5. **범위(Scopes)** 단계:
   - **범위 추가 또는 삭제** 클릭
   - 필수 범위 선택:
     - `openid`
     - `profile`
     - `email`
   - **업데이트** 클릭
   - **저장 후 계속** 클릭

6. **테스트 사용자** 단계:
   - 개발/테스트 중에는 본인 이메일 추가
   - **사용자 추가** 클릭 → 이메일 입력
   - **저장 후 계속** 클릭

7. **요약** 확인 후 **대시보드로 돌아가기** 클릭

### Step 2: iOS Client ID 생성

1. 좌측 메뉴 → **API 및 서비스** → **사용자 인증 정보**
2. 상단의 **+ 사용자 인증 정보 만들기** 클릭
3. **OAuth 클라이언트 ID** 선택

4. 애플리케이션 유형:
   - **iOS** 선택

5. **이름** 입력:
   ```
   DoDo iOS App
   ```

6. **번들 ID** 입력:
   ```
   kr.bluesky.dodo
   ```
   **중요**: Info.plist의 Bundle Identifier와 정확히 일치해야 합니다.

7. **App Store ID** (선택사항):
   - 아직 앱스토어에 출시 전이면 비워두기
   - 출시 후 App Store ID 입력 (예: `1234567890`)

8. **만들기** 클릭

### Step 3: Client ID 복사

생성 완료 후 팝업창이 나타납니다:

```
OAuth 클라이언트 생성됨

클라이언트 ID:
123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com

[JSON 다운로드] [확인]
```

**중요**: 이 Client ID를 복사하세요!

**형식**: `숫자-문자열.apps.googleusercontent.com`

**예시**: `123456789-abc123def456ghi789jkl012mno345pq.apps.googleusercontent.com`

---

## 3. Info.plist 업데이트

### Step 1: Info.plist 파일 열기

```bash
# 터미널에서
open /Users/leechanhee/Dropbox/Mac/Downloads/todo_app/ios/Runner/Info.plist

# 또는 Xcode에서
open /Users/leechanhee/Dropbox/Mac/Downloads/todo_app/ios/Runner.xcworkspace
# Runner > Runner > Info.plist 선택
```

### Step 2: GIDClientID 값 변경

**현재 (Line 72-73)**:
```xml
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID_HERE</string>
```

**변경 후**:
```xml
<key>GIDClientID</key>
<string>123456789-abc123def456ghi789jkl012mno345pq.apps.googleusercontent.com</string>
```

**주의사항**:
- ✅ Client ID 전체를 복사 (`.apps.googleusercontent.com` 포함)
- ✅ 앞뒤 공백 없이 정확히 입력
- ❌ Web Client ID가 아닌 iOS Client ID 사용
- ❌ `<` `>` 같은 특수문자 제거

### Step 3: URL Scheme 확인 (필수)

Info.plist에서 `CFBundleURLTypes`가 올바르게 설정되어 있는지 확인:

```xml
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
```

**이미 설정되어 있음** ✅

---

## 4. 검증 및 테스트

### Step 1: 빌드 및 실행

```bash
# Clean 빌드
flutter clean

# iOS 빌드
flutter build ios --debug

# 시뮬레이터에서 실행
flutter run -d <ios-simulator-id>
```

### Step 2: Google 로그인 테스트

1. 앱 실행
2. **Google 로그인** 버튼 클릭
3. Google 계정 선택 창이 나타나야 함
4. 계정 선택 후 로그인 완료 확인

### Step 3: 오류 발생 시 확인사항

#### 오류 1: "Client ID not found"
```
Error: The OAuth client was not found.
```

**원인**: Client ID가 잘못 입력됨
**해결**:
- Info.plist의 GIDClientID 값 재확인
- Google Cloud Console에서 Client ID 재복사
- `.apps.googleusercontent.com` 포함 여부 확인

#### 오류 2: "Bundle ID mismatch"
```
Error: The bundle identifier in the request does not match the bundle identifier for the app.
```

**원인**: Bundle ID 불일치
**해결**:
1. Info.plist에서 Bundle Identifier 확인:
   ```bash
   grep -A1 "CFBundleIdentifier" ios/Runner/Info.plist
   ```
2. Xcode에서 Bundle Identifier 확인:
   - Runner → General → Identity → Bundle Identifier
3. Google Cloud Console에서 iOS Client ID의 Bundle ID 확인
4. 모두 `kr.bluesky.dodo`로 일치시키기

#### 오류 3: "Redirect URI mismatch"
```
Error: redirect_uri_mismatch
```

**원인**: URL Scheme 설정 누락
**해결**:
- Info.plist의 `CFBundleURLSchemes`에 `kr.bluesky.dodo` 포함 확인
- 이미 설정되어 있으므로 정상

#### 오류 4: "Access blocked: This app is not verified"
```
This app hasn't been verified by Google yet. You can only sign in with test users.
```

**원인**: OAuth 동의 화면이 테스트 모드
**해결**:
- 개발 중에는 정상 동작 (테스트 사용자로 로그인 가능)
- 출시 전에 **OAuth 동의 화면 검토 신청** 필요

---

## 5. 고급 설정 (선택사항)

### Web Client ID도 필요한 경우

일부 Google API는 Web Client ID도 필요합니다.

1. Google Cloud Console → **Credentials**
2. **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Application type: **Web application**
4. 이름: `DoDo Web Client`
5. Authorized redirect URIs:
   - `https://your-domain.com/auth/callback`
   - `https://localhost:8080/auth/callback` (로컬 테스트용)
6. **만들기** 클릭
7. Web Client ID 복사 (필요 시 Flutter 코드에서 사용)

### Supabase와 함께 사용하는 경우

Supabase Auth에서 Google 로그인을 사용하는 경우:

1. Supabase Dashboard → **Authentication** → **Providers**
2. **Google** 활성화
3. **Google OAuth Client ID**: (Web Client ID 입력)
4. **Google OAuth Client Secret**: (Web Client Secret 입력)
5. **Save** 클릭

**주의**: Supabase에는 **Web Client ID**를 입력하고, iOS Info.plist에는 **iOS Client ID**를 입력합니다.

---

## 6. 체크리스트

### Google Cloud Console
- [ ] 프로젝트 생성 또는 선택
- [ ] OAuth 동의 화면 설정 완료
- [ ] iOS Client ID 생성 완료
- [ ] Bundle ID를 `kr.bluesky.dodo`로 설정
- [ ] Client ID 복사 완료

### Info.plist
- [ ] GIDClientID 값 업데이트
- [ ] Client ID가 `.apps.googleusercontent.com`으로 끝나는지 확인
- [ ] CFBundleURLSchemes에 `kr.bluesky.dodo` 포함 확인

### 테스트
- [ ] Flutter clean 실행
- [ ] iOS 앱 빌드 성공
- [ ] 시뮬레이터 또는 실제 기기에서 실행
- [ ] Google 로그인 버튼 클릭
- [ ] Google 계정 선택 창 표시
- [ ] 로그인 성공 확인

---

## 7. 빠른 참조

### 필요한 정보

| 항목 | 값 |
|------|-----|
| Bundle ID | `kr.bluesky.dodo` |
| URL Scheme | `kr.bluesky.dodo` |
| iOS Client ID | `123...xyz.apps.googleusercontent.com` |

### 설정 파일 위치

```bash
# Info.plist
/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/ios/Runner/Info.plist

# Line 72-73에서 GIDClientID 수정
```

### 검증 명령어

```bash
# Bundle ID 확인
grep -A1 "CFBundleIdentifier" ios/Runner/Info.plist

# GIDClientID 확인
grep -A1 "GIDClientID" ios/Runner/Info.plist

# URL Scheme 확인
grep -A5 "CFBundleURLSchemes" ios/Runner/Info.plist
```

---

## 8. 참고 자료

- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios/start-integrating)
- [Google Cloud Console](https://console.cloud.google.com/)
- [OAuth 2.0 설정 가이드](https://developers.google.com/identity/protocols/oauth2)

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2025-11-16
**작성자**: Claude Code
