# Visual Language Inconsistency Examples

## Browser Tab Title Issue

### Current Behavior (INCORRECT)

When a user opens http://localhost:8080, regardless of their browser language:

```
┌─────────────────────────────────────────┐
│ 🌐 할 일 관리                              │  ← Browser Tab
├─────────────────────────────────────────┤
│                                          │
│         [Login Screen in English]        │
│                                          │
│         Login                            │
│         Email: ___________               │
│         Password: ________               │
│         [Sign in with Google]            │
│         [Sign in with Kakao]             │
│                                          │
└─────────────────────────────────────────┘
```

**Problem**: Tab shows Korean "할 일 관리" (Todo Management) but the app content is in English

### Expected Behavior (CORRECT)

**For English Users**:
```
┌─────────────────────────────────────────┐
│ 🌐 Todo App                              │  ← English Tab Title
├─────────────────────────────────────────┤
│         [Login Screen in English]        │
│         Login                            │
│         Email: ___________               │
│         Password: ________               │
└─────────────────────────────────────────┘
```

**For Korean Users**:
```
┌─────────────────────────────────────────┐
│ 🌐 할 일 앱                               │  ← Korean Tab Title
├─────────────────────────────────────────┤
│         [로그인 화면 (한국어)]              │
│         로그인                            │
│         이메일: ___________               │
│         비밀번호: ________                │
└─────────────────────────────────────────┘
```

## Source Code Comparison

### Current (INCORRECT)

**File**: `web/index.html` (line 33)
```html
<title>할 일 관리</title>
```

### Recommended Fix

**Option 1**: English Default
```html
<title>Todo App</title>
```

**Option 2**: Dynamic Based on Browser Language
```html
<title>Todo App</title>
<script>
  const browserLang = navigator.language || navigator.userLanguage;
  const isKorean = browserLang.startsWith('ko');
  document.title = isKorean ? '할 일 앱' : 'Todo App';
</script>
```

**Option 3**: Use Flutter's Localization (BEST)
```dart
// In lib/main.dart MaterialApp.router
MaterialApp.router(
  title: 'app_name'.tr(),  // Will use translation based on current locale
  // ...
)
```

## PWA Installation Issue

### Current Behavior

When a user tries to "Add to Home Screen" (PWA installation):

```
┌──────────────────────────────┐
│  Add to Home Screen?         │
├──────────────────────────────┤
│  📱 todo_app                 │  ← Generic name
│                              │
│  A new Flutter project.      │  ← Generic description
│                              │
│  [Add]  [Cancel]             │
└──────────────────────────────┘
```

### Expected Behavior

```
┌──────────────────────────────┐
│  Add to Home Screen?         │
├──────────────────────────────┤
│  📱 DoDo                     │  ← Branded name
│                              │
│  Simple and smart todo       │
│  management app              │
│                              │
│  [Add]  [Cancel]             │
└──────────────────────────────┘
```

## Screen Reader Impact

### Current Behavior (No lang attribute)

```
Screen Reader: "Document. Unknown language. Heading level 1..."
User: *Confused - can't determine if content is English or Korean*
```

### Expected Behavior (With lang attribute)

```html
<html lang="en">
```

```
Screen Reader: "Document in English. Heading level 1, Login..."
User: *Clear understanding of page language*
```

## Real User Scenarios

### Scenario 1: English Speaker in US

1. User searches for "todo app" on Google
2. Finds your web app
3. Opens link → sees browser tab: "할 일 관리" (Korean)
4. **Reaction**: "Wait, is this a Korean app? Did I click the wrong link?"
5. Sees English content → "Okay, content is in English but the title is Korean?"
6. **First Impression**: Confusion, possible trust issues

### Scenario 2: Korean Speaker in Korea

1. User searches for "할일 앱" on Naver
2. Opens app → sees browser tab: "할 일 관리" (Korean) ✓
3. But app might be in English (if browser default is English)
4. **Expectation**: Everything should be in Korean
5. **Reality**: Mixed language experience

### Scenario 3: Bilingual User

1. User switches app language from English to Korean
2. Browser tab title stays "할 일 관리" (doesn't update)
3. **Expected**: Tab title should update to match selected language
4. **Actual**: Static Korean title regardless of app language

## Language Detection Priority

The app should determine language in this order:

```
1. User's explicit choice (saved in localStorage)
   ↓
2. Browser's language preference (navigator.language)
   ↓
3. Fallback locale (English)
```

### Current Implementation

```dart
// main.dart
fallbackLocale: const Locale('en'),  // ✓ Correct
```

### HTML Title Should Match

```javascript
// Dynamic title matching Flutter's locale
const getLocale = () => {
  // Check saved preference
  const saved = localStorage.getItem('locale');
  if (saved) return saved;

  // Check browser language
  const browserLang = navigator.language;
  if (browserLang.startsWith('ko')) return 'ko';

  // Fallback
  return 'en';
};

const titles = { 'en': 'Todo App', 'ko': '할 일 앱' };
document.title = titles[getLocale()];
```

## Testing Matrix

| User Language | Expected Tab Title | Expected App Content | Current Tab Title | Status |
|---------------|-------------------|---------------------|------------------|--------|
| English (US)  | "Todo App"        | English             | "할 일 관리" (KO) | ❌ FAIL |
| English (UK)  | "Todo App"        | English             | "할 일 관리" (KO) | ❌ FAIL |
| Korean (KR)   | "할 일 앱"         | Korean              | "할 일 관리" (KO) | ⚠️ PARTIAL |
| Japanese (JP) | "Todo App"        | English (fallback)  | "할 일 관리" (KO) | ❌ FAIL |
| Spanish (ES)  | "Todo App"        | English (fallback)  | "할 일 관리" (KO) | ❌ FAIL |

## Accessibility Impact

### WCAG 2.1 Compliance

**3.1.1 Language of Page (Level A)**
- **Requirement**: The default human language of each Web page can be programmatically determined
- **Current Status**: ❌ FAIL (no lang attribute)
- **Impact**: Screen readers can't announce correct language

### Fix

```html
<html lang="en">
```

Or dynamically:

```html
<html id="root-html">
<script>
  const locale = localStorage.getItem('locale') ||
                 (navigator.language.startsWith('ko') ? 'ko' : 'en');
  document.getElementById('root-html').setAttribute('lang', locale);
</script>
```

## Summary

**Critical Issue**: Hardcoded Korean title in English-default app
**Impact**: First impression, trust, accessibility, SEO
**Scope**: Web platform only (iOS/Android have separate configurations)
**Severity**: HIGH (user-facing)
**Complexity**: LOW (simple fix)
**Files Affected**: 2 (index.html, 404.html) + 1 (manifest.json)
