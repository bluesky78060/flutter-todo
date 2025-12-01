# 🔐 Notion API 설정 및 GitHub Actions 자동화 가이드

## 📋 목차
1. [Notion API Key 생성](#notion-api-key-생성)
2. [Release Notes 페이지 ID 찾기](#release-notes-페이지-id-찾기)
3. [로컬 테스트](#로컬-테스트)
4. [GitHub Secrets 설정](#github-secrets-설정)
5. [GitHub Actions 자동화](#github-actions-자동화)
6. [문제 해결](#문제-해결)

---

## 🚀 Notion API Key 생성

### Step 1: Notion Integration 만들기

1. **Notion 설정 페이지 방문**
   ```
   https://www.notion.so/my-integrations
   ```

2. **"New integration" 클릭**

3. **Integration 정보 입력**
   - **Name**: `DoDo Release Notes Bot` (또는 원하는 이름)
   - **Associated workspace**: 당신의 Notion workspace 선택
   - **User capabilities**: 기본값 유지

4. **로고 추가 (선택사항)**
   - Integration을 더 잘 식별할 수 있는 아이콘

5. **Submit 클릭**

### Step 2: API Key 복사

1. Integration이 생성되면 "Integration tokens" 섹션 표시
2. "Internal Integration Token" 복사
3. 안전한 곳에 저장 (나중에 필요)

```
노션_API_KEY_예시:
secret_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p
```

### Step 3: Release Notes 페이지에 권한 추가

1. Notion에서 "Release Notes" 페이지 열기
2. 우상단 **"Share"** 클릭
3. **"Integration"** 탭으로 이동
4. 만든 Integration 선택하여 추가
5. 권한 설정:
   - ✓ Read content
   - ✓ Update content
   - ✓ Create pages

> 📖 **더 자세한 가이드**
>
> 이 부분이 어렵다면 [NOTION_INTEGRATION_PERMISSION_GUIDE.md](./NOTION_INTEGRATION_PERMISSION_GUIDE.md) 를 참조하세요.
>
> 포함된 내용:
> - 📸 단계별 UI 화면 설명
> - 🎯 각 단계의 정확한 위치
> - 💡 문제 해결 (Integration이 보이지 않을 때 등)
> - ✅ 완료 확인 방법

---

## 📍 Release Notes 페이지 ID 찾기

### 방법 1: URL에서 추출 (가장 간단)

1. Notion에서 Release Notes 페이지 열기
2. 브라우저 주소창의 URL 확인:
   ```
   https://www.notion.so/[WORKSPACE_ID]/Release-Notes-[PAGE_ID]?v=[VERSION]
   ```

3. **PAGE_ID 추출**:
   - URL에서 `Release-Notes-` 다음의 32자 문자열
   - 예시: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p`

4. **올바른 형식 확인**:
   - 32자리 숫자 및 문자 (a-f, 0-9)
   - 하이픈 제거

### 방법 2: Notion에서 링크 복사

1. Release Notes 페이지 우상단 **"..."** 클릭
2. **"Copy link as markdown"** 선택
3. 복사된 텍스트에서 ID 추출:
   ```markdown
   [Release Notes](https://www.notion.so/a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p)
   ```

### 페이지 ID 검증

생성된 ID가 올바른지 확인:
```bash
# UUID 형식 (32자)
# 예: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p
```

---

## 💻 로컬 테스트

### 준비 조건
- Node.js 18+ 설치
- npm 또는 yarn 설치

### 방법 1: 환경변수 설정

```bash
# 터미널에서 환경변수 설정
export NOTION_API_KEY="your_api_key_here"
export NOTION_PAGE_ID="your_page_id_here"

# 스크립트 실행
./scripts/update-notion-local.sh
```

### 방법 2: 파라미터로 전달

```bash
./scripts/update-notion-local.sh "your_api_key_here" "your_page_id_here"
```

### 방법 3: .env 파일 사용

```bash
# 프로젝트 루트에서 .env 파일 생성
cat > .env << EOF
NOTION_API_KEY=your_api_key_here
NOTION_PAGE_ID=your_page_id_here
EOF

# 스크립트 실행
source .env
./scripts/update-notion-local.sh
```

### 성공 메시지 예시

```
✅ Local Notion Release Notes Updater

✅ NOTION_API_KEY 설정됨 (길이: 50)
✅ NOTION_PAGE_ID 설정됨: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p

📖 RELEASE_NOTES.md에서 정보 추출 중...
✅ 버전: 1.0.13+39
✅ 릴리즈 날짜: 2025년 11월 25일
✅ 상태: Google Play에 배포됨

✅ Node.js v18.20.0 설치됨
✅ axios 설치됨

🚀 Notion 페이지 업데이트 중...

   1️⃣  페이지 정보 조회 중...
      ✓ 페이지 ID: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p
      ✓ URL: https://notion.so/a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p

   2️⃣  페이지 속성 업데이트 중...
      ✓ 제목 업데이트 완료
      ✓ 새 제목: DoDo 릴리즈 노트 - 1.0.13+39

✅ Notion 페이지 업데이트 완료!
```

---

## 🔐 GitHub Secrets 설정

### Step 1: GitHub Repository Settings 접속

1. GitHub에서 저장소 열기
2. **Settings** 탭 클릭
3. **Secrets and variables** → **Actions** 선택

### Step 2: Secrets 추가

#### Secret 1: NOTION_API_KEY
```
Name:  NOTION_API_KEY
Value: secret_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p
```

#### Secret 2: NOTION_PAGE_ID
```
Name:  NOTION_PAGE_ID
Value: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p
```

### Step 3: 저장

1. 각 secret에 대해 **"Add secret"** 클릭
2. 두 개가 모두 표시되는지 확인

### Secrets 확인

Settings → Secrets and variables → Actions에서:
- ✓ NOTION_API_KEY (길이 확인 가능)
- ✓ NOTION_PAGE_ID (길이 확인 가능)

---

## ⚙️ GitHub Actions 자동화

### 워크플로우 파일 위치

```
.github/workflows/update-notion.yml
```

이미 생성되었으므로, GitHub에 푸시하면 자동으로 활성화됩니다.

### 트리거 조건

워크플로우는 다음 경우에 자동으로 실행됩니다:

1. **RELEASE_NOTES.md 파일 변경**
   - `main` 브랜치에 푸시할 때

2. **Release 발행**
   - GitHub Release 생성할 때

3. **수동 실행**
   - GitHub Actions 탭에서 "Run workflow" 클릭

### 수동 실행 방법

1. GitHub 저장소의 **"Actions"** 탭 열기
2. **"Update Notion Release Notes"** 워크플로우 선택
3. **"Run workflow"** 클릭
4. (선택) 버전과 릴리즈 날짜 입력
5. **"Run workflow"** 확인

### 자동 실행 예시

```bash
# RELEASE_NOTES.md를 수정하고 커밋
git add RELEASE_NOTES.md
git commit -m "docs: Update release notes for v1.0.14"
git push origin main

# GitHub Actions가 자동으로 실행됨
# Notion 페이지가 자동으로 업데이트됨
```

---

## 🔍 문제 해결

### 401 Unauthorized

**증상**: "Error: 401 - Unauthorized"

**원인**:
- API Key가 잘못됨
- API Key가 만료됨
- API Key가 설정되지 않음

**해결**:
```bash
# 1. API Key 확인
echo $NOTION_API_KEY

# 2. 새로운 API Key 생성
# https://www.notion.so/my-integrations

# 3. GitHub Secrets 업데이트
# Settings → Secrets and variables → Actions
```

### 404 Not Found

**증상**: "Error: 404 - Not Found"

**원인**:
- 페이지 ID가 잘못됨
- 페이지가 삭제됨
- 잘못된 페이지 ID 형식

**해결**:
```bash
# 1. 페이지 ID 확인
# https://www.notion.so/Release-Notes-[PAGE_ID]

# 2. URL에서 ID 추출 (하이픈 제거)
# 올바른 형식: 32자의 16진수 문자열

# 3. GitHub Secrets 업데이트
```

### 403 Forbidden

**증상**: "Error: 403 - Forbidden"

**원인**:
- Integration에 페이지 접근 권한이 없음
- Integration이 workspace에서 제거됨

**해결**:
```
1. Notion 페이지 열기
2. "Share" 클릭
3. "Integration" 탭에서 Integration 추가
4. 권한 확인:
   - ✓ Read content
   - ✓ Update content
   - ✓ Create pages
```

### 스크립트 실행 권한 오류

**증상**: "Permission denied: ./scripts/update-notion-local.sh"

**해결**:
```bash
chmod +x ./scripts/update-notion-local.sh
```

### Node.js 또는 npm 오류

**증상**: "command not found: node" 또는 "npm: not found"

**해결**:
```bash
# macOS
brew install node

# Ubuntu/Debian
sudo apt-get install nodejs npm

# Windows
# https://nodejs.org/ 방문하여 설치
```

### Notion API 레이트 제한

**증상**: "Too many requests"

**해결**:
- 스크립트를 너무 자주 실행하지 않기
- API 호출 간 최소 1초 지연 권장

---

## 📚 유용한 리소스

### Notion API 문서
- [Notion API 공식 문서](https://developers.notion.com/)
- [Notion API 레퍼런스](https://developers.notion.com/reference/intro)
- [Notion API 예제](https://github.com/makenotion/notion-sdk-js)

### GitHub Actions 문서
- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)
- [Secrets 관리](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [워크플로우 문법](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

### 관련 파일
- [NOTION_RELEASE_NOTES.md](./NOTION_RELEASE_NOTES.md) - Notion용 마크다운
- [NOTION_UPDATE_GUIDE.md](./NOTION_UPDATE_GUIDE.md) - 기본 가이드
- [.github/workflows/update-notion.yml](./.github/workflows/update-notion.yml) - GitHub Actions 워크플로우
- [scripts/update-notion-local.sh](./scripts/update-notion-local.sh) - 로컬 업데이트 스크립트

---

## ✅ 설정 체크리스트

- [ ] Notion API Key 생성
- [ ] Release Notes 페이지 ID 확인
- [ ] Integration에 페이지 권한 추가
- [ ] 로컬 테스트 성공
- [ ] GitHub Secrets 추가 (NOTION_API_KEY)
- [ ] GitHub Secrets 추가 (NOTION_PAGE_ID)
- [ ] 워크플로우 파일 푸시 (.github/workflows/update-notion.yml)
- [ ] GitHub Actions 테스트 실행
- [ ] Notion 페이지 업데이트 확인

---

## 💡 팁

### 빠른 테스트
```bash
# 환경변수 설정 후 바로 테스트
export NOTION_API_KEY="your_key"
export NOTION_PAGE_ID="your_id"
./scripts/update-notion-local.sh
```

### 디버깅
```bash
# 상세 로그 출력
DEBUG=* ./scripts/update-notion-local.sh

# API 요청 확인
curl -H "Authorization: Bearer YOUR_KEY" \
     -H "Notion-Version: 2024-06-15" \
     https://api.notion.com/v1/pages/YOUR_PAGE_ID
```

### 자동화 확장
GitHub Actions 워크플로우를 수정하여:
- 다른 이벤트 트리거 추가
- 이메일 알림 추가
- Slack 연동
- 커밋 메시지 포함

---

**최종 업데이트**: 2025년 11월 26일
**상태**: ✅ 준비 완료

모든 설정이 완료되었습니다! 🎉
