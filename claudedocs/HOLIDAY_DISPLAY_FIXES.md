# Holiday Display Bug Fixes

## Summary
Fixed two critical bugs in the holiday display system:
1. 설날 (Lunar New Year) not showing in calendar for February 2026
2. 3.1절 (Independence Movement Day) appearing multiple times in holiday list

## Root Causes Identified

### Issue 1: Missing 2026 Lunar Holiday Data
**Problem**: The `_getLunarHolidayInfo()` method in `korean_holiday_service.dart` was missing the 2026 lunar holiday data. While the `_getLunarHolidays()` method had the correct DateTime objects for February 16-18, 2026, the `_getLunarHolidayInfo()` method (which returns holiday metadata like names and descriptions) did not include any entries for 2026.

**Impact**: When navigating to February 2026, the calendar showed the orange marker dots for the 16th-18th (from `_getKoreanHolidays()`), but the holiday list section below the calendar was empty because `getHolidayInfoForMonth()` had no data to display.

**Solution**: Added complete 2026 lunar holiday data to `_getLunarHolidayInfo()`:
```dart
2026: [
  // 설날 (Feb 16-18)
  { 'year': 2026, 'month': 2, 'day': 16, 'nameKo': '설날', ... },
  { 'year': 2026, 'month': 2, 'day': 17, 'nameKo': '설날', ... },
  { 'year': 2026, 'month': 2, 'day': 18, 'nameKo': '설날', ... },
  // 부처님오신날 (May 24-25)
  // 추석 (Sep 24-26)
  // ... all other 2026 holidays
]
```

### Issue 2: Holiday Duplication in Display
**Problem**: Multi-day holidays (설날 spans 3 days, 추석 spans 3 days, etc.) were being displayed as separate entries in the holiday list, making it appear as if the same holiday occurred multiple times.

**Impact**: In the "이달의 휴일" (Holidays This Month) section, users would see:
```
설날  (Feb 16)
설날  (Feb 17)
설날  (Feb 18)
```
Instead of just:
```
설날  (Feb 16)
```

**Solution**: Implemented deduplication in `getHolidayInfoForMonth()` by keeping only the first occurrence of each holiday name (by Korean name `nameKo`):
```dart
// Deduplicate holidays with the same name (keep only the first day)
final uniqueHolidays = <String, HolidayInfo>{};
for (final holiday in holidayList) {
  if (!uniqueHolidays.containsKey(holiday.nameKo)) {
    uniqueHolidays[holiday.nameKo] = holiday;
  }
}

final deduplicatedList = uniqueHolidays.values.toList();
deduplicatedList.sort((a, b) => a.day.compareTo(b.day));
```

## Files Modified

### lib/core/services/korean_holiday_service.dart
- Added 2026 lunar holiday data (8 entries: 설날 3 days, 부처님오신날 2 days, 추석 3 days)
- Implemented deduplication logic in `getHolidayInfoForMonth()` method
- Maintains sorting by day after deduplication

## Testing

### Before Fix (February 2026)
- Calendar markers showed orange dots on 16, 17, 18 ✓
- Holiday list section: **Empty** (no holiday info displayed) ✗
- Would show 3 separate "삼일절" entries in March if there was multi-day data ✗

### After Fix (February 2026)
- Calendar markers show orange dots on 16, 17, 18 ✓
- Holiday list section shows: **설날** (with description) ✓
- Only one entry per holiday name, regardless of number of days ✓

## Data Structure Consistency

### Two Parallel Holiday Systems
The app maintains two parallel systems for managing holidays:

1. **`_getKoreanHolidays()` / `_getLunarHolidays()`**
   - Returns `DateTime` objects or just day numbers
   - Used for calendar marker display (orange dots)
   - Keeps all days separate (needed for calendar rendering)

2. **`_getFixedHolidayInfo()` / `_getLunarHolidayInfo()`**
   - Returns `Map<String, dynamic>` with holiday metadata
   - Used for holiday list display (names and descriptions)
   - Needs deduplication to avoid repetition

### 2026 Lunar Holiday Dates (Verified)
- 설날: February 16-18 (대체공휴일 없음)
- 부처님오신날: May 24-25 (일요일이므로 대체공휴일 May 25)
- 추석: September 24-26 (정기휴일만, 대체공휴일 없음)

## Performance Impact
- **Memory**: Minimal - deduplication creates a temporary Map that's immediately converted to a List
- **CPU**: Negligible - O(n) deduplication for a small fixed set of holidays
- **Caching**: Deduplication result is cached in `_holidayInfoCache`, so future requests for the same month are instant

## Future Considerations

### Scaling to Multiple Years
If adding more years, remember to update both:
1. `_getLunarHolidays()` with DateTime objects (for calendar markers)
2. `_getLunarHolidayInfo()` with Map entries (for display)

### Internationalization
The deduplication key uses `nameKo` (Korean name). If adding more languages, consider:
- Using a unique identifier instead of `nameKo`
- Or deduplicating by a shared ID field

### Maintenance Checklist
When adding new holiday years:
- [ ] Add DateTime entries to `_getLunarHolidays()` for calendar markers
- [ ] Add Map entries to `_getLunarHolidayInfo()` with bilingual names/descriptions
- [ ] Verify lunar date conversions from official Korean government sources
- [ ] Test all three months (설날, 부처님오신날, 추석) display correctly
- [ ] Check that deduplication works (no duplicate names in output)

## Commit Information
- **Hash**: c0d3eb5
- **Date**: 2025-12-01
- **Message**: "fix: Fix holiday display bugs - add 2026 lunar holiday data and deduplicate holidays"
- **Files Changed**: 2 (korean_holiday_service.dart, pubspec.yaml.backup)
- **Insertions**: +90, **Deletions**: -2
