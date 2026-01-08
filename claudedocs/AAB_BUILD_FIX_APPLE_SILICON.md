# Flutter AAB 빌드 오류 해결 - Apple Silicon Mac

## 개요

Flutter 3.32+ 버전에서 Apple Silicon (M1/M2/M3) Mac에서 Android App Bundle (AAB) 릴리스 빌드 시 발생하는 `strip debug symbols` 오류 해결 방법을 문서화합니다.

## 문제 발생일

2025-12-08

## 환경

- **OS**: macOS Darwin 25.1.0 (Apple Silicon)
- **Flutter**: 3.38.4 stable
- **NDK**: 27.0.12077973
- **패키지**: kr.bluesky.dodo

## 오류 메시지

```
Release app bundle failed to strip debug symbols from native libraries
```

또는

```
FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':app:stripReleaseDebugSymbols'.
```

## 근본 원인

Flutter 3.32+ 버전에서 발생하는 알려진 버그 (GitHub Issues #170004, #173682, #175118):

1. NDK 27.x의 `llvm-strip` 도구가 Apple Silicon (darwin-arm64) 아키텍처에서 제대로 작동하지 않음
2. Flutter의 내부 strip 프로세스가 darwin-arm64 바이너리를 처리하지 못함
3. 네이티브 라이브러리(.so 파일)에서 디버그 심볼을 제거하는 과정에서 실패

## 해결 방법

### 방법 1: flutter.stripDebugSymbols 비활성화 (권장)

`android/gradle.properties` 파일에 다음 설정 추가:

```properties
# Apple Silicon Mac에서 NDK strip 문제 해결
# NDK의 llvm-strip이 darwin-arm64에서 작동하지 않는 문제 우회
flutter.stripDebugSymbols=false
```

### 방법 2: NDK 25.1.x 다운그레이드 (대안)

NDK 25.1.x 버전에서는 이 문제가 발생하지 않습니다.

```bash
# Android SDK cmdline-tools 설치 확인
ls ~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager

# cmdline-tools가 없으면 설치
# https://developer.android.com/studio#command-tools 에서 다운로드

# NDK 25.1.8937393 설치
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "ndk;25.1.8937393"

# build.gradle.kts에서 NDK 버전 변경
# ndkVersion = "25.1.8937393"
```

**주의**: NDK 25.1.x 사용 시 플러그인 호환성 경고가 발생할 수 있으나 빌드는 성공합니다.

### 방법 3: ndk 블록 제거 (부분 해결)

`android/app/build.gradle.kts`에서 ndk 블록을 주석 처리:

```kotlin
buildTypes {
    release {
        // ...

        // 네이티브 디버그 심볼 비활성화 (Apple Silicon strip 문제)
        // ndk { debugSymbolLevel = "none" }
    }
}
```

## 적용된 설정

### android/gradle.properties

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true

# R8 최적화 설정
android.enableR8.fullMode=true

# Kotlin 언어 버전 설정 (Sentry 호환성을 위해 필요)
kotlin.languageVersion=1.9

# Apple Silicon Mac에서 NDK strip 문제 해결
# NDK의 llvm-strip이 darwin-arm64에서 작동하지 않는 문제 우회
flutter.stripDebugSymbols=false
```

### android/app/build.gradle.kts

```kotlin
android {
    namespace = "kr.bluesky.dodo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // ...

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }

            // 코드 최적화 활성화
            isMinifyEnabled = true
            // 리소스 최적화 활성화
            isShrinkResources = true

            // ProGuard 규칙 파일
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // 네이티브 디버그 심볼 비활성화 (Apple Silicon strip 문제)
            // Flutter 3.38에서 내부 strip 프로세스가 실패하므로 완전히 제거
            // ndk { debugSymbolLevel = "none" }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}
```

## 빌드 명령어

```bash
# AAB 빌드 (버전 지정)
flutter build appbundle --release --build-name=1.0.17 --build-number=55

# 빌드 결과물 위치
# build/app/outputs/bundle/release/app-release.aab
```

## 빌드 스크립트 사용

```bash
# 기본 빌드
./scripts/build_android.sh

# 커스텀 버전 빌드
./scripts/build_android.sh 1.0.17 55 release
```

## 설치된 NDK 버전 확인

```bash
ls -la ~/Library/Android/sdk/ndk/
# 25.1.8937393  (백업용)
# 27.0.12077973 (기본)
# 28.2.13676358 (최신)
```

## 참고 자료

- [Flutter GitHub Issue #170004](https://github.com/flutter/flutter/issues/170004)
- [Flutter GitHub Issue #173682](https://github.com/flutter/flutter/issues/173682)
- [Flutter GitHub Issue #175118](https://github.com/flutter/flutter/issues/175118)
- [Stack Overflow: Flutter strip debug symbols error](https://stackoverflow.com/questions/79505958/flutter-release-apk-build-strip-debug-symbols-error)

## 트러블슈팅

### 문제: 플러그인이 다른 NDK 버전을 요구함

```
Your project is configured with Android NDK 25.1.8937393, but the following plugin(s) depend on a different Android NDK version:
- app_links requires Android NDK 27.0.12077973
- battery_plus requires Android NDK 27.0.12077973
...
```

**해결**: NDK는 하위 호환성이 있으므로 경고를 무시해도 됩니다. 또는 `flutter.stripDebugSymbols=false` 설정을 사용하면 NDK 27.x를 유지하면서 문제를 해결할 수 있습니다.

### 문제: sdkmanager가 없음

```bash
# cmdline-tools 다운로드 및 설치
curl -O https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip commandlinetools-mac-11076708_latest.zip
mkdir -p ~/Library/Android/sdk/cmdline-tools/latest
mv cmdline-tools/* ~/Library/Android/sdk/cmdline-tools/latest/

# 라이선스 동의
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses
```

### 문제: 빌드 후 AAB 파일이 없음

```bash
# 빌드 디렉토리 확인
ls -la build/app/outputs/bundle/release/

# clean 후 재빌드
flutter clean
flutter pub get
flutter build appbundle --release
```

## 결론

Apple Silicon Mac에서 Flutter 3.32+ AAB 빌드 오류는 `flutter.stripDebugSymbols=false` 설정으로 간단히 해결됩니다. 이 설정은 디버그 심볼 제거 과정을 건너뛰지만, 릴리스 빌드의 기능이나 성능에는 영향을 주지 않습니다. Google Play Store 업로드에도 문제없이 사용할 수 있습니다.
