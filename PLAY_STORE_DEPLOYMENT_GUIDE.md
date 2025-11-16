# Google Play Store 배포 가이드

**프로젝트**: DoDo Todo App
**버전**: 1.0.0+1
**작성일**: 2025-11-06

---

## 📋 목차

1. [프로덕션 Signing Key 생성](#1단계-프로덕션-signing-key-생성)
2. [key.properties 파일 생성](#2단계-keyproperties-파일-생성)
3. [build.gradle.kts 수정](#3단계-buildgradlekts-수정)
4. [AAB 빌드](#4단계-aabandroid-app-bundle-빌드)
5. [Google Play Console 설정](#5단계-google-play-console-설정)
6. [앱 콘텐츠 등록](#6단계-앱-콘텐츠-등록)
7. [프로덕션 릴리스](#7단계-프로덕션-릴리스)
8. [심사 대기](#8단계-심사-대기)

---

## 1단계: 프로덕션 Signing Key 생성

현재 앱은 debug key로 서명되어 있어서 Play Store에 업로드할 수 없습니다. 먼저 프로덕션 키를 생성해야 합니다.

### 명령어

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 입력할 정보

| 항목 | 설명 | 예시 |
|------|------|------|
| **비밀번호** | 안전한 비밀번호 (잊어버리면 안 됨!) | `MySecurePass123!` |
| **이름** | 개인 또는 회사명 | `홍길동` |
| **조직** | 조직명 (개인이면 본인 이름) | `홍길동` |
| **조직 단위** | 부서명 (선택) | `Development` |
| **도시** | 도시명 | `서울` |
| **시/도** | 지역명 | `서울특별시` |
| **국가 코드** | 2자리 국가 코드 | `KR` |

### ⚠️ 중요 사항

> **비밀번호와 keystore 파일을 안전하게 보관하세요!**
>
> - 분실 시 앱 업데이트 불가능
> - 백업 권장 위치: 외장 하드, 클라우드 저장소
> - Git에 절대 커밋하지 마세요!

---

## 2단계: key.properties 파일 생성

### 파일 위치

```
android/key.properties
```

### 파일 내용

```properties
storePassword=<1단계에서 입력한 비밀번호>
keyPassword=<1단계에서 입력한 비밀번호>
keyAlias=upload
storeFile=/Users/leechanhee/upload-keystore.jks
```

### 예시

```properties
storePassword=MySecurePass123!
keyPassword=MySecurePass123!
keyAlias=upload
storeFile=/Users/leechanhee/upload-keystore.jks
```

### .gitignore 업데이트

`.gitignore` 파일에 다음 추가:

```gitignore
# Android signing keys
android/key.properties
*.keystore
*.jks
```

---

## 3단계: build.gradle.kts 수정

### 현재 상태

`android/app/build.gradle.kts` 파일은 현재 debug 키로만 서명됩니다:

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

### 수정할 내용

파일 상단에 key.properties 로드 코드 추가:

```kotlin
// 파일 최상단에 추가 (plugins 블록 전)
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

`android` 블록 내에 signingConfigs 추가:

```kotlin
android {
    // ... 기존 설정 ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

## 4단계: AAB(Android App Bundle) 빌드

### AAB란?

AAB는 Google Play Store가 권장하는 최신 앱 배포 형식입니다.

### AAB 장점

| 장점 | 설명 |
|------|------|
| **더 작은 다운로드 크기** | 사용자 기기에 맞는 리소스만 다운로드 |
| **자동 최적화** | Play Store가 자동으로 APK 생성 |
| **최신 기능 지원** | Dynamic Delivery, Asset Packs 지원 |
| **보안 강화** | App Signing by Google Play 사용 가능 |

### 빌드 명령어

#### 기본 빌드
```bash
flutter build appbundle --release
```

#### Obfuscation 포함 (권장)
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

### 출력 파일

```
build/app/outputs/bundle/release/app-release.aab
```

### 파일 크기 분석

```bash
flutter build appbundle --analyze-size
```

---

## 5단계: Google Play Console 설정

### 5.1 개발자 계정 생성

1. **Play Console 접속**: https://play.google.com/console
2. **계정 등록**: 개발자 계정 생성
3. **등록비 결제**: 일회성 $25 USD
4. **본인 확인**: 신분증 확인 및 결제 정보 입력

### 5.2 앱 만들기

1. Play Console에서 **"앱 만들기"** 클릭
2. 앱 세부정보 입력:

| 항목 | 입력값 |
|------|--------|
| **앱 이름** | `DoDo` |
| **기본 언어** | `한국어 (대한민국)` |
| **앱 유형** | `앱` |
| **무료/유료** | `무료` |

3. 선언 체크박스:
   - [ ] Google Play 개발자 프로그램 정책 준수
   - [ ] 미국 수출법 준수

### 5.3 앱 정보 작성

#### 짧은 설명 (80자 이하)

```
심플하고 스마트한 할 일 관리 앱. 알림, 통계, 클라우드 동기화 지원.
```

#### 전체 설명 (4000자 이하)

```markdown
# DoDo - 심플한 할 일 관리

심플하고 스마트한 할 일 관리 앱 DoDo로 하루를 더 생산적으로 만들어보세요.

## 주요 기능

📝 할 일 관리
• 간편한 할 일 추가/수정/삭제
• 완료 상태 관리
• 중요도 설정

⏰ 스마트 알림
• 시간 알림 설정
• 반복 알림 지원
• 놓치지 않는 리마인더

📊 통계 및 분석
• 일별/주별/월별 통계
• 완료율 확인
• 생산성 트렌드

🔐 로그인 및 동기화
• Google/Kakao 로그인
• 클라우드 자동 동기화
• 다중 기기 지원

🎨 사용자 경험
• Fluent Design
• 다크 모드
• 직관적인 인터페이스

🔒 보안
• 안전한 클라우드 저장
• 암호화된 데이터
• OAuth 2.0 인증

## 이런 분들께 추천

• 할 일을 체계적으로 관리하고 싶은 분
• 중요한 일정을 놓치지 않고 싶은 분
• 여러 기기에서 동기화가 필요한 분
• 생산성을 높이고 싶은 분

## 지원 플랫폼

• Android 6.0 이상
• 휴대폰 및 태블릿

## 완전 무료

광고 없이 모든 기능을 무료로 사용하세요!
```

### 5.4 스크린샷 준비

#### 필수 스크린샷 요구사항

| 기기 유형 | 해상도 | 최소 개수 | 최대 개수 |
|----------|--------|-----------|-----------|
| **휴대전화** | 1080 x 1920px | 2개 | 8개 |
| **7인치 태블릿** | 1024 x 768px | 0개 (선택) | 8개 |
| **10인치 태블릿** | 1024 x 768px | 0개 (선택) | 8개 |

#### 권장 스크린샷 구성

1. **로그인 화면** - 앱의 첫 인상
2. **할 일 목록** - 메인 화면
3. **할 일 추가** - 주요 기능
4. **할 일 상세** - 세부 기능
5. **통계 화면** - 차별화 포인트
6. **설정 화면** - 다크 모드 등
7. **알림 화면** - 알림 기능 강조

#### 스크린샷 촬영 방법

**에뮬레이터 사용:**
```bash
# 에뮬레이터 실행
flutter emulators --launch <emulator-id>

# 앱 실행
flutter run

# 스크린샷은 에뮬레이터 도구 사용 (카메라 아이콘)
```

**실제 기기 사용:**
- 전원 + 볼륨 다운 버튼 동시 누르기
- 스크린샷을 1080 x 1920 해상도로 리사이즈

### 5.5 그래픽 에셋

#### 앱 아이콘
- **크기**: 512 x 512px
- **형식**: PNG (32-bit)
- **위치**: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

#### Feature Graphic (필수)
- **크기**: 1024 x 500px
- **형식**: JPG 또는 PNG
- **용도**: Play Store 상단 배너
- **디자인 팁**:
  - 앱 아이콘 포함
  - 앱 이름 표시
  - 간단한 태그라인
  - 시각적으로 매력적인 배경

#### 프로모션 비디오 (선택)
- **길이**: 30초 - 2분
- **형식**: YouTube 링크
- **내용**: 주요 기능 시연

---

## 6단계: 앱 콘텐츠 등록

### 6.1 개인정보처리방침

**필수 조건**: 개인정보를 수집하는 경우 반드시 필요

#### 간단한 방법: GitHub Pages

1. 프로젝트에 `privacy-policy.md` 생성
2. GitHub Pages로 배포
3. Play Console에 URL 입력

#### 개인정보처리방침 템플릿

```markdown
# 개인정보처리방침

## 1. 수집하는 개인정보 항목
- 이메일 주소 (선택)
- 소셜 로그인 정보 (Google, Kakao)
- 할 일 데이터
- 사용 통계

## 2. 개인정보의 수집 및 이용 목적
- 사용자 인증 및 서비스 제공
- 데이터 동기화
- 서비스 개선

## 3. 개인정보의 보유 및 이용 기간
- 회원 탈퇴 시까지

## 4. 개인정보의 파기
- 회원 탈퇴 시 즉시 삭제

## 5. 개인정보 제3자 제공
- 제3자 제공 없음

## 6. 개인정보 처리 위탁
- Supabase (데이터 저장)

## 7. 정보주체의 권리
- 개인정보 열람 요청
- 개인정보 삭제 요청

## 8. 문의처
- 이메일: your-email@example.com
```

### 6.2 타겟 연령 및 콘텐츠

| 항목 | 선택 |
|------|------|
| **타겟 연령** | 만 13세 이상 |
| **연령 제한 콘텐츠** | 없음 |
| **광고 포함 여부** | 광고 없음 |
| **위치 정보 사용** | 사용 안 함 |
| **인앱 구매** | 없음 |

### 6.3 콘텐츠 등급

**IARC 등급 설정**: 자동 설문을 통해 결정

예상 등급: **모든 연령 적합 (PEGI 3, ESRB Everyone)**

### 6.4 데이터 보안 설문

#### 데이터 수집 및 공유

| 질문 | 답변 |
|------|------|
| 사용자 데이터를 수집하나요? | **예** |
| 수집한 데이터를 제3자와 공유하나요? | **아니요** |

#### 수집하는 데이터 유형

- [x] 이메일 주소
- [x] 사용자 계정 정보
- [ ] 위치 정보
- [ ] 기기 ID

#### 데이터 보안 조치

- [x] 전송 중 암호화 (HTTPS)
- [x] 저장 시 암호화
- [x] 사용자 데이터 삭제 요청 처리 가능

---

## 7단계: 프로덕션 릴리스

### 7.1 내부 테스트 (권장)

#### 목적
- 소규모 테스터 그룹과 빠른 테스트
- 치명적 버그 조기 발견
- 배포 프로세스 검증

#### 절차

1. **트랙 선택**: "내부 테스트"
2. **테스터 목록 생성**:
   - 이메일 주소 추가 (최대 100명)
   - Google 계정 이메일이어야 함
3. **AAB 업로드**:
   ```bash
   flutter build appbundle --release
   ```
4. **출시 노트 작성**:
   ```
   내부 테스트 버전 1.0.0

   테스트 포인트:
   - 로그인 플로우 정상 작동 여부
   - 할 일 CRUD 기능
   - 알림 기능
   - 데이터 동기화
   ```
5. **배포**: "검토 및 출시" 클릭
6. **테스터에게 링크 공유**: Play Console에서 제공하는 설치 링크

#### 테스트 체크리스트

- [ ] 앱 설치 및 실행
- [ ] 로그인/로그아웃
- [ ] 할 일 추가/수정/삭제
- [ ] 알림 설정 및 수신
- [ ] 다크 모드 전환
- [ ] 데이터 동기화
- [ ] 크래시 없이 안정적 작동

### 7.2 비공개 테스트 (선택)

#### 목적
- 더 많은 사용자와 테스트 (최대 수천 명)
- 실제 사용 환경에서 검증
- 성능 및 안정성 확인

#### 절차
내부 테스트와 동일하나 더 많은 테스터 초대 가능

### 7.3 프로덕션 배포

#### 절차

1. **트랙 선택**: "프로덕션"
2. **AAB 업로드**: 최종 검증된 빌드
3. **출시 노트 작성** (한국어):
   ```markdown
   # 🎉 DoDo 첫 번째 릴리스!

   심플하고 스마트한 할 일 관리 앱 DoDo를 소개합니다.

   ## ✨ 주요 기능
   • 직관적인 할 일 추가/수정/삭제
   • 놓치지 않는 스마트 알림
   • 생산성 향상을 위한 통계
   • Google/Kakao 간편 로그인
   • 여러 기기에서 자동 동기화
   • 눈에 편안한 다크 모드

   ## 🆓 완전 무료
   광고 없이 모든 기능을 무료로 사용하세요!

   ## 📧 피드백
   버그 리포트나 기능 제안은 언제든 환영합니다.
   ```

4. **국가 선택**:
   - [x] 대한민국
   - [ ] 기타 국가 (원하는 경우 추가)

5. **출시 일정**:
   - 심사 승인 즉시 배포
   - 또는 특정 날짜/시간 지정

6. **검토 제출**: "검토 제출" 클릭

---

## 8단계: 심사 대기

### 심사 프로세스

#### 심사 시간
- **일반적**: 1-3일
- **최대**: 7일
- **긴급 심사**: 제공되지 않음

#### 심사 기준

| 항목 | 확인 사항 |
|------|-----------|
| **기능성** | 앱이 설명대로 작동하는가 |
| **안정성** | 크래시나 치명적 버그가 없는가 |
| **정책 준수** | Google Play 정책 위반 여부 |
| **콘텐츠** | 앱 설명과 실제 기능이 일치하는가 |
| **개인정보** | 개인정보처리방침이 적절한가 |

#### 심사 상태

```
제출 → 검토 중 → 승인 or 거부 → 출시
```

### 심사 거부 시 대응

#### 일반적인 거부 사유

1. **정책 위반**
   - 대응: 정책 위반 내용 수정 후 재제출

2. **메타데이터 문제**
   - 대응: 스크린샷, 설명, 아이콘 수정

3. **기능 문제**
   - 대응: 버그 수정 후 새 빌드 업로드

4. **개인정보 문제**
   - 대응: 개인정보처리방침 보완

#### 재제출 절차
1. 거부 사유 확인
2. 문제 수정
3. 새 버전 빌드 (버전 코드 증가)
4. 재제출 및 수정 사항 설명

---

## 🚀 빠른 시작 체크리스트

### 준비 단계 (1-2시간)

- [ ] **1단계**: Signing key 생성 (5분)
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias upload
  ```

- [ ] **2단계**: key.properties 파일 생성 (5분)
  - 파일 위치: `android/key.properties`
  - 내용: storePassword, keyPassword, keyAlias, storeFile

- [ ] **3단계**: build.gradle.kts 수정 (10분)
  - key.properties 로드 코드 추가
  - signingConfigs 설정

- [ ] **4단계**: AAB 빌드 (5분)
  ```bash
  flutter build appbundle --release
  ```

### Play Console 설정 (2-4시간)

- [ ] **5단계**: Google Play Console 계정 생성 (30분)
  - 개발자 등록비 $25 결제
  - 본인 확인

- [ ] **6단계**: 앱 정보 준비 (1-2시간)
  - 앱 설명 작성
  - 스크린샷 8개 준비
  - Feature Graphic 제작
  - 개인정보처리방침 작성

- [ ] **7단계**: 앱 콘텐츠 등록 (1시간)
  - 타겟 연령 설정
  - 콘텐츠 등급 설문
  - 데이터 보안 설문

### 배포 단계 (1일-1주)

- [ ] **8단계**: 내부 테스트 (선택, 1-3일)
  - 테스터 초대
  - 피드백 수집
  - 버그 수정

- [ ] **9단계**: 프로덕션 출시 (1-3일)
  - AAB 업로드
  - 출시 노트 작성
  - 심사 제출

- [ ] **10단계**: 심사 승인 대기 (1-7일)
  - 심사 상태 모니터링
  - 승인 시 자동 배포

---

## 💡 유용한 팁

### 심사 통과 확률을 높이는 방법

1. **완성도 높은 앱**
   - 모든 기능이 정상 작동
   - 크래시 없음
   - 로딩 속도 최적화

2. **명확한 메타데이터**
   - 정확한 앱 설명
   - 고품질 스크린샷
   - 실제 기능과 일치하는 콘텐츠

3. **정책 준수**
   - 개인정보처리방침 필수
   - 타겟 연령 정확히 설정
   - 데이터 보안 설문 성실히 작성

4. **테스트 철저히**
   - 내부 테스트 활용
   - 다양한 기기에서 테스트
   - 실제 사용자 피드백 반영

### 배포 후 해야 할 일

#### 즉시

- [ ] Play Store 페이지 확인
- [ ] 앱 다운로드 및 설치 테스트
- [ ] 지인들에게 공유
- [ ] SNS에 홍보

#### 1주일 내

- [ ] 사용자 리뷰 모니터링
- [ ] 크래시 리포트 확인
- [ ] 버그 수정 준비

#### 1개월 내

- [ ] 사용자 피드백 수집
- [ ] 기능 개선 계획
- [ ] 마이너 업데이트 배포

---

## 📞 문제 해결

### 자주 묻는 질문

#### Q1: Signing key를 분실했어요!
**A**: 안타깝게도 새로운 앱으로 등록해야 합니다. 반드시 백업하세요!

#### Q2: 심사가 너무 오래 걸려요
**A**: 평균 1-3일이지만 최대 7일까지 걸릴 수 있습니다. 기다려주세요.

#### Q3: 심사가 거부되었어요
**A**: 거부 사유를 확인하고 수정 후 재제출하세요. 대부분 2-3회 안에 승인됩니다.

#### Q4: 앱 업데이트는 어떻게 하나요?
**A**:
1. `pubspec.yaml`에서 버전 증가
2. 새로운 AAB 빌드
3. Play Console에서 새 버전 업로드

#### Q5: 앱 아이콘을 변경하고 싶어요
**A**:
1. 아이콘 변경
2. 새 버전 빌드
3. Play Console에서 업데이트

---

## 🎯 다음 단계

### 지금 바로 시작

1. **Signing key 생성부터 시작하세요**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. **도움이 필요하면**
   - build.gradle.kts 수정
   - AAB 빌드
   - 개인정보처리방침 작성
   - 스크린샷 가이드

### 추가 리소스

- **Google Play Console 가이드**: https://support.google.com/googleplay/android-developer
- **Flutter 배포 문서**: https://docs.flutter.dev/deployment/android
- **Android 서명 가이드**: https://developer.android.com/studio/publish/app-signing

---

**작성일**: 2025-11-06
**프로젝트**: DoDo Todo App v1.0.0+1
**상태**: 배포 준비 완료 ✅

---

## 부록: 버전 관리 전략

### 버전 번호 규칙

```
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

예시: `1.0.0+1`

| 부분 | 의미 | 증가 시점 |
|------|------|-----------|
| **MAJOR** | 주요 버전 | 큰 변경, 호환성 깨짐 |
| **MINOR** | 부 버전 | 새 기능 추가 |
| **PATCH** | 패치 버전 | 버그 수정 |
| **BUILD** | 빌드 번호 | 매 빌드마다 증가 |

### 업데이트 예시

```yaml
# 초기 버전
version: 1.0.0+1

# 버그 수정
version: 1.0.1+2

# 새 기능 추가
version: 1.1.0+3

# 대규모 리뉴얼
version: 2.0.0+4
```

---

**끝** 🎉
