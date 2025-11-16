# 플랫폼별 버전 관리 가이드

Android와 iOS의 버전을 독립적으로 관리하는 방법을 설명합니다.

## 목차
1. [버전 관리 전략](#버전-관리-전략)
2. [빌드 스크립트 사용법](#빌드-스크립트-사용법)
3. [수동 빌드 방법](#수동-빌드-방법)
4. [버전 히스토리 관리](#버전-히스토리-관리)
5. [트러블슈팅](#트러블슈팅)

---

## 버전 관리 전략

### 현재 설정
- **pubspec.yaml**: `version: 1.0.10+34` (기본값, 빌드 시 오버라이드 가능)
- **Android**: 빌드 시 독립적인 버전 지정 가능
- **iOS**: 빌드 시 독립적인 버전 지정 가능

### 버전 번호 체계
```
[major].[minor].[patch]+[build-number]
   1   .   0   .  10   +      34

- major: 주요 버전 (호환성 깨짐)
- minor: 기능 추가 (호환성 유지)
- patch: 버그 수정
- build-number: 빌드 횟수 (자동 증가)
```

### 플랫폼별 버전 예시

| 플랫폼 | 버전 | 빌드 번호 | 사용 이유 |
|--------|------|----------|---------|
| Android | 1.0.10 | 34 | Google Play에 이미 34까지 업로드 |
| iOS | 1.0.5 | 15 | App Store는 15부터 시작 |

**주의**: 각 스토어에서는 빌드 번호가 항상 증가해야 합니다.

---

## 빌드 스크립트 사용법

### Android 빌드

#### 기본 사용법
```bash
# 기본값으로 빌드 (1.0.10+34)
./scripts/build_android.sh

# 버전 지정
./scripts/build_android.sh 1.0.11 35

# 버전, 빌드 번호, 타입 모두 지정
./scripts/build_android.sh 1.0.11 35 release
```

#### 파라미터
1. **버전** (선택, 기본값: 1.0.10)
2. **빌드 번호** (선택, 기본값: 34)
3. **빌드 타입** (선택, 기본값: release)
   - `release`: AAB + APK 생성
   - `debug`: Debug APK 생성

#### 출력 파일
빌드가 완료되면 버전 번호가 포함된 파일이 생성됩니다:
```
build/app/outputs/bundle/release/
  ├── app-release.aab                    # 원본
  └── app-release-1.0.11+35.aab         # 버전 포함 복사본

build/app/outputs/flutter-apk/
  ├── app-release.apk                    # 원본
  └── app-release-1.0.11+35.apk         # 버전 포함 복사본
```

#### 예시
```bash
# Android 버전 1.0.11, 빌드 35로 릴리즈 빌드
./scripts/build_android.sh 1.0.11 35 release

# Android 버전 1.0.12, 빌드 36으로 디버그 빌드
./scripts/build_android.sh 1.0.12 36 debug
```

### iOS 빌드

#### 기본 사용법
```bash
# 기본값으로 빌드 (1.0.5+15)
./scripts/build_ios.sh

# 버전 지정
./scripts/build_ios.sh 1.0.6 16

# 최신 버전으로 빌드
./scripts/build_ios.sh 1.0.7 17
```

#### 파라미터
1. **버전** (선택, 기본값: 1.0.5)
2. **빌드 번호** (선택, 기본값: 15)

#### 다음 단계
스크립트 완료 후:
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. **Product → Archive** 선택
3. **Organizer → Distribute App** 클릭
4. App Store Connect에 업로드

#### 예시
```bash
# iOS 버전 1.0.6, 빌드 16으로 빌드
./scripts/build_ios.sh 1.0.6 16

# iOS 버전 1.0.7, 빌드 17로 빌드
./scripts/build_ios.sh 1.0.7 17
```

---

## 수동 빌드 방법

빌드 스크립트 없이 수동으로 빌드하는 방법입니다.

### Android 수동 빌드

#### AAB (Google Play 업로드용)
```bash
flutter build appbundle \
    --release \
    --build-name=1.0.11 \
    --build-number=35

# 출력: build/app/outputs/bundle/release/app-release.aab

# 버전 포함 파일명으로 복사
cp build/app/outputs/bundle/release/app-release.aab \
   build/app/outputs/bundle/release/app-release-1.0.11+35.aab
```

#### APK (직접 배포용)
```bash
flutter build apk \
    --release \
    --build-name=1.0.11 \
    --build-number=35

# 출력: build/app/outputs/flutter-apk/app-release.apk

# 버전 포함 파일명으로 복사
cp build/app/outputs/flutter-apk/app-release.apk \
   build/app/outputs/flutter-apk/app-release-1.0.11+35.apk
```

### iOS 수동 빌드

```bash
# 1. Clean 및 Dependencies
flutter clean
flutter pub get
cd ios && pod install && cd ..

# 2. iOS 빌드
flutter build ios \
    --release \
    --build-name=1.0.6 \
    --build-number=16 \
    --no-codesign

# 3. Xcode에서 Archive
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

---

## 버전 히스토리 관리

### 현재 버전 상태

#### Android
```yaml
현재 버전: 1.0.10+34
다음 버전: 1.0.11+35 (마이너 업데이트)
다음 버전: 1.0.10+35 (버그 수정)
다음 버전: 2.0.0+35 (메이저 업데이트)
```

#### iOS
```yaml
현재 버전: 1.0.5+15
다음 버전: 1.0.6+16 (마이너 업데이트)
다음 버전: 1.0.5+16 (버그 수정)
다음 버전: 2.0.0+16 (메이저 업데이트)
```

### 버전 업데이트 시나리오

#### 시나리오 1: 버그 수정 (Patch)
```bash
# Android: 1.0.10+34 → 1.0.10+35
./scripts/build_android.sh 1.0.10 35

# iOS: 1.0.5+15 → 1.0.5+16
./scripts/build_ios.sh 1.0.5 16
```

#### 시나리오 2: 기능 추가 (Minor)
```bash
# Android: 1.0.10+34 → 1.0.11+35
./scripts/build_android.sh 1.0.11 35

# iOS: 1.0.5+15 → 1.0.6+16
./scripts/build_ios.sh 1.0.6 16
```

#### 시나리오 3: 메이저 업데이트 (Major)
```bash
# Android: 1.0.10+34 → 2.0.0+35
./scripts/build_android.sh 2.0.0 35

# iOS: 1.0.5+15 → 2.0.0+16
./scripts/build_ios.sh 2.0.0 16
```

#### 시나리오 4: Android만 업데이트
```bash
# Android만 버전업
./scripts/build_android.sh 1.0.11 35

# iOS는 그대로 유지
./scripts/build_ios.sh 1.0.5 15
```

#### 시나리오 5: iOS만 업데이트
```bash
# Android는 그대로 유지
./scripts/build_android.sh 1.0.10 34

# iOS만 버전업
./scripts/build_ios.sh 1.0.6 16
```

### 버전 추적 템플릿

`VERSION_HISTORY.md` 파일을 만들어 관리하는 것을 권장합니다:

```markdown
# 버전 히스토리

## Android

### v1.0.11+35 (2025-11-16)
- 기능: 반복 할 일 기능 추가
- 수정: 알림 시간 표시 버그 수정

### v1.0.10+34 (2025-11-15)
- 기능: 카테고리 관리 개선
- 수정: 로그인 에러 수정

## iOS

### v1.0.6+16 (2025-11-16)
- 기능: 반복 할 일 기능 추가
- 수정: 알림 권한 요청 개선

### v1.0.5+15 (2025-11-15)
- 최초 App Store 출시
```

---

## 트러블슈팅

### 1. 빌드 번호가 이전보다 작다는 오류

**오류 메시지**:
```
Error: The version code of the new build (34) must be greater than the version code of the previous build (34).
```

**원인**: Google Play / App Store는 빌드 번호가 항상 증가해야 함

**해결**:
```bash
# 빌드 번호를 1 증가시켜서 다시 빌드
./scripts/build_android.sh 1.0.10 35
```

### 2. pubspec.yaml이 변경되었다는 경고

**원인**: 빌드 스크립트가 pubspec.yaml을 백업하고 복원함

**해결**: 정상 동작이므로 무시하거나, Git에서 변경 취소:
```bash
git checkout pubspec.yaml
```

### 3. iOS CocoaPods 설치 실패

**오류**: `pod install` 실패

**해결**:
```bash
# CocoaPods 업데이트
sudo gem install cocoapods

# 캐시 삭제 후 재설치
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### 4. Android 서명 키 오류

**오류**: `Keystore file not found`

**원인**: `android/key.properties` 파일 누락

**해결**:
1. [GOOGLE_PLAY_RELEASE.md](GOOGLE_PLAY_RELEASE.md#2-업로드-키-생성) 참고
2. 업로드 키 생성
3. `android/key.properties` 파일 생성

### 5. 스크립트 실행 권한 오류

**오류**: `Permission denied: ./scripts/build_android.sh`

**해결**:
```bash
chmod +x scripts/*.sh
```

---

## 체크리스트

### 새 버전 릴리즈 전 확인사항

#### Android
- [ ] 빌드 번호가 이전보다 큰지 확인
- [ ] `android/key.properties` 파일 존재 확인
- [ ] AAB 파일 생성 확인
- [ ] APK로 실제 기기 테스트 완료
- [ ] ProGuard 난독화 동작 확인
- [ ] Google Play Console에 업로드 준비

#### iOS
- [ ] 빌드 번호가 이전보다 큰지 확인
- [ ] Apple Developer 계정 활성화 확인
- [ ] Xcode Signing 설정 완료
- [ ] 실제 기기에서 테스트 완료
- [ ] Archive 및 Upload 준비
- [ ] App Store Connect에 업로드 준비

#### 공통
- [ ] 버전 번호가 Semantic Versioning 준수
- [ ] RELEASE_NOTES.md 업데이트
- [ ] VERSION_HISTORY.md 업데이트 (선택)
- [ ] Git 커밋 및 태그 생성
- [ ] 스크린샷 및 스토어 설명 업데이트 (필요 시)

---

## 빠른 참조

### 일반적인 빌드 명령어

```bash
# Android 다음 버전 빌드
./scripts/build_android.sh 1.0.11 35

# iOS 다음 버전 빌드
./scripts/build_ios.sh 1.0.6 16

# 두 플랫폼 동시 빌드 (순차 실행)
./scripts/build_android.sh 1.0.11 35 && ./scripts/build_ios.sh 1.0.6 16
```

### 버전 번호 규칙

```yaml
버그 수정: 1.0.10 → 1.0.11 (patch +1)
기능 추가: 1.0.10 → 1.1.0 (minor +1, patch 0)
메이저 변경: 1.0.10 → 2.0.0 (major +1, minor 0, patch 0)
빌드 번호: 항상 +1 증가
```

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2025-11-16
**작성자**: Claude Code
