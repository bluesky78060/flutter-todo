#!/bin/bash

# Android 빌드 스크립트
# 사용법: ./scripts/build_android.sh <build-number> [version] [build-type]
# 예: ./scripts/build_android.sh 69 1.0.17 release
#
# build-number 는 필수다. 기본값을 두지 않는 이유:
# 예전에는 1.0.10+34 가 기본값이었는데, Play Store 활성 빌드가 이미 +67 이라
# 인자 없이 실행하면 스토어가 거부할 AAB 가 만들어졌다. 어떤 숫자를 넣어 두어도
# 시간이 지나면 같은 상태가 된다. 빌드 번호는 저장소가 알 수 없는 값이므로
# 부를 때마다 받는다.
#
# 넣을 값: Play Console > 앱 번들 탐색기에서 최신 versionCode 를 확인하고 그보다 큰 수.

# set -e 제거: flutter build 경고가 스크립트를 중단시키는 문제 해결

# Flutter 경로 설정
export PATH="$PATH:/opt/homebrew/share/flutter/bin"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 인자 처리
# build-number: 필수. 위 주석 참고.
BUILD_NUMBER=$1
if [ -z "$BUILD_NUMBER" ]; then
    echo -e "${RED}❌ build-number 가 필요합니다.${NC}"
    echo -e "${YELLOW}사용법:${NC} ./scripts/build_android.sh <build-number> [version] [build-type]"
    echo -e "${YELLOW}예:${NC}     ./scripts/build_android.sh 69 1.0.17 release"
    echo
    echo -e "Play Console > 앱 번들 탐색기에서 최신 versionCode 를 확인하고 그보다 큰 수를 넣으십시오."
    exit 1
fi
if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ build-number 는 숫자여야 합니다: '${BUILD_NUMBER}'${NC}"
    exit 1
fi

# version: 생략하면 pubspec.yaml 의 현재 값을 쓴다. 하드코딩하면 낡는다.
VERSION=${2:-$(grep -m1 '^version:' pubspec.yaml | sed 's/^version: *//; s/+.*//')}
BUILD_TYPE=${3:-release}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Android Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}버전:${NC} ${VERSION}"
echo -e "${GREEN}빌드 번호:${NC} ${BUILD_NUMBER}"
echo -e "${GREEN}빌드 타입:${NC} ${BUILD_TYPE}"
echo -e "${BLUE}========================================${NC}\n"

# pubspec.yaml 백업
echo -e "${YELLOW}📦 pubspec.yaml 백업 중...${NC}"
cp pubspec.yaml pubspec.yaml.backup

# Clean
echo -e "${YELLOW}🧹 Clean 수행 중...${NC}"
flutter clean

# Pub get
echo -e "${YELLOW}📥 Dependencies 설치 중...${NC}"
flutter pub get

# Build
if [ "$BUILD_TYPE" = "release" ]; then
    echo -e "${YELLOW}🔨 Android Release 빌드 중...${NC}"

    # AAB (Google Play)
    echo -e "${BLUE}Building AAB (App Bundle)...${NC}"
    flutter build appbundle \
        --release \
        --build-name=${VERSION} \
        --build-number=${BUILD_NUMBER} || true

    # AAB 빌드 결과 확인
    if [ ! -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        echo -e "${RED}❌ AAB 빌드 실패${NC}"
        mv pubspec.yaml.backup pubspec.yaml 2>/dev/null
        exit 1
    fi

    # APK (직접 배포용)
    echo -e "${BLUE}Building APK...${NC}"
    flutter build apk \
        --release \
        --build-name=${VERSION} \
        --build-number=${BUILD_NUMBER} || true

    # APK 빌드 결과 확인
    if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo -e "${RED}❌ APK 빌드 실패${NC}"
        mv pubspec.yaml.backup pubspec.yaml 2>/dev/null
        exit 1
    fi

    # 빌드 파일 복사 (버전 번호 포함)
    echo -e "${YELLOW}📦 빌드 파일 복사 중...${NC}"

    AAB_SOURCE="build/app/outputs/bundle/release/app-release.aab"
    AAB_DEST="build/app/outputs/bundle/release/app-release-${VERSION}+${BUILD_NUMBER}.aab"

    APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
    APK_DEST="build/app/outputs/flutter-apk/app-release-${VERSION}+${BUILD_NUMBER}.apk"

    if [ -f "$AAB_SOURCE" ]; then
        cp "$AAB_SOURCE" "$AAB_DEST"
        echo -e "${GREEN}✅ AAB 복사 완료:${NC} ${AAB_DEST}"
    fi

    if [ -f "$APK_SOURCE" ]; then
        cp "$APK_SOURCE" "$APK_DEST"
        echo -e "${GREEN}✅ APK 복사 완료:${NC} ${APK_DEST}"
    fi

elif [ "$BUILD_TYPE" = "debug" ]; then
    echo -e "${YELLOW}🔨 Android Debug 빌드 중...${NC}"
    flutter build apk \
        --debug \
        --build-name=${VERSION} \
        --build-number=${BUILD_NUMBER}
else
    echo -e "${RED}❌ 오류: 유효하지 않은 빌드 타입 '${BUILD_TYPE}'${NC}"
    echo -e "${YELLOW}지원되는 타입: release, debug${NC}"
    exit 1
fi

# pubspec.yaml 복원
echo -e "${YELLOW}♻️  pubspec.yaml 복원 중...${NC}"
mv pubspec.yaml.backup pubspec.yaml

# 완료 메시지
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Android 빌드 완료!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}버전:${NC} ${VERSION}+${BUILD_NUMBER}"

if [ "$BUILD_TYPE" = "release" ]; then
    echo -e "\n${YELLOW}📁 빌드 결과물:${NC}"
    echo -e "  - AAB: ${AAB_DEST}"
    echo -e "  - APK: ${APK_DEST}"

    # 파일 크기 표시
    if [ -f "$AAB_DEST" ]; then
        AAB_SIZE=$(ls -lh "$AAB_DEST" | awk '{print $5}')
        echo -e "\n${BLUE}AAB 크기:${NC} ${AAB_SIZE}"
    fi

    if [ -f "$APK_DEST" ]; then
        APK_SIZE=$(ls -lh "$APK_DEST" | awk '{print $5}')
        echo -e "${BLUE}APK 크기:${NC} ${APK_SIZE}"
    fi
else
    echo -e "\n${YELLOW}📁 빌드 결과물:${NC}"
    echo -e "  - APK: build/app/outputs/flutter-apk/app-debug.apk"
fi

echo -e "\n${GREEN}🎉 빌드가 성공적으로 완료되었습니다!${NC}"
