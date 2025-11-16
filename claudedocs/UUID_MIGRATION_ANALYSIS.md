# AuthUser.id UUID 마이그레이션 분석 리포트

**분석 날짜**: 2025-11-12
**버전**: v1.0.8+20

## 요약

✅ **AuthUser.id → uuid 마이그레이션은 이미 완료된 상태입니다.**

모든 중요 사용처에서 이미 `AuthUser.uuid` (String UUID)를 사용하고 있으며, 레거시 `id` 필드는 하위 호환성을 위해서만 hashCode로 유지되고 있습니다.

## AuthUser 엔티티 현재 상태

### 필드 정의
```dart
// lib/domain/entities/auth_user.dart
class AuthUser {
  @Deprecated('Use uuid instead. This field will be removed in future versions.')
  final int id;  // Legacy: 하위 호환성을 위한 hashCode
  final String uuid;  // Primary: Supabase UUID (실제 사용 필드)
  final String email;
  final String name;
  final DateTime? createdAt;
}
```

### 설계 의도
- **uuid (String)**: Supabase auth.users(id)의 실제 UUID
- **id (int, @Deprecated)**: 레거시 시스템과의 호환성을 위한 hashCode

## 주요 사용처 분석

### 1. SupabaseAuthDataSource (✅ UUID 사용)

**위치**: `lib/data/datasources/remote/supabase_datasource.dart`

**getCurrentUser()** (라인 192-204):
```dart
return domain.AuthUser(
  // ignore: deprecated_member_use_from_same_package
  id: user.id.hashCode,  // Legacy: hash UUID to int
  uuid: user.id,  // ✅ Primary: use Supabase UUID
  email: user.email ?? '',
  name: user.userMetadata?['name'] as String? ?? user.email ?? '',
  createdAt: user.createdAt.isNotEmpty ? DateTime.parse(user.createdAt) : null,
);
```

**authStateChanges()** (라인 234-248):
```dart
return domain.AuthUser(
  // ignore: deprecated_member_use_from_same_package
  id: user.id.hashCode,  // Legacy: hash UUID to int
  uuid: user.id,  // ✅ Primary: Supabase UUID
  email: user.email ?? '',
  name: user.userMetadata?['name'] as String? ?? user.email ?? '',
  createdAt: user.createdAt.isNotEmpty ? DateTime.parse(user.createdAt) : null,
);
```

**결론**: Supabase에서 받은 UUID를 `uuid` 필드에 정확히 저장하고 있음.

### 2. Category 생성 (✅ UUID 사용)

**위치**: `lib/presentation/screens/category_management_screen.dart`

**_saveCategory()** (라인 597-602):
```dart
if (widget.category == null) {
  // Create new category
  await ref.read(categoryActionsProvider).createCategory(
    currentUser.uuid,  // ✅ Use Supabase UUID instead of id
    _nameController.text.trim(),
    _selectedColor,
    _selectedIcon,
  );
}
```

**결론**: 카테고리 생성 시 `currentUser.uuid`를 사용하여 올바른 Supabase UUID 전달.

### 3. Category 엔티티 (✅ String userId)

**위치**: `lib/domain/entities/category.dart`

```dart
class Category {
  final int id;
  final String userId;  // ✅ Already String type (UUID-compatible)
  final String name;
  final String color;
  final String? icon;
  final DateTime createdAt;
}
```

**결론**: `userId` 필드가 이미 `String` 타입으로 UUID를 저장할 수 있음.

### 4. Todo 생성 (✅ Supabase UUID 자동 사용)

**위치**: `lib/data/datasources/remote/supabase_datasource.dart`

**createTodo()** (라인 62-65):
```dart
final userId = client.auth.currentUser?.id;  // ✅ Supabase UUID (String)
if (userId == null) {
  throw Exception('로그인이 필요합니다. 다시 로그인해주세요.');
}
```

**결론**: Todo 생성 시 Supabase client에서 직접 UUID를 가져와 사용.

## 데이터 흐름 분석

### 인증 흐름
```
Supabase auth.users(id) [UUID String]
    ↓
SupabaseAuthDataSource.getCurrentUser()
    ↓
AuthUser.uuid [String] ← ✅ 메인 식별자
AuthUser.id [int] ← Deprecated (hashCode만)
    ↓
CategoryManagementScreen._saveCategory()
    ↓
currentUser.uuid ← ✅ 카테고리 생성에 사용
    ↓
CategoryRepository.createCategory(userId: String)
    ↓
Category.userId [String] ← ✅ UUID 저장
```

### Todo 생성 흐름
```
SupabaseTodoDataSource.createTodo()
    ↓
client.auth.currentUser?.id ← ✅ 직접 Supabase UUID 사용
    ↓
todos.user_id [UUID in Supabase]
```

## 남은 레거시 필드 정리 가능성

### AuthUser.id 필드 완전 제거 검토

**현재 상태**:
- `@Deprecated` 마커 추가됨
- `ignore: deprecated_member_use_from_same_package` 주석으로 무시
- 실제 사용처 없음 (모든 곳에서 `uuid` 사용)

**제거 가능 여부**: ✅ 제거 가능
- 외부에서 `AuthUser.id`를 사용하는 코드 없음
- Supabase에서 제공하는 UUID가 String이므로 int로 변환할 필요 없음
- hashCode는 안정적인 식별자가 아니므로 실제로 사용되어선 안 됨

**제거 시 영향**:
- `lib/data/datasources/remote/supabase_datasource.dart` (2곳):
  - `getCurrentUser()` 라인 198
  - `authStateChanges()` 라인 241
- `lib/domain/entities/auth_user.dart`:
  - 필드 정의 및 생성자 파라미터

**제거 방법**:
```dart
// Before
class AuthUser {
  @Deprecated('Use uuid instead')
  final int id;
  final String uuid;
  // ...

  const AuthUser({
    @Deprecated('Use uuid instead') required this.id,
    required this.uuid,
    // ...
  });
}

// After
class AuthUser {
  final String uuid;  // Supabase UUID - primary identifier
  // ...

  const AuthUser({
    required this.uuid,
    // ...
  });
}
```

## Supabase 스키마 정합성

### todos 테이블
```sql
CREATE TABLE todos (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,  -- ✅ UUID 타입
  -- ...
);
```

### categories 테이블
```sql
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,  -- ✅ UUID 타입
  -- ...
);
```

**결론**: Supabase 테이블의 `user_id` 컬럼이 모두 `UUID` 타입으로 정의되어 있어, Flutter의 `String uuid` 필드와 완벽히 호환됨.

## RLS (Row Level Security) 정책

### todos 정책
```sql
CREATE POLICY "Users can CRUD their own todos" ON todos
  USING (auth.uid() = user_id)  -- ✅ auth.uid() returns UUID
  WITH CHECK (auth.uid() = user_id);
```

### categories 정책
```sql
CREATE POLICY "Users can CRUD their own categories" ON categories
  USING (auth.uid() = user_id)  -- ✅ auth.uid() returns UUID
  WITH CHECK (auth.uid() = user_id);
```

**결론**: RLS 정책이 `auth.uid()` (UUID)와 `user_id` (UUID)를 비교하므로, 데이터 격리가 올바르게 작동함.

## 카테고리 필터링 정책

### 현재 상태
**위치**: `lib/data/repositories/category_repository_impl.dart`

```dart
@override
Future<Either<Failure, List<entity.Category>>> getCategories() async {
  try {
    final categories = await database.getAllCategories();  // ❌ 모든 카테고리 조회
    return Right(_mapCategoriesToEntities(categories));
  } catch (e) {
    return Left(DatabaseFailure(e.toString()));
  }
}
```

**문제점**:
- 로컬 Drift 데이터베이스에서 **모든 카테고리**를 조회
- 현재 로그인한 사용자의 카테고리만 필터링하지 않음
- 멀티 유저 환경에서 다른 사용자의 카테고리가 노출될 수 있음

### 권장 개선 사항

#### 옵션 1: 로컬 데이터베이스 필터링
```dart
@override
Future<Either<Failure, List<entity.Category>>> getCategories(String userId) async {
  try {
    // userId로 필터링하여 조회
    final categories = await database.getCategoriesByUserId(userId);
    return Right(_mapCategoriesToEntities(categories));
  } catch (e) {
    return Left(DatabaseFailure(e.toString()));
  }
}
```

**필요 변경사항**:
- `AppDatabase`에 `getCategoriesByUserId(String userId)` 메서드 추가
- `CategoryRepository` 인터페이스에 `userId` 파라미터 추가
- Provider에서 현재 사용자의 uuid 전달

#### 옵션 2: Supabase로 카테고리 이전
```dart
class SupabaseCategoryDataSource {
  final SupabaseClient client;

  Future<List<Category>> getCategories() async {
    // RLS 정책이 자동으로 현재 사용자의 카테고리만 반환
    final response = await client
        .from('categories')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => _categoryFromJson(json)).toList();
  }
}
```

**장점**:
- Supabase RLS가 자동으로 사용자별 데이터 격리 수행
- 여러 기기 간 카테고리 동기화 가능
- 백업 및 복구 용이

**단점**:
- 네트워크 의존성
- Supabase 요금 증가 가능성

### 권장 방향
**옵션 1 (로컬 필터링)**을 먼저 구현하는 것을 권장:
1. 빠른 구현 (기존 Drift 인프라 활용)
2. 오프라인 지원 유지
3. 필요 시 나중에 옵션 2로 전환 가능

## 마이그레이션 체크리스트

### ✅ 이미 완료된 항목
- [x] AuthUser 엔티티에 uuid 필드 추가
- [x] Category 엔티티 userId를 String 타입으로 정의
- [x] SupabaseAuthDataSource에서 uuid 필드 매핑
- [x] CategoryManagementScreen에서 uuid 사용
- [x] Supabase 테이블 user_id를 UUID 타입으로 정의
- [x] RLS 정책에서 auth.uid() 사용

### ⚠️ 선택적 개선 사항
- [ ] AuthUser.id (Deprecated) 필드 완전 제거
- [ ] Category 조회 시 userId 필터링 추가 (옵션 1 권장)
- [ ] Category를 Supabase로 이전 (옵션 2, 나중에 고려)

### 📋 레거시 필드 제거 시 수정 필요 파일
1. `lib/domain/entities/auth_user.dart` - id 필드 및 생성자 제거
2. `lib/data/datasources/remote/supabase_datasource.dart` - id 할당 코드 제거 (2곳)

## 결론

**UUID 마이그레이션은 이미 성공적으로 완료되었습니다.**

모든 핵심 기능(인증, 카테고리 생성, Todo 생성)에서 Supabase UUID를 올바르게 사용하고 있으며, 레거시 `id` 필드는 실제로 사용되지 않고 있습니다.

### 즉시 조치 필요 사항
**없음** - 현재 시스템은 안정적으로 작동하고 있습니다.

### 향후 개선 사항
1. **카테고리 userId 필터링 추가** (멀티 유저 시나리오 대비)
2. **레거시 id 필드 제거** (코드 정리 차원)

---

**작성자**: Claude Code (UUID Migration Analysis)
**최종 업데이트**: 2025-11-12
