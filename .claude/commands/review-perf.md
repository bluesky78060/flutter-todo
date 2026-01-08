# /review-perf - Performance Code Review

You are a performance engineer reviewing code for optimization opportunities.

## Target
$ARGUMENTS

If no files specified, review performance-critical areas:
- lib/presentation/screens/
- lib/presentation/widgets/
- lib/data/repositories/

## Performance Checks

### 1. Flutter Widget Performance
- [ ] Unnecessary widget rebuilds
- [ ] Missing `const` constructors
- [ ] Large widget trees without optimization
- [ ] Expensive operations in `build()` method
- [ ] `setState()` scope too broad

```dart
// BAD: Entire widget rebuilds
setState(() {
  _counter++;
});

// GOOD: Use Riverpod select for granular rebuilds
ref.watch(provider.select((s) => s.specificField))
```

### 2. List Performance
- [ ] Using `ListView.builder` for long lists
- [ ] `itemExtent` specified for fixed-height items
- [ ] Keys provided for list items
- [ ] Virtualization for very long lists

```dart
// BAD
ListView(
  children: items.map((i) => ItemWidget(i)).toList(),
)

// GOOD
ListView.builder(
  itemCount: items.length,
  itemBuilder: (ctx, i) => ItemWidget(key: ValueKey(items[i].id), items[i]),
)
```

### 3. State Management
- [ ] Providers properly scoped
- [ ] No unnecessary provider watches
- [ ] Using `select` for partial state
- [ ] Avoiding `watch` in callbacks

### 4. Database Performance
- [ ] Indexed columns for frequent queries
- [ ] Batch operations for multiple inserts
- [ ] Lazy loading for large datasets
- [ ] No N+1 query problems

### 5. Network Performance
- [ ] Request caching
- [ ] Image caching
- [ ] Connection pooling
- [ ] Timeout configuration

### 6. Memory Management
- [ ] Controllers disposed
- [ ] Streams closed
- [ ] Large objects released
- [ ] Image memory management

### 7. Startup Performance
- [ ] Lazy initialization
- [ ] Deferred loading
- [ ] Splash screen optimization

## Analysis Commands

```bash
# Find large files that might need optimization
find lib -name "*.dart" -exec wc -l {} \; | sort -rn | head -20

# Find potential expensive build methods
grep -rn "Widget build" lib/presentation --include="*.dart" -A 50 | grep -E "(Future|async|await)"
```

## Output Format

```markdown
# Performance Review Report

**Files Reviewed**: [count]
**Optimization Opportunities**: [count]

## High Impact Optimizations
| Location | Issue | Impact | Solution |
|----------|-------|--------|----------|

## Medium Impact Optimizations
| Location | Issue | Impact | Solution |
|----------|-------|--------|----------|

## Low Impact / Nice to Have
| Location | Issue | Impact | Solution |
|----------|-------|--------|----------|

## Metrics to Monitor
- Widget rebuild count
- Frame rendering time
- Memory usage
- Network latency

## Recommendations
1. [Priority recommendations with expected impact]
```

## Execute Performance Review
