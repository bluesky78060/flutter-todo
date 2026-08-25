/// 범위 일정의 날짜 계산 유틸.
///
/// 여기 있는 함수들은 순수 함수다. 타임존에 민감한 로직이라
/// `TZ` 를 바꿔 가며 테스트할 수 있도록 위젯·프로바이더에서 떼어 두었다.
library;

/// 기간 열거의 상한. 하루 단위로 1년 + 윤일.
///
/// 폼 검증과 **별개로** 필요하다. 폼을 거치지 않는 유입 경로가 있다 —
/// 백업 복원, Supabase 대시보드 직접 수정, 다른 기기의 구버전 앱.
/// 잘못된 행 하나(예: dueDate 가 9999년)가 들어오면 순회가 앱을 멈춘다.
const int kMaxRangeDays = 366;

/// 로컬 시간대 기준으로 시각을 버리고 날짜만 남긴다.
///
/// 날짜 비교와 맵 키 생성에 쓴다. Google Calendar 의 `date` 필드에는
/// [dateOnlyUtc] 를 써야 한다. Dart 에서 `DateTime.utc(y,m,d) == DateTime(y,m,d)`
/// 는 `isUtc` 까지 비교하므로 **false** 이며, 둘을 섞으면 조용히 어긋난다.
DateTime dateOnlyLocal(DateTime d) => DateTime(d.year, d.month, d.day);

/// UTC 기준으로 날짜만 남긴다. Google Calendar 의 종일 이벤트 `date` 전용.
///
/// googleapis 는 `date` 를 `toUtc()` 없이 `year/month/day` 로 직렬화하므로
/// 사용자의 로컬 달력 날짜가 그대로 나간다.
DateTime dateOnlyUtc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// [start] 부터 [end] 까지의 날짜를 열거한다. **양끝 포함**, 로컬 날짜 기준.
///
/// `Duration(days: 1)` 을 누적하지 않는다. DST 가 시작되는 날은 23시간이라
/// 커서가 다음 날로 넘어가지 못하고 **무한 루프**에 빠진다.
/// (예: 미국 2025-03-09. 한국은 DST 가 없지만 이 앱은 웹으로 배포되고
/// 브라우저 타임존은 통제할 수 없다.)
///
/// 대신 달력 필드로부터 매번 새로 구성한다. Dart 가 범위를 벗어난 day 를
/// 자동 정규화하므로 `DateTime(2025, 3, 32)` 는 `2025-04-01` 이 된다.
///
/// [start] 가 [end] 보다 뒤면 빈 목록을 돌려준다.
/// 길이는 [kMaxRangeDays] 로 잘린다.
List<DateTime> enumerateDays(DateTime start, DateTime end) {
  final from = dateOnlyLocal(start);
  final to = dateOnlyLocal(end);
  final result = <DateTime>[];

  for (var i = 0; i <= kMaxRangeDays; i++) {
    final day = DateTime(from.year, from.month, from.day + i);
    if (day.isAfter(to)) break;
    result.add(day);
  }

  return result;
}

/// 이 할 일에 기간(범위)을 설정할 수 있는가.
///
/// 반복과 기간은 함께 쓸 수 없다 (DTA-3-4 Discovery 합의).
/// RRULE 인스턴스 생성이 기간까지 복제해야 해서 복잡도가 크게 오른다.
///
/// **`recurrenceRule` 만 봐서는 안 된다.** 반복 *인스턴스* 는
/// `recurrenceRule` 을 갖지 않는다 — `RecurringTodoService` 가 인스턴스를 만들 때
/// `parentRecurringTodoId` 만 넘기기 때문이다.
/// 규칙만 검사하면 마스터는 막히고 인스턴스는 통과해 가드가 뚫린다.
bool canSetDateRange({
  required String? recurrenceRule,
  required int? parentRecurringTodoId,
}) {
  final hasRule = recurrenceRule != null && recurrenceRule.isNotEmpty;
  return !hasRule && parentRecurringTodoId == null;
}
