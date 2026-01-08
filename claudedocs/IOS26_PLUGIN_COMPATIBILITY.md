# iOS 26 Plugin Compatibility Report

## Summary

iOS 26 (beta) 환경에서 Flutter 플러그인 호환성 테스트 결과입니다.
앱이 성공적으로 실행되려면 일부 플러그인을 비활성화해야 합니다.

**테스트 날짜**: 2026-01-08
**디바이스**: iPhone (Lch0408) - iOS 26.2
**Flutter 버전**: 3.38.4

---

## Working Plugins (19개)

다음 플러그인들은 iOS 26에서 정상 작동합니다:

| Plugin | Class | 기능 |
|--------|-------|------|
| device_info_plus | FPPDeviceInfoPlusPlugin | 디바이스 정보 |
| file_picker | FilePickerPlugin | 파일 선택 |
| flutter_local_notifications | FlutterLocalNotificationsPlugin | 로컬 알림 |
| flutter_naver_map | SwiftFlutterNaverMapPlugin | 네이버 지도 |
| geocoding_ios | GeocodingPlugin | 지오코딩 |
| geolocator_apple | GeolocatorPlugin | 위치 서비스 |
| google_sign_in_ios | FLTGoogleSignInPlugin | Google 로그인 |
| home_widget | HomeWidgetPlugin | iOS 위젯 |
| image_picker_ios | FLTImagePickerPlugin | 이미지 선택 |
| package_info_plus | FPPPackageInfoPlusPlugin | 패키지 정보 |
| path_provider_foundation | PathProviderPlugin | 경로 제공 |
| permission_handler_apple | PermissionHandlerPlugin | 권한 처리 |
| share_plus | FPPSharePlusPlugin | 공유 기능 |
| shared_preferences_foundation | SharedPreferencesPlugin | 로컬 저장소 |
| sign_in_with_apple | SignInWithApplePlugin | Apple 로그인 |
| sqflite_darwin | SqflitePlugin | SQLite 데이터베이스 |
| sqlite3_flutter_libs | Sqlite3FlutterLibsPlugin | SQLite3 라이브러리 |
| syncfusion_flutter_pdfviewer | SyncfusionFlutterPdfViewerPlugin | PDF 뷰어 |
| url_launcher_ios | URLLauncherPlugin | URL 실행 |

---

## Disabled Plugins (7개)

다음 플러그인들은 iOS 26에서 크래시를 일으키므로 비활성화되었습니다:

| Plugin | Class | 오류 유형 | 영향받는 기능 |
|--------|-------|----------|--------------|
| **app_links** | AppLinksIosPlugin | EXC_BAD_ACCESS | 딥링크 |
| **connectivity_plus** | ConnectivityPlusPlugin | EXC_BAD_ACCESS | 네트워크 상태 확인 |
| **battery_plus** | FPPBatteryPlusPlugin | iOS 26 incompatible | 배터리 상태 |
| **flutter_activity_recognition** | FlutterActivityRecognitionPlugin | iOS 26 incompatible | 활동 인식 |
| **geofence_service** | GeofenceServicePlugin | iOS 26 incompatible | 지오펜싱 |
| **fl_location** | FlLocationPlugin | iOS 26 incompatible | 위치 서비스 (대체) |
| **workmanager_apple** | WorkmanagerPlugin | iOS 26 incompatible | 백그라운드 작업 |

### 크래시 상세

**app_links & connectivity_plus**:
- 오류: `EXC_BAD_ACCESS (SIGSEGV)` in `swift_getObjectType + 40`
- 원인: iOS 26 Swift 런타임 변경으로 인한 플러그인 등록 시 크래시

**기타 플러그인**:
- iOS 26 beta API 변경으로 인한 호환성 문제
- 정식 버전 출시 시 플러그인 업데이트 필요

---

## 비활성화된 기능 대체 방안

### 네트워크 상태 (connectivity_plus)
- Dart의 `http` 패키지로 직접 연결 테스트
- 또는 네트워크 요청 실패 시 오프라인으로 간주

### 딥링크 (app_links)
- 앱 내 딥링크 비활성화
- iOS 정식 버전 출시 후 재활성화

### 백그라운드 작업 (workmanager_apple)
- 앱이 포그라운드에 있을 때만 작업 수행
- 또는 푸시 알림 기반 백그라운드 트리거

### 지오펜싱 (geofence_service)
- geolocator_apple로 수동 위치 확인
- 위치 기반 알림 기능 제한

---

## GeneratedPluginRegistrant.m 수정 방법

`ios/Runner/GeneratedPluginRegistrant.m` 파일에서:

1. 비활성화할 플러그인의 `#if...#endif` import 블록 제거
2. `registerWithRegistry` 메서드에서 해당 플러그인 등록 코드 주석 처리

**주의**: `flutter pub get` 또는 `flutter run` 실행 시 파일이 재생성됩니다.
Xcode에서 직접 빌드하거나, 빌드 후 스크립트로 수정하세요.

---

## 권장 빌드 방법

```bash
# 1. GeneratedPluginRegistrant.m 수정
# 2. Xcode에서 직접 빌드
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination 'id=DEVICE_ID' build

# 3. 앱 설치
xcrun devicectl device install app --device DEVICE_ID \
  ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphoneos/Runner.app

# 4. 앱 실행
xcrun devicectl device process launch --device DEVICE_ID kr.bluesky.dodo
```

---

## 향후 조치

1. **플러그인 업데이트 모니터링**: iOS 26 정식 출시 시 플러그인 업데이트 확인
2. **Flutter 업데이트**: iOS 26 지원 Flutter 버전 출시 시 업그레이드
3. **점진적 재활성화**: 플러그인 하나씩 다시 활성화하며 테스트
4. **대체 플러그인 검토**: 호환되지 않는 플러그인의 대안 검토

---

## 관련 파일

- `ios/Runner/GeneratedPluginRegistrant.m` - 플러그인 등록 파일
- `ios/scripts/disable_app_links.sh` - 플러그인 비활성화 스크립트 (수정 필요)
- `ios/Podfile` - CocoaPods 의존성
