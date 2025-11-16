# iOS 앱 배포 설정 가이드

## 목차
1. [Apple Developer Program 가입](#1-apple-developer-program-가입)
2. [인증서(Certificates) 생성](#2-인증서certificates-생성)
3. [식별자(Identifiers) 등록](#3-식별자identifiers-등록)
4. [프로비저닝 프로파일(Provisioning Profiles) 생성](#4-프로비저닝-프로파일provisioning-profiles-생성)
5. [Xcode 설정](#5-xcode-설정)
6. [빌드 및 테스트](#6-빌드-및-테스트)

---

## 1. Apple Developer Program 가입

### 비용 및 요구사항
- **연회비**: $99 USD (약 130,000원)
- **필요 항목**: Apple ID, 신용카드
- **소요 시간**: 24-48시간 (심사 필요)

### 가입 절차
1. **Apple Developer 사이트 접속**
   - https://developer.apple.com/programs/enroll/

2. **Start Your Enrollment 클릭**

3. **Apple ID로 로그인**

4. **계정 유형 선택**
   - **Individual**: 개인 개발자 (추천)
   - **Organization**: 회사/단체

5. **정보 입력**
   - 이름, 주소, 전화번호
   - 신용카드 정보

6. **약관 동의 및 결제**

7. **승인 대기** (24-48시간)

---

## 2. 인증서(Certificates) 생성

인증서는 앱 서명에 사용되며, 앱이 신뢰할 수 있는 출처에서 왔음을 증명합니다.

### 2.1 인증서 종류

| 인증서 종류 | 용도 | 필요 시점 |
|-----------|------|---------|
| **Development** | 개발/테스트 | 디버깅, 실제 기기 테스트 |
| **Distribution** | 배포 | App Store, TestFlight, Ad Hoc |

### 2.2 인증서 생성 방법

#### 방법 A: Xcode 자동 생성 (권장)
1. **Xcode 열기**
2. **Xcode → Settings (⌘,)**
3. **Accounts 탭 선택**
4. **Apple ID 추가** (+ 버튼 클릭)
5. **Apple ID 로그인**
6. **팀 선택 → Manage Certificates**
7. **+ 버튼 → Apple Distribution 선택**
8. **Done 클릭**

✅ **장점**: 간단하고 빠름, 자동으로 관리됨
❌ **단점**: 수동 제어 불가

#### 방법 B: 수동 생성 (고급 사용자)

**Step 1: CSR 파일 생성**
```bash
# 키체인 접근 앱 실행
open -a "Keychain Access"
```

1. **키체인 접근 → 인증서 지원 → 인증 기관에서 인증서 요청**
2. **정보 입력**:
   - 사용자 이메일 주소: 본인 이메일
   - 일반 이름: 본인 이름
   - CA 이메일 주소: 비워둠
   - 요청 항목: **디스크에 저장됨** 선택
   - 본인의 키 쌍 정보 지정 체크
3. **계속 클릭 → CSR 파일 저장** (`CertificateSigningRequest.certSigningRequest`)

**Step 2: Apple Developer 사이트에서 인증서 생성**
1. **Apple Developer 사이트 접속**
   - https://developer.apple.com/account/resources/certificates/list

2. **+ 버튼 클릭 (새 인증서)**

3. **인증서 유형 선택**:
   - 개발용: **Apple Development**
   - 배포용: **Apple Distribution**

4. **Continue 클릭**

5. **CSR 파일 업로드**
   - Choose File → 위에서 생성한 CSR 파일 선택

6. **Continue → Download**
   - `.cer` 파일 다운로드

7. **더블클릭하여 키체인에 설치**

**검증**:
```bash
# 키체인에서 인증서 확인
security find-identity -v -p codesigning
```

---

## 3. 식별자(Identifiers) 등록

App ID는 앱을 고유하게 식별하는 번들 식별자입니다.

### 3.1 Bundle ID 규칙
- **형식**: `com.company.appname`
- **현재 프로젝트**: `kr.bluesky.dodo`
- **주의**: 한 번 등록하면 변경 불가

### 3.2 App ID 등록

1. **Apple Developer 사이트 접속**
   - https://developer.apple.com/account/resources/identifiers/list

2. **+ 버튼 클릭**

3. **App IDs 선택 → Continue**

4. **Type 선택**
   - **App** 선택 → Continue

5. **App ID 설정**
   ```
   Description: DoDo Todo App
   Bundle ID: Explicit
   Bundle ID 입력: kr.bluesky.dodo
   ```

6. **Capabilities 설정** (필요한 기능 체크)
   - ✅ **Push Notifications** (알림)
   - ✅ **Sign in with Apple** (Apple 로그인)
   - ✅ **Associated Domains** (Supabase Deep Link)
   - ✅ **Background Modes** (백그라운드 작업)

7. **Continue → Register**

---

## 4. 프로비저닝 프로파일(Provisioning Profiles) 생성

프로비저닝 프로파일은 인증서, App ID, 기기를 연결합니다.

### 4.1 프로파일 종류

| 프로파일 종류 | 용도 | 설치 위치 |
|-------------|------|---------|
| **Development** | 개발/테스트 | 등록된 실제 기기 |
| **Ad Hoc** | 베타 테스트 | 최대 100대 기기 |
| **App Store** | 앱스토어 배포 | 전체 사용자 |

### 4.2 Development Profile 생성

1. **Apple Developer 사이트 접속**
   - https://developer.apple.com/account/resources/profiles/list

2. **+ 버튼 클릭**

3. **iOS App Development 선택 → Continue**

4. **App ID 선택**
   - `kr.bluesky.dodo` 선택 → Continue

5. **인증서 선택**
   - Development 인증서 체크 → Continue

6. **디바이스 선택** (실제 기기에서 테스트할 경우)
   - 테스트할 iPhone/iPad 선택 → Continue
   - 디바이스 등록 방법:
     - Xcode → Window → Devices and Simulators
     - 기기 연결 → Identifier 복사
     - Developer 사이트 → Devices → + 버튼

7. **프로파일 이름 입력**
   ```
   DoDo Development
   ```

8. **Generate → Download**
   - `.mobileprovision` 파일 다운로드

9. **더블클릭하여 설치**

### 4.3 App Store Distribution Profile 생성

1. **+ 버튼 클릭**

2. **App Store 선택 → Continue**

3. **App ID 선택**
   - `kr.bluesky.dodo` 선택 → Continue

4. **Distribution 인증서 선택 → Continue**

5. **프로파일 이름 입력**
   ```
   DoDo App Store Distribution
   ```

6. **Generate → Download → 더블클릭 설치**

---

## 5. Xcode 설정

### 5.1 자동 서명 (권장 - 초보자)

1. **Xcode에서 프로젝트 열기**
   ```bash
   cd /Users/leechanhee/Dropbox/Mac/Downloads/todo_app
   open ios/Runner.xcworkspace
   ```

2. **Runner 프로젝트 선택** (좌측 네비게이터)

3. **Signing & Capabilities 탭**

4. **설정**:
   ```
   ✅ Automatically manage signing (체크)
   Team: [본인 Apple Developer 팀 선택]
   Bundle Identifier: kr.bluesky.dodo
   ```

5. **자동으로 프로비저닝 프로파일 생성됨**

✅ **장점**: 간단, Xcode가 자동 관리
❌ **단점**: CI/CD 환경에서 제한적

### 5.2 수동 서명 (고급 - CI/CD)

1. **Xcode에서 프로젝트 열기**

2. **Signing & Capabilities 탭**

3. **설정**:
   ```
   ❌ Automatically manage signing (체크 해제)
   Team: [본인 Apple Developer 팀 선택]
   Provisioning Profile (Debug): DoDo Development
   Provisioning Profile (Release): DoDo App Store Distribution
   ```

---

## 6. 빌드 및 테스트

### 6.1 시뮬레이터에서 테스트

```bash
# 사용 가능한 시뮬레이터 확인
flutter devices

# 시뮬레이터 실행
open -a Simulator

# 앱 실행
flutter run -d <simulator-id>
```

### 6.2 실제 기기에서 테스트

```bash
# 기기 연결 확인
flutter devices

# 실제 기기에서 실행
flutter run -d <device-id>
```

**오류 발생 시**:
- Xcode에서 Team 재선택
- Provisioning Profile 재다운로드
- `flutter clean` 후 재시도

### 6.3 Release 빌드

```bash
# IPA 파일 생성 (App Store 제출용)
flutter build ipa --release

# 빌드 위치
# build/ios/ipa/todo_app.ipa
```

---

## 🚨 자주 발생하는 오류

### 1. "Failed to create provisioning profile"
**원인**: Bundle ID 불일치 또는 Capabilities 미설정
**해결**:
1. Developer 사이트에서 App ID 확인
2. Xcode Bundle Identifier와 일치하는지 확인
3. Capabilities가 모두 활성화되었는지 확인

### 2. "No signing certificate found"
**원인**: 인증서가 키체인에 없음
**해결**:
1. Developer 사이트에서 인증서 재다운로드
2. 더블클릭하여 키체인에 설치
3. Xcode 재시작

### 3. "Provisioning profile doesn't include the device"
**원인**: 디바이스가 프로파일에 등록되지 않음
**해결**:
1. Developer 사이트 → Devices → 기기 추가
2. Profile 재생성 (기기 포함)
3. Xcode에서 Profile 재다운로드

### 4. "Capability not supported"
**원인**: 무료 개발자 계정 사용 시 일부 기능 제한
**해결**:
- Apple Developer Program 가입 필요 ($99/년)

---

## 📚 참고 자료

- **Apple Developer Documentation**: https://developer.apple.com/documentation/
- **Flutter iOS Deployment**: https://docs.flutter.dev/deployment/ios
- **App Store Connect**: https://appstoreconnect.apple.com/
- **TestFlight**: https://testflight.apple.com/

---

## ✅ 체크리스트

배포 전 확인 사항:

- [ ] Apple Developer Program 가입 완료
- [ ] Distribution Certificate 생성 및 설치
- [ ] App ID 등록 (kr.bluesky.dodo)
- [ ] Provisioning Profile 생성 및 설치
- [ ] Xcode Signing 설정 완료
- [ ] Info.plist OAuth 설정 (Google Client ID, Supabase URL)
- [ ] 아이콘 및 스플래시 스크린 설정
- [ ] 앱 버전 및 빌드 번호 확인
- [ ] Privacy Policy URL 준비
- [ ] 스크린샷 및 앱 설명 준비
- [ ] TestFlight 베타 테스트 완료
- [ ] App Store Review 가이드라인 준수 확인

---

**현재 프로젝트 상태**:
- ✅ Bundle ID: `kr.bluesky.dodo`
- ✅ iOS 아이콘 설정 완료
- ✅ Info.plist 권한 설정 완료
- ⚠️ OAuth Client ID 설정 필요
- ⚠️ 인증서 및 프로파일 생성 필요
