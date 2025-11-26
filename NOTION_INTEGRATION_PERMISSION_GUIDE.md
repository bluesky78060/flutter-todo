# 🔐 Notion Integration 권한 설정 상세 가이드

## 📸 단계별 시각 가이드

### Step 1️⃣: Release Notes 페이지 열기

```
1. Notion 워크스페이스 열기
   ↓
2. 왼쪽 사이드바에서 "Release Notes" 페이지 찾기
   ↓
3. 페이지 클릭하여 열기
```

**예시:**
```
Notion 메인 화면
├── 🏠 Home
├── 📚 Database
├── 📄 Release Notes  ← 이 페이지를 클릭
└── 🔧 Settings
```

---

### Step 2️⃣: Share 버튼 클릭

Release Notes 페이지를 열었을 때:

```
┌─────────────────────────────────────────┐
│ Release Notes                      🔍 ⊙ │  ← 페이지 제목 영역
├─────────────────────────────────────────┤
│                                         │
│ [Share]  [Favorite]  [...]             │  ← Share 버튼 여기!
│                                         │
│ 페이지 콘텐츠...                        │
│                                         │
└─────────────────────────────────────────┘
```

**Share 버튼 위치:**
- 페이지 우상단
- 파란색 또는 회색 버튼
- 텍스트: "Share" 또는 공유 아이콘

---

### Step 3️⃣: Integration 탭 찾기

Share 버튼을 클릭하면 팝업 메뉴가 나타납니다:

```
┌─────────────────────────────────────────┐
│ Share                                   │
├─────────────────────────────────────────┤
│                                         │
│ [👤 People]  [🤖 Integration]  [🔗 Link]│
│    탭             탭              탭      │
│                                         │
│ 기본값: People 탭이 표시됨              │
│                                         │
│ "Integration" 탭을 클릭해야 함!        │
│                                         │
└─────────────────────────────────────────┘
```

**Integration 탭 찾기:**
- 여러 탭이 있는 경우: "People" / "Integration" / "Link" 중 선택
- "Integration" 탭 클릭
- 만약 Integration 탭이 보이지 않으면:
  - 스크롤해서 더 많은 탭 찾기
  - 또는 "..."를 클릭하면 더 많은 옵션 표시

---

### Step 4️⃣: Integration 추가

Integration 탭을 열었을 때:

```
┌─────────────────────────────────────────┐
│ Integration 탭                          │
├─────────────────────────────────────────┤
│                                         │
│ 현재 Integrations:                      │
│ (아무것도 없음 또는 이미 있는 것들)     │
│                                         │
│ [+ Add Integration]  또는               │
│ [+ 추가]                                │
│                                         │
└─────────────────────────────────────────┘
```

**버튼 클릭:**
1. "+ Add Integration" 또는 "+ 추가" 버튼 클릭
2. Integration 목록 표시됨

```
┌─────────────────────────────────────────┐
│ Select integration:                     │
├─────────────────────────────────────────┤
│                                         │
│ 만든 Integration 찾기:                  │
│                                         │
│ ☐ "DoDo Release Notes Bot"             │
│    (또는 당신이 만든 이름)              │
│                                         │
│ 이 Integration을 선택                   │
│                                         │
└─────────────────────────────────────────┘
```

**찾는 방법:**
- 목록에서 "DoDo Release Notes Bot" 찾기
- 또는 만든 Integration 이름으로 검색
- 찾으면 클릭하여 선택

---

### Step 5️⃣: 권한 설정

Integration을 선택하면 권한 체크박스 표시:

```
┌─────────────────────────────────────────┐
│ DoDo Release Notes Bot                  │
├─────────────────────────────────────────┤
│                                         │
│ Permissions:                            │
│                                         │
│ ☑ Read content         (읽기)          │
│ ☑ Update content       (쓰기)          │
│ ☑ Create pages         (페이지 생성)   │
│                                         │
│ [Save]  [Cancel]                        │
│                                         │
└─────────────────────────────────────────┘
```

**필요한 권한:**
- ✅ **Read content** (필수)
  - Integration이 페이지 내용을 읽을 수 있음

- ✅ **Update content** (필수)
  - Integration이 페이지를 수정할 수 있음
  - Release Notes 업데이트 시 필요

- ✅ **Create pages** (권장)
  - Integration이 새 페이지를 만들 수 있음
  - 향후 자동화를 위해 권장

**모두 체크하기:**
```
기본값:  □ Read content
        □ Update content
        □ Create pages

변경:    ☑ Read content
        ☑ Update content
        ☑ Create pages

[Save] 클릭!
```

---

## 🎯 전체 과정 요약

```
1️⃣ Release Notes 페이지 열기
   ↓
2️⃣ 우상단 [Share] 버튼 클릭
   ↓
3️⃣ "Integration" 탭 선택
   ↓
4️⃣ [+ Add Integration] 또는 [+ 추가] 클릭
   ↓
5️⃣ "DoDo Release Notes Bot" 선택
   ↓
6️⃣ 3개 권한 모두 체크 (☑)
   ↓
7️⃣ [Save] 클릭
   ↓
✅ 완료!
```

---

## 💡 문제 해결

### Integration 탭이 보이지 않음

**원인:** Integration 기능이 활성화되지 않음

**해결:**
```
1. 페이지 상단의 "..." 메뉴 클릭
2. "Share settings" 또는 "공유 설정" 찾기
3. Integration 옵션 활성화
```

### "DoDo Release Notes Bot"이 목록에 없음

**원인:** Integration이 아직 생성되지 않음

**해결:**
```
1. https://www.notion.so/my-integrations 방문
2. Integration이 생성되었는지 확인
3. 생성되지 않았으면: "New integration" 클릭하여 생성
4. 위 과정 다시 진행
```

### 권한 체크박스가 회색으로 표시됨 (비활성)

**원인:** 이미 해당 권한이 있거나 권한 제한됨

**해결:**
```
• 회색 권한은 이미 활성화됨
• 필요한 권한이 모두 체크되어 있으면 OK
• 체크되지 않은 것을 클릭하여 활성화 시도
```

---

## ✅ 완료 확인

권한 설정이 완료되면:

```
Integration 탭에 표시됨:
├── DoDo Release Notes Bot
│   ├── ✓ Read content
│   ├── ✓ Update content
│   └── ✓ Create pages
│
└── [권한 조정] 또는 [Remove]
```

이렇게 표시되면 성공! 🎉

---

## 🔍 Notion UI 변경 대비

**참고:** Notion의 UI는 자주 변경될 수 있습니다.

만약 위의 설명과 다르면:

**기본 원리 (변하지 않음):**
1. 페이지 공유 설정 찾기 (Share/공유)
2. People/사람 탭이 아닌 Integration/봇/앱 탭 찾기
3. Integration 추가하기
4. 권한 확인 및 활성화
5. 저장

이 기본 원리에 따라 진행하면 대부분 작동합니다.

---

## 📚 추가 팁

### Integration 권한 확인하기
```
현재 상황 확인:
1. Release Notes 페이지의 Share → Integration 탭
2. "DoDo Release Notes Bot" 옆의 권한 아이콘 확인
3. 필요한 권한이 모두 ✓ 표시되어 있는지 확인
```

### 여러 페이지에 권한 추가하기
```
같은 Integration을 여러 페이지에 추가:
1. 각 페이지에서 위의 과정 반복
2. 같은 Integration 선택
3. 권한 설정
4. 저장

이렇게 하면 하나의 Integration으로 여러 페이지 관리 가능!
```

### Integration 제거하기
```
만약 제거해야 하면:
1. Release Notes 페이지의 Share → Integration 탭
2. "DoDo Release Notes Bot" 옆의 [×] 또는 [Remove] 클릭
3. 확인

주의: 이후 API 호출이 이 페이지에서 실패합니다!
```

---

## 🎓 Notion Integration 개념

**Integration이 하는 일:**
- API를 통해 Notion과 외부 도구를 연결
- 자동화 스크립트가 페이지를 수정할 수 있게 함
- 권한을 통해 보안 유지

**왜 권한이 필요한가:**
- **Read**: 페이지 내용을 봐야 함
- **Update**: 페이지를 수정해야 함
- **Create**: 새 페이지를 만들어야 함 (선택사항)

**보안:**
- 각 Integration마다 다른 권한 설정 가능
- 최소 필요한 권한만 부여 권장
- Integration이 다른 페이지는 건드릴 수 없음

---

**더 궁금하면:**
- 공식 Notion 가이드: https://developers.notion.com/
- Notion 커뮤니티: https://www.notion.so/help

이 가이드로도 안 되면 스크린샷을 찍어서 보여주세요! 📸
