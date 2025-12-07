/// Holiday info model for displaying holiday details
class HolidayInfo {
  final int day;
  final String nameKo;
  final String nameEn;
  final String descriptionKo;
  final String descriptionEn;

  HolidayInfo({
    required this.day,
    required this.nameKo,
    required this.nameEn,
    required this.descriptionKo,
    required this.descriptionEn,
  });
}

/// Service to provide Korean public holidays
/// Uses hardcoded data for fixed holidays and calculated lunar dates
class KoreanHolidayService {
  // Cache holidays to avoid recalculation
  static final Map<String, Set<int>> _holidayCache = {};
  static final Map<String, List<HolidayInfo>> _holidayInfoCache = {};

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

  /// Get holiday names map for a specific month
  /// Returns a Map of day number to holiday name (Korean)
  static Future<Map<int, String>> getHolidayNamesForMonth(int year, int month) async {
    final holidayInfoList = await getHolidayInfoForMonth(year, month);
    final holidayNames = <int, String>{};

    for (final info in holidayInfoList) {
      holidayNames[info.day] = info.nameKo;
    }

    // Also add holiday days that might not have info (e.g., multi-day holidays)
    final holidays = await getHolidaysForMonth(year, month);
    for (final day in holidays) {
      if (!holidayNames.containsKey(day)) {
        // Find the closest holiday name (for multi-day holidays like 설날, 추석)
        for (final info in holidayInfoList) {
          if ((day - info.day).abs() <= 2) {
            holidayNames[day] = info.nameKo;
            break;
          }
        }
      }
    }

    return holidayNames;
  }

  /// Get holiday information (name and description) for a specific month
  static Future<List<HolidayInfo>> getHolidayInfoForMonth(int year, int month) async {
    final cacheKey = '$year-$month';

    if (_holidayInfoCache.containsKey(cacheKey)) {
      return _holidayInfoCache[cacheKey]!;
    }

    final List<HolidayInfo> holidayList = [];
    final fixedHolidays = _getFixedHolidayInfo(year);
    final lunarHolidays = _getLunarHolidayInfo(year);

    // Add fixed holidays for this month
    for (final holiday in fixedHolidays) {
      final holidayDay = holiday['day'] as int;
      if (holidayDay ~/ 100 == month) {
        final day = holidayDay % 100;
        holidayList.add(HolidayInfo(
          day: day,
          nameKo: holiday['nameKo'] as String,
          nameEn: holiday['nameEn'] as String,
          descriptionKo: holiday['descriptionKo'] as String,
          descriptionEn: holiday['descriptionEn'] as String,
        ));
      }
    }

    // Add lunar holidays for this month
    for (final holiday in lunarHolidays) {
      if (holiday['year'] == year && holiday['month'] == month) {
        holidayList.add(HolidayInfo(
          day: holiday['day'] as int,
          nameKo: holiday['nameKo'] as String,
          nameEn: holiday['nameEn'] as String,
          descriptionKo: holiday['descriptionKo'] as String,
          descriptionEn: holiday['descriptionEn'] as String,
        ));
      }
    }

    // Sort by day
    holidayList.sort((a, b) => a.day.compareTo(b.day));

    // Deduplicate holidays with the same name (keep only the first day)
    final uniqueHolidays = <String, HolidayInfo>{};
    for (final holiday in holidayList) {
      if (!uniqueHolidays.containsKey(holiday.nameKo)) {
        uniqueHolidays[holiday.nameKo] = holiday;
      }
    }

    final deduplicatedList = uniqueHolidays.values.toList();
    deduplicatedList.sort((a, b) => a.day.compareTo(b.day));

    _holidayInfoCache[cacheKey] = deduplicatedList;
    return deduplicatedList;
  }

  /// Get fixed Korean holidays with descriptions
  static List<Map<String, dynamic>> _getFixedHolidayInfo(int year) {
    return [
      {
        'day': 0101,
        'nameKo': '신정',
        'nameEn': "New Year's Day",
        'descriptionKo': '새해 첫날을 기념하는 날',
        'descriptionEn': 'Celebration of the first day of the new year',
      },
      {
        'day': 0301,
        'nameKo': '삼일절',
        'nameEn': 'Independence Movement Day',
        'descriptionKo': '1919년 3월 1일 독립운동을 기념하는 날',
        'descriptionEn': 'Commemorates the 1919 independence movement',
      },
      {
        'day': 0302,
        'nameKo': '삼일절 대체공휴일',
        'nameEn': 'Independence Movement Day (Alternative)',
        'descriptionKo': '삼일절이 주말과 겹칠 때 지정되는 대체 공휴일',
        'descriptionEn': 'Alternative holiday when Independence Movement Day overlaps weekend',
      },
      {
        'day': 0505,
        'nameKo': '어린이날',
        'nameEn': "Children's Day",
        'descriptionKo': '어린이의 인격을 존중하고 그 행복을 도모하기 위해 지정한 날',
        'descriptionEn': 'A day to celebrate and respect children',
      },
      {
        'day': 0606,
        'nameKo': '현충일',
        'nameEn': 'Memorial Day',
        'descriptionKo': '국가를 위해 헌신한 분들을 추도하는 날',
        'descriptionEn': 'Day of remembrance for those who died for the nation',
      },
      {
        'day': 0815,
        'nameKo': '광복절',
        'nameEn': 'Liberation Day',
        'descriptionKo': '1945년 8월 15일 한국 독립을 기념하는 날',
        'descriptionEn': 'Celebrates Korean independence on August 15, 1945',
      },
      {
        'day': 1003,
        'nameKo': '개천절',
        'nameEn': 'National Foundation Day',
        'descriptionKo': '단군왕검이 고조선을 건국한 것을 기념하는 날',
        'descriptionEn': 'Commemorates the founding of Gojoseon by Dangun',
      },
      {
        'day': 1009,
        'nameKo': '한글날',
        'nameEn': 'Hangul Day',
        'descriptionKo': '한글 창제를 기념하고 우리 글 한글의 우수성을 기리는 날',
        'descriptionEn': 'Celebrates the creation and excellence of Hangul',
      },
      {
        'day': 1225,
        'nameKo': '성탄절',
        'nameEn': 'Christmas',
        'descriptionKo': '예수 그리스도의 탄생을 축하하는 날',
        'descriptionEn': 'Celebrates the birth of Jesus Christ',
      },
    ];
  }

  /// Get lunar holidays with descriptions for specific years
  static List<Map<String, dynamic>> _getLunarHolidayInfo(int year) {
    const Map<int, List<Map<String, dynamic>>> lunarInfo = {
      2024: [
        {
          'year': 2024,
          'month': 2,
          'day': 9,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2024,
          'month': 2,
          'day': 10,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2024,
          'month': 2,
          'day': 11,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2024,
          'month': 2,
          'day': 12,
          'nameKo': '설날 대체공휴일',
          'nameEn': 'Lunar New Year (Alternative)',
          'descriptionKo': '설날이 주말과 겹칠 때 지정되는 대체 공휴일',
          'descriptionEn': 'Alternative holiday when Lunar New Year overlaps weekend',
        },
        {
          'year': 2024,
          'month': 5,
          'day': 15,
          'nameKo': '부처님오신날',
          'nameEn': "Buddha's Birthday",
          'descriptionKo': '불교의 창시자 석가모니 부처님의 탄생을 기념하는 명절',
          'descriptionEn': 'Celebrates the birth of Buddha',
        },
        {
          'year': 2024,
          'month': 9,
          'day': 16,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
        {
          'year': 2024,
          'month': 9,
          'day': 17,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
        {
          'year': 2024,
          'month': 9,
          'day': 18,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
      ],
      2025: [
        {
          'year': 2025,
          'month': 1,
          'day': 28,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2025,
          'month': 1,
          'day': 29,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2025,
          'month': 1,
          'day': 30,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2025,
          'month': 5,
          'day': 5,
          'nameKo': '부처님오신날',
          'nameEn': "Buddha's Birthday",
          'descriptionKo': '불교의 창시자 석가모니 부처님의 탄생을 기념하는 명절',
          'descriptionEn': 'Celebrates the birth of Buddha',
        },
        {
          'year': 2025,
          'month': 5,
          'day': 6,
          'nameKo': '부처님오신날 대체공휴일',
          'nameEn': "Buddha's Birthday (Alternative)",
          'descriptionKo': '부처님오신날이 어린이날과 겹칠 때 지정되는 대체 공휴일',
          'descriptionEn': 'Alternative holiday for Buddha\'s Birthday',
        },
        {
          'year': 2025,
          'month': 10,
          'day': 5,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
        {
          'year': 2025,
          'month': 10,
          'day': 6,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
        {
          'year': 2025,
          'month': 10,
          'day': 7,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
        {
          'year': 2025,
          'month': 10,
          'day': 8,
          'nameKo': '추석 대체공휴일',
          'nameEn': 'Chuseok (Alternative)',
          'descriptionKo': '추석이 주말과 겹칠 때 지정되는 대체 공휴일',
          'descriptionEn': 'Alternative holiday when Chuseok overlaps weekend',
        },
      ],
      2026: [
        {
          'year': 2026,
          'month': 2,
          'day': 16,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2026,
          'month': 2,
          'day': 17,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2026,
          'month': 2,
          'day': 18,
          'nameKo': '설날',
          'nameEn': 'Lunar New Year',
          'descriptionKo': '음력 1월 1일, 한 해를 시작하는 명절',
          'descriptionEn': 'First day of Lunar calendar, Korean New Year celebration',
        },
        {
          'year': 2026,
          'month': 5,
          'day': 24,
          'nameKo': '부처님오신날',
          'nameEn': "Buddha's Birthday",
          'descriptionKo': '불교의 창시자 석가모니 부처님의 탄생을 기념하는 명절',
          'descriptionEn': 'Celebrates the birth of Buddha',
        },
        {
          'year': 2026,
          'month': 5,
          'day': 25,
          'nameKo': '부처님오신날 대체공휴일',
          'nameEn': "Buddha's Birthday (Alternative)",
          'descriptionKo': '부처님오신날이 일요일과 겹칠 때 지정되는 대체 공휴일',
          'descriptionEn': 'Alternative holiday for Buddha\'s Birthday',
        },
        {
          'year': 2026,
          'month': 9,
          'day': 24,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
        {
          'year': 2026,
          'month': 9,
          'day': 25,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
        {
          'year': 2026,
          'month': 9,
          'day': 26,
          'nameKo': '추석',
          'nameEn': 'Chuseok',
          'descriptionKo': '음력 8월 15일, 가을 추수를 감사하는 명절',
          'descriptionEn': 'Harvest festival celebrated on 15th day of lunar August',
        },
      ],
    };

    return lunarInfo[year] ?? [];
  }
}
