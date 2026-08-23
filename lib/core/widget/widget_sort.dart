/// 홈 위젯의 할 일 정렬.
///
/// 위젯 서비스에서 떼어 둔 이유는 순수 함수로 테스트하기 위해서다.
/// 예전에는 이 로직이 `WidgetService` 안에 있었고, 그래서
/// "등록 순으로 나온다"는 결함이 테스트 없이 오래 남아 있었다.
library;

import 'package:todo_app/domain/entities/todo.dart';

/// 위젯에 보여 줄 순서로 정렬한다. **원본을 바꾸지 않는다.**
///
/// 기준은 "다음에 할 일" 이다. 마감이 가까운 것이 위에 온다.
///
/// 예전 구현은 `position`(드래그 순서)으로 정렬했다. `position` 은 할 일을
/// 만들 때 증가하므로 결과적으로 **등록 순**이 됐고, 11월 마감 일정이
/// 8월 일정보다 위에 뜨는 일이 생겼다.
List<Todo> sortTodosByUpcoming(List<Todo> todos, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final sorted = List<Todo>.from(todos);
  sorted.sort((a, b) => compareByUpcoming(a, b, today));
  return sorted;
}

/// [sortTodosByUpcoming] 의 비교 규칙.
///
/// 1. **기간이 오늘을 걸치는 일정이 최우선.** 진행 중인 출장·여행은
///    마감일이 며칠 뒤여도 지금 신경 써야 할 일이다.
/// 2. 마감일 오름차순 (가까운 것부터)
/// 3. 같은 날이면 알림 시각 오름차순
/// 4. 마감일이 없는 것은 맨 뒤
/// 5. 그래도 같으면 `position` — 사용자의 드래그 순서를 존중한다
int compareByUpcoming(Todo a, Todo b, DateTime today) {
  // 1. 기간 중인 일정 우선
  final aOngoing = a.isRanged && a.occursOn(today);
  final bOngoing = b.isRanged && b.occursOn(today);
  if (aOngoing != bOngoing) {
    return aOngoing ? -1 : 1;
  }

  // 2~4. 마감일
  final aDue = a.dueDate;
  final bDue = b.dueDate;
  if (aDue == null && bDue != null) return 1; // 마감 없는 것은 뒤로
  if (aDue != null && bDue == null) return -1;
  if (aDue != null && bDue != null) {
    final aDay = DateTime(aDue.year, aDue.month, aDue.day);
    final bDay = DateTime(bDue.year, bDue.month, bDue.day);
    final byDay = aDay.compareTo(bDay);
    if (byDay != 0) return byDay;

    // 3. 같은 날이면 알림 시각
    final aTime = a.notificationTime;
    final bTime = b.notificationTime;
    if (aTime == null && bTime != null) return 1; // 시각 없는 종일이 뒤
    if (aTime != null && bTime == null) return -1;
    if (aTime != null && bTime != null) {
      final byTime = aTime.compareTo(bTime);
      if (byTime != 0) return byTime;
    }
  }

  // 5. 사용자 드래그 순서
  return a.position.compareTo(b.position);
}

/// 위젯 항목 오른쪽에 표시할 라벨을 만든다.
///
/// 예전에는 알림 시간이 있으면 **날짜를 버리고 시각만** 넣었다.
/// 위젯이 "오늘 것만" 보여줄 때는 그래도 됐지만, 이제 다가오는 일정까지
/// 올라오므로 8/25 일정이 `09:00` 으로만 보여 며칠 뒤인지 알 수 없었다.
///
/// 규칙:
/// - 오늘 일정 → 시각만 (`09:00`). 오늘인 건 자명하다
/// - 다른 날 → 날짜 + 시각 (`8/25 09:00`), 시각이 없으면 날짜만 (`8/25`)
/// - 기간이 오늘을 걸치면 → `~종료일` (지금 진행 중임을 드러낸다)
/// - 마감일이 없으면 → 빈 문자열
String buildWidgetTimeLabel(Todo todo, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final due = todo.dueDate;
  if (due == null) return '';

  // 진행 중인 범위 일정은 "언제까지인가"가 가장 쓸모 있다.
  if (todo.isRanged && todo.occursOn(today)) {
    return '~${due.month}/${due.day}';
  }

  final isToday =
      due.year == today.year && due.month == today.month && due.day == today.day;

  String timePart = '';
  final notify = todo.notificationTime;
  if (notify != null) {
    timePart =
        '${notify.hour.toString().padLeft(2, '0')}:${notify.minute.toString().padLeft(2, '0')}';
  } else if (due.hour != 0 || due.minute != 0) {
    timePart =
        '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';
  }

  if (isToday) return timePart;

  final datePart = '${due.month}/${due.day}';
  return timePart.isEmpty ? datePart : '$datePart $timePart';
}
