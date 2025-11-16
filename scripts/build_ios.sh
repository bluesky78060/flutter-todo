#!/bin/bash

# iOS 빌드 스크립트
# 사용법: ./scripts/build_ios.sh [version] [build-number]
# 예: ./scripts/build_ios.sh 1.0.5 15

set -e  # 오류 발생 시 스크립트 중단

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 기본값 설정
DEFAULT_VERSION="1.0.5"
DEFAULT_BUILD_NUMBER="15"

# 인자 처리
VERSION=${1:-$DEFAULT_VERSION}
BUILD_NUMBER=${2:-$DEFAULT_BUILD_NUMBER}

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
