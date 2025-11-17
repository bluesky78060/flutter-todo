# SHA Fingerprints for Google Maps API

**Generated**: 2025-11-17
**Package Name**: `kr.bluesky.dodo`

## Release Keystore (upload-keystore.jks)

이 SHA-1 fingerprint를 Google Cloud Console의 API 키 제한 설정에 추가하세요.

**SHA-1 Fingerprint**:
```
AF:1F:9D:DA:7F:0E:66:9A:E8:11:C3:DB:25:27:7E:9C:E6:3E:C6:B1
```

**SHA-256 Fingerprint** (참고용):
```
B0:8A:AA:B9:68:8E:F1:B6:CF:DD:86:F4:A9:B2:98:6F:8F:AC:62:05:75:03:AF:71:DA:07:C6:72:99:B0:7A:3F
```

## Google Cloud Console 설정

### 1. API 키 제한 설정

1. **Google Cloud Console 접속**
   - https://console.cloud.google.com/
   - APIs & Services > Credentials

2. **API 키 편집**
   - 생성한 API 키 클릭 > "Edit API key"

3. **Application restrictions**
   - "Android apps" 선택
   - "ADD AN ITEM" 클릭
   - **Package name**: `kr.bluesky.dodo`
   - **SHA-1 certificate fingerprint**: `AF:1F:9D:DA:7F:0E:66:9A:E8:11:C3:DB:25:27:7E:9C:E6:3E:C6:B1`

4. **API restrictions**
   - "Restrict key" 선택
   - "Maps SDK for Android" 체크

5. **저장**
   - "SAVE" 클릭

### 2. local.properties 설정

```bash
# 파일 생성
cd /Users/leechanhee/todo_app/android
cp local.properties.example local.properties

# 편집
nano local.properties
```

파일 내용:
```properties
# Flutter SDK 경로 (자동 생성됨)
sdk.dir=/Users/leechanhee/Library/Android/sdk
flutter.sdk=/opt/homebrew/share/flutter

# Google Maps API Key (여기에 실제 키 입력)
MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
```

### 3. 테스트

```bash
# Clean build
flutter clean
flutter pub get

# Debug build
flutter build apk --debug

# Release build
flutter build appbundle --release

# 디바이스에서 실행
flutter run -d RF9NB0146AB
```

앱에서 "할 일 추가" > "위치 설정" 클릭하여 지도가 정상적으로 표시되는지 확인하세요.

## 키스토어 정보

**Release Keystore**:
- 파일: `/Users/leechanhee/todo_app/android/app/upload-keystore.jks`
- Alias: `upload`
- 생성일: 2025년 11월 17일
- 만료일: 2053년 4월 4일 (28년)
- 소유자: CN=이찬희, OU=개인개발자, O=이찬희, L=경상북도, ST=봉화군, C=KR

## 재생성 명령어

나중에 다시 확인이 필요하면:

```bash
# JAVA_HOME 설정
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# SHA-1 fingerprint 확인
"$JAVA_HOME/bin/keytool" -list -v \
  -keystore /Users/leechanhee/todo_app/android/app/upload-keystore.jks \
  -alias upload \
  -storepass "Dodo2025!@#" \
  -keypass "Dodo2025!@#" | grep SHA1
```

## 보안 주의사항

⚠️ **중요**: 이 문서는 민감한 정보를 포함하지 않으므로 커밋해도 안전합니다.
- SHA fingerprint는 공개 정보입니다 (앱 서명 확인용)
- Keystore 파일과 비밀번호는 **절대 공개하지 마세요**
- `android/key.properties`와 `android/app/upload-keystore.jks`는 .gitignore에 포함되어 있습니다

## 참고 문서

- [LOCATION_SETUP_GUIDE.md](LOCATION_SETUP_GUIDE.md) - 전체 설정 가이드
- [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md) - 상세 API 설정 가이드
