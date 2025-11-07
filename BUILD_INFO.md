# DoDo 앱 빌드 정보

**빌드 날짜**: 2025-11-06 15:31
**빌드 도구**: Flutter SDK
**앱 버전**: 1.0.0+1

---

## 📦 APK 빌드 결과

### Release APK
**파일 경로**: `build/app/outputs/flutter-apk/app-release.apk`
**파일 크기**: 59 MB (61.9 MB 원본)
**SHA-1**: `6ed4b3d5c620b8ae0899b5a6fb02f821fc4127fe`
**빌드 시간**: 102.6초

### 최적화 결과
Flutter 빌드 과정에서 자동 최적화가 적용되었습니다:

1. **Icon Tree-Shaking** (아이콘 최적화)
   - `FluentSystemIcons-Filled.ttf`: 2,148,440 → 2,232 bytes (99.9% 감소)
   - `FluentSystemIcons-Regular.ttf`: 2,435,788 → 6,072 bytes (99.8% 감소)
   - `MaterialIcons-Regular.otf`: 1,645,184 → 3,180 bytes (99.8% 감소)

2. **코드 최적화**
   - Release mode 컴파일
   - Dead code elimination
   - Obfuscation (난독화)

---

## 🔧 빌드 설정

### Android 설정
- **Application ID**: `com.example.todo_app`
- **Min SDK**: Android 6.0 (API 23)
- **Target SDK**: Android 14 (API 34)
- **Compile SDK**: Android 34
- **Kotlin**: JVM Target 11
- **Java**: Version 11

### 서명 정보
- **현재 서명**: Debug Signing Key
- **용도**: 개발/테스트 전용
- **상태**: ⚠️ 프로덕션 배포 시 별도 signing key 필요

---

## 📱 APK 설치 및 테스트

### 에뮬레이터에 설치
```bash
flutter install
```
또는
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 실제 기기에 설치
1. USB 디버깅 활성화
2. 기기 연결
3. 설치 명령 실행:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### APK 파일 공유
파일 위치에서 직접 복사하여 공유:
```bash
open build/app/outputs/flutter-apk/
```

---

## 🚀 프로덕션 배포 준비

### ⚠️ 중요: 프로덕션 서명 키 생성 필요

프로덕션 배포를 위해서는 별도의 서명 키를 생성해야 합니다.

#### 1. Signing Key 생성
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**입력 정보**:
- Password: (안전한 비밀번호)
- Name: (개발자/회사명)
- Organization: (조직명)
- City/State/Country: (위치 정보)

#### 2. key.properties 파일 생성
`android/key.properties` 파일 생성:
```properties
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=upload
storeFile=<location of the key store file, such as /Users/<user name>/upload-keystore.jks>
```

#### 3. build.gradle.kts 수정
`android/app/build.gradle.kts` 파일에 추가:

```kotlin
// 파일 상단에 추가
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

#### 4. .gitignore 업데이트
보안을 위해 키 파일 제외:
```
key.properties
*.keystore
*.jks
```

#### 5. 프로덕션 APK 재빌드
```bash
flutter build apk --release
```

---

## 📊 Play Store 업로드 (AAB 권장)

Google Play Store는 APK 대신 **AAB (Android App Bundle)** 형식을 권장합니다.

### AAB 빌드
```bash
flutter build appbundle --release
```

**출력 파일**: `build/app/outputs/bundle/release/app-release.aab`

### AAB 장점
- 더 작은 다운로드 크기 (기기별 최적화)
- Play Store가 자동으로 APK 생성
- 최신 Android 기능 지원

---

## 🔍 APK 분석

### APK 크기 분석
```bash
flutter build apk --analyze-size
```

### APK 내용 확인
```bash
unzip -l build/app/outputs/flutter-apk/app-release.apk
```

### 서명 정보 확인
```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

---

## ⚡ 성능 최적화 팁

### 1. Obfuscation (난독화)
보안 강화 및 크기 감소:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### 2. Split APKs (ABI별 분리)
각 CPU 아키텍처별 APK 생성:
```bash
flutter build apk --release --split-per-abi
```

**생성되는 APK**:
- `app-armeabi-v7a-release.apk` (~20MB) - 구형 ARM 기기
- `app-arm64-v8a-release.apk` (~20MB) - 최신 ARM 기기
- `app-x86_64-release.apk` (~20MB) - 에뮬레이터/태블릿

### 3. R8 최적화
자동으로 활성화됨 (Android Gradle Plugin 3.4.0+)

---

## 📋 체크리스트

### 현재 빌드 (개발/테스트용)
- [x] Release APK 빌드 완료
- [x] 파일 크기: 59 MB
- [x] Icon tree-shaking 적용
- [x] Debug signing 사용 (테스트용)

### 프로덕션 배포 준비
- [ ] 프로덕션 signing key 생성
- [ ] key.properties 설정
- [ ] build.gradle.kts 수정
- [ ] .gitignore 업데이트
- [ ] 프로덕션 APK/AAB 재빌드
- [ ] 서명 검증
- [ ] Play Console에 업로드

---

## 🎯 다음 단계

### 즉시 가능
1. ✅ **현재 APK 테스트** - 에뮬레이터나 실제 기기에 설치
2. ✅ **기능 검증** - 모든 기능이 정상 작동하는지 확인
3. ✅ **베타 테스트** - 지인들에게 APK 공유하여 피드백 수집

### 프로덕션 배포 전
1. ⏳ **Signing Key 생성** - 프로덕션용 서명 키 생성
2. ⏳ **Play Console 설정** - Google Play Developer 계정
3. ⏳ **스크린샷 준비** - 앱 스토어 등록용 이미지
4. ⏳ **앱 설명 작성** - 한글/영문 설명 및 키워드
5. ⏳ **비공개 테스트** - Play Console의 Internal Testing
6. ⏳ **공개 배포** - 프로덕션 릴리스

---

## 📞 지원

### 추가 빌드 옵션
```bash
# 전체 빌드 옵션 확인
flutter build apk --help

# Profile 모드 빌드 (성능 프로파일링용)
flutter build apk --profile

# 다양한 flavor 빌드 (설정 시)
flutter build apk --release --flavor production
```

### 문제 해결
- 빌드 실패 시: `flutter clean && flutter pub get`
- Gradle 캐시 문제: `cd android && ./gradlew clean`
- 의존성 문제: `flutter doctor -v`

---

**빌드 완료**: 2025-11-06 15:31
**빌드 상태**: ✅ 성공
**테스트 준비**: ✅ 완료
**프로덕션 배포**: ⏳ Signing Key 필요
