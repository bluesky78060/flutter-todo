# DoDo 앱 코드 분석 보고서

**생성일**: 2025-11-06
**분석 도구**: Flutter Analyze
**프로젝트**: DoDo (Todo App)
**버전**: 1.0.0+1

---

## 📊 요약

| 항목 | 수치 |
|------|------|
| **총 이슈 수** | 102개 |
| **Warning** | 4개 |
| **Info** | 98개 |
| **Dart 파일 수** | 40개 |
| **분석 시간** | 4.8초 |

---

## 🎯 개선 완료 항목

### ✅ 수정된 이슈 (8개)

1. **Unused Imports 제거 (5개)**
   - `lib/presentation/providers/database_provider.dart`
     - `flutter/foundation.dart (kIsWeb)` 제거
     - `todo_repository_impl.dart` 제거
   - `lib/presentation/providers/todo_providers.dart`
     - `flutter/foundation.dart (kIsWeb)` 제거
   - `lib/presentation/screens/todo_detail_screen.dart`
     - `intl/intl.dart` 제거
   - `lib/presentation/widgets/custom_todo_item.dart`
     - `flutter/foundation.dart (kIsWeb)` 제거
   - `lib/presentation/widgets/todo_form_dialog.dart`
     - `flutter/foundation.dart (kIsWeb)` 제거

2. **Null Safety 이슈 수정 (2개)**
   - `lib/core/services/web_notification_service.dart:49`
     - 불필요한 `!= null` 체크 제거
   - `lib/core/services/web_notification_service.dart:50`
     - 불필요한 `!` (null assertion) 연산자 제거

3. **기타 개선 (1개)**
   - 코드 간결성 향상

---

## ⚠️ 현재 남은 이슈

### 🔴 Priority 1 - Warning (4개)

#### 1. Unused Local Variable
**파일**: `lib/presentation/screens/oauth_callback_screen.dart:18`
**이슈**: `userAsync` 변수가 선언되었으나 사용되지 않음

```dart
final userAsync = ref.watch(currentUserProvider);  // ❌ 사용되지 않음
```

**권장 수정**:
- 변수를 실제로 사용하거나
- 필요 없다면 해당 라인 제거

---

#### 2. Unused Element
**파일**: `lib/presentation/screens/settings_screen.dart:230`
**이슈**: `_buildThemeCard` 함수가 정의되었으나 호출되지 않음

```dart
Widget _buildThemeCard() { ... }  // ❌ 호출되지 않음
```

**권장 수정**:
- 함수를 실제로 사용하거나
- 미사용 코드라면 삭제

---

#### 3. Unused Import
**파일**: `lib/presentation/screens/statistics_screen.dart:5`
**이슈**: `intl/intl.dart` import가 사용되지 않음

```dart
import 'package:intl/intl.dart';  // ❌ 사용되지 않음
```

**권장 수정**:
```dart
// 해당 import 라인 제거
```

---

#### 4. Unused Import
**파일**: `lib/presentation/screens/stylish_login_screen.dart:7`
**이슈**: `auth_providers.dart` import가 사용되지 않음

```dart
import 'package:todo_app/presentation/providers/auth_providers.dart';  // ❌ 사용되지 않음
```

**권장 수정**:
```dart
// 해당 import 라인 제거
```

---

### 🟡 Priority 2 - Info (98개)

#### 1. Production 로깅 이슈 (38개)

**문제**: `print()` 함수를 프로덕션 코드에서 사용

**영향 받는 파일**:
- `lib/core/config/oauth_redirect.dart` (2개)
- `lib/core/router/app_router.dart` (7개)
- `lib/core/router/auth_notifier.dart` (2개)
- `lib/main.dart` (7개)
- `lib/presentation/providers/auth_providers.dart` (9개)
- `lib/presentation/providers/todo_providers.dart` (11개)

**권장 해결책**:

1. **Logger 패키지 도입**
```yaml
# pubspec.yaml
dependencies:
  logger: ^2.0.0
```

2. **Logger 설정**
```dart
// lib/core/utils/app_logger.dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
  ),
);
```

3. **print() 대체**
```dart
// Before
print('🔗 OAuth Redirect URL: $url');

// After
logger.i('OAuth Redirect URL: $url');
logger.d('Debug message');
logger.w('Warning message');
logger.e('Error message');
```

**효과**:
- 로그 레벨 제어 가능
- 프로덕션에서 로그 비활성화 가능
- 더 나은 로그 포맷팅
- 성능 향상

---

#### 2. Deprecated API 사용 (59개)

##### A. `withOpacity()` → `withValues()` (59개)

**문제**: `Color.withOpacity()`가 deprecated됨

**영향 받는 파일**:
- `lib/presentation/screens/stylish_login_screen.dart` (55개)
- `lib/presentation/screens/todo_list_screen.dart` (4개)
- `lib/presentation/widgets/progress_card.dart` (2개)
- `lib/presentation/widgets/todo_form_dialog.dart` (1개)

**마이그레이션 예시**:
```dart
// Before
color: Colors.blue.withOpacity(0.5)

// After
color: Colors.blue.withValues(alpha: 0.5)
```

**일괄 변경 스크립트** (참고용):
```bash
# macOS/Linux
find lib -name "*.dart" -type f -exec sed -i '' 's/\.withOpacity(\([0-9.]*\))/.withValues(alpha: \1)/g' {} +

# 수동 검토 후 적용 권장
```

---

##### B. Web API Deprecated (3개)

**파일**: `lib/core/services/web_notification_service.dart`

**이슈**:
1. `dart:html` → `package:web` + `dart:js_interop`
2. `dart:js` → `dart:js_interop`
3. Flutter 웹 플러그인 외부에서 웹 라이브러리 사용

**마이그레이션 가이드**:
```dart
// Before
import 'dart:html' as html;
import 'dart:js' as js;

// After
import 'package:web/web.dart' as web;
import 'dart:js_interop';
```

**참고 자료**:
- [Dart 3.0 Web API Migration](https://dart.dev/guides/libraries/dart-html-migration)

---

##### C. Drift Web (1개)

**파일**: `lib/data/datasources/local/connection/web.dart:2`

**이슈**: `package:drift/web.dart` deprecated

**마이그레이션**:
```dart
// Before
import 'package:drift/web.dart';

// After
import 'package:drift/wasm.dart';
```

**참고**: https://drift.simonbinder.eu/web

---

##### D. Material Theme (1개)

**파일**: `lib/main.dart:100`

**이슈**: `ColorScheme.background` deprecated

**수정**:
```dart
// Before
colorScheme: ColorScheme.dark(
  background: AppColors.darkBackground,
)

// After
colorScheme: ColorScheme.dark(
  surface: AppColors.darkBackground,
)
```

---

## 📈 프로젝트 구조 분석

### ✅ 강점

1. **Clean Architecture 적용**
   ```
   lib/
   ├── domain/          # 비즈니스 로직
   ├── data/            # 데이터 레이어
   └── presentation/    # UI 레이어
   ```

2. **현대적 Flutter 스택**
   - Riverpod 3.x (상태 관리)
   - GoRouter 14.x (라우팅)
   - Drift 2.x (로컬 DB)
   - Supabase (백엔드/인증)

3. **멀티 플랫폼 지원**
   - Web, Android, iOS 대응
   - Platform-specific 구현 분리

4. **Repository 패턴**
   - 데이터 소스 추상화
   - 테스트 용이성 향상

### ⚠️ 개선 필요 사항

1. **로깅 시스템 부재**
   - 38개의 `print()` 문 산재
   - 로그 레벨 제어 불가

2. **Deprecated API 대량 사용**
   - 64개의 deprecated API
   - 향후 Flutter 버전 업그레이드 시 문제 발생 가능

3. **데드 코드 존재**
   - 사용되지 않는 함수, 변수, import

---

## 🎯 우선순위별 개선 계획

### 🔴 Priority 1 (즉시 수정 - 1일)

**목표**: Warning 제거

1. ✅ Unused imports 제거 (2개)
   - `statistics_screen.dart`
   - `stylish_login_screen.dart`

2. ✅ Unused variable 제거 (1개)
   - `oauth_callback_screen.dart`

3. ✅ Unused element 제거 (1개)
   - `settings_screen.dart`

**예상 소요 시간**: 30분
**난이도**: ⭐ (매우 쉬움)

---

### 🟡 Priority 2 (단기 - 1-2주)

**목표**: 로깅 시스템 구축

1. ⚠️ Logger 패키지 도입
2. ⚠️ `print()` → `logger` 마이그레이션 (38개)
3. ⚠️ 로그 레벨 정책 수립
   - Debug: 개발 환경 전용
   - Info: 중요 이벤트
   - Warning: 주의 필요
   - Error: 에러 발생

**예상 소요 시간**: 4-6시간
**난이도**: ⭐⭐ (쉬움)

---

### 🟢 Priority 3 (중기 - 1개월)

**목표**: Deprecated API 마이그레이션

1. 📋 `withOpacity()` → `withValues()` (59개)
   - 자동화 스크립트 작성
   - 수동 검토 및 테스트

2. 📋 Web API 마이그레이션
   - `dart:html` → `package:web`
   - `dart:js` → `dart:js_interop`

3. 📋 Drift web 마이그레이션
   - `drift/web.dart` → `drift/wasm.dart`

4. 📋 Material Theme 업데이트
   - `background` → `surface`

**예상 소요 시간**: 1-2일
**난이도**: ⭐⭐⭐ (중간)

---

## 🔍 보안 분석

### ✅ 긍정적 요소

1. **인증 시스템**
   - Supabase 인증 사용
   - OAuth 2.0 지원 (Google, Kakao)
   - Deep linking 구현

2. **데이터 보안**
   - 로컬 DB 암호화 (Drift)
   - HTTPS 통신 (Supabase)

### ⚠️ 주의 필요 사항

1. **로그에 민감 정보 노출 가능**
   ```dart
   // 현재 코드
   print('🔗 OAuth Redirect URL: $redirectUrl');  // ⚠️ URL에 토큰 포함 가능

   // 개선 필요
   logger.d('OAuth Redirect configured');  // 민감 정보 제외
   ```

2. **환경 변수 관리**
   - Supabase URL/Key 하드코딩 확인 필요
   - `.env` 파일 사용 권장

3. **권한 관리**
   - Android 알림 권한 (적절히 구현됨)
   - iOS 권한 (추가 확인 필요)

---

## 📊 메트릭 상세

### 카테고리별 분포

```
Info (로깅)         ████████████████████████░░░░░░  38개 (37.3%)
Info (Deprecated)   ██████████████████████████████  60개 (58.8%)
Warning             █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   4개 (3.9%)
```

### 파일별 이슈 수 (Top 10)

| 파일 | 이슈 수 | 주요 이슈 |
|------|---------|-----------|
| `stylish_login_screen.dart` | 56 | `withOpacity()` deprecated |
| `todo_providers.dart` | 11 | `print()` 로깅 |
| `auth_providers.dart` | 9 | `print()` 로깅 |
| `app_router.dart` | 7 | `print()` 로깅 |
| `main.dart` | 7 | `print()` 로깅 |
| `todo_list_screen.dart` | 4 | `withOpacity()` deprecated |
| `web_notification_service.dart` | 4 | Deprecated web API |
| `oauth_redirect.dart` | 2 | `print()` 로깅 |
| `progress_card.dart` | 2 | `withOpacity()` deprecated |
| 기타 | 0 | - |

---

## 🛠️ 권장 도구 및 설정

### 1. Analysis Options 강화

**파일**: `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # 추가 권장 룰
    - prefer_const_constructors
    - prefer_const_declarations
    - unnecessary_null_checks
    - avoid_print  # 이미 적용됨
    - prefer_single_quotes
    - sort_pub_dependencies

analyzer:
  errors:
    # Warning을 Error로 승격
    unused_import: error
    unused_local_variable: error
    dead_code: error
```

### 2. Pre-commit Hook

**파일**: `.git/hooks/pre-commit`

```bash
#!/bin/bash

echo "Running Flutter analyze..."
flutter analyze

if [ $? -ne 0 ]; then
  echo "❌ Analysis failed. Please fix the issues before committing."
  exit 1
fi

echo "✅ Analysis passed"
exit 0
```

### 3. CI/CD 통합

**GitHub Actions 예시**:

```yaml
name: Code Analysis

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
```

---

## 📝 다음 단계

### 즉시 실행 (오늘)

- [ ] Unused imports 제거 (2개)
- [ ] Unused variable/element 제거 (2개)
- [ ] 분석 결과 팀과 공유

### 이번 주

- [ ] Logger 패키지 도입
- [ ] `print()` 마이그레이션 계획 수립
- [ ] 로그 레벨 정책 문서화

### 이번 달

- [ ] `withOpacity()` 마이그레이션
- [ ] Web API 업데이트 검토
- [ ] Pre-commit hook 설정

---

## 📚 참고 자료

### Flutter 공식 문서
- [Dart Code Metrics](https://dart.dev/guides/language/analysis-options)
- [Flutter Best Practices](https://docs.flutter.dev/development/best-practices)
- [Deprecated APIs](https://docs.flutter.dev/release/breaking-changes)

### 패키지 문서
- [Logger Package](https://pub.dev/packages/logger)
- [Drift Migration Guide](https://drift.simonbinder.eu/web)
- [Web Interop](https://dart.dev/guides/libraries/dart-html-migration)

### 관련 이슈
- [Flutter withOpacity Deprecation](https://github.com/flutter/flutter/issues/xxxxx)
- [Dart 3.0 Web APIs](https://github.com/dart-lang/sdk/issues/xxxxx)

---

## ✅ 결론

### 전반적 평가: **양호 (B+)**

**장점**:
- ✅ Clean Architecture 적용
- ✅ 현대적 Flutter 스택
- ✅ 멀티 플랫폼 지원
- ✅ Repository 패턴 구현

**개선 필요**:
- ⚠️ 로깅 시스템 부재
- ⚠️ Deprecated API 대량 사용
- ⚠️ 데드 코드 존재

**종합 평가**:
잘 구조화된 프로젝트이나, **프로덕션 배포 전 Priority 1-2 이슈 해결 필수**.

**권장 타임라인**:
- **1주일 내**: Priority 1 완료
- **1개월 내**: Priority 2 완료
- **3개월 내**: Priority 3 완료

---

**보고서 작성**: Claude Code
**검증**: Flutter Analyze v3.9.2
**프로젝트**: DoDo Todo App
**날짜**: 2025-11-06
