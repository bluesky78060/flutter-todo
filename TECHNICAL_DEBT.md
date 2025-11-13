# 기술 부채 (Technical Debt) 문서

이 문서는 현재 코드베이스에 존재하는 기술 부채와 향후 개선이 필요한 사항들을 정리합니다.

## 🔴 Critical (치명적) - 즉시 해결 필요

### 1. ✅ AuthUser ID 타입 불일치 (해결 완료 - v1.0.7+19, v1.0.8+20)

**문제** (해결됨):
- `AuthUser.id`가 `int`로 정의되어 있음
- Supabase는 UUID (`String`) 사용
- 현재 모든 사용자가 `id: 0`으로 하드코딩됨

**해결 방안 (적용됨)**:
- ✅ **v1.0.7+19**: AuthUser에 `uuid` 필드 추가 (non-breaking)
  ```dart
  class AuthUser {
    @Deprecated('Use uuid instead')
    final int id;  // Legacy: hashCode of UUID
    final String uuid;  // Supabase UUID - primary identifier
    ...
  }
  ```
- ✅ **v1.0.7+19**: Supabase datasource에서 uuid 필드 populate
  ```dart
  return domain.AuthUser(
    id: user.id.hashCode,  // Legacy compatibility
    uuid: user.id,  // Primary: Supabase UUID
    email: user.email ?? '',
    ...
  );
  ```
- ✅ **v1.0.8+20**: 카테고리 생성 시 `currentUser.uuid` 사용
  ```dart
  // lib/presentation/screens/category_management_screen.dart:598
  await ref.read(categoryActionsProvider).createCategory(
    currentUser.uuid,  // ✅ Use Supabase UUID
    _nameController.text.trim(),
    ...
  );
  ```

**다음 단계** (향후 작업):
- [ ] Drift DB에 uuid 컬럼 추가 (migration)
- [ ] 모든 코드를 uuid 사용으로 전환
- [ ] id 필드 제거 (breaking change)

**상태**: ✅ 해결 완료 (Non-breaking migration 적용)
**적용 버전**: v1.0.7+19, v1.0.8+20
**해결 날짜**: 2024-11-12

---

## 🟡 High (높음) - 조만간 해결 필요

### 2. ✅ 카테고리 userId 동기화 문제 (해결 완료 - v1.0.8+20)

**문제** (해결됨):
- 카테고리의 `userId`가 로컬 DB에만 저장됨
- Supabase의 실제 `auth.uid()`와 일치하지 않음
- 현재 `userId = "0"` (String)으로 저장됨

**해결 방안 (적용됨)**:
- ✅ **v1.0.8+20**: 카테고리 생성 시 `currentUser.uuid` 사용
  ```dart
  // lib/presentation/screens/category_management_screen.dart:598
  await ref.read(categoryActionsProvider).createCategory(
    currentUser.uuid,  // ✅ Supabase UUID 사용
    _nameController.text.trim(),
    _selectedColor,
    _selectedIcon,
  );
  ```

**검증 완료**:
- ✅ `CategoryRepositoryImpl.createCategory()`는 이미 userId를 파라미터로 받음
- ✅ Drift DB의 Categories 테이블은 이미 `TextColumn userId`로 정의됨
- ✅ 새로 생성되는 모든 카테고리는 Supabase UUID 사용

**다음 단계** (선택사항):
- [ ] 기존 카테고리의 userId를 UUID로 마이그레이션 (데이터 정리)
- [ ] Supabase에 categories 테이블 추가 (현재는 로컬 DB만 사용)

**상태**: ✅ 해결 완료 (새 카테고리는 올바른 UUID 사용)
**적용 버전**: v1.0.8+20
**해결 날짜**: 2024-11-12

---

### 3. 테스트 커버리지 부족

**문제**:
- 단위 테스트가 거의 없음
- 통합 테스트 부재
- E2E 테스트 부재

**현재 상태**:
```bash
test/
└── widget_test.dart  # 기본 템플릿만 존재
```

**필요한 테스트**:
1. **서비스 레이어**:
   - `NotificationService` 권한 처리 테스트
   - `RecurringTodoService` 인스턴스 생성 로직 테스트
   - `BatteryOptimizationService` 플랫폼별 동작 테스트

2. **리포지토리 레이어**:
   - 로컬/원격 동기화 로직 테스트
   - 에러 핸들링 테스트
   - 충돌 해결 로직 테스트

3. **라우터**:
   - 인증 가드 리다이렉트 테스트
   - 딥링크 처리 테스트
   - OAuth 콜백 처리 테스트

4. **반복 Todo**:
   - 인스턴스 생성 로직 테스트
   - 재발 규칙 파싱 테스트
   - 중복 방지 테스트

**해결 방안**:
```bash
test/
├── unit/
│   ├── services/
│   │   ├── notification_service_test.dart
│   │   ├── recurring_todo_service_test.dart
│   │   └── battery_optimization_service_test.dart
│   ├── repositories/
│   │   ├── todo_repository_test.dart
│   │   └── category_repository_test.dart
│   └── utils/
│       └── recurrence_utils_test.dart
├── integration/
│   ├── auth_flow_test.dart
│   ├── todo_sync_test.dart
│   └── recurring_todo_test.dart
└── e2e/
    ├── user_journey_test.dart
    └── notification_flow_test.dart
```

**우선순위**: 🟡 High
**예상 작업 시간**: 2-3일 (전체 커버리지 40-50% 목표)
**리스크**: 낮음 (기능 추가, breaking change 없음)

---

## 🟢 Medium (중간) - 시간 날 때 개선

### 4. 반복 Todo 성능 최적화

**문제**:
- `RecurringTodoService.generateUpcomingInstances()` 메서드가 모든 반복 Todo를 매번 처리
- 인스턴스 중복 체크를 위해 전체 DB 쿼리

**위치**:
- `lib/core/services/recurring_todo_service.dart:52-150`

**영향**:
```dart
// 현재 로직
for (final recurringTodo in allRecurringTodos) {
  // 각 반복 Todo마다 인스턴스 생성 시도
  for (int i = 0; i < upcomingCount; i++) {
    // DB에서 기존 인스턴스 확인
    final exists = await _localRepo.getTodoById(instanceId);
    if (exists == null) {
      // 새 인스턴스 생성
    }
  }
}
```

**성능 이슈**:
- 반복 Todo 10개 × 인스턴스 5개 = 50번의 DB 쿼리
- 사용자가 많아질수록 성능 저하
- 앱 시작 시 지연 발생 가능

**해결 방안**:
1. **배치 쿼리 사용**:
   ```dart
   // 모든 instanceId를 미리 수집
   final instanceIds = [...];
   // 한 번에 조회
   final existingInstances = await _localRepo.getTodosByIds(instanceIds);
   ```

2. **메모리 캐싱**:
   ```dart
   // 생성된 인스턴스 ID를 메모리에 캐시
   final _generatedInstances = <int, DateTime>{};
   ```

3. **인덱스 최적화**:
   ```dart
   // Drift DB에 복합 인덱스 추가
   @TableIndex(name: 'idx_parent_scheduled', columns: {#parentRecurringTodoId, #scheduledDate})
   ```

**우선순위**: 🟢 Medium
**예상 작업 시간**: 3-4시간
**리스크**: 낮음 (내부 최적화)

---

### 5. 에러 핸들링 표준화

**문제**:
- 에러 처리 방식이 일관되지 않음
- 일부는 Exception, 일부는 String 메시지
- 사용자 친화적인 에러 메시지 부족

**예시**:
```dart
// 패턴 1: Exception throw
throw Exception('로그인이 필요합니다');

// 패턴 2: String 리턴
return '알림 권한이 필요합니다';

// 패턴 3: null 리턴
if (error) return null;

// 패턴 4: bool 리턴
if (error) return false;
```

**해결 방안**:
1. **Result 타입 도입**:
   ```dart
   sealed class Result<T> {
     const Result();
   }

   class Success<T> extends Result<T> {
     final T data;
     const Success(this.data);
   }

   class Failure<T> extends Result<T> {
     final AppError error;
     const Failure(this.error);
   }
   ```

2. **에러 타입 정의**:
   ```dart
   enum AppErrorType {
     network,
     authentication,
     permission,
     validation,
     unknown,
   }

   class AppError {
     final AppErrorType type;
     final String message;
     final String? userMessage;  // 사용자에게 표시할 메시지
     final dynamic originalError;

     const AppError({...});
   }
   ```

**우선순위**: 🟢 Medium
**예상 작업 시간**: 1-2일
**리스크**: 중간 (기존 코드 수정 필요)

---

## 🔵 Low (낮음) - Nice to Have

### 6. Dependency Injection 개선

**문제**:
- Riverpod Provider가 여러 파일에 분산
- 의존성 주입이 명시적이지 않음
- 테스트 시 Mock 객체 주입이 어려움

**현재 구조**:
```dart
// lib/presentation/providers/todo_providers.dart
// lib/presentation/providers/category_providers.dart
// lib/presentation/providers/auth_providers.dart
// lib/presentation/providers/database_provider.dart
```

**해결 방안**:
1. **Provider 계층 분리**:
   ```dart
   lib/core/di/
   ├── data_providers.dart      # Repository, DataSource
   ├── service_providers.dart   # Services
   └── presentation_providers.dart  # UI State
   ```

2. **Injectable 패키지 도입** (선택사항):
   ```dart
   @injectable
   class TodoRepository {
     final LocalDataSource local;
     final RemoteDataSource remote;

     @factoryMethod
     TodoRepository(this.local, this.remote);
   }
   ```

**우선순위**: 🔵 Low
**예상 작업 시간**: 4-6시간
**리스크**: 낮음 (리팩토링)

---

### 7. 코드 주석 및 문서화

**문제**:
- 복잡한 로직에 주석 부족
- API 문서 부재
- 아키텍처 설명 부족

**필요한 문서**:
1. **아키텍처 문서** (`ARCHITECTURE.md`)
2. **API 문서** (`API.md`)
3. **기여 가이드** (`CONTRIBUTING.md`)
4. **코드 주석** (복잡한 비즈니스 로직)

**우선순위**: 🔵 Low
**예상 작업 시간**: 1-2일
**리스크**: 없음

---

## 우선순위 요약

### ✅ 해결 완료
1. ✅ AuthUser ID 마이그레이션 (v1.0.7+19, v1.0.8+20)
2. ✅ 카테고리 userId 동기화 (v1.0.8+20)

### 중기 해결 (1-2개월 내)
3. 🟡 테스트 커버리지 확대
4. 🟢 반복 Todo 성능 최적화
5. 🟢 에러 핸들링 표준화

### 장기 개선 (시간 날 때)
6. 🔵 DI 개선
7. 🔵 문서화 보강

---

## 마이그레이션 전략

### Phase 1: AuthUser ID 마이그레이션 (권장)

**단계**:
1. `AuthUser`에 `uuid` 필드 추가 (non-breaking)
2. 기존 `id` 필드 유지 (deprecated로 표시)
3. 모든 새 코드는 `uuid` 사용
4. Drift DB 스키마에 `uuid` 컬럼 추가 (migration)
5. 기존 데이터 마이그레이션 (uuid 생성 또는 Supabase에서 가져오기)
6. 모든 코드를 `uuid` 사용으로 전환
7. `id` 필드 제거 (breaking change)

**코드 예시**:
```dart
// Step 1-2: uuid 필드 추가
class AuthUser {
  final int id;  // @deprecated Use uuid instead
  final String uuid;  // Supabase UUID
  final String email;
  ...
}

// Step 3-4: Drift 마이그레이션
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // uuid 컬럼 추가
        await m.addColumn(todos, todos.userUuid);
        await m.addColumn(categories, categories.userUuid);
      }
    },
  );
}

// Step 5: 데이터 마이그레이션
Future<void> migrateUserIds() async {
  final supabaseUuid = supabase.auth.currentUser?.id;
  if (supabaseUuid != null) {
    await db.update(todos).write(TodosCompanion(
      userUuid: Value(supabaseUuid),
    ));
  }
}
```

**예상 일정**: 1-2주
**리스크**: 중간 (데이터 손실 위험)

---

## 기술 스택 업그레이드 고려사항

### 현재 버전 vs 최신 버전

패키지 분석 결과 (pubspec.yaml 기준):
- Flutter SDK: ^3.9.2 (최신: 3.27.x)
- flutter_local_notifications: 18.0.1 (최신: 19.5.0)
- go_router: 14.8.1 (최신: 17.0.0)
- google_sign_in: 6.3.0 (최신: 7.2.0)

**권장 사항**:
- 메이저 버전 업그레이드는 기능 개발 완료 후
- 보안 패치는 즉시 적용
- breaking change 확인 후 업그레이드

---

## 참고 자료

- [Flutter Clean Architecture](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)
- [Supabase Auth Best Practices](https://supabase.com/docs/guides/auth/auth-best-practices)
- [Drift Database Migrations](https://drift.simonbinder.eu/docs/advanced-features/migrations/)
- [Riverpod Provider Architecture](https://riverpod.dev/docs/concepts/providers)

---

**최종 업데이트**: 2024-11-12
**작성자**: Claude Code (Technical Debt Analysis)

---

## 변경 이력

### 2024-11-12
- ✅ **v1.0.7+19**: AuthUser UUID 필드 추가 (non-breaking)
- ✅ **v1.0.7+19**: Supabase datasource UUID populate
- ✅ **v1.0.8+20**: 카테고리 생성 시 UUID 사용
- 🔴 Critical #1 해결 완료
- 🟡 High #2 해결 완료
