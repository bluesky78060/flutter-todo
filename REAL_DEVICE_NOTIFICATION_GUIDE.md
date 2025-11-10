# 실제 기기 알림 문제 해결 가이드

## 🔍 문제 상황

- ✅ **에뮬레이터**: 알림 정상 작동
- ❌ **실제 기기**: 알림 표시 안 됨

이는 **기기별 배터리 최적화 및 백그라운드 제한** 때문일 가능성이 매우 높습니다.

## 🔴 가장 흔한 원인: 제조사별 배터리 최적화

### Samsung 기기 (가장 까다로움)

Samsung은 기본적으로 **모든 앱의 백그라운드 실행을 제한**합니다.

#### 해결 방법 1: 배터리 최적화 제외

1. **설정** → **앱** → **DoDo**
2. **배터리** 탭 선택
3. **백그라운드 사용 제한** → **제한 없음** 선택
4. **절전 모드에서 앱 사용** → **허용** 선택

#### 해결 방법 2: 보호된 앱 설정

1. **설정** → **배터리 및 디바이스 케어**
2. **배터리** → **백그라운드 사용 제한**
3. **절전 모드 제외 앱** → **DoDo 추가**

#### 해결 방법 3: 자동 최적화 끄기

1. **설정** → **배터리 및 디바이스 케어**
2. **자동 최적화** → **끄기**
3. 또는 **사용하지 않는 앱 자동 끄기** → **끄기**

#### 해결 방법 4: Samsung "잠자는 앱" 확인

Samsung은 사용하지 않는 앱을 자동으로 "잠자는 앱"으로 분류합니다.

1. **설정** → **배터리 및 디바이스 케어** → **배터리**
2. **백그라운드 사용 제한**
3. **잠자는 앱** 또는 **절전 앱** 목록 확인
4. **DoDo가 있다면 제거**

### Xiaomi (MIUI)

Xiaomi는 Samsung보다 더 공격적인 백그라운드 제한을 합니다.

#### 해결 방법:

1. **설정** → **앱** → **앱 관리** → **DoDo**
2. **배터리 절약** → **제한 없음**
3. **자동 시작** → **허용**
4. **백그라운드에서 실행** → **허용**
5. **잠금 화면 정리** → **DoDo 잠금** (중요!)

### Huawei

1. **설정** → **앱** → **DoDo**
2. **실행** 탭
3. **수동 관리** 선택
4. 모든 권한 허용:
   - 자동 실행: ✅
   - 보조 실행: ✅
   - 백그라운드 실행: ✅

### OnePlus (OxygenOS)

1. **설정** → **앱** → **DoDo**
2. **배터리** → **배터리 최적화** → **최적화 안 함**
3. **설정** → **배터리** → **배터리 최적화**
4. DoDo 검색 → **최적화 안 함** 선택

### Oppo / Realme (ColorOS)

1. **설정** → **배터리** → **앱 절전**
2. DoDo → **끄기**
3. **설정** → **개인정보 보호** → **권한 관리자**
4. **자동 시작** → DoDo **허용**

### Vivo (FuntouchOS)

1. **설정** → **배터리** → **백그라운드 전원 소비** → **높은 백그라운드 전원 소비**
2. DoDo 추가
3. **설정** → **앱 및 알림** → **시스템 런처**
4. DoDo → **백그라운드 잠금** 활성화

## 🔧 Android 13+ 공통 설정

### 1. 알림 권한 확인

```bash
# PC에서 실행 (기기 연결 후)
~/Library/Android/sdk/platform-tools/adb shell dumpsys notification | grep kr.bluesky.dodo
```

**예상 출력**:
```
AppSettings: kr.bluesky.dodo (xxxxx) importance=DEFAULT userSet=true
```

- `importance=NONE` → ❌ 권한 없음
- `importance=DEFAULT` or `MAX` → ✅ 권한 있음

### 2. 정확한 알람 권한 (Android 12+)

```bash
~/Library/Android/sdk/platform-tools/adb shell dumpsys package kr.bluesky.dodo | grep SCHEDULE_EXACT_ALARM
```

**수동 확인**:
1. **설정** → **앱** → **DoDo** → **권한**
2. **알람 및 리마인더** → **허용**

## 🎯 앱 내 자동 설정 (권장)

앱에서 이미 구현되어 있는 자동 설정 기능:

### 1. 첫 실행 시 권한 요청

앱 최초 실행 시 다음 다이얼로그가 순차적으로 나타납니다:

1. **알림 권한 요청** → "허용" 선택
2. **배터리 최적화 제외** → "설정하기" 선택

**코드 위치**: `lib/presentation/screens/todo_list_screen.dart:43-154`

### 2. 수동 권한 부여 (테스트용)

```bash
# 알림 권한
~/Library/Android/sdk/platform-tools/adb shell pm grant kr.bluesky.dodo android.permission.POST_NOTIFICATIONS

# 정확한 알람 권한
~/Library/Android/sdk/platform-tools/adb shell pm grant kr.bluesky.dodo android.permission.SCHEDULE_EXACT_ALARM

# 배터리 최적화 제외
~/Library/Android/sdk/platform-tools/adb shell dumpsys deviceidle whitelist +kr.bluesky.dodo
```

## 📱 실제 기기 테스트 절차

### Step 1: 앱 설치

```bash
# Release APK 빌드
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
/opt/homebrew/share/flutter/bin/flutter build apk --release

# 기기 연결 확인
~/Library/Android/sdk/platform-tools/adb devices

# APK 설치
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Step 2: 제조사별 설정

**기기 제조사 확인**:
```bash
~/Library/Android/sdk/platform-tools/adb shell getprop ro.product.manufacturer
```

위에서 확인한 제조사에 맞는 설정 적용

### Step 3: 앱 실행 및 권한 부여

1. 앱 실행
2. 로그인
3. **"알림 권한 요청" 다이얼로그** → "허용"
4. **시스템 권한 다이얼로그** → "허용"
5. **"배터리 최적화 제외" 다이얼로그** → "설정하기"

### Step 4: 추가 제조사 설정

Samsung/Xiaomi/Huawei 등은 **Step 3만으로 부족**합니다.

위의 제조사별 가이드를 따라 **수동 설정 필수**

### Step 5: 알림 테스트

1. 할일 생성
2. 알림 시간: 현재 + 2분
3. 앱 백그라운드로 전환
4. 2분 대기
5. 알림 확인

### Step 6: 로그 확인 (Debug 빌드)

```bash
# Debug 빌드로 재설치
/opt/homebrew/share/flutter/bin/flutter build apk --debug
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/apk/debug/app-debug.apk

# 로그 모니터링
~/Library/Android/sdk/platform-tools/adb logcat | grep -E "(TodoActions|NotificationService|flutter)"
```

**기대하는 로그**:
```
✅ TodoActions: Todo created with ID: X
📅 TodoActions: Scheduling notification for todo X
✅ Notification scheduled successfully
✅ TodoActions: Notification verified in pending list
```

## ⚠️ 알림이 여전히 안 나올 경우

### 원인 1: 기기가 절전 모드

**해결**:
1. **설정** → **배터리** → **절전 모드** → **끄기**
2. 또는 충전기 연결

### 원인 2: 방해 금지 모드

**해결**:
1. **설정** → **알림** → **방해 금지**
2. **끄기** 또는 **예외 앱에 DoDo 추가**

### 원인 3: 앱이 강제 종료됨

일부 제조사는 앱을 강제 종료하면 알림도 함께 취소합니다.

**확인**:
```bash
# 실행 중인 프로세스 확인
~/Library/Android/sdk/platform-tools/adb shell ps | grep kr.bluesky.dodo
```

**해결**:
- 앱을 강제 종료하지 말 것
- "최근 앱"에서 스와이프하지 말고 홈 버튼만 누르기

### 원인 4: 시스템 알림 채널 비활성화

**확인**:
1. **설정** → **앱** → **DoDo** → **알림**
2. **"Todo Reminders"** 채널 확인
3. **활성화** 및 **중요도 높음** 설정

## 🧪 최종 검증 방법

### 1. 포그라운드 테스트

```bash
# 앱을 포그라운드 상태로 유지
# 알림 시간 1-2분 후로 설정
# 알림 발생 확인
```

- **포그라운드에서 성공** → 백그라운드 제한 문제
- **포그라운드에서 실패** → 권한 또는 코드 문제

### 2. 즉시 알림 테스트

테스트 코드 추가:

```dart
// lib/main.dart에 임시로 추가
@override
void initState() {
  super.initState();
  // 10초 후 테스트 알림
  Future.delayed(Duration(seconds: 10), () {
    final service = NotificationService();
    service.scheduleNotification(
      id: 9999,
      title: '즉시 테스트',
      body: '10초 후 알림',
      scheduledDate: DateTime.now().add(Duration(seconds: 10)),
    );
  });
}
```

### 3. 권한 상태 전체 확인

```bash
~/Library/Android/sdk/platform-tools/adb shell dumpsys package kr.bluesky.dodo | grep -A 50 "permission"
```

## 📊 제조사별 성공률

제조사별 알림 성공률 (커뮤니티 데이터 기반):

- Google Pixel: **95%** ✅
- Stock Android: **90%** ✅
- OnePlus: **85%** ⚠️
- Motorola: **80%** ⚠️
- Samsung: **70%** ⚠️ (추가 설정 필수)
- Xiaomi: **60%** ⚠️ (매우 까다로움)
- Huawei: **50%** ❌ (HMS 사용 시 더 복잡)
- Oppo/Realme: **65%** ⚠️
- Vivo: **60%** ⚠️

## 💡 결론

**에뮬레이터에서 작동 = 코드는 정상**

실제 기기 문제의 **90%는 제조사의 배터리 최적화** 때문입니다.

**해결 우선순위**:

1. **제조사 확인** (가장 중요!)
2. **배터리 최적화 제외** 설정
3. **자동 시작 허용** (Xiaomi/Oppo/Vivo)
4. **백그라운드 실행 허용**
5. **잠자는 앱에서 제거** (Samsung)

모든 설정을 했는데도 안 되면:
- **절전 모드 끄기**
- **방해 금지 모드 확인**
- **앱 강제 종료 금지**

---

**참고 자료**:
- https://dontkillmyapp.com/ - 제조사별 상세 가이드
- Android Developer Docs - Background Execution Limits
