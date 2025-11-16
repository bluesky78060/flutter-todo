# Flutter Todo App with Supabase

Supabase 백엔드를 사용하는 Flutter Todo 애플리케이션입니다.

## 주요 기능

- ✅ **사용자 인증**: Supabase Auth를 통한 회원가입/로그인
- ✅ **Todo 관리**: 생성, 읽기, 수정, 삭제 (CRUD)
- ✅ **클라우드 동기화**: Supabase 실시간 데이터베이스
- ✅ **다크 테마**: 현대적인 다크 모드 UI
- ✅ **테마 전환**: 라이트/다크 모드 토글
- ✅ **설정 화면**: 프로필, 테마, 앱 정보
- ✅ **다국어 지원**: 한국어/영어

## 기술 스택

- **Framework**: Flutter 3.x
- **상태 관리**: Riverpod 3.x
- **백엔드**: Supabase (BaaS)
- **로컬 DB**: Drift (SQLite)
- **라우팅**: Go Router
- **함수형 프로그래밍**: fpdart
- **국제화**: Easy Localization

## 로컬 개발 환경 설정

### 1. Flutter SDK 설치
```bash
# Flutter SDK가 설치되어 있는지 확인
flutter doctor
```

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. Supabase 설정
1. [Supabase](https://supabase.com)에서 프로젝트 생성
2. `.env.example`을 `.env`로 복사
3. Supabase 프로젝트의 URL과 anon key 입력:
```env
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 4. Supabase 데이터베이스 설정
Supabase SQL 에디터에서 다음 스크립트 실행:

```sql
-- todos 테이블 생성
CREATE TABLE IF NOT EXISTS todos (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Row Level Security 활성화
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성
CREATE POLICY "Users can view their own todos"
  ON todos FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own todos"
  ON todos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own todos"
  ON todos FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own todos"
  ON todos FOR DELETE
  USING (auth.uid() = user_id);
```

### 5. Supabase 이메일 인증 비활성화 (개발용)
Supabase Dashboard → Authentication → Providers → Email → "Confirm email" **OFF**

### 6. 앱 실행
```bash
# Chrome에서 실행
flutter run -d chrome

# Android/iOS 에뮬레이터에서 실행
flutter run
```


### 방법 2: GitHub 연동
1. GitHub 저장소에 코드 푸시
3. GitHub 저장소 선택
4. 자동 배포 시작

## 프로젝트 구조

```
lib/
├── core/                 # 핵심 설정 및 유틸리티
│   ├── config/          # Supabase 설정
│   ├── router/          # Go Router 설정
│   └── theme/           # 앱 테마 및 색상
├── data/                # 데이터 계층
│   ├── datasources/     # 로컬/원격 데이터 소스
│   └── repositories/    # Repository 구현
├── domain/              # 도메인 계층
│   ├── entities/        # 엔티티
│   └── repositories/    # Repository 인터페이스
└── presentation/        # 프레젠테이션 계층
    ├── providers/       # Riverpod 프로바이더
    ├── screens/         # 화면
    └── widgets/         # 재사용 가능한 위젯
```

## 주요 화면

- **로그인/회원가입**: Supabase Auth 통합
- **Todo 목록**: 진행률 표시, 필터링 (전체/진행중/완료)
- **설정**: 프로필, 테마 전환, 로그아웃, 앱 정보

## 문제 해결

### Supabase 400 Bad Request 에러
- Supabase Dashboard에서 이메일 인증 비활성화 확인
- `.env` 파일에 올바른 URL과 anon key 설정 확인

### Vercel 404 에러
- `vercel.json` 파일이 프로젝트 루트에 있는지 확인
- Vercel 대시보드에서 빌드 로그 확인
- `build/web` 디렉토리가 정상적으로 생성되는지 확인

## 라이선스

MIT License

## 기여

이슈 및 풀 리퀘스트를 환영합니다!
