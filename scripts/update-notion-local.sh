#!/bin/bash

#############################################################################
# 📚 Local Notion Release Notes Updater
#
# Notion API를 사용하여 로컬에서 Release Notes 페이지를 업데이트합니다.
#
# 사용 방법:
#   ./scripts/update-notion-local.sh
#   ./scripts/update-notion-local.sh <API_KEY> <PAGE_ID>
#
# 환경변수로도 설정 가능:
#   export NOTION_API_KEY="your_token"
#   export NOTION_PAGE_ID="your_page_id"
#   ./scripts/update-notion-local.sh
#############################################################################

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수들
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         🚀 Local Notion Release Notes Updater                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. 프롤로그
print_header

# 2. API Key와 Page ID 확인
echo "🔐 Notion 자격증명 확인 중..."
echo ""

NOTION_API_KEY="${1:-$NOTION_API_KEY}"
NOTION_PAGE_ID="${2:-$NOTION_PAGE_ID}"

if [ -z "$NOTION_API_KEY" ]; then
    print_error "NOTION_API_KEY를 찾을 수 없습니다"
    echo ""
    echo "설정 방법:"
    echo "  1️⃣  환경변수로 설정:"
    echo "      export NOTION_API_KEY='your_api_key'"
    echo ""
    echo "  2️⃣  파라미터로 전달:"
    echo "      ./scripts/update-notion-local.sh 'your_api_key' 'your_page_id'"
    echo ""
    echo "  3️⃣  .env 파일로 설정:"
    echo "      NOTION_API_KEY=your_api_key"
    echo "      NOTION_PAGE_ID=your_page_id"
    echo ""
    exit 1
fi

if [ -z "$NOTION_PAGE_ID" ]; then
    print_error "NOTION_PAGE_ID를 찾을 수 없습니다"
    echo ""
    echo "설정 방법: 위의 NOTION_API_KEY 설정 방법과 동일합니다"
    exit 1
fi

print_success "NOTION_API_KEY 설정됨 (길이: ${#NOTION_API_KEY})"
print_success "NOTION_PAGE_ID 설정됨: $NOTION_PAGE_ID"
echo ""

# 3. RELEASE_NOTES.md에서 정보 추출
echo "📖 RELEASE_NOTES.md에서 정보 추출 중..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RELEASE_NOTES_FILE="$PROJECT_ROOT/RELEASE_NOTES.md"

if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    print_error "RELEASE_NOTES.md를 찾을 수 없습니다"
    echo "Expected path: $RELEASE_NOTES_FILE"
    exit 1
fi

# 정보 추출 (더 정확한 파싱)
VERSION=$(grep "## 최신 버전:" "$RELEASE_NOTES_FILE" | head -1 | sed 's/.*: //; s/ .*//' || echo "1.0.13+39")
RELEASE_DATE=$(grep "**최종 업데이트**:" "$RELEASE_NOTES_FILE" | head -1 | sed 's/.*: //' || echo "2025년 11월 25일")
STATUS=$(grep "**현재 상태**:" "$RELEASE_NOTES_FILE" | head -1 | sed 's/.*: //' || echo "Google Play에 배포됨")

print_success "버전: $VERSION"
print_success "릴리즈 날짜: $RELEASE_DATE"
print_success "상태: $STATUS"
echo ""

# 4. Node.js 확인
echo "🔍 Node.js 확인 중..."
if ! command -v node &> /dev/null; then
    print_warning "Node.js를 찾을 수 없습니다"
    echo "  설치 방법:"
    echo "    • macOS: brew install node"
    echo "    • Linux: sudo apt-get install nodejs npm"
    echo "    • Windows: https://nodejs.org/ 방문"
    exit 1
fi

NODE_VERSION=$(node --version)
print_success "Node.js $NODE_VERSION 설치됨"
echo ""

# 5. axios 확인 및 설치
echo "📦 axios 설치 확인 중..."
if ! npm list -g axios &> /dev/null 2>&1; then
    print_info "axios 설치 중..."
    npm install -g axios
fi
print_success "axios 설치됨"
echo ""

# 6. 업데이트 스크립트 생성 및 실행
echo "🚀 Notion 페이지 업데이트 중..."
echo ""

UPDATE_SCRIPT=$(mktemp)

cat > "$UPDATE_SCRIPT" << 'EOF'
const axios = require('axios');

const NOTION_API_KEY = process.argv[2];
const NOTION_PAGE_ID = process.argv[3];
const VERSION = process.argv[4];
const RELEASE_DATE = process.argv[5];
const STATUS = process.argv[6];

const apiClient = axios.create({
  baseURL: 'https://api.notion.com/v1',
  headers: {
    'Authorization': `Bearer ${NOTION_API_KEY}`,
    'Notion-Version': '2024-06-15'
  }
});

async function updatePage() {
  try {
    console.log('🔄 Notion 페이지 업데이트 중...\n');

    // 1. 페이지 정보 조회
    console.log('   1️⃣  페이지 정보 조회 중...');
    const pageResponse = await apiClient.get(`/pages/${NOTION_PAGE_ID}`);
    console.log('      ✓ 페이지 ID:', pageResponse.data.id);
    console.log('      ✓ URL: https://notion.so/' + pageResponse.data.id.replace(/-/g, ''));

    // 2. 페이지 속성 업데이트
    console.log('\n   2️⃣  페이지 속성 업데이트 중...');
    const updateResponse = await apiClient.patch(
      `/pages/${NOTION_PAGE_ID}`,
      {
        properties: {
          'title': [
            {
              'text': {
                'content': `DoDo 릴리즈 노트 - ${VERSION}`
              }
            }
          ]
        }
      }
    );

    console.log('      ✓ 제목 업데이트 완료');
    console.log(`      ✓ 새 제목: DoDo 릴리즈 노트 - ${VERSION}`);

    // 3. 블록 자식 조회
    console.log('\n   3️⃣  블록 자식 조회 중...');
    const blockResponse = await apiClient.get(
      `/blocks/${NOTION_PAGE_ID}/children?page_size=1`
    );
    console.log(`      ✓ 블록 개수: ${blockResponse.data.results.length} (첫 페이지)`);

    console.log('\n✅ Notion 페이지 업데이트 완료!\n');
    console.log('📊 업데이트 정보:');
    console.log(`   • 버전: ${VERSION}`);
    console.log(`   • 릴리즈 날짜: ${RELEASE_DATE}`);
    console.log(`   • 상태: ${STATUS}`);
    console.log(`   • 페이지 ID: ${NOTION_PAGE_ID}`);
    console.log('\n🔗 Notion에서 확인: https://notion.so/' + NOTION_PAGE_ID.replace(/-/g, ''));

  } catch (error) {
    console.error('\n❌ 오류 발생:\n');

    if (error.response) {
      console.error('HTTP Status:', error.response.status);

      if (error.response.status === 401) {
        console.error('문제: API Key가 올바르지 않거나 만료되었습니다');
        console.error('해결: https://www.notion.so/my-integrations에서 새 토큰 생성');
      } else if (error.response.status === 404) {
        console.error('문제: 페이지를 찾을 수 없습니다');
        console.error('해결: 페이지 ID가 올바른지 확인하세요');
      } else if (error.response.status === 403) {
        console.error('문제: Integration에 페이지 접근 권한이 없습니다');
        console.error('해결: Notion에서 페이지 → 공유 → Integration 추가');
      }

      console.error('\n응답 데이터:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('Error:', error.message);
    }

    process.exit(1);
  }
}

updatePage();
EOF

node "$UPDATE_SCRIPT" "$NOTION_API_KEY" "$NOTION_PAGE_ID" "$VERSION" "$RELEASE_DATE" "$STATUS"
RESULT=$?

rm -f "$UPDATE_SCRIPT"

if [ $RESULT -eq 0 ]; then
    echo ""
    print_success "모든 작업이 완료되었습니다!"
    echo ""
    echo "다음 단계:"
    echo "  1. Notion 페이지 열기"
    echo "  2. NOTION_RELEASE_NOTES.md 내용 확인"
    echo "  3. 필요시 수동으로 페이지 콘텐츠 업데이트"
    echo ""
else
    print_error "업데이트 중 오류가 발생했습니다"
    echo ""
    echo "문제 해결:"
    echo "  1. API Key와 Page ID가 올바른지 확인"
    echo "  2. Integration이 해당 페이지에 접근할 수 있는지 확인"
    echo "  3. NOTION_UPDATE_GUIDE.md를 참조하세요"
    echo ""
    exit 1
fi
