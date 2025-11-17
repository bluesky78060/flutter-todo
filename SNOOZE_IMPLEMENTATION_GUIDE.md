# 스누즈 기능 구현 가이드

## ✅ 완료된 작업 (2025-11-17)

### 1. 데이터 모델 업데이트
- **Todo Entity** (`lib/domain/entities/todo.dart`)
  - `snoozeCount`: 스누즈한 횟수
  - `lastSnoozeTime`: 마지막 스누즈 시간
  - `copyWith` 메서드에 새 필드 추가

### 2. 데이터베이스 스키마 업데이트
- **Drift (로컬 DB)** (`lib/data/datasources/local/app_database.dart`)
  - Schema version: 5 → 6
  - `snooze_count INTEGER DEFAULT 0`
  - `last_snooze_time TIMESTAMPTZ`
  - Migration 스크립트 추가 (from < 6)

- **Supabase (원격 DB)** (`supabase_snooze_migration.sql`)
  ```sql
  ALTER TABLE todos
  ADD COLUMN IF NOT EXISTS snooze_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_snooze_time TIMESTAMPTZ;
  ```

### 3. Repository 레이어 업데이트
- **TodoRepositoryImpl** (`lib/data/repositories/todo_repository_impl.dart`)
  - `updateTodo`: snoozeCount, lastSnoozeTime 포함
  - `_mapTodoToEntity`: 새 필드 매핑

- **SupabaseTodoDataSource** (`lib/data/datasources/remote/supabase_datasource.dart`)
  - `updateTodo`: snooze 필드 업데이트 로직
  - `_todoFromJson`: snooze 필드 파싱

### 4. 번역 파일 추가
- **한국어** (`assets/translations/ko.json`)
  - `snooze`: "다시 알림"
  - `snooze_for_5_min`: "5분 후"
  - `snooze_for_10_min`: "10분 후"
  - `snooze_for_30_min`: "30분 후"
  - `snooze_for_1_hour`: "1시간 후"
  - `snooze_for_3_hours`: "3시간 후"
  - `snooze_custom`: "직접 설정"
  - `snooze_scheduled`: "알림이 다시 설정되었습니다"

- **English** (`assets/translations/en.json`)
  - 동일한 키에 영어 번역 추가

### 5. UI 컴포넌트
- **SnoozeDialog** (`lib/presentation/widgets/snooze_dialog.dart`)
  - 5분, 10분, 30분, 1시간, 3시간 옵션
  - 사용자 정의 시간 선택 (DatePicker + TimePicker)
  - Duration 반환

### 6. 알림 서비스
- **NotificationService** (`lib/core/services/notification_service.dart`)
  - `snoozeNotification()` 메서드 추가
  - 기존 알림 취소 → 새 시간에 재스케줄링
  - 로깅 추가

## 🚧 남은 작업

### 1. UI 통합
#### Todo 상세 화면에 스누즈 버튼 추가
```dart
// lib/presentation/screens/todo_detail_screen.dart

// Notification info row 아래에 추가
if (todo.notificationTime != null) ...[
  const SizedBox(height: 12),
  ElevatedButton.icon(
    onPressed: () async {
      final snoozeDuration = await showDialog<Duration>(
        context: context,
        builder: (context) => SnoozeDialog(
          onDismiss: () {},
        ),
      );

      if (snoozeDuration != null) {
        // Update todo with snooze info
        final updatedTodo = todo.copyWith(
          snoozeCount: (todo.snoozeCount ?? 0) + 1,
          lastSnoozeTime: DateTime.now(),
          notificationTime: DateTime.now().add(snoozeDuration),
        );

        // Update in database
        await ref.read(todoListProvider.notifier).updateTodo(updatedTodo);

        // Reschedule notification
        await NotificationService().snoozeNotification(
          id: todo.id,
          title: todo.title,
          body: todo.description,
          snoozeDuration: snoozeDuration,
        );

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('snooze_scheduled'.tr())),
          );
        }
      }
    },
    icon: const Icon(FluentIcons.snooze_24_regular),
    label: Text('snooze'.tr()),
  ),
],

// Snooze count 표시 (있을 경우)
if (todo.snoozeCount != null && todo.snoozeCount! > 0) ...[
  const SizedBox(height: 8),
  Text(
    'snooze_count'.tr(namedArgs: {'count': todo.snoozeCount.toString()}),
    style: const TextStyle(
      color: AppColors.textGray,
      fontSize: 14,
    ),
  ),
],
```

### 2. Provider 업데이트
```dart
// lib/presentation/providers/todo_providers.dart

// 스누즈 액션 추가
Future<void> snoozeTodo(int todoId, Duration snoozeDuration) async {
  final todo = await _getTodoById(todoId);
  if (todo == null) return;

  final updatedTodo = todo.copyWith(
    snoozeCount: (todo.snoozeCount ?? 0) + 1,
    lastSnoozeTime: DateTime.now(),
    notificationTime: DateTime.now().add(snoozeDuration),
  );

  await updateTodo(updatedTodo);

  // Reschedule notification
  await NotificationService().snoozeNotification(
    id: todoId,
    title: todo.title,
    body: todo.description,
    snoozeDuration: snoozeDuration,
  );
}
```

### 3. Supabase 마이그레이션 실행
1. Supabase Dashboard → SQL Editor 열기
2. `supabase_snooze_migration.sql` 내용 복사 & 실행
3. 테이블 스키마 확인

### 4. Drift 코드 생성
```bash
# Flutter 설치 위치 찾기
which flutter

# Build runner 실행 (Drift 코드 재생성)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. 테스트
- [ ] 스누즈 다이얼로그 표시 확인
- [ ] 5분 후 스누즈 테스트
- [ ] 사용자 정의 시간 스누즈 테스트
- [ ] 스누즈 횟수 카운트 확인
- [ ] 로컬/원격 DB 동기화 확인
- [ ] 알림 재스케줄링 검증

## 📁 수정된 파일 목록

```
lib/
├── domain/entities/todo.dart                        # Entity 필드 추가
├── data/
│   ├── datasources/
│   │   ├── local/app_database.dart                 # Schema v6, Migration
│   │   └── remote/supabase_datasource.dart         # Snooze 필드 매핑
│   └── repositories/
│       ├── todo_repository_impl.dart               # Snooze 필드 처리
│       └── supabase_todo_repository.dart           # (자동 적용)
├── core/services/notification_service.dart         # snoozeNotification()
└── presentation/widgets/snooze_dialog.dart         # NEW: UI 컴포넌트

assets/translations/
├── ko.json                                          # 한국어 번역
└── en.json                                          # 영어 번역

supabase_snooze_migration.sql                       # NEW: DB 마이그레이션
SNOOZE_IMPLEMENTATION_GUIDE.md                      # NEW: 이 파일
```

## 🎯 다음 단계

1. **Supabase 마이그레이션 실행** (최우선)
2. **Drift 코드 재생성** (flutter pub run build_runner build)
3. **Todo 상세 화면에 스누즈 버튼 통합**
4. **테스트 및 검증**
5. **FUTURE_TASKS.md 업데이트** (Section 1.2 완료 표시)

## 💡 참고 사항

- 스누즈는 notification_time을 업데이트하는 방식으로 동작
- 스누즈 횟수는 통계/분석에 활용 가능
- Web에서는 Web Notification API 사용
- Mobile에서는 FlutterLocalNotifications 사용

## 🔗 관련 문서

- [FUTURE_TASKS.md](FUTURE_TASKS.md) - Section 1.2
- [CLAUDE.md](CLAUDE.md) - Development Commands
- [README.md](README.md) - Project Overview
