# 다국가 휴일 지원 아키텍처 가이드

**문서 작성일**: 2025-12-01
**상태**: Design Document (미구현)
**우선순위**: 🟡 Medium
**예상 복잡도**: 중상

---

## 1. 개요

현재 앱은 **한국 휴일만** 달력에 표시합니다. 이 문서는 사용자가 환경설정에서 국가를 선택하면 해당 국가의 휴일을 표시하는 다국가 휴일 지원 아키텍처를 설명합니다.

### 목표
- ✅ 사용자가 Settings에서 휴일 표시 국가를 선택
- ✅ 선택된 국가의 휴일만 캘린더에 표시
- ✅ 국가별 Holiday Service 확장 가능하도록 설계
- ✅ 성능 최적화 (캐싱, 불필요한 호출 제거)

---

## 2. 현재 상태

### 기존 구조
```
lib/
└── core/services/
    └── korean_holiday_service.dart (한국 휴일만 지원)
        ├── Fixed holidays (양력): 1월 1일, 3월 1일, ... (8개)
        ├── Lunar holidays (음력): 설날, 부처님오신날, 추석 (2024-2030 사전계산)
        └── Caching: 월별 캐시로 성능 최적화
```

### 문제점
1. 한국만 고정 지원
2. 다른 국가 추가 시 코드 중복 불가피
3. 사용자 선택 옵션 없음

---

## 3. 제안된 아키텍처

### 3.1 HolidayService 추상 인터페이스

```dart
// lib/core/services/holiday_service.dart

/// 휴일 서비스 추상 인터페이스
abstract class HolidayService {
  /// 특정 월의 휴일 목록 반환
  /// Returns: Set<int> - 해당 월의 휴일 날짜 번호 집합
  Future<Set<int>> getHolidaysForMonth(int year, int month);

  /// 특정 날짜가 휴일인지 확인
  Future<bool> isHoliday(int year, int month, int day);

  /// 캐시 초기화
  void clearCache();
}
```

### 3.2 지원할 국가 목록 (Enum)

```dart
// lib/core/services/holiday_region.dart

/// 지원하는 휴일 국가/지역
enum HolidayRegion {
  /// 대한민국
  korea(
    code: 'ko',
    displayName: '🇰🇷 한국',
    className: 'KoreanHolidayService',
  ),

  /// 미국
  usa(
    code: 'us',
    displayName: '🇺🇸 미국',
    className: 'USHolidayService',
  ),

  /// 일본
  japan(
    code: 'ja',
    displayName: '🇯🇵 일본',
    className: 'JapanHolidayService',
  ),

  /// 영국
  uk(
    code: 'gb',
    displayName: '🇬🇧 영국',
    className: 'UKHolidayService',
  );

  final String code;
  final String displayName;
  final String className;

  const HolidayRegion({
    required this.code,
    required this.displayName,
    required this.className,
  });
}
```

### 3.3 Factory 패턴 구현

```dart
// lib/core/services/holiday_service_factory.dart

/// 국가별 HolidayService 생성 팩토리
class HolidayServiceFactory {
  static final Map<String, HolidayService> _instances = {};

  /// 지정된 국가의 HolidayService 반환 (Singleton)
  static HolidayService createService(String countryCode) {
    // 이미 생성된 인스턴스 재사용 (싱글톤)
    if (_instances.containsKey(countryCode)) {
      return _instances[countryCode]!;
    }

    final service = switch (countryCode) {
      'ko' => KoreanHolidayService(),
      'us' => USHolidayService(),
      'ja' => JapanHolidayService(),
      'gb' => UKHolidayService(),
      _ => KoreanHolidayService(), // 기본값: 한국
    };

    _instances[countryCode] = service;
    return service;
  }

  /// 특정 국가로 서비스 생성 (Enum 사용)
  static HolidayService createServiceByRegion(HolidayRegion region) {
    return createService(region.code);
  }
}
```

### 3.4 구체적 구현 - KoreanHolidayService (기존)

```dart
// lib/core/services/korean_holiday_service.dart

class KoreanHolidayService implements HolidayService {
  static final Map<String, Set<int>> _holidayCache = {};

  @override
  Future<Set<int>> getHolidaysForMonth(int year, int month) async {
    final cacheKey = '$year-$month';

    if (_holidayCache.containsKey(cacheKey)) {
      print('🗓️ KoreanHolidayService: Cache hit for $cacheKey');
      return _holidayCache[cacheKey]!;
    }

    final holidays = _getKoreanHolidays(year, month);
    _holidayCache[cacheKey] = holidays;
    return holidays;
  }

  @override
  Future<bool> isHoliday(int year, int month, int day) async {
    final holidays = await getHolidaysForMonth(year, month);
    return holidays.contains(day);
  }

  @override
  void clearCache() {
    _holidayCache.clear();
  }

  static Set<int> _getKoreanHolidays(int year, int month) {
    final holidays = <int>{};

    // 양력 공휴일
    final fixedHolidays = _getFixedHolidays(year);
    for (final holiday in fixedHolidays) {
      if (holiday.month == month) {
        holidays.add(holiday.day);
      }
    }

    // 음력 공휴일
    final lunarHolidays = _getLunarHolidays(year);
    for (final holiday in lunarHolidays) {
      if (holiday.month == month) {
        holidays.add(holiday.day);
      }
    }

    return holidays;
  }

  // ... 기존 _getFixedHolidays, _getLunarHolidays 메서드 유지
}
```

### 3.5 구체적 구현 - USHolidayService (신규)

```dart
// lib/core/services/us_holiday_service.dart

class USHolidayService implements HolidayService {
  static final Map<String, Set<int>> _holidayCache = {};

  @override
  Future<Set<int>> getHolidaysForMonth(int year, int month) async {
    final cacheKey = '$year-$month';

    if (_holidayCache.containsKey(cacheKey)) {
      return _holidayCache[cacheKey]!;
    }

    final holidays = _getUSHolidays(year, month);
    _holidayCache[cacheKey] = holidays;
    return holidays;
  }

  @override
  Future<bool> isHoliday(int year, int month, int day) async {
    final holidays = await getHolidaysForMonth(year, month);
    return holidays.contains(day);
  }

  @override
  void clearCache() {
    _holidayCache.clear();
  }

  static Set<int> _getUSHolidays(int year, int month) {
    final holidays = <int>{};

    // 고정 휴일
    const fixedHolidays = {
      1: 1,    // New Year's Day
      7: 4,    // Independence Day
      11: 28,  // Thanksgiving (placeholder, needs calculation)
      12: 25,  // Christmas
    };

    if (fixedHolidays.containsKey(month)) {
      holidays.add(fixedHolidays[month]!);
    }

    // Thanksgiving: 11월 4번째 목요일
    if (month == 11) {
      int thursdayCount = 0;
      for (int day = 1; day <= 30; day++) {
        final date = DateTime(year, month, day);
        if (date.weekday == DateTime.thursday) {
          thursdayCount++;
          if (thursdayCount == 4) {
            holidays.add(day);
            break;
          }
        }
      }
    }

    // Memorial Day: 5월 마지막 월요일
    if (month == 5) {
      for (int day = 31; day >= 1; day--) {
        final date = DateTime(year, month, day);
        if (date.weekday == DateTime.monday) {
          holidays.add(day);
          break;
        }
      }
    }

    return holidays;
  }
}
```

---

## 4. Riverpod 상태 관리

### 4.1 Settings Provider

```dart
// lib/presentation/providers/settings_providers.dart

/// 선택된 휴일 국가 저장
final selectedHolidayRegionProvider = StateProvider<HolidayRegion>(
  (ref) => HolidayRegion.korea,
  name: 'selectedHolidayRegion',
);

/// 선택된 국가의 특정 월 휴일 조회
final holidaysProvider = FutureProvider.family<Set<int>, (int year, int month)>(
  (ref, params) async {
    final region = ref.watch(selectedHolidayRegionProvider);
    final (year, month) = params;

    final service = HolidayServiceFactory.createServiceByRegion(region);
    final holidays = await service.getHolidaysForMonth(year, month);

    print('📅 Loaded holidays for $region: ${holidays.length} days');
    return holidays;
  },
  name: 'holidays',
);
```

### 4.2 영속성 (SharedPreferences)

```dart
// lib/presentation/providers/settings_providers.dart (추가)

/// 선택된 휴일 국가를 SharedPreferences에 저장
final persistedHolidayRegionProvider =
  FutureProvider<HolidayRegion>((ref) async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('holiday_region') ?? 'ko';

    return HolidayRegion.values.firstWhere(
      (region) => region.code == code,
      orElse: () => HolidayRegion.korea,
    );
  });
```

---

## 5. UI 구현

### 5.1 Settings 화면 - 국가 선택

```dart
// lib/presentation/screens/settings_screen.dart (추가 부분)

class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedHolidayRegionProvider);
    final isDarkMode = ref.watch(themeProvider);

    return ListView(
      children: [
        // ... 기존 설정 항목들 ...

        SizedBox(height: 20),

        // 휴일 표시 국가 설정
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'calendar_settings'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDarkMode),
            ),
          ),
        ),
        SizedBox(height: 12),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.getCard(isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(isDarkMode).withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            title: Text('holiday_country'.tr()),
            subtitle: Text(selectedRegion.displayName),
            trailing: Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
            onTap: () => _showHolidayRegionPicker(context, ref, isDarkMode),
          ),
        ),
      ],
    );
  }

  void _showHolidayRegionPicker(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        title: Text(
          'select_holiday_region'.tr(),
          style: TextStyle(color: AppColors.getText(isDarkMode)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HolidayRegion.values.map((region) {
            final isSelected =
              ref.watch(selectedHolidayRegionProvider) == region;

            return ListTile(
              title: Text(
                region.displayName,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.getText(isDarkMode),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      FluentIcons.checkmark_24_regular,
                      color: AppColors.primaryBlue,
                    )
                  : null,
              onTap: () async {
                // Provider 상태 업데이트
                ref
                    .read(selectedHolidayRegionProvider.notifier)
                    .state = region;

                // SharedPreferences에 저장
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('holiday_region', region.code);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
```

### 5.2 Calendar 화면 - 동적 휴일 표시

```dart
// lib/presentation/screens/calendar_screen.dart (수정)

class CalendarScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final selectedRegion = ref.watch(selectedHolidayRegionProvider);

    // 현재 월의 휴일 로드
    final holidaysAsync = ref.watch(
      holidaysProvider((_focusedDay.year, _focusedDay.month))
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${selectedRegion.displayName} '
          '${_focusedDay.year}년 ${_focusedDay.month}월',
        ),
      ),
      body: holidaysAsync.when(
        data: (holidays) {
          return TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isHoliday = holidays.contains(day.day);
                final isWeekend = day.weekday == DateTime.saturday ||
                                  day.weekday == DateTime.sunday;
                return _buildCalendarDay(
                  day,
                  isHoliday,
                  isDarkMode,
                  isWeekend,
                  false,
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                final isHoliday = holidays.contains(day.day);
                return _buildCalendarDay(
                  day,
                  isHoliday,
                  isDarkMode,
                  false,
                  true,
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final isHoliday = holidays.contains(day.day);
                return _buildCalendarDay(
                  day,
                  isHoliday,
                  isDarkMode,
                  false,
                  false,
                  isToday: true,
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final isHoliday = holidays.contains(day.day);
                return _buildCalendarDay(
                  day,
                  isHoliday,
                  isDarkMode,
                  false,
                  false,
                  isSelected: true,
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'failed_to_load_holidays'.tr(),
            style: TextStyle(color: AppColors.dangerRed),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDay(
    DateTime day,
    bool isHoliday,
    bool isDarkMode,
    bool isWeekend,
    bool isOutside, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    // 기존 _buildCalendarDay 로직 유지
    // (holiday 파라미터만 추가되었을 뿐 렌더링 로직은 동일)
    // ...
  }
}
```

---

## 6. 다국화 지원

### 6.1 번역 문자열 추가

```json
// assets/translations/en.json (추가)
{
  "calendar_settings": "Calendar Settings",
  "holiday_country": "Holiday Country",
  "select_holiday_region": "Select Holiday Region",
  "failed_to_load_holidays": "Failed to load holidays"
}

// assets/translations/ko.json (추가)
{
  "calendar_settings": "달력 설정",
  "holiday_country": "휴일 국가",
  "select_holiday_region": "휴일 국가 선택",
  "failed_to_load_holidays": "휴일을 불러올 수 없습니다"
}
```

---

## 7. 구현 체크리스트

### Phase 1: 기초 구조 (1-2일)
- [ ] `holiday_service.dart` - 추상 인터페이스 생성
- [ ] `holiday_region.dart` - Enum 정의
- [ ] `holiday_service_factory.dart` - Factory 패턴 구현
- [ ] 기존 `KoreanHolidayService` → 인터페이스 상속

### Phase 2: 추가 국가 구현 (1-2일)
- [ ] `us_holiday_service.dart` - 미국 휴일 (고정 + 계산식)
- [ ] `japan_holiday_service.dart` - 일본 휴일
- [ ] `uk_holiday_service.dart` - 영국 휴일

### Phase 3: Riverpod 통합 (1일)
- [ ] `settings_providers.dart` - Provider 추가
- [ ] SharedPreferences 영속성 구현
- [ ] 앱 시작 시 저장된 설정 로드

### Phase 4: UI 구현 (1-2일)
- [ ] Settings 화면 - 국가 선택 UI
- [ ] Calendar 화면 - 동적 휴일 표시 수정
- [ ] 빌드 및 테스트

### Phase 5: 완성 및 검증 (1일)
- [ ] 모든 국가별 휴일 테스트
- [ ] 성능 검증 (캐싱 동작)
- [ ] Release APK 빌드 및 기기 테스트

---

## 8. 성능 고려사항

### 캐싱 전략
```
월별 캐시 (Key: "$year-$month")
├─ KoreanHolidayService: _holidayCache (static)
├─ USHolidayService: _holidayCache (static)
├─ JapanHolidayService: _holidayCache (static)
└─ UKHolidayService: _holidayCache (static)
```

**특징**:
- 각 서비스별 독립 캐시 (중복 없음)
- 싱글톤 인스턴스로 서비스 재사용
- 월 변경 시에만 새로운 호출

### 메모리 사용
- 한 해(12개월) × 서비스당: ~48 bytes (Set<int> 12개)
- 전체 7년(2024-2030): ~3KB 미만

---

## 9. 향후 개선

### API 기반 휴일 조회 (선택사항)
```dart
// 공개 API 활용 (예: Nager.Date)
// https://date.nager.at/api/v3/publicholidays/{year}/{countryCode}
class APIHolidayService implements HolidayService {
  static const String baseUrl = 'https://date.nager.at/api/v3/publicholidays';

  @override
  Future<Set<int>> getHolidaysForMonth(int year, int month) async {
    // API 호출로 최신 휴일 데이터 동적 로드
  }
}
```

**장점**: 새 휴일 추가 시 앱 업데이트 불필요
**단점**: 네트워크 의존, 오프라인 미지원

### 사용자 정의 휴일 (나중 버전)
- 개인 휴일/기념일 추가
- 회사 휴일 설정
- 지역별 휴일 커스터마이징

---

## 10. 참고 자료

### 각 국가별 휴일 정보
- **한국**: 공휴일법 (행정안전부)
- **미국**: Federal Holidays (whitehouse.gov)
- **일본**: 국민의 날 (일본 내각부)
- **영국**: Bank Holidays (gov.uk)

### 외부 API
- [Nager.Date](https://date.nager.at/): 130+ 국가 지원
- [Abstract API](https://www.abstractapi.com/api/holidays): Holidays API
- [Calendarific](https://calendarific.com/): Holiday API

---

## 11. 결론

이 아키텍처는 다음을 보장합니다:
- ✅ 확장성: 새 국가 추가 시 새 Service 클래스만 생성
- ✅ 유지보수성: 각 국가 로직이 독립적
- ✅ 성능: 캐싱과 싱글톤으로 최적화
- ✅ 사용자 맞춤: 설정에서 국가 선택 가능
- ✅ 오프라인 지원: 하드코딩된 데이터 사용

**예상 개발 기간**: 5-7일
**복잡도**: 중상
**테스트 난이도**: 낮음 (각 국가별 모의 테스트 용이)
