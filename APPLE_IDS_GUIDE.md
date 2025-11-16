# Apple App Store ID 및 팀 ID 가이드

Google OAuth iOS 설정 시 필요한 App Store ID와 팀 ID 확인 방법입니다.

## 목차
1. [App Store ID란?](#1-app-store-id란)
2. [팀 ID란?](#2-팀-id란)
3. [Google OAuth에서 사용하기](#3-google-oauth에서-사용하기)

---

## 1. App Store ID란?

### 개념
- **App Store ID**: 앱이 Apple App Store에 게시된 후 자동으로 할당되는 고유 숫자
- **형식**: 10자리 숫자 (예: `1234567890`)
- **용도**: 앱스토어에서 앱을 고유하게 식별

### 언제 생성되나?
App Store Connect에서 **새 앱을 등록**하면 자동으로 생성됩니다.

---

## 1-1. App Store ID 확인 방법

### 방법 1: App Store Connect에서 확인 (앱 등록 후)

#### Step 1: App Store Connect 접속
```
https://appstoreconnect.apple.com/
```

#### Step 2: 앱 선택
1. **나의 앱(My Apps)** 클릭
2. 앱 목록에서 **DoDo** 선택

#### Step 3: App Store ID 확인
1. **앱 정보(App Information)** 탭 클릭
2. **일반 정보(General Information)** 섹션에서 확인

```
┌─────────────────────────────────────┐
│ 앱 정보                              │
├─────────────────────────────────────┤
│ 일반 정보                            │
│                                      │
│ Apple ID: 1234567890    ◀ 여기!     │
│ Bundle ID: kr.bluesky.dodo           │
│ SKU: kr.bluesky.dodo                 │
│                                      │
└─────────────────────────────────────┘
```

**Apple ID = App Store ID**입니다.

### 방법 2: App Store URL에서 확인 (앱 출시 후)

앱이 이미 App Store에 출시된 경우:

```
앱 스토어 URL:
https://apps.apple.com/kr/app/dodo/id1234567890
                                   ↑
                          이 숫자가 App Store ID
```

예시:
- **1Password**: `https://apps.apple.com/app/id1511601750` → App Store ID: `1511601750`
- **Notion**: `https://apps.apple.com/app/id1232780281` → App Store ID: `1232780281`

### 방법 3: Xcode Organizer에서 확인 (Archive 업로드 후)

1. Xcode 열기
2. **Window** → **Organizer** (⌘⇧9)
3. **Archives** 탭 선택
4. 앱 선택 후 우측 패널에서 **App Store** 정보 확인

---

## 1-2. App Store ID가 없는 경우 (아직 출시 전)

### Google OAuth 설정 시 처리

**아직 App Store에 앱을 등록하지 않은 경우**:

```
App Store ID 필드: [          ] ◀ 비워두기
```

**빈 칸으로 두면 됩니다** ✅

나중에 앱스토어 출시 후 Google Cloud Console에서 추가할 수 있습니다:

1. **API 및 서비스** → **사용자 인증 정보**
2. 생성한 **DoDo iOS App** OAuth 클라이언트 클릭
3. **App Store ID** 필드에 숫자 입력
4. **저장** 클릭

---

## 2. 팀 ID란?

### 개념
- **팀 ID**: Apple Developer 계정에 할당된 고유 10자리 영숫자 문자열
- **형식**: 10자리 대문자 + 숫자 (예: `AB12CD34EF`)
- **용도**: 개발자/조직 식별, Provisioning Profile, Code Signing

### 특징
- Apple Developer Program 가입 시 **자동으로 생성**
- 개인 계정, 조직 계정 모두 동일하게 부여
- **변경 불가**
- 모든 앱에 **동일한 팀 ID** 사용

---

## 2-1. 팀 ID 확인 방법

### 방법 1: Apple Developer 웹사이트에서 확인 ⭐ (가장 쉬움)

#### Step 1: Apple Developer 접속
```
https://developer.apple.com/account/
```

#### Step 2: Membership 정보 확인
1. 로그인 후 **Membership** 탭 클릭 (또는 하단의 Membership Details 링크)
2. **Team ID** 확인

```
┌─────────────────────────────────────┐
│ Membership                           │
├─────────────────────────────────────┤
│ Team Name:    Lee Chan Hee           │
│ Team ID:      AB12CD34EF  ◀ 여기!   │
│ Program Type: Individual             │
│ Status:       Active                 │
│                                      │
└─────────────────────────────────────┘
```

### 방법 2: Xcode에서 확인

#### Step 1: Xcode 열기
```bash
open /Users/leechanhee/Dropbox/Mac/Downloads/todo_app/ios/Runner.xcworkspace
```

#### Step 2: 팀 ID 확인
1. **Runner** 프로젝트 선택 (좌측 네비게이터)
2. **Signing & Capabilities** 탭 클릭
3. **Team** 드롭다운 확인

```
┌─────────────────────────────────────┐
│ Signing & Capabilities               │
├─────────────────────────────────────┤
│ ☑ Automatically manage signing       │
│                                      │
│ Team: Lee Chan Hee (AB12CD34EF) ◀   │
│             이름      ↑ 팀 ID        │
│                                      │
│ Bundle Identifier: kr.bluesky.dodo   │
│                                      │
└─────────────────────────────────────┘
```

괄호 안의 영숫자가 **팀 ID**입니다.

### 방법 3: Provisioning Profile에서 확인

1. Apple Developer → **Certificates, Identifiers & Profiles**
2. **Profiles** 클릭
3. 아무 프로파일 선택
4. **Team** 정보에서 확인

### 방법 4: 터미널 명령어로 확인

```bash
# Keychain에서 인증서 확인
security find-identity -v -p codesigning

# 출력 예시:
# 1) AB12CD34EF "Apple Development: your@email.com (Team ID)"
#    ↑ 이 부분이 팀 ID
```

---

## 2-2. 팀 ID가 없는 경우

### Apple Developer Program 미가입 상태

팀 ID는 **Apple Developer Program 가입 시 자동으로 생성**됩니다.

**무료 개발자 계정(Free Developer Account)**으로는 팀 ID가 부여되지 않거나 제한적입니다.

#### 해결 방법:
1. **Apple Developer Program 가입** ($99/년)
   - https://developer.apple.com/programs/enroll/
2. 가입 완료 후 24-48시간 이내 승인
3. 승인 후 자동으로 팀 ID 부여

---

## 3. Google OAuth에서 사용하기

### Google Cloud Console - iOS Client ID 생성 시

```
┌─────────────────────────────────────────┐
│ OAuth 클라이언트 ID 만들기               │
├─────────────────────────────────────────┤
│ 애플리케이션 유형: iOS                   │
│                                          │
│ 이름:                                    │
│ [DoDo iOS App                        ]  │
│                                          │
│ 번들 ID:                                 │
│ [kr.bluesky.dodo                     ]  │
│                                          │
│ App Store ID (선택사항):                │
│ [1234567890                          ]  │
│  ↑ 앱스토어 출시 전이면 비워두기         │
│                                          │
│ 팀 ID (선택사항):                        │
│ [AB12CD34EF                          ]  │
│  ↑ Apple Developer 계정 팀 ID           │
│                                          │
│           [취소]  [만들기]              │
└─────────────────────────────────────────┘
```

### 입력 가이드

#### 번들 ID (필수)
```
kr.bluesky.dodo
```
✅ **반드시 입력**

#### App Store ID (선택사항)
- **앱스토어 출시 전**: 비워두기 ✅
- **앱스토어 출시 후**: 10자리 숫자 입력 (예: `1234567890`)

#### 팀 ID (선택사항)
- **Apple Developer 가입 후**: 10자리 영숫자 입력 (예: `AB12CD34EF`)
- **미가입 또는 모르는 경우**: 비워두기 ✅

**중요**: App Store ID와 팀 ID는 **선택사항**이므로 비워두어도 Google 로그인이 정상 작동합니다.

---

## 4. 입력 예시

### 시나리오 1: 앱스토어 출시 전 (개발 단계)

```yaml
이름: DoDo iOS App
번들 ID: kr.bluesky.dodo
App Store ID: (비워두기)
팀 ID: (비워두기 또는 AB12CD34EF)
```

### 시나리오 2: 앱스토어 출시 후

```yaml
이름: DoDo iOS App
번들 ID: kr.bluesky.dodo
App Store ID: 1234567890
팀 ID: AB12CD34EF
```

---

## 5. 자주 묻는 질문

### Q1. App Store ID를 나중에 추가할 수 있나요?
**A**: 네, 가능합니다.
1. Google Cloud Console → **사용자 인증 정보**
2. 생성한 OAuth 클라이언트 클릭
3. **App Store ID** 필드 수정
4. **저장**

### Q2. 팀 ID를 입력하지 않으면 어떻게 되나요?
**A**: Google 로그인은 정상 작동합니다. 팀 ID는 선택사항입니다.

### Q3. 무료 개발자 계정으로도 되나요?
**A**: 네, 개발 및 테스트는 가능합니다. 하지만 **App Store 출시**는 유료 개발자 계정($99/년)이 필요합니다.

### Q4. 번들 ID를 잘못 입력했어요
**A**: OAuth 클라이언트를 삭제하고 새로 만들어야 합니다. 번들 ID는 생성 후 수정 불가능합니다.

### Q5. 팀 ID를 확인할 수 없어요
**A**: Apple Developer Program 미가입 상태일 수 있습니다. 비워두고 진행하세요.

---

## 6. 체크리스트

### Google OAuth iOS Client ID 생성 시

#### 필수 입력
- [ ] 이름: `DoDo iOS App`
- [ ] 번들 ID: `kr.bluesky.dodo` (정확히 입력)

#### 선택 입력
- [ ] App Store ID: 출시 전이면 비워두기 ✅
- [ ] 팀 ID: 모르면 비워두기 ✅

### 나중에 추가할 정보
- [ ] 앱스토어 출시 후 App Store ID 추가
- [ ] Apple Developer 가입 후 팀 ID 추가 (선택사항)

---

## 7. 빠른 참조

### App Store ID 확인 URL
```
앱스토어 출시 전: 없음 (비워두기)
앱스토어 출시 후: App Store Connect > 앱 정보 > Apple ID
```

### 팀 ID 확인 URL
```
https://developer.apple.com/account/
→ Membership 탭 → Team ID 확인
```

### Google Cloud Console 설정
```
필수: 번들 ID만 정확히 입력
선택: App Store ID, 팀 ID는 비워두어도 됨
```

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2025-11-16
**작성자**: Claude Code
