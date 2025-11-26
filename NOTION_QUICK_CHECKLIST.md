# ⚡ Notion API 설정 빠른 체크리스트

## 🎯 5분 안에 하기

### 1단계: Notion Integration 생성 (2분)

- [ ] https://www.notion.so/my-integrations 방문
- [ ] "New integration" 클릭
- [ ] Integration 이름 설정: `DoDo Release Notes Bot`
- [ ] Workspace 선택
- [ ] Submit/생성 클릭
- [ ] API Key 복사 (안전하게 저장)

```
복사한 API Key:
secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 2단계: Release Notes 페이지 권한 설정 (2분)

- [ ] Notion에서 Release Notes 페이지 열기
- [ ] 우상단 "Share" 버튼 클릭
- [ ] "Integration" 탭 클릭
- [ ] "+ Add Integration" 또는 "+ 추가" 클릭
- [ ] "DoDo Release Notes Bot" 선택
- [ ] 3개 권한 모두 체크:
  - [ ] Read content
  - [ ] Update content
  - [ ] Create pages
- [ ] Save/저장 클릭

### 3단계: Release Notes 페이지 ID 확인 (1분)

- [ ] Release Notes 페이지 URL 확인
- [ ] URL에서 ID 추출:
  ```
  https://www.notion.so/[WORKSPACE]/Release-Notes-[PAGE_ID]

  PAGE_ID 추출:
  a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p
  ```

```
확인한 PAGE_ID:
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p
```

---

## 🚀 로컬 테스트 (1분)

```bash
# 1. 환경변수 설정
export NOTION_API_KEY="secret_xxxxx"
export NOTION_PAGE_ID="a1b2c3d4xxxxx"

# 2. 스크립트 실행
./scripts/update-notion-local.sh

# 3. 성공 메시지 확인
✅ Notion 페이지 업데이트 완료!
```

---

## 🔐 GitHub 자동화 (5분)

### Step 1: GitHub Secrets 설정

- [ ] GitHub Repository 열기
- [ ] Settings 클릭
- [ ] "Secrets and variables" → "Actions" 선택
- [ ] "New repository secret" 클릭

**Secret 1: NOTION_API_KEY**
- [ ] Name: `NOTION_API_KEY`
- [ ] Value: `secret_xxxxx...` (위에서 복사)
- [ ] "Add secret" 클릭

**Secret 2: NOTION_PAGE_ID**
- [ ] Name: `NOTION_PAGE_ID`
- [ ] Value: `a1b2c3d4e5f6...` (위에서 확인)
- [ ] "Add secret" 클릭

### Step 2: 워크플로우 파일 푸시

```bash
# 파일이 이미 있으므로 푸시만 하면 됨
git add .github/workflows/update-notion.yml
git commit -m "ci: Add Notion auto-update workflow"
git push origin main
```

- [ ] 파일 푸시 완료
- [ ] GitHub Actions 탭에서 워크플로우 확인

---

## ✅ 확인 체크리스트

### Notion 설정 확인

- [ ] Integration 생성됨
- [ ] API Key 복사됨
- [ ] Release Notes 페이지에 권한 추가됨
- [ ] PAGE_ID 확인됨

### 로컬 테스트 확인

- [ ] `./scripts/update-notion-local.sh` 실행 완료
- [ ] 성공 메시지 출력됨
- [ ] Notion 페이지 제목 업데이트됨

### GitHub 자동화 확인

- [ ] NOTION_API_KEY Secret 추가됨
- [ ] NOTION_PAGE_ID Secret 추가됨
- [ ] 워크플로우 파일 푸시됨
- [ ] GitHub Actions 탭에 워크플로우 표시됨

---

## 🎯 다음은?

### 기본 설정 완료 후

1. **RELEASE_NOTES.md 업데이트**
   ```bash
   # 새 버전 정보 추가
   git add RELEASE_NOTES.md
   git commit -m "docs: Update release notes for v1.0.14"
   git push origin main
   ```
   → GitHub Actions 자동 실행!

2. **Notion 페이지 확인**
   - Notion에서 Release Notes 페이지 열기
   - 제목이 업데이트되었는지 확인
   - 시간을 기록해두세요 (자동화 증거)

3. **다음 버전 릴리스 시 반복**
   - RELEASE_NOTES.md 수정
   - git push
   - Notion 자동 업데이트 ✨

---

## 🆘 빠른 문제 해결

### Integration이 보이지 않음
→ [NOTION_INTEGRATION_PERMISSION_GUIDE.md](./NOTION_INTEGRATION_PERMISSION_GUIDE.md) 참조

### 로컬 스크립트 실행 실패
→ [NOTION_API_SETUP.md](./NOTION_API_SETUP.md) - "문제 해결" 섹션 참조

### GitHub Actions 실패
→ GitHub Actions 탭에서 로그 확인
→ [NOTION_API_SETUP.md](./NOTION_API_SETUP.md) - "문제 해결" 섹션 참조

---

## 📊 설정 상태 체크

```
Notion 설정:       ████░░░░░░  (Step 1-3)
로컬 테스트:       ░░░░░░░░░░  (테스트 대기 중)
GitHub 설정:       ░░░░░░░░░░  (Secret 대기 중)
자동화 테스트:     ░░░░░░░░░░  (배포 대기 중)

진행률: 30% (설정 완료)
```

---

## 💡 팁

**빨리 완료하려면:**
1. 이 체크리스트 순서대로 진행
2. 각 단계마다 체크박스 클릭
3. 막히는 부분은 해당 가이드 문서 참조

**로컬 테스트가 성공하면:**
- API Key와 Page ID가 올바름
- GitHub도 같은 값으로 설정하면 됨

**GitHub Actions가 실패하면:**
- 로그 확인: GitHub Actions 탭 → 해당 워크플로우
- 대부분 권한 문제

---

## 📱 스마트폰에서도 가능

**Notion Integration 설정:**
- [ ] Notion 앱 열기
- [ ] Release Notes 페이지 열기
- [ ] 공유 버튼 → Integration 탭
- (웹과 동일한 과정)

**GitHub Secrets:**
- [ ] GitHub 앱 열기
- [ ] Settings → Secrets
- (웹과 동일한 과정)

---

**최종 목표:**
```
git push → GitHub Actions 실행 → Notion 자동 업데이트 ✨
```

이 체크리스트로 완료하면 완전 자동화! 🎉
