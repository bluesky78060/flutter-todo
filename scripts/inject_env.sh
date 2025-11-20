#!/bin/bash

# Script to inject environment variables into web/index.html from .env file
# This should be run before flutter build web or flutter run -d chrome

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Injecting environment variables into web/index.html${NC}"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Error: .env file not found!${NC}"
    echo -e "${YELLOW}💡 Please create .env file from .env.example:${NC}"
    echo -e "   cp .env.example .env"
    echo -e "   # Then edit .env with your API keys"
    exit 1
fi

# Check if template exists
if [ ! -f "web/index.template.html" ]; then
    echo -e "${RED}❌ Error: web/index.template.html not found!${NC}"
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check if required variables are set
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo -e "${RED}❌ Error: GOOGLE_MAPS_API_KEY not set in .env${NC}"
    exit 1
fi

if [ -z "$NAVER_MAPS_CLIENT_ID" ]; then
    echo -e "${RED}❌ Error: NAVER_MAPS_CLIENT_ID not set in .env${NC}"
    exit 1
fi

# Replace placeholders in template
echo -e "${YELLOW}📝 Replacing placeholders...${NC}"
sed -e "s|{{GOOGLE_MAPS_API_KEY}}|${GOOGLE_MAPS_API_KEY}|g" \
    -e "s|{{NAVER_MAPS_CLIENT_ID}}|${NAVER_MAPS_CLIENT_ID}|g" \
    web/index.template.html > web/index.html

echo -e "${GREEN}✅ Environment variables injected successfully!${NC}"
echo -e "${YELLOW}⚠️  Remember: web/index.html is generated and should not be committed${NC}"
