# Supabase Anon Key 재설정 가이드

## 문제 상황
- OAuth 로그인 시 401 Unauthorized 에러 발생
- Health check 실패: 기존 Anon Key가 무효화됨

## 해결 방법

### 1. Supabase Dashboard에서 유효한 키 확인

1. **Supabase Dashboard 접속**:
   - URL: https://supabase.com/dashboard/project/bulwfcsyqgsvmbadhlye
   - 로그인 후 프로젝트 선택

2. **API 설정으로 이동**:
   - 왼쪽 메뉴: **Settings** (톱니바퀴 아이콘)
   - **API** 섹션 클릭

3. **Anon Key 복사**:
   ```
   Project API keys 섹션에서:

   anon public (공개 키):
   eyJhbGciOi... [COPY THIS]

   ⚠️ 주의: service_role key는 절대 사용하지 마세요!
   ```

### 2. 로컬 환경 업데이트

```bash
# .env 파일 수정
nano /Users/leechanhee/todo_app/.env

# SUPABASE_ANON_KEY 값을 새 키로 교체
SUPABASE_ANON_KEY=eyJhbGciOi... [새로 복사한 키]

# 저장 후 환경변수 주입
./scripts/inject_env.sh

# 로컬 테스트
curl -H "apikey: <새_키>" \
  https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/health

# 결과: HTTP 200 OK가 나와야 함
```

### 3. GitHub Secret 업데이트

1. **GitHub 저장소 접속**:
   - https://github.com/bluesky78060/flutter-todo

2. **Settings → Secrets and variables → Actions**

3. **APP_SUPABASE_ANON_KEY 업데이트**:
   - 기존 Secret 클릭
   - **Update** 버튼
   - 값 삭제 후 새 키 붙여넣기
   - **Update secret** 클릭

### 4. 재배포

```bash
# GitHub Actions 수동 재실행
# Repository → Actions → 최신 workflow → Re-run all jobs

# 또는 더미 커밋으로 강제 재배포
git commit --allow-empty -m "chore: Update Supabase anon key"
git push origin main
```

### 5. 검증

배포 완료 후 (2-3분):

```javascript
// 브라우저 콘솔 (F12)에서 실행
fetch('https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/health', {
  headers: { 'apikey': window.ENV.SUPABASE_ANON_KEY }
}).then(r => console.log('Status:', r.status));

// 예상 결과: Status: 200
```

---

## 추가 확인 사항

### OAuth Redirect URL 화이트리스트

**Supabase Dashboard → Authentication → URL Configuration**:

**Redirect URLs에 추가**:
```
https://bluesky78060.github.io/flutter-todo/#/oauth-callback
```

**Site URL**:
```
https://bluesky78060.github.io/flutter-todo/
```

### OAuth Provider 활성화 확인

**Authentication → Providers**:
- ✅ Google: Enabled, Client ID 설정됨
- ✅ Kakao: Enabled, Client ID 설정됨

---

## 키 만료 방지

### 키 로테이션 알림 설정

Supabase는 기본적으로 키를 만료시키지 않지만, 다음 상황에서 무효화될 수 있습니다:

1. **수동 키 재생성** (Dashboard에서 Reset 버튼)
2. **프로젝트 일시 중지 후 재개**
3. **보안 사고 발생 시 자동 무효화**

### 검증 스크립트

```bash
# validate_supabase_key.sh
#!/bin/bash

ANON_KEY=$(grep SUPABASE_ANON_KEY .env | cut -d'=' -f2)

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $ANON_KEY" \
  https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/health)

if [ "$RESPONSE" = "200" ]; then
  echo "✅ Supabase Anon Key is valid"
  exit 0
else
  echo "❌ Supabase Anon Key is invalid (HTTP $RESPONSE)"
  exit 1
fi
```

---

## 트러블슈팅

### Q: 새 키를 설정했는데도 401 에러가 발생해요

A: 다음을 확인하세요:
1. GitHub Actions가 완전히 완료되었는지 (2-3분 소요)
2. 브라우저 캐시 완전 삭제 (Ctrl+Shift+Delete)
3. 시크릿 모드로 테스트
4. `window.ENV.SUPABASE_ANON_KEY` 값이 새 키와 일치하는지

### Q: Dashboard에서 키를 찾을 수 없어요

A:
1. 프로젝트가 일시 중지된 경우: **Restore** 버튼 클릭
2. Settings → API 페이지로 이동
3. "anon public" 라벨이 있는 키 사용

### Q: 로컬은 작동하는데 배포판만 실패해요

A: GitHub Secret 값과 로컬 .env 값이 다릅니다:
1. 로컬에서 작동하는 키를 복사
2. GitHub Secret을 그 키로 업데이트
3. 재배포

---

## 문서 링크

- [Supabase Auth API](https://supabase.com/docs/guides/auth)
- [OAuth with Flutter](https://supabase.com/docs/guides/auth/social-login)
- [API Keys Management](https://supabase.com/docs/guides/api#api-keys)