# Flutter Todo App - 배포 가이드

## ⚠️ 중요: Vercel 배포 제한사항

**Vercel은 기본적으로 Flutter SDK를 제공하지 않습니다.**

따라서 다음 두 가지 방법 중 하나를 선택해야 합니다:

---

## 방법 1: GitHub Pages 배포 (추천) ✅

### 1단계: 로컬에서 빌드
```bash
flutter build web --release
```

### 2단계: `build/web` 디렉토리를 gh-pages 브랜치에 배포
```bash
# gh-pages 브랜치 생성
git checkout --orphan gh-pages

# 모든 파일 제거
git rm -rf .

# build/web 파일 복사
cp -r build/web/* .

# 커밋 및 푸시
git add .
git commit -m "Deploy Flutter web app"
git push -f origin gh-pages

# main 브랜치로 복귀
git checkout main
```

### 3단계: GitHub Pages 활성화
1. GitHub 저장소 → **Settings**
2. **Pages** 섹션
3. Source: **gh-pages** 브랜치 선택
4. **Save** 클릭

**배포 URL**: https://bluesky78060.github.io/flutter-todo

---

## 방법 2: Netlify 배포 (추천) ✅

### 옵션 A: Netlify CLI 사용
```bash
# Netlify CLI 설치
npm install -g netlify-cli

# 로컬 빌드
flutter build web --release

# Netlify에 배포
cd build/web
netlify deploy --prod
```

### 옵션 B: Netlify UI 사용
1. [Netlify](https://netlify.com) 접속 및 로그인
2. **Sites** → **Add new site** → **Deploy manually**
3. `build/web` 폴더를 드래그 앤 드롭
4. 배포 완료!

**Netlify 설정 (netlify.toml)**:
```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

## 방법 3: Firebase Hosting (추천) ✅

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Firebase 로그인
firebase login

# Firebase 프로젝트 초기화
firebase init hosting

# 빌드
flutter build web --release

# 배포
firebase deploy --only hosting
```

---

## ❌ Vercel 배포 (작동하지 않음)

**문제**: Vercel에 Flutter SDK가 없어서 빌드 실패

**에러**:
```
sh: line 1: flutter: command not found
Error: Command "flutter doctor" exited with 127
```

**해결 불가**: Vercel은 Flutter 빌드를 지원하지 않습니다.

---

## 🎯 권장 사항

| 플랫폼 | 난이도 | 속도 | 무료 | 추천 |
|--------|--------|------|------|------|
| **GitHub Pages** | ⭐⭐⭐ 쉬움 | 빠름 | ✅ | ⭐⭐⭐⭐⭐ |
| **Netlify** | ⭐⭐ 매우 쉬움 | 매우 빠름 | ✅ | ⭐⭐⭐⭐⭐ |
| **Firebase** | ⭐⭐⭐ 보통 | 빠름 | ✅ | ⭐⭐⭐⭐ |
| **Vercel** | ❌ 불가능 | - | - | ❌ |

**가장 간단한 방법**: **Netlify 수동 배포** (드래그 앤 드롭)

---

## 환경 변수 설정

배포 플랫폼에서 다음 환경 변수를 설정하세요:

- `SUPABASE_URL`: Supabase 프로젝트 URL
- `SUPABASE_ANON_KEY`: Supabase anon key

### Netlify에서 환경 변수 설정:
1. Site settings → Build & deploy → Environment
2. "Add variable" 클릭
3. 변수 추가 후 "Save"

### Firebase에서 환경 변수 설정:
```bash
firebase functions:config:set supabase.url="YOUR_URL"
firebase functions:config:set supabase.key="YOUR_KEY"
```

---

## 문제 해결

### SPA 라우팅 404 에러
모든 경로를 `index.html`로 리다이렉트하도록 설정:

**Netlify**: `_redirects` 파일 생성
```
/*    /index.html   200
```

**Firebase**: `firebase.json` 설정
```json
{
  "hosting": {
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

**GitHub Pages**: 자동으로 처리됨

---

## 결론

**Vercel 대신 GitHub Pages나 Netlify를 사용하세요!** 🚀

더 간단하고, 빠르며, Flutter 웹 앱에 최적화되어 있습니다.
