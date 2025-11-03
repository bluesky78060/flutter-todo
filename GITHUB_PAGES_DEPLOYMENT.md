# GitHub Pages 배포 가이드

이 프로젝트는 GitHub Actions를 통해 자동으로 GitHub Pages에 배포됩니다.

## 🚀 자동 배포 설정

### 1. GitHub Actions 워크플로우
`.github/workflows/deploy.yml` 파일이 자동 배포를 처리합니다.

**트리거:**
- `main` 브랜치에 push할 때 자동 실행
- GitHub에서 수동 실행 가능 (workflow_dispatch)

### 2. GitHub Pages 설정

GitHub 저장소에서 다음 단계를 수행하세요:

1. **Settings** → **Pages** 이동
2. **Source** 설정:
   - Source: **Deploy from a branch**
   - Branch: **gh-pages** / **root** 선택
   - Save 클릭

### 3. 배포 확인

- Actions 탭에서 배포 진행 상황 확인
- 5-10분 후 배포 완료
- **URL**: https://bluesky78060.github.io/flutter-todo/

## 📦 배포 프로세스

1. `main` 브랜치에 코드 push
2. GitHub Actions가 자동으로 실행
3. Flutter 환경 설정
4. `flutter build web --release` 실행
5. `build/web` 폴더를 `gh-pages` 브랜치에 배포
6. GitHub Pages가 자동으로 사이트 업데이트

## ⚙️ 워크플로우 세부사항

```yaml
- Flutter 버전: 3.24.0
- Base href: /flutter-todo/
- Build 명령어: flutter build web --release
- 배포 브랜치: gh-pages
```

## 🔄 수동 배포

GitHub 저장소에서:
1. **Actions** 탭 이동
2. **Deploy to GitHub Pages** 워크플로우 선택
3. **Run workflow** 클릭
4. **Run workflow** 버튼 클릭

## 📝 주의사항

- **무료**: GitHub Pages는 완전 무료입니다
- **용량**: 1GB 저장소 제한, 100GB/월 대역폭
- **빌드 시간**: 5-10분 소요
- **HTTPS**: 자동 제공됨

## 🎯 장점

✅ 완전 무료
✅ 자동 배포
✅ HTTPS 기본 제공
✅ GitHub 통합
✅ 무제한 배포 횟수

## 🆚 Netlify 대비 장점

| 항목 | GitHub Pages | Netlify |
|------|-------------|---------|
| 비용 | 완전 무료 | 크레딧 제한 |
| 배포 | 무제한 | 제한적 |
| 빌드 시간 | 무료 무제한 | 크레딧 소진 |
| 설정 | GitHub 통합 | 별도 계정 |

## 🐛 문제 해결

### 배포 실패 시
1. Actions 탭에서 에러 로그 확인
2. Flutter 버전 확인
3. 빌드 로그 검토

### 페이지 404 에러
1. GitHub Pages가 활성화되어 있는지 확인
2. `gh-pages` 브랜치가 존재하는지 확인
3. base-href 설정 확인 (`/flutter-todo/`)

### 느린 배포
- 첫 배포: 5-10분 소요 (정상)
- 이후 배포: 3-5분 소요

## 📞 지원

배포 관련 문제가 있으면 GitHub Issues에 문의하세요.
