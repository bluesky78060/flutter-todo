import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/utils/date_range_utils.dart';

/// DTA-3-4 회귀 방지.
///
/// DST 경계 검증은 **로컬 타임존에 의존**한다. Dart 의 로컬 타임존은 프로세스
/// 시작 시 `TZ` 로 결정되고 테스트 중에는 바꿀 수 없다. 그래서 이 파일은
/// 게이트에서 별도 명령으로 돌린다:
///
/// ```
/// TZ=America/New_York flutter test test/unit/utils/date_range_test.dart
/// ```
///
/// KST(DST 없음)에서만 돌리면 이 테스트들은 자명하게 통과해 아무것도 지키지 못한다.
void main() {
  group('enumerateDays — 기본', () {
    test('양끝을 포함한다', () {
      final days = enumerateDays(DateTime(2025, 8, 21), DateTime(2025, 8, 25));

      expect(days.length, 5);
      expect(days.first, DateTime(2025, 8, 21));
      expect(days.last, DateTime(2025, 8, 25));
    });

    test('같은 날이면 하루만', () {
      final days = enumerateDays(DateTime(2025, 8, 21), DateTime(2025, 8, 21));
      expect(days, [DateTime(2025, 8, 21)]);
    });

    test('시작이 종료보다 뒤면 빈 목록', () {
      expect(enumerateDays(DateTime(2025, 8, 25), DateTime(2025, 8, 21)), isEmpty);
    });

    test('시각은 버리고 날짜만 남긴다', () {
      final days = enumerateDays(
        DateTime(2025, 8, 21, 23, 59),
        DateTime(2025, 8, 22, 0, 1),
      );
      expect(days, [DateTime(2025, 8, 21), DateTime(2025, 8, 22)]);
    });

    test('월 경계를 넘는다', () {
      final days = enumerateDays(DateTime(2025, 2, 27), DateTime(2025, 3, 2));
      expect(days, [
        DateTime(2025, 2, 27),
        DateTime(2025, 2, 28),
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 2),
      ]);
    });

    test('연 경계를 넘는다', () {
      final days = enumerateDays(DateTime(2025, 12, 31), DateTime(2026, 1, 1));
      expect(days, [DateTime(2025, 12, 31), DateTime(2026, 1, 1)]);
    });
  });

  group('enumerateDays — DST 경계 (TZ=America/New_York 에서 의미 있음)', () {
    test('서머타임 시작(3월 둘째 일요일)을 지나도 전진한다', () {
      // 2025-03-09 는 미국 서머타임 시작일이라 23시간짜리 하루다.
      // Duration(days: 1) 을 누적하면 커서가 3/9 에 갇혀 무한 루프에 빠진다.
      final days = enumerateDays(DateTime(2025, 3, 8), DateTime(2025, 3, 12));

      expect(days.length, 5, reason: '23시간짜리 하루가 0일로 깎이면 안 된다');
      expect(days[0], DateTime(2025, 3, 8));
      expect(days[1], DateTime(2025, 3, 9));
      expect(days[2], DateTime(2025, 3, 10));
      expect(days[4], DateTime(2025, 3, 12));
    });

    test('서머타임 종료(11월 첫째 일요일)를 지나도 중복이 없다', () {
      // 2025-11-02 는 25시간짜리 하루다.
      final days = enumerateDays(DateTime(2025, 11, 1), DateTime(2025, 11, 4));

      expect(days.length, 4);
      expect(days.toSet().length, 4, reason: '같은 날짜가 두 번 나오면 안 된다');
    });

    test('DST 경계를 포함한 긴 범위도 정확한 일수를 낸다', () {
      final days = enumerateDays(DateTime(2025, 3, 1), DateTime(2025, 3, 31));
      expect(days.length, 31);
    });
  });

  group('enumerateDays — 상한 방어', () {
    test('kMaxRangeDays 를 넘는 범위는 잘린다', () {
      // 폼 검증을 거치지 않는 유입 경로(백업 복원, 대시보드 직접 수정)에서
      // 잘못된 행이 들어와도 순회가 앱을 멈추지 않아야 한다.
      final days = enumerateDays(DateTime(2025, 1, 1), DateTime(9999, 12, 31));

      expect(days.length, kMaxRangeDays + 1);
      expect(days.length, lessThan(400));
    });
  });

  group('canSetDateRange — 반복 차단 가드 (CRITICAL 회귀 방지)', _guardTests);

  group('dateOnlyLocal / dateOnlyUtc', () {
    test('서로 같지 않다 — 섞어 쓰면 조용히 어긋난다', () {
      final d = DateTime(2025, 8, 21, 14, 30);
      expect(dateOnlyLocal(d) == dateOnlyUtc(d), isFalse,
          reason: 'DateTime 의 == 는 isUtc 까지 비교한다');
    });

    test('dateOnlyLocal 은 로컬, dateOnlyUtc 는 UTC 플래그를 갖는다', () {
      final d = DateTime(2025, 8, 21, 14, 30);
      expect(dateOnlyLocal(d).isUtc, isFalse);
      expect(dateOnlyUtc(d).isUtc, isTrue);
      expect(dateOnlyUtc(d), DateTime.utc(2025, 8, 21));
    });
  });
}

/// DTA-3-4 코드 리뷰 CRITICAL 회귀 방지.
///
/// 반복과 기간은 함께 쓸 수 없다. 그런데 반복 **인스턴스**는 `recurrenceRule` 을
/// 갖지 않는다 — `RecurringTodoService` 가 인스턴스를 만들 때
/// `parentRecurringTodoId` 만 넘기기 때문이다.
/// 규칙만 검사하는 가드는 마스터만 막고 인스턴스는 통과시켜 뚫린다.
void _guardTests() {
  test('평범한 할 일은 기간을 설정할 수 있다', () {
    expect(
      canSetDateRange(recurrenceRule: null, parentRecurringTodoId: null),
      isTrue,
    );
  });

  test('반복 마스터는 막힌다 (recurrenceRule 있음)', () {
    expect(
      canSetDateRange(
          recurrenceRule: 'FREQ=WEEKLY', parentRecurringTodoId: null),
      isFalse,
    );
  });

  test('반복 인스턴스도 막힌다 — recurrenceRule 이 null 이어도', () {
    expect(
      canSetDateRange(recurrenceRule: null, parentRecurringTodoId: 42),
      isFalse,
      reason: '인스턴스는 recurrenceRule 을 갖지 않는다. 규칙만 검사하면 '
          '사용자가 기간을 설정할 수 있고, 저장 시 그 값이 조용히 버려진다',
    );
  });

  test('빈 문자열 recurrenceRule 은 규칙이 없는 것으로 본다', () {
    expect(
      canSetDateRange(recurrenceRule: '', parentRecurringTodoId: null),
      isTrue,
    );
  });

  test('둘 다 있으면 막힌다', () {
    expect(
      canSetDateRange(recurrenceRule: 'FREQ=DAILY', parentRecurringTodoId: 7),
      isFalse,
    );
  });
}
