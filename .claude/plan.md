# 데이터 내보내기 (CSV, PDF) 기능 구현 계획

## 목표
사용자가 모든 할 일 데이터를 CSV 또는 PDF 형식으로 내보내고, 파일을 공유할 수 있도록 하는 기능 구현

## 현황 분석

### 기존 백업 기능
- ✅ JSON 백업/복원 기능 (`backup_service.dart`)
- ✅ `BackupService` 클래스로 구현
- ✅ 필요한 의존성 이미 설치: `file_picker`, `share_plus`, `path_provider`
- ✅ Settings 화면에 통합

### 필요한 의존성
- ✅ `csv: ^6.0.0` - CSV 생성 (pubspec에 추가 필요)
- ✅ `pdf: ^3.10.0` - PDF 생성 (pubspec에 추가 필요)
- ✅ 나머지 의존성은 이미 설치됨

### 데이터 구조
- `Todo` 엔티티: title, description, isCompleted, dueDate, reminderTime, category 등
- `Category` 엔티티: name, color 등
- `BackupService`에서 todos와 categories를 이미 수집 중

## 구현 전략

### Phase 1: 의존성 추가 (15분)
- [ ] pubspec.yaml에 csv와 pdf 패키지 추가
- [ ] `flutter pub get` 실행

### Phase 2: ExportService 확장 (2-3시간)
새 파일: `lib/core/services/export_service.dart`
- [ ] `ExportService` 클래스 생성
- [ ] CSV 내보내기 메서드
  - Todo 데이터 + Category 정보
  - UTF-8 인코딩 (한글 지원)
  - 헤더: ID, 제목, 설명, 상태, 마감일, 카테고리, 생성일
- [ ] PDF 내보내기 메서드
  - 스타일링 적용 (폰트, 색상, 테이블)
  - 카테고리별 그룹화
  - 요약 정보 추가 (총 개수, 완료율 등)
  - 다국어 지원

### Phase 3: UI 컴포넌트 (1-2시간)
수정: `lib/presentation/screens/settings_screen.dart`
- [ ] 내보내기 옵션 섹션 추가
- [ ] CSV/PDF 선택 다이얼로그
- [ ] 로딩 인디케이터
- [ ] 성공/실패 메시지

### Phase 4: 프로바이더 (30분)
새 파일: `lib/presentation/providers/export_provider.dart`
- [ ] `exportTodosAsCSV` 프로바이더
- [ ] `exportTodosAsPDF` 프로바이더
- [ ] 에러 처리

### Phase 5: 다국화 (30분)
수정: `assets/translations/ko.json`, `en.json`
- [ ] 내보내기 관련 텍스트 추가
  - "내보내기", "Export"
  - "CSV로 내보내기", "Export as CSV"
  - "PDF로 내보내기", "Export as PDF"
  - "내보내기 완료", "Export completed"
  - 등등

### Phase 6: 테스트 및 최적화 (1-2시간)
- [ ] 로컬 테스트 (물리 기기)
- [ ] 한글 데이터 검증
- [ ] 대용량 데이터 성능 테스트
- [ ] Release APK 빌드

### Phase 7: 문서 및 커밋 (30분)
- [ ] FUTURE_TASKS.md 업데이트
- [ ] Git 커밋
- [ ] Release Notes 작성

## 기술적 고려사항

### CSV 포맷
```
ID,제목,설명,상태,마감일,카테고리,생성일
1,장보기,우유 사러 가기,미완료,2025-12-10,쇼핑,2025-12-01
2,회의,팀 미팅,완료,2025-12-02,업무,2025-12-01
```

### PDF 레이아웃
- 헤더: 앱 로고, 타이틀, 내보내기 날짜
- 요약: 총 todos 개수, 완료된 개수, 완료율
- 테이블: 모든 todos를 카테고리별로 표시
- 푸터: 페이지 번호, 내보내기 시간

### 멀티 플랫폼 지원
- Android: `/storage/emulated/0/Download` 또는 `getExternalStorageDirectory()`
- iOS: `getApplicationDocumentsDirectory()`
- Web: 브라우저 다운로드

### 권한 처리
- Android: `Permission.storage`
- iOS: 기본 제공 (Documents 폴더)
- Web: 브라우저 기본 동작

## 파일 구조
```
lib/
├── core/services/
│   └── export_service.dart          (NEW: CSV/PDF 내보내기 로직)
└── presentation/
    ├── providers/
    │   └── export_provider.dart      (NEW: 상태 관리)
    └── screens/
        └── settings_screen.dart      (수정: UI 추가)
```

## 예상 작업 시간
- 총 소요 시간: **5-7시간**
- 최종 버전: **1.0.15+47**

## 이슈 및 위험요소
1. 대용량 데이터 처리 시 메모리 문제
   - 해결: 1000개 todo 이상일 경우 페이지 분할
2. 한글 폰트 지원
   - 해결: pdf 패키지의 다국어 폰트 지원 확인
3. 파일 경로 권한
   - 해결: 기존 BackupService 패턴 재사용

## 성공 기준
- ✅ CSV 파일이 정상적으로 생성되고 Excel에서 열림
- ✅ PDF 파일이 정상적으로 생성되고 뷰어에서 열림
- ✅ 한글 데이터가 제대로 표시됨
- ✅ 파일 공유 기능 작동
- ✅ Release APK 빌드 성공 (< 65MB)
- ✅ 물리 기기에서 정상 작동 테스트 완료
