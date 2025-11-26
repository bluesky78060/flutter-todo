# 📚 Notion 릴리즈 노트 업데이트 가이드

## 📋 개요

로컬 `RELEASE_NOTES.md` 파일이 Notion과 동기화되도록 업데이트했습니다.

## 🚀 최신 정보

| 항목 | 내용 |
|------|------|
| **현재 버전** | 1.0.13+39 |
| **릴리즈 날짜** | 2025년 11월 25일 |
| **상태** | ✅ Google Play에 배포됨 |
| **플랫폼** | Android 6.0+, iOS 11.0+, Web |

## 📝 업데이트할 내용

### v1.0.13+39 주요 기능
1. **드래그 앤 드롭 정렬 기능**
   - Todo 항목을 드래그로 순서 변경 가능
   - 카테고리별 독립적인 정렬 지원

2. **관리자 대시보드 (익명화된 통계)**
   - 사용자, Todo, 카테고리 통계
   - 시간대별 활동 분석
   - 요일별 완료율 분석

3. **첨부파일 시스템 Phase 1**
   - Supabase Storage 버킷 생성
   - 파일 업로드/다운로드 기능
   - 이미지/PDF/텍스트 파일 뷰어

### 기술 개선사항
- Position 필드 추가 (Drift + Supabase)
- Supabase RPC 함수 5개 (SECURITY DEFINER)
- 128개 테스트 통과 (CI/CD)

## 🔗 Notion 업데이트 방법

### 방법 1: 마크다운 복사 (권장)

1. **파일 열기**
   ```bash
   cat /Users/leechanhee/todo_app/NOTION_RELEASE_NOTES.md
   ```

2. **전체 내용 복사**
   - 위 파일의 전체 내용을 복사합니다

3. **Notion에서 업데이트**
   - Notion에서 "Release Notes" 페이지 열기
   - `Edit` 모드로 전환
   - 기존 콘텐츠 삭제
   - 복사한 마크다운 붙여넣기

4. **페이지 속성 업데이트**
   - Version: `1.0.13+39`
   - Release Date: `November 25, 2025`
   - Status: `배포됨 (Google Play)`
   - Platform: `Android, iOS, Web`

### 방법 2: Notion MCP 사용 (자동화)

Notion MCP가 이미 설치되어 있습니다.

**필수 조건:**
- NOTION_API_KEY 환경변수 설정
- Release Notes 페이지 ID 알아야 함

**명령어:**
```bash
# Notion 페이지 검색
mcp__notion__search "Release Notes"

# 페이지 블록 업데이트
mcp__notion__patch_block_children \
  --block_id "YOUR_PAGE_ID" \
  --children "[...]"
```

### 방법 3: GitHub Actions (향후)

자동 배포 후 Notion 업데이트를 위해:
1. GitHub Secrets에 `NOTION_API_KEY` 추가
2. CI/CD 파이프라인에 Notion 업데이트 단계 추가
3. Release 태그 생성 시 자동으로 Notion 업데이트

## 📁 생성된 파일

```
/Users/leechanhee/todo_app/
├── RELEASE_NOTES.md                 # 로컬 마스터 문서 (이미 업데이트됨)
├── NOTION_RELEASE_NOTES.md          # Notion용 마크다운 (새로 생성)
├── NOTION_UPDATE_GUIDE.md           # 이 파일
└── notion_update.js                 # 자동화 스크립트
```

## ✅ 체크리스트

- [x] RELEASE_NOTES.md 로컬 업데이트 완료
- [x] NOTION_RELEASE_NOTES.md 생성 완료
- [x] 최신 버전 정보 반영 (1.0.13+39)
- [x] 모든 기능 설명 추가
- [x] 기술 스택 정보 포함
- [ ] Notion 페이지 수동 업데이트 필요
- [ ] (선택) NOTION_API_KEY 설정 및 자동화

## 🔍 확인 사항

### RELEASE_NOTES.md 확인
```bash
head -10 /Users/leechanhee/todo_app/RELEASE_NOTES.md
```

### NOTION_RELEASE_NOTES.md 확인
```bash
head -10 /Users/leechanhee/todo_app/NOTION_RELEASE_NOTES.md
```

## 💡 추가 정보

### 로컬 파일 동기화
- RELEASE_NOTES.md와 Notion은 수동으로 동기화됩니다
- 새 버전 릴리스 후 항상 두 곳 모두 업데이트하세요
- NOTION_RELEASE_NOTES.md를 템플릿으로 사용할 수 있습니다

### Notion API 설정 (선택사항)
```bash
# 환경변수 설정
export NOTION_API_KEY="your_notion_api_key"

# 테스트
npx @notionhq/notion-mcp-server
```

### 페이지 ID 찾는 방법
1. Notion에서 Release Notes 페이지 열기
2. URL에서 ID 추출: `https://notion.so/Release-Notes-[PAGE_ID]`
3. 또는 Notion 메뉴 → "Copy link as markdown" 사용

## 🎯 다음 단계

1. **지금**: NOTION_RELEASE_NOTES.md를 Notion에 복사/붙여넣기
2. **향후**: NOTION_API_KEY 설정 시 자동화 가능
3. **유지**: 새 버전 릴리스마다 양쪽 모두 업데이트

---

**마지막 업데이트**: 2025년 11월 26일
**작성자**: Claude Code
**상태**: ✅ 준비 완료
