#!/bin/bash

# iOS 빌드 스크립트
# 사용법: ./scripts/build_ios.sh <build-number> [version]
# 예: ./scripts/build_ios.sh 16 1.0.6
#
# build-number 는 필수다. 기본값(1.0.5+15)을 두었더니 낡아서, 인자 없이 실행하면
# App Store Connect 가 거부할 빌드가 만들어졌다. 어떤 숫자를 넣어 두어도 같은 일이
# 반복되므로 부를 때마다 받는다.
#
# 넣을 값: App Store Connect 에서 최신 빌드 번호를 확인하고 그보다 큰 수.
# (Play Console 이 아니다 — iOS 는 별도 번호 체계를 쓴다.)

set -e  # 오류 발생 시 스크립트 중단

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
    echo -e "${YELLOW}사용법:${NC} ./scripts/build_ios.sh <build-number> [version]"
    echo -e "${YELLOW}예:${NC}     ./scripts/build_ios.sh 16 1.0.6"
    echo
    echo -e "App Store Connect 에서 최신 빌드 번호를 확인하고 그보다 큰 수를 넣으십시오."
    exit 1
fi
if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ build-number 는 숫자여야 합니다: '${BUILD_NUMBER}'${NC}"
    exit 1
fi

# version: 생략하면 pubspec.yaml 의 현재 값을 쓴다. 하드코딩하면 낡는다.
VERSION=${2:-$(grep -m1 '^version:' pubspec.yaml | sed 's/^version: *//; s/+.*//')}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   iOS Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}버전:${NC} ${VERSION}"
echo -e "${GREEN}빌드 번호:${NC} ${BUILD_NUMBER}"
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

# CocoaPods 설치
echo -e "${YELLOW}📥 CocoaPods 설치 중...${NC}"
cd ios
pod install
cd ..

# Build iOS
echo -e "${YELLOW}🔨 iOS Release 빌드 중...${NC}"
flutter build ios \
    --release \
    --build-name=${VERSION} \
    --build-number=${BUILD_NUMBER} \
    --no-codesign

# pubspec.yaml 복원
echo -e "${YELLOW}♻️  pubspec.yaml 복원 중...${NC}"
mv pubspec.yaml.backup pubspec.yaml

# 완료 메시지
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅ iOS 빌드 완료!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}버전:${NC} ${VERSION}+${BUILD_NUMBER}"

echo -e "\n${YELLOW}📱 다음 단계:${NC}"
echo -e "1. Xcode에서 ${BLUE}ios/Runner.xcworkspace${NC} 열기"
echo -e "2. ${BLUE}Product → Archive${NC} 선택"
echo -e "3. Organizer에서 ${BLUE}Distribute App${NC} 클릭"
echo -e "4. App Store Connect에 업로드"

echo -e "\n${YELLOW}또는 Xcode 명령줄로:${NC}"
echo -e "  ${BLUE}xcodebuild archive ...${NC}"
echo -e "  ${BLUE}xcodebuild -exportArchive ...${NC}"

echo -e "\n${GREEN}🎉 빌드가 성공적으로 완료되었습니다!${NC}"
