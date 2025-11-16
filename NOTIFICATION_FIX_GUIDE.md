# 알림 문제 해결 가이드

## 문제 원인

진단 결과, 앱의 알림이 시스템 레벨에서 차단되어 있습니다:
```
AppSettings: kr.bluesky.dodo (10275) allowNoti=false
```

## 해결 방법

### 1단계: 알림 권한 활성화

**방법 A: 설정 앱에서 직접 활성화**
1. 설정 앱 열기
2. `앱` → `DODO` (또는 앱 목록에서 DODO 찾기)
3. `알림` 선택
4. **"알림 허용"** 토글을 **켜기**로 변경
5. `Todo Reminders` 채널이 활성화되어 있는지 확인

**방법 B: 알림에서 직접 설정**
1. 앱에서 테스트 알림 생성 (1-2분 후 알림 설정)
2. 알림이 차단되면 "알림이 차단됨" 메시지 확인
3. 메시지 터치하여 설정으로 이동
4. "알림 허용" 활성화

### 2단계: 테스트

1. **즉시 알림 테스트**:
   - 새 할일 생성
   - 알림 시간을 **현재 시간 + 2분**으로 설정
   - 저장 후 앱을 백그라운드로 이동 (홈 버튼)
   - 2분 후 알림이 표시되는지 확인

2. **로그 확인** (개발자용):
   ```bash
   ~/Library/Android/sdk/platform-tools/adb -s RF9NB0146AB logcat | grep -E "(flutter|TodoActions|NotificationService)"
   ```

## 확인된 정상 설정

✅ **알림 채널**: `todo_notifications_v2` 정상 생성됨
✅ **채널 중요도**: MAX (5) - 헤드업 알림 지원
✅ **정확한 알람 권한**: 허용됨 (`SCHEDULE_EXACT_ALARM`)
✅ **배터리 최적화**: 예외 목록에 등록됨
✅ **알림 히스토리**: 앱이 알림을 enqueue하고 있음 (3개)

## 추가 권장 설정 (선택사항)

### 삼성 기기 최적화 설정

1. **절전 모드 예외 설정**:
   - 설정 → 배터리 및 디바이스 케어 → 배터리
   - 백그라운드 사용 제한 → DODO 앱 찾기
   - **"제한 안 함"** 선택

2. **자동 실행 허용** (일부 삼성 기기):
   - 설정 → 앱 → DODO
   - 배터리 → 백그라운드 사용 제한
   - **"제한 안 함"** 선택

## 문제가 계속되면

1. **앱 재시작**: 앱을 완전히 종료하고 다시 실행
2. **기기 재부팅**: 알림 설정 변경 후 재부팅
3. **앱 재설치**: 최후의 수단으로 앱 삭제 후 재설치
   - 주의: 로컬 데이터는 클라우드에 동기화되어야 복구 가능

## 디버그 명령어 (개발자용)

```bash
# 알림 설정 확인
~/Library/Android/sdk/platform-tools/adb -s RF9NB0146AB shell dumpsys notification | grep -A 5 "kr.bluesky.dodo"

# 알림 권한 상태 확인
~/Library/Android/sdk/platform-tools/adb -s RF9NB0146AB shell dumpsys package kr.bluesky.dodo | grep -E "(POST_NOTIFICATIONS|allowNoti)"

# 예약된 알림 확인
~/Library/Android/sdk/platform-tools/adb -s RF9NB0146AB shell dumpsys alarm | grep -A 10 kr.bluesky.dodo
```

## 성공 확인

알림이 정상적으로 작동하면:
- 📱 설정 시간에 정확히 알림이 표시됨
- 🔔 알림음과 진동이 작동함
- 📲 헤드업 알림(팝업)이 화면에 나타남
- 🔍 로그에 "Notification verified in pending list" 메시지 표시됨
