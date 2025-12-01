# 📋 Notion API 통합 설정 완료 요약

## 🎯 설정 상태: ✅ 완료

모든 Notion API 통합 설정이 완료되었습니다. 다음 단계는 당신의 Notion 계정과 GitHub에서 실제 설정을 진행하면 됩니다.

---

## 📚 제공된 문서 가이드

당신의 선호도에 따라 3가지 가이드 중 선택하세요:

### 1️⃣ **빠른 체크리스트** (5분) ⏰
📄 **파일**: [NOTION_QUICK_CHECKLIST.md](./NOTION_QUICK_CHECKLIST.md)

**추천 대상**: 시간이 부족하거나 빠르게 시작하고 싶은 경우

**포함 내용**:
- 체크박스 형식 진행 추적
- Notion Integration 생성 (2분)
- 권한 설정 (2분)
- 페이지 ID 확인 (1분)
- 로컬 테스트 (1분)
- GitHub 자동화 (5분)

**특징**: 최소한의 설명, 빠른 실행

---

### 2️⃣ **상세 설정 가이드** (30분) 📖
📄 **파일**: [NOTION_API_SETUP.md](./NOTION_API_SETUP.md)

**추천 대상**: 각 단계를 자세히 이해하고 싶은 경우

**포함 내용**:
- Notion API Key 생성 상세 설명
- Release Notes 페이지 ID 찾기 (3가지 방법)
- 로컬 테스트 (3가지 방식)
- GitHub Secrets 설정
- GitHub Actions 자동화
- 문제 해결 (401, 404, 403, 권한 오류 등)
- 유용한 리소스 및 참고 링크

**특징**: 완벽한 단계별 설명, 문제 해결 가이드 포함

---

### 3️⃣ **시각적 권한 설정 가이드** (10분) 🎨
📄 **파일**: [NOTION_INTEGRATION_PERMISSION_GUIDE.md](./NOTION_INTEGRATION_PERMISSION_GUIDE.md)

**추천 대상**: UI가 어렵거나 화면 설명이 필요한 경우

**포함 내용**:
- ASCII 아트로 표현한 UI 요소
- Share 버튼 위치 설명
- Integration 탭 찾기
- 권한 체크박스 설명
- 문제 해결:
  - Integration 탭이 보이지 않음
  - "DoDo Release Notes Bot"이 목록에 없음
  - 권한 체크박스가 회색으로 표시됨

**특징**: 화면 중심의 설명, 시각적 이해

---

## 🛠️ 생성된 자동화 파일

### GitHub Actions 워크플로우
📄 **파일**: [.github/workflows/update-notion.yml](./.github/workflows/update-notion.yml)

**3가지 트리거 방식**:
1. **수동 실행** (Workflow Dispatch)
   - 버전과 릴리즈 날짜 직접 입력
   - GitHub Actions 탭에서 "Run workflow" 클릭

2. **자동 실행** (Push Trigger)
   - `RELEASE_NOTES.md` 또는 `NOTION_RELEASE_NOTES.md` 수정 시 자동 실행
   - `main` 브랜치에 푸시할 때만 작동

3. **릴리스 발행** (Release Trigger)
   - GitHub Release 생성 시 자동 실행

---

### 로컬 테스트 스크립트
📄 **파일**: [scripts/update-notion-local.sh](./scripts/update-notion-local.sh)

**3가지 사용 방법**:

#### 방법 1: 환경변수 설정
```bash
export NOTION_API_KEY="secret_xxxxx..."
export NOTION_PAGE_ID="a1b2c3d4e5f6..."
./scripts/update-notion-local.sh
```

#### 방법 2: 파라미터로 전달
```bash
./scripts/update-notion-local.sh "secret_xxxxx..." "a1b2c3d4e5f6..."
```

#### 방법 3: .env 파일 사용
```bash
cat > .env << EOF
NOTION_API_KEY=secret_xxxxx...
NOTION_PAGE_ID=a1b2c3d4e5f6...
EOF

source .env
./scripts/update-notion-local.sh
```

**특징**:
- 색상 출력으로 진행 상황 표시
- 자세한 에러 메시지 제공
- 성공 시 Notion 페이지 URL 표시
- Node.js와 axios 자동 설치

---

## 📋 설정 단계별 체크리스트

### Phase 1: Notion 설정 (5분)

- [ ] https://www.notion.so/my-integrations 방문
- [ ] "New integration" 클릭
- [ ] Integration 이름: `DoDo Release Notes Bot` 입력
- [ ] Workspace 선택
- [ ] Submit/생성 클릭
- [ ] API Key 복사 및 안전한 곳에 저장

### Phase 2: 권한 설정 (2분)

- [ ] Notion에서 Release Notes 페이지 열기
- [ ] 우상단 "Share" 버튼 클릭
- [ ] "Integration" 탭 선택
- [ ] "DoDo Release Notes Bot" 추가
- [ ] 3개 권한 모두 체크:
  - [ ] Read content
  - [ ] Update content
  - [ ] Create pages
- [ ] Save/저장 클릭

### Phase 3: 페이지 ID 확인 (1분)

- [ ] Release Notes 페이지 URL 확인
- [ ] URL에서 PAGE_ID 추출:
  ```
  https://www.notion.so/Release-Notes-[PAGE_ID]
  32자 문자열 추출
  ```

### Phase 4: 로컬 테스트 (2분)

- [ ] 환경변수 설정: `export NOTION_API_KEY="..."`
- [ ] 환경변수 설정: `export NOTION_PAGE_ID="..."`
- [ ] 스크립트 실행: `./scripts/update-notion-local.sh`
- [ ] 성공 메시지 확인
- [ ] Notion 페이지 업데이트 확인

### Phase 5: GitHub 자동화 (5분)

- [ ] GitHub Repository Settings 열기
- [ ] "Secrets and variables" → "Actions" 선택
- [ ] "New repository secret" → `NOTION_API_KEY` 추가
- [ ] "New repository secret" → `NOTION_PAGE_ID` 추가
- [ ] GitHub Actions 탭에서 워크플로우 확인

---

## 🚀 사용 방법

### 수동으로 로컬에서 테스트

```bash
# API Key와 Page ID 설정 후 실행
export NOTION_API_KEY="secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export NOTION_PAGE_ID="a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p"

./scripts/update-notion-local.sh
```

### GitHub Actions로 자동 업데이트

**방법 1: RELEASE_NOTES.md 수정**
```bash
# RELEASE_NOTES.md를 편집하고 커밋
git add RELEASE_NOTES.md
git commit -m "docs: Update release notes for v1.0.14"
git push origin main

# GitHub Actions가 자동으로 실행됨 ✨
# Notion 페이지가 자동으로 업데이트됨
```

**방법 2: 수동으로 워크플로우 실행**
1. GitHub 저장소의 "Actions" 탭 열기
2. "Update Notion Release Notes" 워크플로우 선택
3. "Run workflow" 클릭
4. 버전과 릴리즈 날짜 입력 (선택사항)
5. "Run workflow" 확인

---

## 🔍 문제 해결

### 401 Unauthorized
- **원인**: API Key가 잘못되었거나 만료됨
- **해결**: https://www.notion.so/my-integrations에서 새 토큰 생성
- **참고**: [NOTION_API_SETUP.md의 문제 해결 섹션](./NOTION_API_SETUP.md#-문제-해결)

### 404 Not Found
- **원인**: 페이지 ID가 잘못되었음
- **해결**: URL에서 페이지 ID 다시 확인 (32자, 하이픈 제거)
- **참고**: [NOTION_API_SETUP.md의 페이지 ID 찾기](./NOTION_API_SETUP.md#-release-notes-페이지-id-찾기)

### 403 Forbidden
- **원인**: Integration에 페이지 접근 권한이 없음
- **해결**: Notion 페이지 → Share → Integration에서 권한 추가
- **참고**: [NOTION_INTEGRATION_PERMISSION_GUIDE.md](./NOTION_INTEGRATION_PERMISSION_GUIDE.md)

### "Integration 탭이 보이지 않음"
- **해결**: [NOTION_INTEGRATION_PERMISSION_GUIDE.md의 문제 해결 섹션](./NOTION_INTEGRATION_PERMISSION_GUIDE.md#-문제-해결)

---

## 📁 파일 구조

```
프로젝트 루트/
├── NOTION_QUICK_CHECKLIST.md              ← 빠른 시작 (5분)
├── NOTION_API_SETUP.md                    ← 상세 가이드 (30분)
├── NOTION_INTEGRATION_PERMISSION_GUIDE.md ← 시각적 가이드 (10분)
├── NOTION_RELEASE_NOTES.md                ← Notion용 마크다운
├── NOTION_UPDATE_GUIDE.md                 ← 기본 가이드
├── NOTION_SETUP_SUMMARY.md                ← 이 파일 (개요)
├── scripts/
│   └── update-notion-local.sh             ← 로컬 테스트 스크립트
├── .github/workflows/
│   └── update-notion.yml                  ← GitHub Actions 워크플로우
└── RELEASE_NOTES.md                       ← 현재 릴리즈 노트
```

---

## ✅ 다음 단계

1. **가이드 선택**
   - 시간이 없으면: **NOTION_QUICK_CHECKLIST.md** 읽기
   - 자세히 배우고 싶으면: **NOTION_API_SETUP.md** 읽기
   - 화면이 필요하면: **NOTION_INTEGRATION_PERMISSION_GUIDE.md** 읽기

2. **실제 설정 진행**
   - Notion Integration 생성
   - Release Notes 페이지에 권한 추가
   - 페이지 ID 복사

3. **로컬 테스트**
   - 스크립트 실행하여 Notion 연결 확인

4. **GitHub 설정**
   - GitHub Secrets 추가 (NOTION_API_KEY, NOTION_PAGE_ID)
   - 이후 자동 업데이트 활성화

5. **완전 자동화**
   ```
   RELEASE_NOTES.md 수정 → git push → GitHub Actions 실행 → Notion 자동 업데이트 ✨
   ```

---

## 💡 팁

- **로컬 테스트를 먼저 하세요**: API Key와 Page ID가 올바른지 확인
- **GitHub Secrets는 안전합니다**: API Key는 로그에 표시되지 않음
- **버전 형식**: `1.0.13+39` (버전+빌드번호)
- **Notion 링크**: https://notion.so/[PAGE_ID] 형식으로 접속

---

## 📞 도움말

각 가이드 문서에 상세한 문제 해결 섹션이 포함되어 있습니다:

- **빠른 질문**: NOTION_QUICK_CHECKLIST.md 참조
- **기술적 문제**: NOTION_API_SETUP.md의 "문제 해결" 섹션
- **UI 문제**: NOTION_INTEGRATION_PERMISSION_GUIDE.md의 "문제 해결" 섹션

---

## 🎉 완료!

모든 준비가 완료되었습니다. 이제 당신의 Notion 계정과 GitHub에서 실제 설정을 시작하면 됩니다!

**성공 후 결과**:
```
git push → GitHub Actions 🚀 → Notion 자동 업데이트 ✨
```
