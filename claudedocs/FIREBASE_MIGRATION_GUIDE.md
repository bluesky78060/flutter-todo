# Supabase에서 Firebase로 이관 가이드

## 목차
1. [현재 프로젝트 구조](#현재-프로젝트-구조)
2. [Google Database 옵션 비교](#google-database-옵션-비교)
3. [Firebase 이관 상세 가이드](#firebase-이관-상세-가이드)
4. [데이터 마이그레이션](#데이터-마이그레이션)
5. [이관 일정 및 체크리스트](#이관-일정-및-체크리스트)

---

## 현재 프로젝트 구조

### 백엔드 스택
| 구성 요소 | 현재 기술 | 설명 |
|----------|----------|------|
| 인증 | Supabase Auth | Google/Kakao OAuth |
| 데이터베이스 | Supabase PostgreSQL | todos, categories 테이블 |
| 로컬 저장소 | Drift (SQLite) | 오프라인 지원 |
| 보안 | RLS Policies | 사용자별 데이터 격리 |
| 실시간 | Supabase Realtime | 데이터 동기화 |

### 현재 데이터베이스 스키마

```sql
-- todos 테이블
CREATE TABLE todos (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT false,
  category_id BIGINT REFERENCES categories(id),
  due_date TIMESTAMPTZ,
  reminder_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- categories 테이블
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 현재 주요 파일
```
lib/
├── core/config/
│   ├── supabase_config.dart      # Supabase 초기화
│   └── oauth_redirect.dart       # OAuth 설정
├── data/datasources/remote/
│   ├── supabase_todo_repository.dart
│   └── supabase_category_repository.dart
└── presentation/providers/
    ├── auth_provider.dart        # Supabase Auth
    └── todo_provider.dart
```

---

## Google Database 옵션 비교

### 옵션 1: Firebase (권장)

| 항목 | 설명 |
|------|------|
| **적합성** | 모바일/웹 앱에 최적화, Supabase와 가장 유사 |
| **비용** | 무료 티어 충분 (Spark Plan) |
| **학습 곡선** | 낮음 (Flutter 공식 지원) |
| **실시간 지원** | Firestore 실시간 리스너 |

**서비스 매핑**
| Supabase | Firebase |
|----------|----------|
| Supabase Auth | Firebase Authentication |
| PostgreSQL | Cloud Firestore (NoSQL) |
| RLS Policies | Firestore Security Rules |
| Realtime | Firestore Snapshots |
| Storage | Firebase Storage |

### 옵션 2: Google Cloud SQL

| 항목 | 설명 |
|------|------|
| **적합성** | 기존 PostgreSQL 스키마 유지 필요시 |
| **비용** | 높음 (항상 인스턴스 비용 발생) |
| **학습 곡선** | 높음 (직접 API 구현 필요) |
| **실시간 지원** | 직접 구현 필요 |

### 옵션 3: Google Cloud Datastore

| 항목 | 설명 |
|------|------|
| **적합성** | 대규모 데이터, 서버리스 |
| **비용** | 사용량 기반 |
| **학습 곡선** | 중간 |
| **실시간 지원** | 없음 |

### 권장 사항

**Firebase Firestore 권장 이유:**
1. Flutter 공식 플러그인 지원
2. 무료 티어로 소규모 앱 운영 가능
3. 실시간 데이터 동기화 내장
4. Google OAuth 네이티브 지원
5. 오프라인 지원 내장

---

## Firebase 이관 상세 가이드

### Phase 1: Firebase 프로젝트 설정

#### 1.1 Firebase Console 설정

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 새 프로젝트 생성: `dodo-todo-app`
3. Google Analytics 활성화 (선택)

#### 1.2 Firebase CLI 설치

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# 로그인
firebase login

# 프로젝트 디렉토리에서 초기화
cd /Users/leechanhee/todo_app
firebase init

# 선택 항목:
# - Firestore
# - Authentication
# - (선택) Functions
# - (선택) Storage
```

#### 1.3 Flutter 패키지 설정

```yaml
# pubspec.yaml 변경

dependencies:
  # 제거할 패키지
  # supabase_flutter: ^2.8.4

  # 추가할 패키지
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  cloud_firestore: ^5.6.1
  google_sign_in: ^6.2.2
  firebase_storage: ^12.3.7  # 필요시
```

```bash
# 패키지 설치
flutter pub get
```

#### 1.4 플랫폼별 설정

**Android 설정**

1. Firebase Console → 프로젝트 설정 → 앱 추가 → Android
2. 패키지명: `kr.bluesky.dodo`
3. `google-services.json` 다운로드
4. 파일 위치: `android/app/google-services.json`

```kotlin
// android/build.gradle.kts
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

// android/app/build.gradle.kts
plugins {
    id("com.google.gms.google-services")
}
```

**iOS 설정**

1. Firebase Console → 프로젝트 설정 → 앱 추가 → iOS
2. Bundle ID: `kr.bluesky.dodo`
3. `GoogleService-Info.plist` 다운로드
4. Xcode에서 Runner에 추가

```ruby
# ios/Podfile
platform :ios, '13.0'
```

---

### Phase 2: 인증 이관

#### 2.1 Firebase Auth 초기화

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (Supabase 대체)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

#### 2.2 Firebase Auth 서비스

```dart
// lib/core/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google 로그인 플로우
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 인증 정보 획득
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google 로그인 오류: $e');
      return null;
    }
  }

  // 카카오 로그인 (Cloud Functions 필요)
  Future<UserCredential?> signInWithKakao() async {
    // 카카오 SDK로 로그인 후 Custom Token 발급 필요
    // Cloud Functions에서 Custom Token 생성
    // 자세한 구현은 Phase 2.3 참조
    throw UnimplementedError('카카오 로그인은 Cloud Functions 설정 필요');
  }

  // 이메일/비밀번호 로그인
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('이메일 로그인 오류: ${e.message}');
      return null;
    }
  }

  // 이메일/비밀번호 회원가입
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('회원가입 오류: ${e.message}');
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 비밀번호 재설정
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
```

#### 2.3 카카오 로그인 (Cloud Functions)

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.createKakaoCustomToken = functions.https.onCall(async (data, context) => {
  const kakaoAccessToken = data.accessToken;

  try {
    // 카카오 사용자 정보 조회
    const response = await axios.get('https://kapi.kakao.com/v2/user/me', {
      headers: {
        Authorization: `Bearer ${kakaoAccessToken}`,
      },
    });

    const kakaoUser = response.data;
    const uid = `kakao:${kakaoUser.id}`;

    // Firebase Custom Token 생성
    const customToken = await admin.auth().createCustomToken(uid, {
      provider: 'kakao',
      kakaoId: kakaoUser.id,
      email: kakaoUser.kakao_account?.email,
      nickname: kakaoUser.properties?.nickname,
    });

    return { customToken };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

```dart
// lib/core/services/firebase_auth_service.dart (카카오 부분)
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<UserCredential?> signInWithKakao() async {
  try {
    // 카카오 로그인
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    // Cloud Function 호출하여 Custom Token 획득
    final callable = FirebaseFunctions.instance.httpsCallable('createKakaoCustomToken');
    final result = await callable.call({'accessToken': token.accessToken});
    final customToken = result.data['customToken'];

    // Firebase 로그인
    return await _auth.signInWithCustomToken(customToken);
  } catch (e) {
    print('카카오 로그인 오류: $e');
    return null;
  }
}
```

#### 2.4 Auth Provider 수정

```dart
// lib/presentation/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider).value;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final FirebaseAuthService _authService;

  @override
  FutureOr<User?> build() {
    _authService = FirebaseAuthService();
    return _authService.currentUser;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await _authService.signInWithGoogle();
    state = AsyncData(result?.user);
  }

  Future<void> signInWithKakao() async {
    state = const AsyncLoading();
    final result = await _authService.signInWithKakao();
    state = AsyncData(result?.user);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncData(null);
  }
}
```

---

### Phase 3: 데이터베이스 이관

#### 3.1 Firestore 스키마 설계

```
firestore/
├── users/
│   └── {userId}/
│       ├── todos/
│       │   └── {todoId}/
│       │       ├── title: string
│       │       ├── description: string?
│       │       ├── isCompleted: boolean
│       │       ├── categoryId: string?
│       │       ├── dueDate: timestamp?
│       │       ├── reminderTime: timestamp?
│       │       ├── rrule: string?
│       │       ├── createdAt: timestamp
│       │       └── completedAt: timestamp?
│       │
│       └── categories/
│           └── {categoryId}/
│               ├── name: string
│               ├── color: string
│               └── createdAt: timestamp
```

#### 3.2 Entity 모델 수정

```dart
// lib/domain/entities/todo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

@freezed
class Todo with _$Todo {
  const factory Todo({
    String? id,
    required String title,
    String? description,
    @Default(false) bool isCompleted,
    String? categoryId,
    DateTime? dueDate,
    DateTime? reminderTime,
    String? rrule,
    DateTime? createdAt,
    DateTime? completedAt,
  }) = _Todo;

  const Todo._();

  // Firestore에서 변환
  factory Todo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Todo(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      categoryId: data['categoryId'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      reminderTime: (data['reminderTime'] as Timestamp?)?.toDate(),
      rrule: data['rrule'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Firestore로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'categoryId': categoryId,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'rrule': rrule,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
```

```dart
// lib/domain/entities/category.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    String? id,
    required String name,
    required String color,
    DateTime? createdAt,
  }) = _Category;

  const Category._();

  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      color: data['color'] ?? '#7B61FF',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
```

#### 3.3 Firestore Repository 구현

```dart
// lib/data/datasources/remote/firestore_todo_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreTodoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _todosRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('todos');
  }

  // 할 일 목록 실시간 스트림
  Stream<List<Todo>> watchTodos(String userId) {
    return _todosRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Todo.fromFirestore(doc))
            .toList());
  }

  // 할 일 목록 조회 (일회성)
  Future<Either<Failure, List<Todo>>> getTodos(String userId) async {
    try {
      final snapshot = await _todosRef(userId)
          .orderBy('createdAt', descending: true)
          .get();

      final todos = snapshot.docs
          .map((doc) => Todo.fromFirestore(doc))
          .toList();

      return right(todos);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 완료되지 않은 할 일 조회
  Future<Either<Failure, List<Todo>>> getIncompleteTodos(String userId) async {
    try {
      final snapshot = await _todosRef(userId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .get();

      final todos = snapshot.docs
          .map((doc) => Todo.fromFirestore(doc))
          .toList();

      return right(todos);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 특정 날짜의 할 일 조회
  Future<Either<Failure, List<Todo>>> getTodosByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _todosRef(userId)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final todos = snapshot.docs
          .map((doc) => Todo.fromFirestore(doc))
          .toList();

      return right(todos);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 할 일 추가
  Future<Either<Failure, String>> addTodo(String userId, Todo todo) async {
    try {
      final docRef = await _todosRef(userId).add(todo.toFirestore());
      return right(docRef.id);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 할 일 수정
  Future<Either<Failure, Unit>> updateTodo(
    String userId,
    String todoId,
    Todo todo,
  ) async {
    try {
      await _todosRef(userId).doc(todoId).update(todo.toFirestore());
      return right(unit);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 할 일 삭제
  Future<Either<Failure, Unit>> deleteTodo(String userId, String todoId) async {
    try {
      await _todosRef(userId).doc(todoId).delete();
      return right(unit);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 할 일 완료 토글
  Future<Either<Failure, Unit>> toggleComplete(
    String userId,
    String todoId,
    bool isCompleted,
  ) async {
    try {
      await _todosRef(userId).doc(todoId).update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      });
      return right(unit);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 배치 삭제
  Future<Either<Failure, Unit>> deleteCompletedTodos(String userId) async {
    try {
      final snapshot = await _todosRef(userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return right(unit);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }
}
```

```dart
// lib/data/datasources/remote/firestore_category_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreCategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _categoriesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories');
  }

  // 카테고리 목록 실시간 스트림
  Stream<List<Category>> watchCategories(String userId) {
    return _categoriesRef(userId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(doc))
            .toList());
  }

  // 카테고리 목록 조회
  Future<Either<Failure, List<Category>>> getCategories(String userId) async {
    try {
      final snapshot = await _categoriesRef(userId).orderBy('createdAt').get();

      final categories = snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      return right(categories);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 카테고리 추가
  Future<Either<Failure, String>> addCategory(
    String userId,
    Category category,
  ) async {
    try {
      final docRef = await _categoriesRef(userId).add(category.toFirestore());
      return right(docRef.id);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 카테고리 수정
  Future<Either<Failure, Unit>> updateCategory(
    String userId,
    String categoryId,
    Category category,
  ) async {
    try {
      await _categoriesRef(userId).doc(categoryId).update(category.toFirestore());
      return right(unit);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }

  // 카테고리 삭제
  Future<Either<Failure, Unit>> deleteCategory(
    String userId,
    String categoryId,
  ) async {
    try {
      await _categoriesRef(userId).doc(categoryId).delete();
      return right(unit);
    } catch (e) {
      return left(Failure(message: e.toString()));
    }
  }
}
```

#### 3.4 Firestore Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 사용자 문서
    match /users/{userId} {
      // 본인 문서만 접근 가능
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // 할 일 컬렉션
      match /todos/{todoId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;

        // 데이터 검증
        allow create: if request.resource.data.title is string
                      && request.resource.data.title.size() > 0
                      && request.resource.data.title.size() <= 500;

        allow update: if request.resource.data.title is string
                      && request.resource.data.title.size() > 0
                      && request.resource.data.title.size() <= 500;
      }

      // 카테고리 컬렉션
      match /categories/{categoryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;

        // 데이터 검증
        allow create: if request.resource.data.name is string
                      && request.resource.data.name.size() > 0
                      && request.resource.data.color is string;
      }
    }
  }
}
```

#### 3.5 Provider 수정

```dart
// lib/presentation/providers/todo_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'todo_provider.g.dart';

@riverpod
FirestoreTodoRepository firestoreTodoRepository(FirestoreTodoRepositoryRef ref) {
  return FirestoreTodoRepository();
}

@riverpod
Stream<List<Todo>> todosStream(TodosStreamRef ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(firestoreTodoRepositoryProvider);
  return repository.watchTodos(user.uid);
}

@riverpod
class TodosNotifier extends _$TodosNotifier {
  @override
  FutureOr<List<Todo>> build() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final repository = ref.read(firestoreTodoRepositoryProvider);
    final result = await repository.getTodos(user.uid);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (todos) => todos,
    );
  }

  Future<void> addTodo(Todo todo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final repository = ref.read(firestoreTodoRepositoryProvider);
    await repository.addTodo(user.uid, todo);
    ref.invalidateSelf();
  }

  Future<void> updateTodo(String todoId, Todo todo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final repository = ref.read(firestoreTodoRepositoryProvider);
    await repository.updateTodo(user.uid, todoId, todo);
    ref.invalidateSelf();
  }

  Future<void> deleteTodo(String todoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final repository = ref.read(firestoreTodoRepositoryProvider);
    await repository.deleteTodo(user.uid, todoId);
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(String todoId, bool isCompleted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final repository = ref.read(firestoreTodoRepositoryProvider);
    await repository.toggleComplete(user.uid, todoId, isCompleted);
    ref.invalidateSelf();
  }
}
```

---

## 데이터 마이그레이션

### 마이그레이션 스크립트

```dart
// scripts/migrate_supabase_to_firebase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataMigrationService {
  final SupabaseClient _supabase;
  final FirebaseFirestore _firestore;

  DataMigrationService(this._supabase, this._firestore);

  /// 전체 데이터 마이그레이션
  Future<MigrationResult> migrateAllData() async {
    final result = MigrationResult();

    try {
      // 1. 사용자 목록 조회 (관리자 권한 필요)
      final users = await _supabase.auth.admin.listUsers();

      for (final user in users) {
        await _migrateUserData(user.id, result);
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// 현재 로그인된 사용자 데이터만 마이그레이션
  Future<MigrationResult> migrateCurrentUserData() async {
    final result = MigrationResult();

    try {
      final supabaseUser = _supabase.auth.currentUser;
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (supabaseUser == null || firebaseUser == null) {
        throw Exception('사용자 로그인 필요');
      }

      await _migrateUserData(
        supabaseUser.id,
        result,
        targetUserId: firebaseUser.uid,
      );

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  Future<void> _migrateUserData(
    String supabaseUserId,
    MigrationResult result, {
    String? targetUserId,
  }) async {
    final firebaseUserId = targetUserId ?? supabaseUserId;

    // 카테고리 마이그레이션
    final categories = await _supabase
        .from('categories')
        .select()
        .eq('user_id', supabaseUserId);

    final categoryIdMap = <int, String>{};

    for (final category in categories) {
      final docRef = await _firestore
          .collection('users')
          .doc(firebaseUserId)
          .collection('categories')
          .add({
            'name': category['name'],
            'color': category['color'],
            'createdAt': category['created_at'] != null
                ? Timestamp.fromDate(DateTime.parse(category['created_at']))
                : FieldValue.serverTimestamp(),
          });

      // 기존 ID와 새 ID 매핑
      categoryIdMap[category['id']] = docRef.id;
      result.categoriesMigrated++;
    }

    // 할 일 마이그레이션
    final todos = await _supabase
        .from('todos')
        .select()
        .eq('user_id', supabaseUserId);

    final batch = _firestore.batch();

    for (final todo in todos) {
      final docRef = _firestore
          .collection('users')
          .doc(firebaseUserId)
          .collection('todos')
          .doc();

      batch.set(docRef, {
        'title': todo['title'],
        'description': todo['description'],
        'isCompleted': todo['is_completed'] ?? false,
        'categoryId': todo['category_id'] != null
            ? categoryIdMap[todo['category_id']]
            : null,
        'dueDate': todo['due_date'] != null
            ? Timestamp.fromDate(DateTime.parse(todo['due_date']))
            : null,
        'reminderTime': todo['reminder_time'] != null
            ? Timestamp.fromDate(DateTime.parse(todo['reminder_time']))
            : null,
        'rrule': todo['rrule'],
        'createdAt': todo['created_at'] != null
            ? Timestamp.fromDate(DateTime.parse(todo['created_at']))
            : FieldValue.serverTimestamp(),
        'completedAt': todo['completed_at'] != null
            ? Timestamp.fromDate(DateTime.parse(todo['completed_at']))
            : null,
      });

      result.todosMigrated++;
    }

    await batch.commit();
    result.usersMigrated++;
  }
}

class MigrationResult {
  bool success = false;
  String? error;
  int usersMigrated = 0;
  int todosMigrated = 0;
  int categoriesMigrated = 0;

  @override
  String toString() {
    return '''
마이그레이션 결과:
- 성공: $success
- 사용자: $usersMigrated명
- 할 일: $todosMigrated개
- 카테고리: $categoriesMigrated개
${error != null ? '- 오류: $error' : ''}
''';
  }
}
```

### 마이그레이션 실행 화면

```dart
// lib/presentation/screens/migration_screen.dart
class MigrationScreen extends ConsumerStatefulWidget {
  @override
  _MigrationScreenState createState() => _MigrationScreenState();
}

class _MigrationScreenState extends ConsumerState<MigrationScreen> {
  bool _isMigrating = false;
  MigrationResult? _result;

  Future<void> _startMigration() async {
    setState(() => _isMigrating = true);

    final migrationService = DataMigrationService(
      Supabase.instance.client,
      FirebaseFirestore.instance,
    );

    final result = await migrationService.migrateCurrentUserData();

    setState(() {
      _isMigrating = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('데이터 마이그레이션')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isMigrating)
              CircularProgressIndicator()
            else if (_result != null)
              Text(_result.toString())
            else
              ElevatedButton(
                onPressed: _startMigration,
                child: Text('마이그레이션 시작'),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 이관 일정 및 체크리스트

### Phase 1: 준비 (1-2일)

- [ ] Firebase Console 프로젝트 생성
- [ ] Firebase CLI 설치 및 초기화
- [ ] Flutter 패키지 변경 (pubspec.yaml)
- [ ] Android 설정 (google-services.json)
- [ ] iOS 설정 (GoogleService-Info.plist)
- [ ] Firebase 초기화 코드 작성

### Phase 2: 인증 이관 (2-3일)

- [ ] FirebaseAuthService 클래스 작성
- [ ] Google 로그인 구현
- [ ] 이메일/비밀번호 로그인 구현
- [ ] 카카오 로그인 Cloud Functions 작성 (선택)
- [ ] AuthProvider 수정
- [ ] GoRouter 인증 가드 수정
- [ ] 로그인/회원가입 화면 수정

### Phase 3: 데이터베이스 이관 (3-5일)

- [ ] Firestore 스키마 설계
- [ ] Entity 모델 Firestore 변환 메서드 추가
- [ ] FirestoreTodoRepository 구현
- [ ] FirestoreCategoryRepository 구현
- [ ] Firestore Security Rules 작성
- [ ] TodoProvider 수정
- [ ] CategoryProvider 수정
- [ ] 실시간 동기화 테스트

### Phase 4: 데이터 마이그레이션 (1-2일)

- [ ] 마이그레이션 스크립트 작성
- [ ] 마이그레이션 화면 구현
- [ ] 테스트 사용자로 마이그레이션 테스트
- [ ] 기존 사용자 데이터 마이그레이션
- [ ] 데이터 무결성 검증

### Phase 5: 테스트 및 배포 (2-3일)

- [ ] 전체 기능 테스트 (CRUD)
- [ ] 인증 플로우 테스트
- [ ] 오프라인 동기화 테스트
- [ ] 위젯 데이터 연동 테스트
- [ ] 성능 테스트
- [ ] Play Store / App Store 배포

---

## 주요 변경 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `pubspec.yaml` | supabase_flutter 제거, firebase 패키지 추가 |
| `lib/main.dart` | Firebase.initializeApp() |
| `lib/core/config/supabase_config.dart` | 삭제 |
| `lib/core/services/firebase_auth_service.dart` | 신규 |
| `lib/data/datasources/remote/supabase_*.dart` | 삭제 |
| `lib/data/datasources/remote/firestore_*.dart` | 신규 |
| `lib/domain/entities/*.dart` | toFirestore/fromFirestore 추가 |
| `lib/presentation/providers/auth_provider.dart` | Firebase Auth로 변경 |
| `lib/presentation/providers/todo_provider.dart` | Firestore로 변경 |
| `lib/presentation/providers/category_provider.dart` | Firestore로 변경 |
| `android/app/google-services.json` | 신규 |
| `ios/Runner/GoogleService-Info.plist` | 신규 |
| `firestore.rules` | 신규 |
| `functions/index.js` | 신규 (카카오 로그인) |

---

## 비용 비교

### Supabase (현재)
- **Free Tier**: 500MB 데이터베이스, 1GB 스토리지, 50,000 MAU
- **Pro**: $25/월

### Firebase
- **Spark (Free)**: 1GB Firestore, 50K reads/20K writes/day
- **Blaze (Pay-as-you-go)**: 사용량 기반

### 예상 비용 (월간)
| 사용량 | Supabase | Firebase |
|--------|----------|----------|
| < 1,000 MAU | $0 | $0 |
| 1,000-10,000 MAU | $0-25 | $0-10 |
| > 50,000 MAU | $25+ | $50+ |

---

## 참고 자료

- [Firebase Flutter 공식 문서](https://firebase.flutter.dev/)
- [Cloud Firestore 가이드](https://firebase.google.com/docs/firestore)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
