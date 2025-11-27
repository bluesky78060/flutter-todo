/// Service to provide Korean public holidays
/// Uses hardcoded data for fixed holidays and calculated lunar dates
class KoreanHolidayService {
  // Cache holidays to avoid recalculation
  static final Map<String, Set<int>> _holidayCache = {};

  /// Get holidays for a specific month
  /// Returns a Set of day numbers that are holidays
  static Future<Set<int>> getHolidaysForMonth(int year, int month) async {
    final cacheKey = '$year-$month';

    // Check cache first
    if (_holidayCache.containsKey(cacheKey)) {
      print('🗓️ KoreanHolidayService: Using cached holidays for $year-$month');
      return _holidayCache[cacheKey]!;
    }

    final holidays = _getKoreanHolidays(year, month);
    _holidayCache[cacheKey] = holidays;
    print('🗓️ KoreanHolidayService: Found ${holidays.length} holidays for $year-$month: $holidays');
    return holidays;
  }

  /// Get Korean holidays for a specific year and month
  static Set<int> _getKoreanHolidays(int year, int month) {
    final holidays = <int>{};

    // Fixed holidays (양력 공휴일)
    final fixedHolidays = _getFixedHolidays(year);
    for (final holiday in fixedHolidays) {
      if (holiday.month == month) {
        holidays.add(holiday.day);
      }
    }

    // Lunar-based holidays (음력 공휴일) - pre-calculated for 2024-2030
    final lunarHolidays = _getLunarHolidays(year);
    for (final holiday in lunarHolidays) {
      if (holiday.month == month) {
        holidays.add(holiday.day);
      }
    }

    return holidays;
  }

  /// Fixed Korean holidays (양력 공휴일)
  static List<DateTime> _getFixedHolidays(int year) {
    return [
      DateTime(year, 1, 1),   // 신정 (New Year's Day)
      DateTime(year, 3, 1),   // 삼일절 (Independence Movement Day)
      DateTime(year, 5, 5),   // 어린이날 (Children's Day)
      DateTime(year, 6, 6),   // 현충일 (Memorial Day)
      DateTime(year, 8, 15),  // 광복절 (Liberation Day)
      DateTime(year, 10, 3),  // 개천절 (National Foundation Day)
      DateTime(year, 10, 9),  // 한글날 (Hangul Day)
      DateTime(year, 12, 25), // 성탄절 (Christmas)
    ];
  }

  /// Lunar-based Korean holidays (음력 공휴일)
  /// Pre-calculated solar dates for major lunar holidays
  static List<DateTime> _getLunarHolidays(int year) {
    // 설날 (Lunar New Year): 음력 1월 1일 전후 3일
    // 부처님오신날 (Buddha's Birthday): 음력 4월 8일
    // 추석 (Chuseok): 음력 8월 15일 전후 3일

    final lunarHolidaysMap = <int, List<DateTime>>{
      2024: [
        // 설날 (2024년 2월 9-11일)
        DateTime(2024, 2, 9),
        DateTime(2024, 2, 10),
        DateTime(2024, 2, 11),
        DateTime(2024, 2, 12), // 대체공휴일
        // 부처님오신날 (2024년 5월 15일)
        DateTime(2024, 5, 15),
        // 추석 (2024년 9월 16-18일)
        DateTime(2024, 9, 16),
        DateTime(2024, 9, 17),
        DateTime(2024, 9, 18),
      ],
      2025: [
        // 설날 (2025년 1월 28-30일)
        DateTime(2025, 1, 28),
        DateTime(2025, 1, 29),
        DateTime(2025, 1, 30),
        // 부처님오신날 (2025년 5월 5일) - 어린이날과 겹침
        DateTime(2025, 5, 5),
        DateTime(2025, 5, 6), // 대체공휴일
        // 추석 (2025년 10월 5-7일)
        DateTime(2025, 10, 5),
        DateTime(2025, 10, 6),
        DateTime(2025, 10, 7),
        DateTime(2025, 10, 8), // 대체공휴일
      ],
      2026: [
        // 설날 (2026년 2월 16-18일)
        DateTime(2026, 2, 16),
        DateTime(2026, 2, 17),
        DateTime(2026, 2, 18),
        // 부처님오신날 (2026년 5월 24일)
        DateTime(2026, 5, 24),
        DateTime(2026, 5, 25), // 대체공휴일 (일요일)
        // 추석 (2026년 9월 24-26일)
        DateTime(2026, 9, 24),
        DateTime(2026, 9, 25),
        DateTime(2026, 9, 26),
      ],
      2027: [
        // 설날 (2027년 2월 5-7일)
        DateTime(2027, 2, 5),
        DateTime(2027, 2, 6),
        DateTime(2027, 2, 7),
        DateTime(2027, 2, 8), // 대체공휴일
        // 부처님오신날 (2027년 5월 13일)
        DateTime(2027, 5, 13),
        // 추석 (2027년 9월 14-16일)
        DateTime(2027, 9, 14),
        DateTime(2027, 9, 15),
        DateTime(2027, 9, 16),
      ],
      2028: [
        // 설날 (2028년 1월 25-27일)
        DateTime(2028, 1, 25),
        DateTime(2028, 1, 26),
        DateTime(2028, 1, 27),
        // 부처님오신날 (2028년 5월 2일)
        DateTime(2028, 5, 2),
        // 추석 (2028년 10월 2-4일)
        DateTime(2028, 10, 2),
        DateTime(2028, 10, 3), // 개천절과 겹침
        DateTime(2028, 10, 4),
        DateTime(2028, 10, 5), // 대체공휴일
      ],
      2029: [
        // 설날 (2029년 2월 12-14일)
        DateTime(2029, 2, 12),
        DateTime(2029, 2, 13),
        DateTime(2029, 2, 14),
        // 부처님오신날 (2029년 5월 20일)
        DateTime(2029, 5, 20),
        DateTime(2029, 5, 21), // 대체공휴일 (일요일)
        // 추석 (2029년 9월 21-23일)
        DateTime(2029, 9, 21),
        DateTime(2029, 9, 22),
        DateTime(2029, 9, 23),
        DateTime(2029, 9, 24), // 대체공휴일
      ],
      2030: [
        // 설날 (2030년 2월 2-4일)
        DateTime(2030, 2, 2),
        DateTime(2030, 2, 3),
        DateTime(2030, 2, 4),
        // 부처님오신날 (2030년 5월 9일)
        DateTime(2030, 5, 9),
        // 추석 (2030년 9월 11-13일)
        DateTime(2030, 9, 11),
        DateTime(2030, 9, 12),
        DateTime(2030, 9, 13),
      ],
    };

    return lunarHolidaysMap[year] ?? [];
  }

  /// Clear the cache
  static void clearCache() {
    _holidayCache.clear();
    print('🗓️ KoreanHolidayService: Cache cleared');
  }

  /// Check if a specific day is a holiday
  static Future<bool> isHoliday(int year, int month, int day) async {
    final holidays = await getHolidaysForMonth(year, month);
    return holidays.contains(day);
  }
}
