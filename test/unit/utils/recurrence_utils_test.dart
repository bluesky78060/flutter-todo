import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';

void main() {
  group('RecurrenceUtils', () {
    group('parseRRule', () {
      test('parses valid RRULE string with prefix', () {
        final result = RecurrenceUtils.parseRRule('RRULE:FREQ=DAILY;INTERVAL=1');
        expect(result, isNotNull);
      });

      test('parses valid RRULE string without prefix', () {
        final result = RecurrenceUtils.parseRRule('FREQ=DAILY;INTERVAL=1');
        expect(result, isNotNull);
      });

      test('returns null for empty string', () {
        final result = RecurrenceUtils.parseRRule('');
        expect(result, isNull);
      });

      test('returns null for null input', () {
        final result = RecurrenceUtils.parseRRule(null);
        expect(result, isNull);
      });

      test('returns null for invalid RRULE', () {
        final result = RecurrenceUtils.parseRRule('INVALID_RRULE');
        expect(result, isNull);
      });
    });

    group('getNextOccurrences', () {
      test('returns daily occurrences', () {
        final startDate = DateTime.utc(2025, 1, 1, 10, 0);
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'FREQ=DAILY;INTERVAL=1',
          startDate,
          count: 5,
        );

        expect(occurrences.length, 5);
        expect(occurrences[0], DateTime.utc(2025, 1, 1, 10, 0));
        expect(occurrences[1], DateTime.utc(2025, 1, 2, 10, 0));
        expect(occurrences[2], DateTime.utc(2025, 1, 3, 10, 0));
        expect(occurrences[3], DateTime.utc(2025, 1, 4, 10, 0));
        expect(occurrences[4], DateTime.utc(2025, 1, 5, 10, 0));
      });

      test('returns weekly occurrences', () {
        final startDate = DateTime.utc(2025, 1, 1, 10, 0); // Monday
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'FREQ=WEEKLY;INTERVAL=1',
          startDate,
          count: 3,
        );

        expect(occurrences.length, 3);
        expect(occurrences[0], DateTime.utc(2025, 1, 1, 10, 0));
        expect(occurrences[1], DateTime.utc(2025, 1, 8, 10, 0));
        expect(occurrences[2], DateTime.utc(2025, 1, 15, 10, 0));
      });

      test('returns monthly occurrences', () {
        final startDate = DateTime.utc(2025, 1, 15, 10, 0);
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'FREQ=MONTHLY;INTERVAL=1',
          startDate,
          count: 3,
        );

        expect(occurrences.length, 3);
        expect(occurrences[0], DateTime.utc(2025, 1, 15, 10, 0));
        expect(occurrences[1], DateTime.utc(2025, 2, 15, 10, 0));
        expect(occurrences[2], DateTime.utc(2025, 3, 15, 10, 0));
      });

      test('respects interval parameter', () {
        final startDate = DateTime.utc(2025, 1, 1, 10, 0);
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'FREQ=DAILY;INTERVAL=2',
          startDate,
          count: 3,
        );

        expect(occurrences.length, 3);
        expect(occurrences[0], DateTime.utc(2025, 1, 1, 10, 0));
        expect(occurrences[1], DateTime.utc(2025, 1, 3, 10, 0));
        expect(occurrences[2], DateTime.utc(2025, 1, 5, 10, 0));
      });

      test('filters occurrences after specified date', () {
        final startDate = DateTime.utc(2025, 1, 1, 10, 0);
        final after = DateTime.utc(2025, 1, 3, 10, 0);
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'FREQ=DAILY;INTERVAL=1',
          startDate,
          count: 3,
          after: after,
        );

        expect(occurrences.length, 3);
        expect(occurrences[0], DateTime.utc(2025, 1, 4, 10, 0));
        expect(occurrences[1], DateTime.utc(2025, 1, 5, 10, 0));
        expect(occurrences[2], DateTime.utc(2025, 1, 6, 10, 0));
      });

      test('returns empty list for invalid RRULE', () {
        final startDate = DateTime.utc(2025, 1, 1, 10, 0);
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'INVALID',
          startDate,
          count: 5,
        );

        expect(occurrences, isEmpty);
      });

      test('enforces maximum occurrence limit', () {
        final startDate = DateTime.utc(2025, 1, 1, 10, 0);

        // Request 2000 occurrences (exceeds maxOccurrences of 1000)
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'FREQ=DAILY;INTERVAL=1',
          startDate,
          count: 2000,
        );

        // Should be capped at maxOccurrences (1000)
        expect(occurrences.length, lessThanOrEqualTo(RecurrenceUtils.maxOccurrences));
        expect(occurrences.length, RecurrenceUtils.maxOccurrences);
      });

      test('handles infinite recurrence safely', () {
        final startDate = DateTime.utc(2025, 1, 1, 10, 0);

        // RRULE with no COUNT or UNTIL (infinite)
        final occurrences = RecurrenceUtils.getNextOccurrences(
          'FREQ=DAILY;INTERVAL=1',
          startDate,
          count: 100,
        );

        // Should return exactly 100 occurrences, not infinite
        expect(occurrences.length, 100);
        expect(occurrences.first, DateTime.utc(2025, 1, 1, 10, 0));
        expect(occurrences.last, DateTime.utc(2025, 4, 10, 10, 0)); // Jan 1 + 99 days = Apr 10
      });
    });

    group('getNextOccurrence', () {
      test('returns next single occurrence', () {
        final after = DateTime.utc(2025, 1, 1, 10, 0);
        final next = RecurrenceUtils.getNextOccurrence(
          'FREQ=DAILY;INTERVAL=1',
          after,
        );

        expect(next, isNotNull);
        expect(next, DateTime.utc(2025, 1, 2, 10, 0));
      });

      test('returns null for invalid RRULE', () {
        final after = DateTime.utc(2025, 1, 1, 10, 0);
        final next = RecurrenceUtils.getNextOccurrence(
          'INVALID',
          after,
        );

        expect(next, isNull);
      });
    });

    group('isRecurrenceEnded', () {
      test('returns false for ongoing daily recurrence', () {
        final currentDate = DateTime.utc(2025, 1, 1, 10, 0);
        final ended = RecurrenceUtils.isRecurrenceEnded(
          'FREQ=DAILY;INTERVAL=1',
          currentDate,
        );

        expect(ended, isFalse);
      });

      test('returns true for invalid RRULE', () {
        final currentDate = DateTime.utc(2025, 1, 1, 10, 0);
        final ended = RecurrenceUtils.isRecurrenceEnded(
          'INVALID',
          currentDate,
        );

        expect(ended, isTrue);
      });
    });

    group('createRRule', () {
      test('creates daily RRULE', () {
        final rrule = RecurrenceUtils.createRRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );

        expect(rrule, 'FREQ=DAILY');
      });

      test('creates weekly RRULE with interval', () {
        final rrule = RecurrenceUtils.createRRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        );

        expect(rrule, 'FREQ=WEEKLY;INTERVAL=2');
      });

      test('creates monthly RRULE with count', () {
        final rrule = RecurrenceUtils.createRRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          count: 12,
        );

        expect(rrule, 'FREQ=MONTHLY;COUNT=12');
      });

      test('creates yearly RRULE with until date', () {
        final until = DateTime(2025, 12, 31, 23, 59, 59);
        final rrule = RecurrenceUtils.createRRule(
          frequency: RecurrenceFrequency.yearly,
          interval: 1,
          until: until,
        );

        expect(rrule, contains('FREQ=YEARLY'));
        expect(rrule, contains('UNTIL='));
      });

      test('creates weekly RRULE with specific weekdays', () {
        final rrule = RecurrenceUtils.createRRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          byWeekDay: [0, 2, 4], // Monday, Wednesday, Friday
        );

        expect(rrule, 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
      });

      test('creates monthly RRULE with specific month days', () {
        final rrule = RecurrenceUtils.createRRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          byMonthDay: [1, 15],
        );

        expect(rrule, 'FREQ=MONTHLY;BYMONTHDAY=1,15');
      });
    });

    group('getDescription', () {
      test('returns Korean description for daily recurrence', () {
        final desc = RecurrenceUtils.getDescription(
          'FREQ=DAILY;INTERVAL=1',
          'ko',
        );

        expect(desc, '매일');
      });

      test('returns Korean description for weekly recurrence with interval', () {
        final desc = RecurrenceUtils.getDescription(
          'FREQ=WEEKLY;INTERVAL=2',
          'ko',
        );

        expect(desc, '2주마다');
      });

      test('returns Korean description with count', () {
        final desc = RecurrenceUtils.getDescription(
          'FREQ=MONTHLY;INTERVAL=1;COUNT=12',
          'ko',
        );

        expect(desc, '매월 (12회)');
      });

      test('returns English description for daily recurrence', () {
        final desc = RecurrenceUtils.getDescription(
          'FREQ=DAILY;INTERVAL=1',
          'en',
        );

        expect(desc, 'Every day');
      });

      test('returns English description for weekly recurrence with interval', () {
        final desc = RecurrenceUtils.getDescription(
          'FREQ=WEEKLY;INTERVAL=2',
          'en',
        );

        expect(desc, 'Every 2 weeks');
      });

      test('returns English description with count', () {
        final desc = RecurrenceUtils.getDescription(
          'FREQ=MONTHLY;INTERVAL=1;COUNT=12',
          'en',
        );

        expect(desc, 'Every month (12 times)');
      });

      test('returns no recurrence message for null', () {
        final descKo = RecurrenceUtils.getDescription(null, 'ko');
        final descEn = RecurrenceUtils.getDescription(null, 'en');

        expect(descKo, '반복 없음');
        expect(descEn, 'No recurrence');
      });

      test('returns invalid message for empty string', () {
        final descKo = RecurrenceUtils.getDescription('', 'ko');
        final descEn = RecurrenceUtils.getDescription('', 'en');

        expect(descKo, '반복 없음');
        expect(descEn, 'No recurrence');
      });
    });
  });
}
