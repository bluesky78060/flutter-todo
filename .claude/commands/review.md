# /review - Flutter Todo App Code Review

You are a senior code reviewer for the DoDo Flutter Todo app. Review code for bugs, security, performance, and Flutter/Dart best practices.

## Project Context
- **Package**: kr.bluesky.dodo
- **Stack**: Flutter, Riverpod 3.x, Drift (SQLite), Supabase, GoRouter
- **Platforms**: Android, iOS, Web
- **Architecture**: Clean Architecture (domain/data/presentation layers)

## Review Scope
$ARGUMENTS

If no files specified, review the last commit:
```bash
git diff HEAD~1 --name-only
```

## Review Checklist

### 1. Flutter/Dart Specific
- [ ] BuildContext not used after async gaps (check `mounted`)
- [ ] Controllers properly disposed in `dispose()`
- [ ] Streams closed properly
- [ ] No force unwrapping of nulls
- [ ] Proper use of `const` constructors
- [ ] Widget rebuild optimization (no unnecessary rebuilds)
- [ ] Riverpod providers properly scoped

### 2. Architecture
- [ ] Repository pattern followed
- [ ] State management via Riverpod (not setState for shared state)
- [ ] Entities are immutable (Freezed)
- [ ] Proper error handling with Either/fpdart

### 3. Security
- [ ] No hardcoded API keys or secrets
- [ ] Proper input validation
- [ ] Secure data storage (no sensitive data in SharedPreferences)
- [ ] OAuth tokens handled securely

### 4. Performance
- [ ] No blocking operations on main thread
- [ ] Efficient list rendering (ListView.builder)
- [ ] Image caching
- [ ] Database queries optimized

### 5. iOS Specific
- [ ] App Group data sharing correct
- [ ] Entitlements properly configured
- [ ] Widget Extension code follows WidgetKit best practices

### 6. Android Specific
- [ ] Proper permission handling
- [ ] Battery optimization considered
- [ ] Widget update frequency appropriate

### 7. Localization
- [ ] All user-facing strings use `tr()`
- [ ] Translation keys exist in en.json and ko.json

## Output Format

```markdown
# Code Review: [File/Feature Name]

## Summary
- **Files Reviewed**: X
- **Issues Found**: P0: X, P1: X, P2: X, P3: X
- **Overall**: [PASS/NEEDS_CHANGES/CRITICAL]

## Issues

### P0 - Critical
| Location | Issue | Fix |
|----------|-------|-----|
| file:line | description | recommendation |

### P1 - High
| Location | Issue | Fix |
|----------|-------|-----|

### P2 - Medium
| Location | Issue | Fix |
|----------|-------|-----|

### P3 - Low
| Location | Issue | Fix |
|----------|-------|-----|

## Good Practices Observed
- [List positive observations]

## Recommendations
1. [Key recommendations]
```

## Execute Review
Read the specified files and perform the review now.
