# Google Maps API 설정 가이드

위치 기반 알림 기능을 사용하려면 Google Maps API 키가 필요합니다.

## 1. Google Cloud Console 설정

### 1.1 프로젝트 생성
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택 또는 새 프로젝트 생성

### 1.2 Maps SDK for Android 활성화
1. 왼쪽 메뉴에서 **API 및 서비스 > 라이브러리** 선택
2. "Maps SDK for Android" 검색
3. **사용 설정** 클릭

### 1.3 API 키 생성
1. **사용자 인증 정보 > 사용자 인증 정보 만들기 > API 키** 선택
2. API 키가 생성됨 (예: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)

### 1.4 API 키 제한 설정 (보안 강화)
1. 생성된 API 키 옆 **편집** 아이콘 클릭
2. **애플리케이션 제한사항**:
   - **Android 앱** 선택
   - **항목 추가** 클릭
   - **패키지 이름**: `kr.bluesky.dodo`
   - **SHA-1 인증서 지문**: 아래 명령어로 확인

## 2. SHA-1 인증서 지문 확인

### 개발용 (Debug) 키스토어
```bash
# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA1:"

# Windows
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr "SHA1:"
```

### 배포용 (Release) 키스토어
```bash
# upload-keystore.jks 사용 시
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload | grep "SHA1:"
# 키스토어 비밀번호 입력 필요
```

**참고**: Debug와 Release 키스토어의 SHA-1 지문을 **모두** Google Cloud Console에 추가해야 합니다.

## 3. API 키 설정

### 3.1 AndroidManifest.xml 업데이트
`android/app/src/main/AndroidManifest.xml` 파일에서:

```xml
<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```

위 코드의 `YOUR_GOOGLE_MAPS_API_KEY_HERE`를 실제 API 키로 교체:

```xml
<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
```

### 3.2 .gitignore 확인
API 키가 포함된 파일이 Git에 커밋되지 않도록 확인:

```bash
# .gitignore에 다음 항목이 있는지 확인
android/key.properties
.env
```

**보안 참고**: API 키를 하드코딩하는 대신 환경 변수나 secrets 파일 사용을 권장합니다.

## 4. 환경 변수 사용 (선택사항, 권장)

### 4.1 local.properties 파일 생성
`android/local.properties` 파일에 추가:

```properties
MAPS_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### 4.2 build.gradle.kts 수정
`android/app/build.gradle.kts`에서:

```kotlin
android {
    defaultConfig {
        // ...

        // local.properties에서 Maps API Key 읽기
        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { localProperties.load(it) }
        }
        val mapsApiKey = localProperties.getProperty("MAPS_API_KEY") ?: ""
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }
}
```

### 4.3 AndroidManifest.xml 수정
```xml
<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />
```

### 4.4 .gitignore 업데이트
```bash
# android/local.properties가 .gitignore에 있는지 확인
android/local.properties
```

## 5. 테스트

### 5.1 앱 실행
```bash
flutter run -d <device-id>
```

### 5.2 위치 기능 테스트
1. Todo 생성/편집 다이얼로그 열기
2. "위치 기반 알림 (선택사항)" 버튼 클릭
3. Google Maps가 표시되는지 확인
4. 현재 위치 버튼이 작동하는지 확인

## 6. 문제 해결

### Maps가 표시되지 않음
- API 키가 올바른지 확인
- Maps SDK for Android가 활성화되어 있는지 확인
- SHA-1 지문이 정확히 등록되어 있는지 확인
- 앱을 완전히 삭제 후 재설치

### "This app won't run without Google Play services" 메시지
- Android 에뮬레이터에서는 Google Play Services가 설치된 이미지 사용
- 실제 디바이스에서 Google Play Services 업데이트

### Logcat에서 오류 확인
```bash
adb logcat | grep -E "(Google|Maps|API)"
```

## 7. 비용 관리

Google Maps API는 사용량에 따라 과금됩니다:
- **Maps SDK for Android**: 월 $200 무료 크레딧 제공
- 기본 맵 로드: 1,000회당 $2
- **개발/테스트 단계**: 무료 크레딧 내에서 충분히 사용 가능

**참고**: API 키 제한(패키지 이름, SHA-1)을 설정하면 무단 사용을 방지할 수 있습니다.

## 8. 참고 자료

- [Google Maps Platform 시작하기](https://developers.google.com/maps/documentation/android-sdk/start)
- [API 키 제한 설정](https://cloud.google.com/docs/authentication/api-keys)
- [Flutter Google Maps 플러그인](https://pub.dev/packages/google_maps_flutter)
