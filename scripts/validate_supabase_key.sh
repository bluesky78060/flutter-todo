#!/bin/bash

# Supabase Anon Key 검증 스크립트
# 사용법: ./scripts/validate_supabase_key.sh

set -e

echo "🔍 Supabase Anon Key 검증 중..."

# .env 파일에서 키 읽기
if [ ! -f ".env" ]; then
  echo "❌ .env 파일을 찾을 수 없습니다"
  exit 1
fi

SUPABASE_URL=$(grep "^SUPABASE_URL=" .env | cut -d'=' -f2)
ANON_KEY=$(grep "^SUPABASE_ANON_KEY=" .env | cut -d'=' -f2)

if [ -z "$SUPABASE_URL" ]; then
  echo "❌ SUPABASE_URL이 .env 파일에 없습니다"
  exit 1
fi

if [ -z "$ANON_KEY" ]; then
  echo "❌ SUPABASE_ANON_KEY가 .env 파일에 없습니다"
  exit 1
fi

echo "📍 Supabase URL: $SUPABASE_URL"
echo "🔑 Anon Key: ${ANON_KEY:0:50}..."

# Health endpoint 테스트
echo ""
echo "🏥 Health endpoint 테스트 중..."

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $ANON_KEY" \
  "$SUPABASE_URL/auth/v1/health")

if [ "$RESPONSE" = "200" ]; then
  echo "✅ Supabase Anon Key가 유효합니다!"
  echo ""

  # 추가 정보 가져오기
  echo "📊 Supabase 설정 정보:"
  curl -s -H "apikey: $ANON_KEY" \
    "$SUPABASE_URL/auth/v1/settings" | \
    python3 -m json.tool 2>/dev/null || echo "설정 정보를 가져올 수 없습니다"

  exit 0
else
  echo "❌ Supabase Anon Key가 유효하지 않습니다 (HTTP $RESPONSE)"
  echo ""
  echo "해결 방법:"
  echo "1. Supabase Dashboard에서 새 anon key 복사"
  echo "   https://supabase.com/dashboard/project/bulwfcsyqgsvmbadhlye/settings/api"
  echo "2. .env 파일의 SUPABASE_ANON_KEY 업데이트"
  echo "3. 이 스크립트 다시 실행"
  echo ""
  exit 1
fi