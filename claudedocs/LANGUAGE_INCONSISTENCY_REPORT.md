# Language Inconsistency Report

**Date**: 2025-11-17
**App**: Todo App (DoDo)
**Platform Analyzed**: Web (http://localhost:8080)

## Executive Summary

Language mixing detected in the Flutter web app. While the app properly implements EasyLocalization with separate English and Korean translation files, **hardcoded Korean text exists in HTML files** that bypasses the localization system.

## Findings

### 1. CRITICAL: Hardcoded Korean Text in HTML Files

**Location**: `/Users/leechanhee/todo_app/web/index.html` (line 33)

```html
<title>할 일 관리</title>
```

**Translation**: "Todo Management" (Korean)

**Impact**:
- When users access the web app, they always see Korean text in the browser tab title, regardless of their language preference
- This breaks the localization system since the title should use the translated value from `app_name` key

**Also Found In**:
- `/Users/leechanhee/todo_app/web/404.html` (line 33) - Same issue

### 2. Missing HTML Lang Attribute

**Issue**: The `<html>` tag lacks a `lang` attribute in both index.html and 404.html

```html
<!-- Current -->
<html>

<!-- Should be -->
<html lang="en">
<!-- or dynamically set based on user's locale -->
```

**Impact**:
- Accessibility issue for screen readers
- SEO impact (search engines can't determine page language)
- Browser translation features may not work correctly

### 3. Web Manifest Language Issues

**Location**: `/Users/leechanhee/todo_app/web/manifest.json`

**Current**:
```json
{
  "name": "todo_app",
  "short_name": "todo_app",
  "description": "A new Flutter project."
}
```

**Issue**: Generic English descriptions that don't match the app's actual name "DoDo"

**Expected**: Should reflect the actual app branding

## Translation File Analysis

### Translation Files: ✅ PASSED

**Status**: All translation keys match between English and Korean files
- English keys: 209
- Korean keys: 209
- Missing keys: 0
- Language mixing in translation files: None detected

**Key Login Page Translations Verified**:

| Key | English | Korean |
|-----|---------|--------|
| `app_name` | "Todo App" | "할 일 앱" |
| `login` | "Login" | "로그인" |
| `sign_up` | "Sign Up" | "회원가입" |
| `email` | "Email" | "이메일" |
| `password` | "Password" | "비밀번호" |
| `google_login` | "Sign in with Google" | "Google 로그인" |
| `kakao_login` | "Sign in with Kakao" | "Kakao 로그인" |
| `login_subtitle` | "Sign in easily with your social account" | "소셜 계정으로 간편하게 로그인하세요" |

### Source Code: ✅ PASSED

Korean characters found in Dart files are **only in logger statements** (debugging output), which is acceptable:

```dart
logger.d('✅ 로그인 성공 - StreamProvider가 자동으로 업데이트합니다');
logger.d('❌ 로그인 에러: $e');
```

All user-facing text properly uses translation keys:
```dart
_showSnackBar('login_success'.tr());  // ✅ Correct
_showSnackBar('email_password_required'.tr());  // ✅ Correct
```

## App Configuration

**EasyLocalization Setup** (from `lib/main.dart`):
```dart
EasyLocalization(
  supportedLocales: const [Locale('en'), Locale('ko')],
  path: 'assets/translations',
  fallbackLocale: const Locale('en'),  // Default: English
  child: ProviderScope(...),
)
```

**Default Locale**: English (`en`)
**Supported Locales**: English (`en`), Korean (`ko`)

## Impact Assessment

### High Priority Issues

1. **Browser Tab Title** (CRITICAL)
   - **Current Behavior**: Always shows "할 일 관리" (Korean)
   - **Expected Behavior**: Should show "Todo App" (EN) or "할 일 앱" (KO) based on user locale
   - **User Impact**: Confusing for English-speaking users
   - **First Impression**: Users see Korean before the app even loads

2. **Accessibility** (HIGH)
   - Missing `lang` attribute affects screen reader users
   - International users may face navigation difficulties

3. **SEO & PWA** (MEDIUM)
   - Search engines can't properly index the app
   - PWA installation may show incorrect app name

## Recommendations

### 1. Dynamic HTML Title

Replace hardcoded title with dynamic approach:

**Option A**: Use Flutter's localization in title (preferred)
```dart
// In MaterialApp.router
title: 'app_name'.tr(),
```

**Option B**: JavaScript-based dynamic title
```html
<title>Todo App</title>
<script>
  // Update title based on user's browser language
  const userLang = navigator.language.startsWith('ko') ? 'ko' : 'en';
  const titles = {
    'en': 'Todo App',
    'ko': '할 일 앱'
  };
  document.title = titles[userLang] || titles['en'];
</script>
```

### 2. Add Lang Attribute

**index.html & 404.html**:
```html
<html lang="en">
```

Or dynamically set based on browser language:
```html
<html lang="en" id="app-html">
<script>
  document.getElementById('app-html').lang =
    navigator.language.startsWith('ko') ? 'ko' : 'en';
</script>
```

### 3. Update Web Manifest

**manifest.json**:
```json
{
  "name": "DoDo - Todo App",
  "short_name": "DoDo",
  "description": "Simple and smart todo management app with cloud sync",
  "lang": "en"
}
```

### 4. Add Meta Description

**index.html**:
```html
<meta name="description" content="Simple and smart todo management app with cloud sync and notifications">
```

## Testing Checklist

After implementing fixes:

- [ ] Browser tab shows "Todo App" for English locale
- [ ] Browser tab shows "할 일 앱" for Korean locale
- [ ] `<html lang="...">` attribute matches user's locale
- [ ] Screen readers announce correct language
- [ ] PWA installation shows correct app name
- [ ] Search engines can index the page properly

## Files Requiring Changes

1. `/Users/leechanhee/todo_app/web/index.html` (line 33)
2. `/Users/leechanhee/todo_app/web/404.html` (line 33)
3. `/Users/leechanhee/todo_app/web/manifest.json` (lines 2-3, 8)

## Additional Notes

### iOS Info.plist

Korean text also found in iOS notification permission description:
```xml
<string>할 일 알림을 보내기 위해 알림 권한이 필요합니다.</string>
```

**Status**: This is acceptable as iOS apps typically show permission messages in the device's system language, not the app's current locale.

### Documentation Files

Multiple Korean texts found in:
- `RELEASE_NOTES.md`
- `PLAY_STORE_DEPLOYMENT_GUIDE.md`
- `APP_STORE_METADATA.md`
- `FUTURE_TASKS.md`

**Status**: These are documentation/metadata files and do not affect the app's runtime language behavior.

## Conclusion

The language mixing issue is **limited to static HTML files** and does not affect the core application logic. The localization system itself is properly implemented with complete translations in both languages. Fixing the hardcoded Korean title in `index.html` and `404.html` will resolve the primary user-facing language inconsistency.

**Priority**: HIGH
**Effort**: LOW (simple text replacement)
**Risk**: MINIMAL (static HTML changes only)
