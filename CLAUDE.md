# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter Todo app with Supabase backend, featuring OAuth authentication (Google/Kakao), local/cloud sync, notifications, and multi-platform support (Web, Android, iOS).

**Package**: `kr.bluesky.dodo`
**Current Version**: 1.0.3+15 (see pubspec.yaml)

## Development Commands

### Running the App

```bash
# Web
flutter run -d chrome

# Android emulator
flutter run -d emulator-5554

# iOS simulator
flutter run -d <ios-simulator-id>

# Physical device (Samsung Galaxy example)
flutter run -d RF9NB0146AB

# List devices
flutter devices

# Hot reload (send to running Flutter process)
kill -SIGUSR1 <pid>

# Hot restart
kill -SIGUSR2 <pid>
```

### Build Commands

#### 플랫폼별 독립 버전 빌드 (권장)

**빌드 스크립트 사용** (플랫폼별 버전 자동 관리):

```bash
# Android 빌드 (기본값: 1.0.10+34)
./scripts/build_android.sh

# Android 커스텀 버전 빌드
./scripts/build_android.sh 1.0.11 35

# iOS 빌드 (기본값: 1.0.5+15)
./scripts/build_ios.sh

# iOS 커스텀 버전 빌드
./scripts/build_ios.sh 1.0.6 16
```

**자동 기능**:
- 버전 번호 파일명 자동 생성 (예: `app-release-1.0.11+35.aab`)
- pubspec.yaml 자동 백업 및 복원
- Clean 및 dependency 설치 자동화
- 상세한 빌드 로그 및 결과 표시

**상세 가이드**: [VERSION_MANAGEMENT.md](VERSION_MANAGEMENT.md)

#### 수동 빌드 (고급)

```bash
# Android Development APK
flutter build apk --debug

# Android Release (커스텀 버전)
flutter build apk --release --build-name=1.0.11 --build-number=35
flutter build appbundle --release --build-name=1.0.11 --build-number=35

# iOS Release (커스텀 버전)
flutter build ios --release --build-name=1.0.6 --build-number=16 --no-codesign

# Build outputs:
# Android:
#   - AAB: build/app/outputs/bundle/release/app-release.aab
#   - APK: build/app/outputs/flutter-apk/app-release.apk
# iOS:
#   - 추가로 Xcode에서 Archive 필요 (ios/Runner.xcworkspace)
```

**버전 관리 전략**:
- Android와 iOS는 독립적인 버전 번호 사용 가능
- 각 스토어별로 빌드 번호는 항상 증가해야 함
- 현재 Android: 1.0.10+34, iOS: 1.0.5+15

**CRITICAL: 빌드 전 최신 업로드 버전 확인 필수**
```bash
# Google Play Console에서 최신 업로드된 빌드 번호 확인
# Settings > App integrity > App bundles > 최신 버전 번호 확인
#
# 예: Google Play Console에 1.0.12+37이 업로드되어 있다면
# 새 빌드는 반드시 38 이상이어야 함
#
# WRONG: ./scripts/build_android.sh 1.0.13 35  # 35 < 37 (거부됨)
# RIGHT: ./scripts/build_android.sh 1.0.13 39  # 39 > 37 (승인됨)
```

**빌드 번호 규칙**:
- 새 빌드 번호는 반드시 Google Play에 업로드된 최신 빌드 번호보다 커야 함
- 빌드 전 항상 Google Play Console에서 최신 버전 확인
- 빌드 번호가 작으면 업로드 시 "Version code X has already been used" 오류 발생

**IMPORTANT**: 빌드 스크립트 사용 시 버전 번호가 포함된 파일이 자동 생성되므로 수동 복사 불필요

### Code Generation

```bash
# Generate code (Freezed, Drift, JSON Serializable)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
dart run build_runner watch --delete-conflicting-outputs
```

### Testing & Analysis

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/utils/recurrence_utils_test.dart

# Run specific test group
flutter test test/unit/utils/recurrence_utils_test.dart --plain-name "getNextOccurrences"

# Generate mock files (for tests using @GenerateMocks)
dart run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze

# Check dependencies
flutter pub outdated
```

**Testing Standards**:
- **Date Convention**: All test dates use **2025 as the base year** for consistency and to avoid past-date issues
- **UTC DateTime**: Always use `DateTime.utc()` for RRULE-related tests (required by rrule package)
- **Test Structure**: Follow Arrange-Act-Assert pattern with clear group organization
- **Mock Setup**: Use mockito with `@GenerateMocks` annotation and fpdart's Either type

### Android Debugging

```bash
# Install APK to device
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/apk/release/app-release.apk

# View logs
~/Library/Android/sdk/platform-tools/adb logcat

# View filtered logs (Flutter/Supabase/Auth)
~/Library/Android/sdk/platform-tools/adb logcat | grep -E "(flutter|kr.bluesky.dodo|OAuth|Supabase|Auth)"

# Clear logs
~/Library/Android/sdk/platform-tools/adb logcat -c

# Launch app
~/Library/Android/sdk/platform-tools/adb shell am start -n kr.bluesky.dodo/.MainActivity

# Uninstall app
~/Library/Android/sdk/platform-tools/adb uninstall kr.bluesky.dodo

# Take screenshot
~/Library/Android/sdk/platform-tools/adb exec-out screencap -p > screenshot.png
```

## Architecture

### Clean Architecture Layers

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── config/             # Supabase, OAuth configuration
│   ├── router/             # GoRouter setup, auth guards
│   ├── services/           # Notifications, battery optimization
│   ├── theme/              # Colors, theming
│   └── utils/              # Logger, helpers
│
├── domain/                 # Business logic (platform-agnostic)
│   ├── entities/           # Freezed immutable models
│   └── repositories/       # Repository interfaces
│
├── data/                   # Data layer
│   ├── datasources/
│   │   ├── local/         # Drift (SQLite) for offline storage
│   │   └── remote/        # Supabase client
│   └── repositories/       # Repository implementations
│
└── presentation/           # UI layer
    ├── providers/          # Riverpod 3.x state management
    ├── screens/            # Page-level widgets
    └── widgets/            # Reusable components
```

### Key Architectural Patterns

**1. Dual Repository Pattern**
- Each entity has TWO repositories: local (Drift) and remote (Supabase)
- Provider layer orchestrates sync: read from local, write to both
- Example: `TodoRepositoryImpl` (local) + `SupabaseTodoRepository` (remote)

**2. Auth Flow with GoRouter**
- `AuthNotifier` listens to Supabase auth state changes
- `goRouterProvider` uses `refreshListenable` for automatic routing
- Protected routes redirect to login when unauthenticated
- OAuth callback handled via `/oauth-callback` route

**3. Notification Architecture**
- Platform-specific: `FlutterLocalNotifications` (mobile), custom web service
- Permission handling: delayed until Activity context ready (Android)
- Crash prevention: duplicate request guards, sequential delays (300-500ms)

**4. State Management (Riverpod 3.x)**
- `AsyncNotifierProvider` for async state (todos, categories)
- `StreamProvider` for real-time Supabase auth
- `StateProvider` for simple state (theme, selected filter)

## Critical Implementation Details

### Android Permissions (Crash-Prone Area)

**Permission Request Timing**: NEVER request permissions in `main()`. Always wait for Activity context:

```dart
// ❌ WRONG - causes crash
void main() async {
  await NotificationService().requestPermissions(); // Crash!
}

// ✅ CORRECT - in screen after context ready
@override
void initState() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAndRequestPermissions();
    });
  });
}
```

**Key Crash Prevention Patterns**:
1. **Duplicate Request Guard**: `bool _isRequestingPermissions` flag
2. **Sequential Delays**: 300ms between permission requests
3. **Activity Ready Delay**: 500ms after `postFrameCallback`
4. **Non-Critical Errors**: Exact alarm permission failures shouldn't crash app

See: [lib/presentation/screens/todo_list_screen.dart](lib/presentation/screens/todo_list_screen.dart) and [lib/core/services/notification_service.dart](lib/core/services/notification_service.dart)

### OAuth Configuration

**Web vs Mobile Redirects**:
- Web: `window.location.origin + '/oauth-callback'` (dynamic)
- Mobile: Platform-specific deep links (handled by Supabase SDK)

**IMPORTANT**: Web OAuth requires static redirect in Supabase Dashboard matching deployed URL.

Configuration: [lib/core/config/oauth_redirect.dart](lib/core/config/oauth_redirect.dart)

### Supabase Setup

Required tables and RLS policies in Supabase:

```sql
-- todos table
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

-- categories table
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and create policies for user isolation
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own todos" ON todos
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can CRUD their own categories" ON categories
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

**OAuth Providers** (configure in Supabase Dashboard):
- Google: Requires OAuth 2.0 Client ID
- Kakao: Requires REST API Key and Redirect URI

### Release Build Configuration

**Android Signing** (android/key.properties):
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

**Build Optimizations** (enabled in [android/app/build.gradle.kts](android/app/build.gradle.kts)):
- R8 code shrinking: `isMinifyEnabled = true`
- Resource shrinking: `isShrinkResources = true`
- Native debug symbols: `debugSymbolLevel = "FULL"`
- ProGuard rules: `proguard-rules.pro`

**Version Management**: Update in [pubspec.yaml](pubspec.yaml) (format: `major.minor.patch+buildNumber`)

## Localization

**Supported Languages**: English (en), Korean (ko)

**Adding Translations**:
1. Edit `assets/translations/en.json` and `assets/translations/ko.json`
2. Use in code: `tr('key.path')` or `context.tr('key.path')`
3. Change language: `context.setLocale(Locale('ko'))`

**Common Keys**:
- Authentication: `login`, `sign_up`, `logout`, `email`, `password`, `google_login`, `kakao_login`
- Todo: `add_todo`, `edit_todo`, `delete_todo`, `completed`, `pending`, `all`
- Settings: `settings`, `categories`, `category_management`, `dark_mode`, `logout`
- Form: `title`, `description`, `save`, `cancel`, `confirm`
- Notifications: `notification_time_optional`, `select_notification_time`

**Translation Structure**: Flat JSON (no nesting) - use underscore-separated keys like `category_optional`

## Common Issues & Troubleshooting

### "Reply already submitted" Crash
**Cause**: Multiple permission handlers processing same result
**Fix**: Add `_isRequestingPermissions` guard flag with delays
**Prevention**: Always use duplicate request guards when requesting Android permissions

### OAuth Redirect Loop
**Cause**: GoRouter redirect logic returning same path
**Fix**: Check `state.matchedLocation != targetRoute` before redirecting
**Context**: OAuth callback uses `LaunchMode.inAppWebView` for auto-close behavior

### Notifications Not Appearing
**Causes**:
1. Permissions not granted (Android 13+) - Check `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`
2. Battery optimization enabled (Samsung devices) - Guide user to disable in settings
3. Exact alarm permission missing (Android 12+)
4. Permission requested too early (before Activity context ready)

**Debug**: Check logcat with `grep -E "(flutter|Notification|Permission)"`

**Key Files**:
- [lib/core/services/notification_service.dart](lib/core/services/notification_service.dart) - Service implementation
- [lib/presentation/screens/todo_list_screen.dart](lib/presentation/screens/todo_list_screen.dart) - Permission request flow

### Build Failures
- **Drift errors**: Run `dart run build_runner build --delete-conflicting-outputs`
- **Dependency conflicts**: Run `flutter pub upgrade` or `flutter pub get`
- **Android build errors**: Clean with `flutter clean && cd android && ./gradlew clean`
- **Keystore missing**: Ensure `android/key.properties` exists for release builds
- **JAVA_HOME not set**: Set with `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`

### Hot Reload Not Working
**Cause**: Flutter process not responding to signals
**Solution**: Find PID with `ps aux | grep flutter` and send `kill -SIGUSR1 <pid>`
**Alternative**: Stop app and restart with `flutter run`

## Testing Workflows

### Manual Testing Checklist

**Auth Flow**:
1. Register new account
2. Login with email/password
3. OAuth login (Google/Kakao)
4. Logout and verify redirect

**Todo CRUD**:
1. Create todo with category and reminder
2. Toggle completion status
3. Edit todo details
4. Delete todo
5. Verify local/cloud sync

**Notifications**:
1. Set reminder for 1-2 minutes from now
2. Grant all permissions
3. Background app
4. Verify notification appears at scheduled time

**Release Testing**:
1. Build release APK: `flutter build apk --release`
2. Install on physical device: `adb install -r <apk-path>`
3. Test without debugger attached
4. Verify ProGuard didn't break functionality

## Deployment

### Google Play Release

1. **Update version** in pubspec.yaml (e.g., `1.0.3+11`)
2. **Build AAB**: `flutter build appbundle --release`
3. **Verify signing**: Check `android/key.properties` exists
4. **Upload to Play Console**: Internal/Alpha/Beta/Production track
5. **Release notes**: Document changes in Korean and English

See [GOOGLE_PLAY_RELEASE.md](GOOGLE_PLAY_RELEASE.md) for detailed guide.

### Web Deployment (Vercel/GitHub Pages)

1. **Build**: `flutter build web --release`
2. **Deploy**: Push to GitHub or `vercel deploy`
3. **Update Supabase**: Add deployed URL to OAuth redirect whitelist

## Performance Considerations

- **Large lists**: Use `ListView.builder` with pagination
- **Image loading**: Cached network images with placeholders
- **Database queries**: Index frequently queried columns
- **State management**: Minimize provider rebuilds with `select`
- **Build methods**: Keep lightweight, extract heavy logic to providers

## Security Notes

- Never commit `android/key.properties` or `.env` files
- Supabase RLS policies enforce user data isolation
- OAuth secrets managed in Supabase Dashboard
- ProGuard obfuscation enabled in release builds

## Feature Development Workflow

**IMPORTANT**: When adding new features, always update [FUTURE_TASKS.md](FUTURE_TASKS.md) and [RELEASE_NOTES.md](RELEASE_NOTES.md) to track progress and document changes.

### Process:
1. **Before starting**: Review FUTURE_TASKS.md to check if the feature is already planned
2. **During development**: Mark tasks with checkboxes as you complete them
3. **After completion**:
   - Update the task status in FUTURE_TASKS.md
   - Document changes in RELEASE_NOTES.md
   - Commit and push changes

### Checkbox Format (FUTURE_TASKS.md):
```markdown
- [ ] Feature not started
- [x] Feature completed
```

### Release Notes Format (RELEASE_NOTES.md):
```markdown
### v1.0.X (YYYY-MM-DD)
**[버전 설명]**

**신규 기능**
- ✅ **[기능 이름]**
  - 세부 기능 1
  - 세부 기능 2

**기술 개선**
- ✅ **[개선 사항]**
  - 세부 개선 1

**수정된 파일**
- `파일경로` (변경 내역)

**커밋 정보**
- 커밋 해시: [hash]
- 커밋 메시지: "[message]"
- 푸시 날짜: YYYY-MM-DD
```

### Example Workflow:
```markdown
## FUTURE_TASKS.md
### 🔴 1.1 Todo 편집 기능 ✅
- [x] Todo 수정 다이얼로그 추가
- [x] 기존 Todo 정보 폼에 자동 입력
- [x] 제목, 설명, 마감일, 알림 시간, 카테고리 수정 가능

## RELEASE_NOTES.md
### v1.0.3 (2025-11-10)
**할 일 편집 기능 추가**

**신규 기능**
- ✅ **할 일 편집 기능 완전 구현**
  - 할 일 상세 화면에서 편집 버튼 추가
  - 편집 모드에서 기존 데이터 자동 입력
```

**Purpose**:
- **FUTURE_TASKS.md**: Single source of truth for feature planning and progress tracking
- **RELEASE_NOTES.md**: Complete history of changes for each version, useful for Play Store releases and team communication

## Testing Guidelines

### Date Convention in Tests

**Critical Rule**: All test dates MUST use **2025 as the base year**.

**Rationale**:
- Avoids past-date issues with RRULE calculations
- Ensures consistency across all tests
- Prevents timezone and date calculation errors
- Makes tests future-proof for longer periods

**Examples**:
```dart
// ✅ CORRECT - Using 2025
final startDate = DateTime.utc(2025, 1, 1, 10, 0);
final dueDate = DateTime(2025, 3, 15, 14, 30);

// ❌ WRONG - Using 2024 or current year
final startDate = DateTime.utc(2024, 1, 1, 10, 0);
final dueDate = DateTime.now().add(Duration(days: 7));
```

### RRULE Test Requirements

**UTC DateTime Mandatory**: The `rrule` package requires UTC DateTime objects.

```dart
// ✅ CORRECT
final startDate = DateTime.utc(2025, 1, 1, 10, 0);
RecurrenceUtils.getNextOccurrences('FREQ=DAILY', startDate);

// ❌ WRONG - Local time causes assertion errors
final startDate = DateTime(2025, 1, 1, 10, 0);
```

### Mock Setup for fpdart

When testing code using `fpdart`'s `Either` type, provide dummy values:

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

setUp(() {
  mockRepository = MockTodoRepository();

  // Provide dummy values for Either types
  provideDummy<Either<Failure, List<Todo>>>(right(<Todo>[]));
  provideDummy<Either<Failure, int>>(right(1));
  provideDummy<Either<Failure, Unit>>(right(unit));
});
```

### Test File Organization

```
test/
├── unit/              # 단위 테스트
│   ├── services/      # 서비스 로직 테스트
│   ├── repositories/  # 리포지토리 테스트
│   └── utils/         # 유틸리티 테스트 ✅
├── widget/            # 위젯 테스트 (향후)
└── integration/       # 통합 테스트 (향후)
```

### Running Specific Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/utils/recurrence_utils_test.dart

# Run specific test group
flutter test test/unit/utils/recurrence_utils_test.dart --plain-name "getNextOccurrences"

# Run with verbose output
flutter test --verbose

# Generate and view coverage report (향후)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Coverage Status

**Current**: 31 tests (RecurrenceUtils 100% coverage) ✅
**Target**: 40-50% overall coverage
**Next Priorities**:
1. Repository tests (CategoryRepository 우선)
2. Provider tests (CategoryProviders)
3. Service tests (RecurringTodoService with date mocking)

See [claudedocs/TEST_COVERAGE_REPORT.md](claudedocs/TEST_COVERAGE_REPORT.md) for detailed coverage information.
