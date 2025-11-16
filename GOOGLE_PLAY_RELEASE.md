# Google Play 배포 가이드

## 📦 생성된 파일

### 🆕 최신 버전 (v1.0.2+12) - 알림 크래시 완전 해결 (최종)
**주요 개선사항**:
- ✅ 알림 시간에 앱 종료되는 문제 완전 해결
- ✅ 백그라운드 알림 핸들러 안정화 (kDebugMode 제거)
- ✅ 백그라운드 상태에서 print 문으로 인한 크래시 방지
- ✅ @pragma('vm:entry-point') 주석으로 트리 쉐이킹 방지
- ✅ 권한 요청 안정성 개선
- ✅ R8 코드 최적화 활성화
- ✅ ProGuard 난독화 적용
- ✅ 네이티브 디버그 심볼 자동 생성

#### Android App Bundle (AAB)
- **파일**: `app-release-v1.0.2+12.aab`
- **버전**: 1.0.2 (코드 12)
- **크기**: 128MB (디버그 심볼 포함)
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/build/app/outputs/bundle/release/app-release-v1.0.2+12.aab`
- **서명**: ✅ Release keystore로 서명됨

#### APK (직접 배포용)
- **파일**: `app-release-v1.0.2+12.apk`
- **크기**: 31MB
- **용도**: 테스트 또는 직접 배포
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/build/app/outputs/flutter-apk/app-release-v1.0.2+12.apk`

### 이전 버전 (v1.0.2+11) - 백그라운드 알림 핸들러 추가 (크래시 있음)
**주요 개선사항**:
- ✅ 백그라운드 알림 핸들러 추가 (onDidReceiveBackgroundNotificationResponse)
- ⚠️ kDebugMode 사용으로 백그라운드에서 크래시 발생

#### Android App Bundle (AAB)
- **파일**: `app-release-v1.0.2+11.aab`
- **버전**: 1.0.2 (코드 11)
- **크기**: 126MB
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/build/app/outputs/bundle/release/app-release-v1.0.2+11.aab`
- **상태**: ⚠️ 사용 권장하지 않음 (알림 시 앱 종료됨)

### 이전 버전 (v1.0.2+6) - OAuth 브라우저 자동 닫기 및 삼성 알림 개선
**주요 개선사항**:
- ✅ OAuth 로그인 후 브라우저 자동 닫기
- ✅ 삼성 기기 배터리 최적화 권한 추가
- ✅ 알림 아이콘 수정 (notification_icon.xml)
- ✅ R8 코드 최적화 활성화
- ✅ ProGuard 난독화 적용
- ✅ 네이티브 디버그 심볼 자동 생성
- ✅ 리소스 최적화

#### Android App Bundle (AAB)
- **파일**: `app-release-v1.0.2+6.aab`
- **버전**: 1.0.2 (코드 6)
- **크기**: 126MB (디버그 심볼 포함)
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/app-release-v1.0.2+6.aab`
- **서명**: ✅ Release keystore로 서명됨

#### APK (직접 배포용)
- **파일**: `app-release-v1.0.2+6.apk`
- **크기**: 28MB
- **용도**: 테스트 또는 직접 배포
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/app-release-v1.0.2+6.apk`

### 이전 버전 (v1.0.2+5) - 알림 수정 완료
**주요 개선사항**:
- ✅ 알림 아이콘 수정 (notification_icon.xml)
- ✅ R8 코드 최적화 활성화
- ✅ ProGuard 난독화 적용
- ✅ 네이티브 디버그 심볼 자동 생성
- ✅ 리소스 최적화

#### Android App Bundle (AAB)
- **파일**: `app-release-v1.0.2+5.aab`
- **버전**: 1.0.2 (코드 5)
- **크기**: 126MB (디버그 심볼 포함)
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/app-release-v1.0.2+5.aab`
- **서명**: ✅ Release keystore로 서명됨

#### APK (직접 배포용)
- **파일**: `app-release-v1.0.2+5.apk`
- **크기**: 28MB
- **용도**: 테스트 또는 직접 배포
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/app-release-v1.0.2+5.apk`

### ⚠️ 이전 버전 (v1.0.2+4) - 알림 문제 있음
**문제점**: 알림 아이콘 미설정으로 알림이 표시되지 않음

#### Android App Bundle (AAB)
- **파일**: `app-release-v1.0.2+4.aab`
- **버전**: 1.0.2 (코드 4)
- **크기**: 29MB
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/app-release-v1.0.2+4.aab`
- **상태**: ❌ 사용 권장하지 않음 (알림 미작동)

#### APK (직접 배포용)
- **파일**: `app-release-v1.0.2+4.apk`
- **크기**: 28MB
- **위치**: `/Users/leechanhee/Dropbox/Mac/Downloads/todo_app/app-release-v1.0.2+4.apk`
- **상태**: ❌ 사용 권장하지 않음 (알림 미작동)

## 🚀 Google Play Console 배포 절차

### 1단계: Google Play Console 접속
1. https://play.google.com/console 접속
2. 개발자 계정 로그인 (또는 신규 등록)
   - 첫 등록 시 $25 일회성 등록비 필요

### 2단계: 새 앱 만들기
1. **모든 앱** → **앱 만들기** 클릭
2. 앱 세부정보 입력:
   - **앱 이름**: DoDo (할일 관리 앱)
   - **기본 언어**: 한국어
   - **앱 또는 게임**: 앱
   - **무료 또는 유료**: 무료
3. 개발자 프로그램 정책 및 미국 수출법 동의
4. **앱 만들기** 클릭

### 3단계: 스토어 등록정보 설정

#### 앱 액세스 권한
- **앱의 모든 기능을 모든 사용자가 제한 없이 이용 가능** 선택
- 제한된 기능이 있다면 상세 설명 제공

#### 광고
- **앱에 광고 포함 여부** 선택 (현재: 아니요)

#### 콘텐츠 등급
1. **설문지 시작** 클릭
2. 카테고리 선택: **유틸리티, 생산성, 커뮤니케이션 또는 기타**
3. 질문에 답변:
   - 폭력적 콘텐츠: 아니요
   - 성적 콘텐츠: 아니요
   - 비속어/욕설: 아니요
   - 약물 관련: 아니요
4. **등급 계산** → **제출**

#### 타겟 고객 및 콘텐츠
1. **타겟 연령**: 모든 연령 (또는 13세 이상)
2. **스토어 게재 위치**: 적절히 선택
3. **앱 세부정보**:
   ```
   간단한 할일 관리 앱입니다.
   카테고리별로 할일을 분류하고,
   알림 기능으로 중요한 일정을 놓치지 마세요.
   ```

#### 데이터 보안
1. **데이터 수집 여부** 선택
2. 현재 앱이 수집하는 데이터:
   - **개인 정보**: 이메일 주소 (OAuth 로그인)
   - **할일 데이터**: 사용자가 생성한 할일 목록
3. **데이터 공유**: 아니요
4. **데이터 암호화**: 예 (전송 중 암호화)
5. **데이터 삭제 요청**: 지원 (사용자가 앱에서 직접 삭제 가능)

### 4단계: 주요 스토어 등록정보

#### 1. 앱 세부정보
```
앱 이름: DoDo
간단한 설명: 간단하고 직관적인 할일 관리 앱

자세한 설명:
DoDo는 당신의 일상을 효율적으로 관리할 수 있는 할일 관리 앱입니다.

주요 기능:
✅ 할일 추가, 수정, 삭제
✅ 카테고리별 분류
✅ 마감일 설정
✅ 알림 기능
✅ 완료 여부 체크
✅ Google/Kakao 소셜 로그인
✅ 다크 모드 지원

간단하면서도 강력한 기능으로
당신의 생산성을 높여보세요!
```

#### 2. 그래픽 에셋 (필수)
**앱 아이콘**:
- 이미 설정됨: `android/app/src/main/res/mipmap-*/ic_launcher.png`

**스크린샷** (최소 2개 필요):
- 크기: 16:9 비율 권장
- 해상도: 1080 x 1920 이상
- 앱의 주요 화면 캡처:
  1. 할일 목록 화면
  2. 할일 추가 화면
  3. 카테고리 화면
  4. 설정 화면

**피처 그래픽** (필수):
- 크기: 1024 x 500
- 앱 로고 + 간단한 설명 텍스트

#### 3. 앱 카테고리
- **카테고리**: 생산성
- **태그**: 할일, 생산성, 일정관리, todo

### 5단계: 프로덕션 트랙에 배포

#### 1. 프로덕션 → 새 버전 만들기
1. **프로덕션** 탭 클릭
2. **새 버전 만들기** 클릭

#### 2. AAB 업로드
1. **Android App Bundle 업로드** 클릭
2. `app-release.aab` 파일 선택 (29MB)
3. 업로드 완료 대기

#### 3. 버전 정보 입력
```
버전 이름: 1.0.2
버전 코드: 12

출시 노트 (한국어):
버전 1.0.2+12 (2025년 11월)

🔧 중요 버그 수정 (최종):
✅ 알림 시간에 앱이 종료되는 문제 완전 해결
✅ 백그라운드 알림 핸들러 안정화
✅ 앱이 종료된 상태에서도 알림이 정상 작동
✅ 모든 상황에서 안정적인 알림 기능 제공

기술적 개선사항:
- 백그라운드 알림 핸들러 최적화 (크래시 방지)
- @pragma('vm:entry-point') 주석으로 트리 쉐이킹 방지
- 백그라운드 상태 print 문 제거로 안정성 향상
- 권한 요청 로직 안정성 개선
- 순차 권한 요청으로 충돌 방지

주요 기능:
✅ 할일 추가, 수정, 삭제
✅ 카테고리별 분류
✅ 마감일 및 알림 설정
✅ Google/Kakao 소셜 로그인
✅ 다크 모드 지원
✅ 헤드업 알림으로 중요한 할일 놓치지 않기
✅ LED 알림 지원 (지원 기기)

이전 버그 수정 내역:
- 알림 시간에 앱이 종료되던 문제 해결 (v1.0.2+12)
- OAuth 로그인 후 브라우저가 백그라운드에 남아있던 문제 해결
- 삼성 갤럭시 기기의 알림 안정성 향상
- 일부 기기에서 알림이 표시되지 않던 문제 해결
- Android 14 호환성 개선
```

#### 4. 검토 및 출시
1. 모든 필수 항목이 완료되었는지 확인
2. **검토 시작** 클릭
3. 최종 확인 후 **프로덕션으로 출시** 클릭

### 6단계: 검토 대기
- Google Play 검토 시간: 보통 1~3일
- 검토 상태: Play Console 대시보드에서 확인
- 거부 시: 피드백 확인 후 수정하여 재제출

## ✅ 배포 전 체크리스트

### 필수 확인 사항
- [ ] **앱 아이콘**: 설정됨 ✅
- [ ] **스크린샷**: 최소 2개 준비 필요
- [ ] **피처 그래픽**: 1024x500 이미지 준비 필요
- [ ] **앱 설명**: 작성 완료
- [ ] **콘텐츠 등급**: 설정 완료
- [ ] **개인정보처리방침**: URL 준비 (필수)
- [ ] **데이터 보안 설문**: 작성 완료
- [ ] **타겟 국가**: 선택 (한국 권장)
- [ ] **가격**: 무료 설정

### 권장 사항
- [ ] **테스트 트랙**: 내부/비공개 테스트 먼저 진행
- [ ] **점진적 배포**: 처음엔 10% 사용자에게만 배포
- [ ] **오류 모니터링**: Play Console의 사전 출시 보고서 확인
- [ ] **업데이트 계획**: 버전 2.0 로드맵 준비

## 📱 앱 정보

### 패키지 정보
- **Package Name**: kr.bluesky.dodo
- **Version Code**: 12
- **Version Name**: 1.0.2
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34

### 권한 목록
```xml
<!-- 알림 관련 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>

<!-- 네트워크 -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

## 🔐 보안 및 서명

### Keystore 정보
- **위치**: `android/upload-keystore.jks`
- **설정 파일**: `android/key.properties`
- **⚠️ 중요**: key.properties는 절대 Git에 커밋하지 말 것!

### key.properties 백업
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=upload-keystore.jks
```
**백업 위치**: 안전한 곳에 별도 보관 필수!

## 🔄 향후 업데이트 방법

### 1. 버전 업데이트
`pubspec.yaml` 수정:
```yaml
version: 1.0.3+4  # 1.0.3 = 버전명, 4 = 버전코드 (항상 증가해야 함)
```

### 2. AAB 빌드
```bash
flutter build appbundle --release
```

### 3. Play Console에서 업데이트
1. 프로덕션 → 새 버전 만들기
2. 새 AAB 업로드
3. 출시 노트 작성
4. 검토 후 출시

## 📞 문의 및 지원

### Google Play 개발자 지원
- 지원 센터: https://support.google.com/googleplay/android-developer
- 정책: https://play.google.com/about/developer-content-policy/

### 개인정보처리방침 예시
앱 배포 전에 반드시 개인정보처리방침 페이지가 필요합니다.
무료 생성 도구: https://www.privacypolicygenerator.info/

## 🎯 배포 후 모니터링

### Play Console 대시보드
- **설치 수**: 일별/월별 설치 현황
- **평점**: 사용자 평가 및 리뷰
- **충돌 보고서**: ANR 및 크래시 로그
- **사전 출시 보고서**: 자동화된 테스트 결과

### Firebase (선택사항)
- 실시간 사용자 분석
- 크래시 분석
- 성능 모니터링

## ⚠️ 주의사항

1. **첫 배포 시간**: 검토에 최대 7일까지 소요될 수 있음
2. **정책 준수**: Google Play 정책을 꼼꼼히 확인
3. **스크린샷**: 실제 앱 화면만 사용 (가짜 이미지 금지)
4. **키스토어 관리**: 분실 시 업데이트 불가능!
5. **버전 코드**: 항상 증가하는 숫자여야 함

## 📚 추가 리소스

- [Flutter 공식 배포 가이드](https://docs.flutter.dev/deployment/android)
- [Google Play Console 도움말](https://support.google.com/googleplay/android-developer)
- [Android 앱 번들 가이드](https://developer.android.com/guide/app-bundle)
