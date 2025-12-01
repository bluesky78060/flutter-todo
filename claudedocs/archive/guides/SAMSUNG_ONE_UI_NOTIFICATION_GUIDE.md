# Samsung One UI 알림 최적화 가이드

## 개요

Samsung Galaxy 플래그십 기기 (S23, S24 등)에서 알림이 작동하지 않는 문제는 One UI 특유의 설정과 제한사항 때문에 발생합니다. 이 문서는 개발자와 사용자 모두를 위한 해결 가이드입니다.

## 현재 구현된 최적화

### 1. 알림 채널 및 중요도 설정

```dart
const androidChannel = AndroidNotificationChannel(
  'todo_notifications_v2',
  'Todo Reminders',
  description: 'Notifications for todo items',
  importance: Importance.max,  // 최대 중요도 (헤드업 알림)
  playSound: true,
  enableVibration: true,
  enableLights: true,
);
```

### 2. 알림 상세 설정

```dart
final androidDetails = AndroidNotificationDetails(
  'todo_notifications_v2',
  'Todo Reminders',
  importance: Importance.max,
  priority: Priority.max,
  // 알림 그룹화 설정
  groupKey: 'kr.bluesky.dodo.TODO_REMINDERS',
  setAsGroupSummary: false,
  // BigText 스타일로 내용 전체 표시
  styleInformation: BigTextStyleInformation(...),
  // ... 기타 설정
);
```

**중요**: Samsung One UI 7의 Live Notifications와 Now Bar는 **포그라운드 서비스 전용**이며 **Samsung 화이트리스트 앱만** 사용할 수 있습니다. Todo 앱의 scheduled notification은 일반 알림 최적화로 충분합니다.

### 3. 사용자 설정 안내 기능

앱은 첫 실행 시 자동으로 사용자를 알림 설정 화면으로 안내합니다:
1. 알림 권한 요청
2. 알림 중요도 설정 안내
3. 시스템 설정 화면으로 직접 이동

## 사용자 체크리스트

### 필수 설정 확인 사항

#### 1. 알림 권한
- **경로**: 설정 → 앱 → DODO → 알림
- **확인**: "알림 허용" 토글이 켜져 있는지
- **중요도**: "높음" 또는 "긴급"으로 설정

#### 2. 알림 카테고리
- **경로**: 설정 → 앱 → DODO → 알림 → 알림 카테고리
- **확인**: "Todo Reminders" 채널이 활성화되어 있는지
- **참고**: Samsung은 기본적으로 알림 카테고리를 비활성화할 수 있습니다

#### 3. 배터리 최적화
- **경로**: 설정 → 배터리 및 디바이스 케어 → 배터리
- **설정**: DODO 앱을 "제한 안 함"으로 설정
- **이유**: 절전 모드가 알림을 차단할 수 있습니다

#### 4. 백그라운드 제한
- **경로**: 설정 → 앱 → DODO → 배터리
- **설정**: "백그라운드 사용 제한" 해제
- **참고**: "절전 앱" 목록에서 제외

#### 5. 잠금화면 알림
- **경로**: 설정 → 잠금화면 및 AOD → 알림
- **설정**: "알림 내용 표시" 활성화
- **참고**: One UI 7/8에서는 Now Bar 설정도 확인

## One UI 버전별 차이점

### One UI 5.0
- 기본적인 알림 제한 정책 시작
- 배터리 최적화 강화

### One UI 6.0
- 알림 카테고리 관리 UI 변경
- "스마트 배터리" 기능 추가

### One UI 7.0 / 8.0 (최신)
- **Now Bar** 기능 추가 (플래그십 전용)
- Live Notifications 지원
- 알림 요약 기능
- 더 세분화된 알림 제어

## 자주 발생하는 문제

### 문제 1: 알림이 전혀 표시되지 않음

**원인**:
- 알림 권한 미허용
- 앱 알림 중요도가 "기본" 또는 "낮음"으로 설정
- allowNoti 시스템 플래그가 false (Galaxy A31 등)

**해결**:
1. 앱에서 "설정 열기" 버튼 클릭
2. 알림 중요도를 "높음"으로 변경
3. 모든 알림 카테고리 활성화

### 문제 2: 알림이 늦게 표시됨

**원인**:
- 배터리 최적화 활성화
- Doze 모드 제한
- 절전 앱 목록에 포함

**해결**:
1. 배터리 최적화 제외
2. 백그라운드 제한 해제
3. 정확한 알람 권한 허용

### 문제 3: 잠금화면에 알림 없음

**원인**:
- 잠금화면 알림 설정 비활성화
- AOD (Always On Display) 설정 문제

**해결**:
1. 잠금화면 → 알림 → 알림 내용 표시 활성화
2. AOD 설정에서 알림 아이콘 표시 활성화

## 개발자를 위한 추가 정보

### 권장 설정

1. **최대 중요도 사용**:
   ```dart
   importance: Importance.max,
   priority: Priority.max,
   ```

2. **알림 최적화 옵션**:
   ```dart
   autoCancel: true,  // 탭하면 자동으로 사라짐
   groupKey: 'kr.bluesky.dodo.TODO_REMINDERS',  // 알림 그룹화
   setAsGroupSummary: false,
   ```

3. **헤드업 알림 설정**:
   ```dart
   category: AndroidNotificationCategory.reminder,
   fullScreenIntent: false,  // 크래시 방지
   ```

4. **BigText 스타일로 내용 전체 표시**:
   ```dart
   styleInformation: BigTextStyleInformation(
     body,
     contentTitle: title,
     summaryText: '할일 알림',
   ),
   ```

### 디버깅 명령어

```bash
# 알림 설정 상태 확인
adb shell dumpsys notification | grep "kr.bluesky.dodo" | grep "importance"

# 알림 권한 확인
adb shell dumpsys package kr.bluesky.dodo | grep "POST_NOTIFICATIONS"

# allowNoti 플래그 확인 (Galaxy A31 버그)
adb shell dumpsys notification | grep "kr.bluesky.dodo" | grep "allowNoti"
```

### 테스트 시나리오

1. **신규 설치 테스트**:
   - 앱 삭제 후 재설치
   - 권한 요청 다이얼로그 확인
   - 설정 안내 다이얼로그 확인

2. **알림 표시 테스트**:
   - 2분 후 알림 설정
   - 앱 백그라운드 전환
   - 알림 표시 확인

3. **장기 테스트**:
   - 24시간 후 알림 설정
   - Doze 모드 동작 확인
   - 배터리 최적화 영향 확인

## 참고 자료

- [Reddit: Samsung notification issues](https://www.reddit.com/r/oneui/)
- [Samsung Community: Notification settings](https://community.samsung.com/)
- [Android Developers: Notification best practices](https://developer.android.com/develop/ui/views/notifications)

## Samsung One UI 7 Live Notifications와 Now Bar 상세 가이드

### Live Notifications와 Now Bar란?

Samsung One UI 7에서 도입된 기능으로, 앱의 **지속적인 알림(ongoing notifications)을 더 눈에 띄게 표시**하는 시스템입니다:

- **Live Notifications**: 알림 창에서 일반 알림과 분리된 별도 섹션에 표시
- **Now Bar**: 잠금 화면에 인터랙티브한 형태로 표시 (예: 스톱워치, YouTube, Spotify)

### 어떤 앱에서 사용할 수 있는가?

#### 미디어 앱
- **즉시 지원**: 미디어 재생 앱은 별도 승인 없이 Live Notifications 사용 가능
- Android의 표준 MediaSession 사용 시 자동으로 지원됨

#### 일반 앱 (포그라운드 서비스)
- **Samsung 화이트리스트 승인 필요**: 포그라운드 서비스 알림은 Samsung의 승인 목록에 포함된 앱만 사용 가능
- 패키지명 기반으로 검증됨
- **일반 개발자는 구현 불가**

### 구현 요구사항 (참고용)

만약 화이트리스트에 등록되었다면:

1. **AndroidManifest.xml**에 메타데이터 추가:
```xml
<meta-data
    android:name="com.samsung.android.support_ongoing_activity"
    android:value="true" />
```

2. **알림 extras**에 스타일 설정:
```java
Bundle bundle = new Bundle();
bundle.putInt("android.ongoingActivityNoti.style", 1); // 필수
notification.extras.putBundle("android.ongoingActivityNoti", bundle);
```

### 지원되는 스타일

#### Live Notifications
- 표준 스타일 (Standard)
- 진행률 스타일 (Progress)
- 커스텀 스타일 (Custom)
- 칩(Chip) 디스플레이 기능

#### Now Bar (잠금화면)
- 표준 스타일 (Standard)
- 커스텀 스타일 (Custom)
- ⚠️ 진행률 스타일은 지원 안 됨

### DODO Todo 앱에 필요한가?

**필요하지 않습니다.** 다음 이유로:

1. **앱 유형 불일치**:
   - Todo 앱은 **scheduled notifications**(예약 알림) 사용
   - Live Notifications는 **ongoing notifications**(지속 알림) 전용
   - 우리는 포그라운드 서비스를 사용하지 않음

2. **화이트리스트 제약**:
   - Samsung 승인이 필요하며 일반 앱은 사용 불가
   - 신청 프로세스나 기준이 공개되지 않음

3. **충분한 대안**:
   - `Importance.max` + `Priority.max` 설정으로 충분히 눈에 띄는 알림 구현
   - 사용자 설정 안내 기능이 더 실질적으로 효과적
   - 배터리 최적화 제외 요청으로 안정성 확보

### 미래 전망: Android 16 Live Updates API

Google은 Android 16에서 **Live Updates API**를 표준화할 예정입니다. 이는:
- Samsung의 Live Notifications와 유사한 기능을 Android 표준으로 제공
- 모든 Android 기기에서 사용 가능
- 화이트리스트 제약 없이 모든 개발자가 사용 가능

### 참고 자료
- [Akexorcist: Live Notifications and Now Bar in Samsung One UI 7 (Developer Guide)](https://akexorcist.dev/live-notifications-and-now-bar-in-samsung-one-ui-7-as-developer-en/)
- [Samsung OneUI Sample App - GitHub](https://github.com/Lemkinator/OneUI-Sample-App)

## 버전 히스토리

### v1.0.5 (최신 - 2024-11-12)
- Live Notifications와 Now Bar 상세 설명 추가
- Samsung 화이트리스트 제약 명확화
- 미디어 앱과 일반 앱 구분 설명
- Android 16 Live Updates API 미래 전망 추가
- 잘못된 Samsung 특화 플래그 제거 (additionalFlags)
- 권장 설정 업데이트 (autoCancel, groupKey 추가)

### v1.0.3
- 알림 중요도 자동 안내 기능
- 알림 그룹화 설정 추가
- 사용자 설정 화면 직접 이동 기능

### v1.0.2
- 알림 채널 중요도 MAX로 상향
- 배터리 최적화 요청 추가

### v1.0.1
- 기본 알림 기능 구현
