# 🎯 Geofencing Phase 4 구현 계획

**목표**: 위치 기반 알림 완전 구현 (Geofencing 백그라운드 모니터링)
**예상 기간**: 2-3주
**우선순위**: 🔴 High
**상태**: Phase 1-3 완료, Phase 4 시작

---

## 📋 현재 상태 분석

### ✅ 이미 구현된 것 (Phase 1-3)
1. **Database Schema**
   - `location_settings` 테이블 (Drift ORM)
   - Supabase RLS 정책
   - todo ↔ location_settings 관계 설정

2. **UI Integration**
   - `LocationPickerDialog` 위젯
   - 지도 표시 및 위치 선택
   - 거리 설정 슬라이더

3. **LocationService 기본 기능**
   - 권한 요청 (포그라운드/백그라운드)
   - 현재 위치 조회
   - 주소 역변환 (좌표 → 주소)

4. **GeofenceWorkManagerService**
   - WorkManager 통합
   - 주기적 위치 확인 (15분 간격)
   - 통합 dispatcher (알림 + Geofencing)

---

## 🔧 Phase 4 - 필요한 구현 작업

### 1️⃣ iOS 권한 설정 (2-3시간)

#### 1.1 Info.plist 업데이트
```
필요한 권한:
- NSLocationWhenInUseUsageDescription (포그라운드)
- NSLocationAlwaysAndWhenInUseUsageDescription (백그라운드)
- NSLocationAlwaysUsageDescription (iOS 10 이하 호환성)
- UIBackgroundModes (위치 업데이트 백그라운드 모드)
```

**파일**: `ios/Runner/Info.plist`
**변경 사항**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>앱이 현재 위치를 사용하여 위치 기반 알림을 제공합니다.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>앱이 백그라운드에서 당신의 위치를 모니터링하여 목표 위치에 도달하면 알림을 보냅니다.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>앱이 백그라운드에서 당신의 위치를 모니터링합니다.</string>

<key>UIBackgroundModes</key>
<array>
  <string>location</string>
</array>
```

#### 1.2 iOS 권한 요청 로직 추가
**파일**: `lib/core/services/location_service.dart`
```dart
// 플랫폼별 권한 요청
Future<bool> requestBackgroundLocationPermission() async {
  // iOS 특화: 항상 권한 요청
  // Android: 백그라운드 권한 (LOCATION_ALWAYS)
}
```

**체크리스트**:
- [ ] Info.plist 4가지 권한 추가
- [ ] UIBackgroundModes 설정
- [ ] 플랫폼별 권한 요청 로직 작성
- [ ] iOS 시뮬레이터/실기기 테스트

---

### 2️⃣ Geofencing 정확도 개선 (3-4시간)

#### 2.1 거리 계산 최적화
```dart
// Haversine 공식으로 정확한 거리 계산
double calculateDistance(
  double userLat, double userLon,
  double targetLat, double targetLon
) {
  // 현재: 간단한 거리 계산
  // 개선: Haversine 공식 적용 (더 정확)
}
```

#### 2.2 반경 범위 관리
```dart
// 문제: 사용자가 반경을 벗어났다가 다시 들어올 때 중복 알림
// 해결책: 상태 머신 구현

enum GeofenceState {
  outside,     // 반경 외부
  entering,    // 반경 진입 중 (거리 < radius)
  inside,      // 반경 내부 (알림 발송됨)
  exiting,     // 반경 퇴출 중
}

// DB에 마지막 상태 저장하여 중복 알림 방지
```

#### 2.3 중복 알림 방지
```dart
// 알림 발송 시간 기록
location_settings {
  id: int
  todo_id: int
  radius: double
  triggered_at: DateTime?  // 마지막 알림 시간 기록
}

// 24시간 내에 같은 위치에서 중복 알림 방지
if (lastTriggeredAt == null ||
    DateTime.now().difference(lastTriggeredAt).inHours >= 24) {
  // 알림 발송
}
```

**체크리스트**:
- [ ] Haversine 공식 구현
- [ ] 상태 머신 추가 (outside → entering → inside → exiting)
- [ ] triggered_at 필드 마이그레이션
- [ ] 중복 알림 방지 로직 구현

---

### 3️⃣ 배터리 최적화 (2-3시간)

#### 3.1 적응형 인터벌 (Adaptive Interval)
```dart
// 배터리 상태에 따라 체크 간격 조정
enum BatteryState {
  full,      // 80% 이상: 10분 간격
  medium,    // 30-80%: 15분 간격 (기본)
  low,       // 10-30%: 30분 간격
  critical,  // 10% 이하: 모니터링 중단
}

Future<void> optimizeCheckInterval() {
  final batteryState = await _getBatteryState();

  int intervalMinutes = switch(batteryState) {
    BatteryState.full => 10,
    BatteryState.medium => 15,
    BatteryState.low => 30,
    BatteryState.critical => 0,  // 중단
  };

  await GeofenceWorkManagerService.startMonitoring(
    intervalMinutes: intervalMinutes
  );
}
```

#### 3.2 배터리 상태 모니터링
```dart
// battery_plus 패키지 사용
import 'package:battery_plus/battery_plus.dart';

Future<int> getBatteryLevel() async {
  return await Battery().batteryLevel;
}

// 배터리 상태 변경 시 리스너
Battery().onBatteryStateChanged.listen((state) {
  // 배터리 상태 변경 시 인터벌 조정
});
```

#### 3.3 CPU 최적화
```dart
// WorkManager 설정 최적화
await Workmanager().registerPeriodicTask(
  _geofenceTaskId,
  _geofenceTaskName,
  frequency: Duration(minutes: intervalMinutes),
  // 중요: 배터리 최적화 활성화
  initialDelay: Duration(minutes: 5),
  // 제약사항: 기기 배터리 상태 고려
  constraints: Constraints(
    requiresBatteryNotLow: true,  // 배터리 부족 시 작업 안함
    requiresDeviceIdle: false,     // CPU 유휴 상태 요구 안함
    requiresNetworking: false,     // 네트워크 필요 없음
  ),
);
```

**체크리스트**:
- [ ] battery_plus 패키지 추가
- [ ] 배터리 상태 감지 로직
- [ ] 적응형 인터벌 구현
- [ ] Constraints 설정 최적화

---

### 4️⃣ 사용자 설정 UI 추가 (2-3시간)

#### 4.1 Settings 화면에 Geofencing 옵션 추가
```dart
// 설정 항목:
// 1. Geofencing 활성화/비활성화 토글
// 2. 체크 간격 선택 (10분, 15분, 30분, 1시간)
// 3. 배터리 최적화 모드 토글
// 4. 현재 모니터링 상태 표시
// 5. 마지막 체크 시간 표시
```

#### 4.2 Todo 상세 화면에서 위치 설정 편집
```dart
// LocationPickerDialog에서:
// - 반경 조정 (100m - 2km)
// - 위치 변경
// - 위치 삭제 (버튼)
```

**체크리스트**:
- [ ] Settings 화면에 Geofencing 섹션 추가
- [ ] 토글 구현 (SharedPreferences 저장)
- [ ] 인터벌 선택 UI
- [ ] 상태 표시 UI

---

### 5️⃣ 테스트 및 디버깅 (3-4시간)

#### 5.1 로컬 테스트
```bash
# 시뮬레이터에서 테스트
flutter run -d emulator-5554  # 또는 iOS 시뮬레이터

# 위치 시뮬레이션 (Android 스튜디오)
1. Logcat에서 위치 데이터 발송
2. 다양한 거리에서 테스트 (반경 내/외)
3. 배터리 상태 변경 시 인터벌 확인
```

#### 5.2 실기기 테스트
```bash
# Samsung Galaxy 등 실제 기기
flutter run -d RF9NB0146AB  # 또는 실제 iOS 기기

# 테스트 시나리오:
1. 위치 설정된 Todo 생성
2. 반경 내로 이동 → 알림 확인
3. 반경 외로 이동 → 알림 중단
4. 배터리 부족 상태에서 동작 확인
5. 백그라운드 앱 상태에서 알림 확인
```

#### 5.3 디버깅 로그 추가
```dart
AppLogger.info('📍 Geofence check: distance=$distance, radius=$radius');
AppLogger.debug('🔋 Battery level: $batteryLevel%');
AppLogger.debug('⏱️ Check interval: $intervalMinutes minutes');
```

**체크리스트**:
- [ ] 시뮬레이터에서 위치 시뮬레이션
- [ ] 반경 내/외 테스트 (5회 반복)
- [ ] 중복 알림 방지 확인
- [ ] 배터리 최적화 동작 확인
- [ ] 실기기에서 백그라운드 테스트

---

## 📦 필요한 패키지

```yaml
dependencies:
  # 이미 설치됨
  geolocator: ^11.2.0        # 위치 조회
  workmanager: ^0.4.2        # 백그라운드 작업
  flutter_local_notifications: ^18.0.1

  # 추가 필요
  battery_plus: ^1.4.0       # 배터리 상태 감지
  # geocoding: ^2.1.0        # 이미 설치됨
```

**설치**:
```bash
flutter pub add battery_plus
```

---

## 🗂️ 파일 구조

```
lib/
├── core/
│   ├── services/
│   │   ├── location_service.dart              (기존 + 개선)
│   │   ├── geofence_workmanager_service.dart  (기존 + 개선)
│   │   └── battery_optimization_service.dart  (신규)
│   └── utils/
│       └── geofence_calculator.dart          (신규 - 거리 계산)
│
├── domain/
│   └── entities/
│       └── geofence_state.dart               (신규 - 상태 관리)
│
├── data/
│   └── datasources/
│       └── local/
│           └── app_database.dart              (마이그레이션 필요)
│
└── presentation/
    └── screens/
        └── settings_screen.dart               (수정 필요)
```

---

## 🔄 구현 순서

### Week 1 (5일)
1. **Day 1**: iOS 권한 설정 + 패키지 추가
2. **Day 2**: Geofencing 정확도 개선 (Haversine, 상태머신)
3. **Day 3**: 배터리 최적화 (adaptive interval)
4. **Day 4**: 사용자 설정 UI
5. **Day 5**: 기본 테스트

### Week 2 (3-5일)
6. **Day 6-7**: 실기기 테스트 (Android + iOS)
7. **Day 8**: 버그 수정 및 최적화
8. **Day 9**: 문서화 및 릴리스 준비

---

## ✅ 완료 기준

- [ ] iOS 시뮬레이터에서 위치 알림 정상 작동
- [ ] Android 실기기에서 백그라운드 모니터링 동작
- [ ] 배터리 최적화 적용 (CPU, 배터리 사용량 감소)
- [ ] 중복 알림 없음
- [ ] Settings 화면에서 설정 가능
- [ ] 전체 테스트 통과 (10회 반복)
- [ ] 문서화 완료

---

## 📚 참고 자료

**이미 생성된 문서**:
- `GOOGLE_MAPS_SETUP.md` - Google Maps API 설정
- `LOCATION_SETUP_GUIDE.md` - 위치 기능 전체 가이드
- 코드: `lib/core/services/geofence_workmanager_service.dart`

**참고 링크**:
- [Geolocator 공식 문서](https://pub.dev/packages/geolocator)
- [WorkManager 공식 문서](https://pub.dev/packages/workmanager)
- [Battery Plus 공식 문서](https://pub.dev/packages/battery_plus)
- [iOS 위치 서비스 가이드](https://developer.apple.com/documentation/corelocation)

---

## 🎯 최종 버전

**완성 후 버전**: 1.0.14+40 (또는 1.0.15+41)
**배포 예상**: 완성 후 5-7일 (Google Play/App Store)

---

**계획 작성**: 2025-11-26
**상태**: 구현 준비 완료 ✅
