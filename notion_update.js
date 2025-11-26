#!/usr/bin/env node

/**
 * Notion Release Notes Updater
 * Updates the Release Notes page in Notion with latest version information
 */

const fs = require('fs');
const path = require('path');

// Latest version information
const releaseInfo = {
  version: "1.0.13",
  buildNumber: "39",
  releaseDate: "2025-11-25",
  status: "Google Play에 배포됨",
  package: "kr.bluesky.dodo",
  platforms: ["Android 6.0 (API 23) 이상", "iOS 11.0 이상", "Web"],
  features: [
    "드래그 앤 드롭 정렬 기능",
    "관리자 대시보드 (익명화된 통계)",
    "첨부파일 시스템 Phase 1"
  ],
  technicalFeatures: [
    "Position 필드 추가 (Drift + Supabase)",
    "관리자 권한 시스템",
    "5개 Supabase RPC 함수 (SECURITY DEFINER)"
  ]
};

console.log("🚀 Notion Release Notes 업데이트 준비 중...\n");
console.log(`📦 버전: ${releaseInfo.version}+${releaseInfo.buildNumber}`);
console.log(`📅 릴리즈 날짜: ${releaseInfo.releaseDate}`);
console.log(`✅ 상태: ${releaseInfo.status}\n`);

console.log("📝 생성된 마크다운 파일:");
console.log("  ✓ /Users/leechanhee/todo_app/NOTION_RELEASE_NOTES.md\n");

console.log("🔗 Notion에서 수동 업데이트 방법:");
console.log("  1. Notion에서 'Release Notes' 또는 'RELEASE_NOTES' 페이지 찾기");
console.log("  2. NOTION_RELEASE_NOTES.md 파일의 내용을 복사");
console.log("  3. Notion 페이지에 마크다운 콘텐츠 붙여넣기");
console.log("  4. 페이지 속성 업데이트:");
console.log(`     - Version: ${releaseInfo.version}+${releaseInfo.buildNumber}`);
console.log(`     - Release Date: ${releaseInfo.releaseDate}`);
console.log(`     - Status: ${releaseInfo.status}\n`);

console.log("💡 Notion API를 통한 자동 업데이트를 위해서는:");
console.log("  - NOTION_API_KEY 환경변수 설정 필요");
console.log("  - Release Notes 페이지 ID 필요\n");

console.log("✨ 준비 완료! NOTION_RELEASE_NOTES.md를 Notion에 복사해주세요.");
