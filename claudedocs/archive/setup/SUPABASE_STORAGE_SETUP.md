# Supabase Storage Setup Guide

이 가이드는 Todo 앱에서 첨부파일 지원을 위한 Supabase Storage 버킷 설정 방법을 설명합니다.

## 1. Storage 버킷 생성

### Supabase Dashboard에서 수동 생성

1. **Supabase Dashboard 접속**
   - https://supabase.com/dashboard
   - 프로젝트 선택

2. **Storage 메뉴로 이동**
   - 왼쪽 메뉴에서 "Storage" 클릭
   - "Create a new bucket" 버튼 클릭

3. **버킷 설정**
   ```
   Name: todo-attachments
   Public: false (체크 해제)
   File size limit: 10485760 (10MB)
   Allowed MIME types: image/*, application/pdf, text/*, application/msword, application/vnd.openxmlformats-officedocument.*
   ```

4. **생성 완료**
   - "Create bucket" 버튼 클릭

## 2. Storage RLS Policies 설정

버킷 생성 후 "Policies" 탭에서 다음 정책들을 추가합니다.

### Policy 1: Users can upload their own files

```sql
Policy name: Users can upload their own files
Allowed operation: INSERT
Policy definition:

bucket_id = 'todo-attachments'
AND (storage.foldername(name))[1] = auth.uid()::text
```

### Policy 2: Users can view their own files

```sql
Policy name: Users can view their own files
Allowed operation: SELECT
Policy definition:

bucket_id = 'todo-attachments'
AND (storage.foldername(name))[1] = auth.uid()::text
```

### Policy 3: Users can update their own files

```sql
Policy name: Users can update their own files
Allowed operation: UPDATE
Policy definition:

bucket_id = 'todo-attachments'
AND (storage.foldername(name))[1] = auth.uid()::text
```

### Policy 4: Users can delete their own files

```sql
Policy name: Users can delete their own files
Allowed operation: DELETE
Policy definition:

bucket_id = 'todo-attachments'
AND (storage.foldername(name))[1] = auth.uid()::text
```

## 3. 파일 경로 구조

파일은 다음과 같은 구조로 저장됩니다:

```
todo-attachments/
└── {user_id}/
    └── {todo_id}/
        ├── image1.jpg
        ├── document.pdf
        └── file.txt
```

예시:
```
todo-attachments/
└── 550e8400-e29b-41d4-a716-446655440000/
    └── 123/
        ├── screenshot.png
        └── notes.pdf
```

## 4. 마이그레이션 실행

데이터베이스 마이그레이션을 실행하여 `attachments` 테이블을 생성합니다:

```bash
# Supabase CLI 사용 (로컬 개발)
supabase migration up

# 또는 Supabase Dashboard에서 SQL Editor로 실행
# supabase/migrations/20251125000000_add_attachments.sql 파일 내용 복사/실행
```

## 5. 검증

### Storage 버킷 확인

1. Supabase Dashboard → Storage
2. `todo-attachments` 버킷이 존재하는지 확인
3. "Policies" 탭에서 4개 정책이 모두 활성화되어 있는지 확인

### 테이블 확인

SQL Editor에서 다음 쿼리 실행:

```sql
-- attachments 테이블 존재 확인
SELECT * FROM attachments LIMIT 1;

-- 인덱스 확인
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'attachments';

-- RLS 정책 확인
SELECT * FROM pg_policies WHERE tablename = 'attachments';
```

## 6. 파일 업로드 테스트

Flutter 앱에서 첨부파일 업로드 기능 테스트:

1. Todo 생성/편집 화면에서 파일 선택
2. 이미지 또는 문서 파일 선택
3. Supabase Dashboard → Storage → todo-attachments에서 파일 확인
4. `{user_id}/{todo_id}/filename` 경로로 저장되었는지 확인

## 7. 용량 제한 및 보안

### 파일 크기 제한
- 최대 파일 크기: 10MB (10485760 bytes)
- 초과 시 업로드 실패

### 허용된 파일 형식
- 이미지: `image/*` (jpg, png, gif, svg, webp 등)
- PDF: `application/pdf`
- 텍스트: `text/*` (txt, csv 등)
- 문서: `application/msword`, `application/vnd.openxmlformats-officedocument.*` (doc, docx, xlsx, pptx 등)

### 보안 정책
- RLS로 사용자별 파일 격리
- 인증된 사용자만 접근 가능
- 다른 사용자의 파일 읽기/쓰기/삭제 불가

## 8. 문제 해결

### 업로드 실패: "Permission denied"
- RLS 정책이 올바르게 설정되었는지 확인
- 사용자 인증 상태 확인 (`auth.uid()` 값 존재 여부)

### 파일이 보이지 않음
- 파일 경로가 `{user_id}/{todo_id}/{filename}` 형식인지 확인
- Storage RLS SELECT 정책이 활성화되어 있는지 확인

### 파일 크기 초과
- 10MB 이하 파일만 업로드 가능
- 이미지 압축 또는 파일 분할 고려

## 참고 자료

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Supabase Storage RLS](https://supabase.com/docs/guides/storage/security/access-control)
- [Flutter Supabase Storage](https://supabase.com/docs/reference/dart/storage-from-upload)
