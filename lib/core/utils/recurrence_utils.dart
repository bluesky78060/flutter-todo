import 'package:rrule/rrule.dart';

/// Utility class for handling recurrence rules (RRULE format)
class RecurrenceUtils {
  RecurrenceUtils._();

  /// Parse RRULE string to RecurrenceRule object
  /// Example: "FREQ=DAILY;INTERVAL=1" -> Daily recurrence
  static RecurrenceRule? parseRRule(String? rruleString) {
    if (rruleString == null || rruleString.isEmpty) {
      return null;
    }

    try {
      return RecurrenceRule.fromString(rruleString);
    } catch (e) {
      return null;
    }
  }

  /// Get the next N occurrences from a start date
  /// Returns list of DateTime when the todo should occur
  static List<DateTime> getNextOccurrences(
    String rruleString,
    DateTime startDate, {
    int count = 30,
    DateTime? after,
  }) {
    final rule = parseRRule(rruleString);
    if (rule == null) return [];

    try {
      final occurrences = rule
          .getInstances(
            start: after ?? startDate,
          )
          .take(count)
          .toList();

      return occurrences;
    } catch (e) {
      return [];
    }
  }

  /// Get the next single occurrence after a specific date
  static DateTime? getNextOccurrence(
    String rruleString,
    DateTime after,
  ) {
    final occurrences = getNextOccurrences(rruleString, after, count: 1, after: after);
    return occurrences.isNotEmpty ? occurrences.first : null;
  }

  /// Check if a recurrence rule has ended (past UNTIL date or COUNT limit)
  static bool isRecurrenceEnded(String rruleString, DateTime currentDate) {
    final rule = parseRRule(rruleString);
    if (rule == null) return true;

    // Check if there are any more occurrences after current date
    final nextOccurrences = getNextOccurrences(rruleString, currentDate, count: 1, after: currentDate);
    return nextOccurrences.isEmpty;
  }

  /// Create RRULE string from parameters
  static String createRRule({
    required RecurrenceFrequency frequency,
    int interval = 1,
    DateTime? until,
    int? count,
    List<int>? byWeekDay, // 0 = Monday, 6 = Sunday
    List<int>? byMonthDay,
    List<int>? byMonth,
  }) {
    final Map<String, dynamic> params = {
      'FREQ': _frequencyToString(frequency),
      if (interval > 1) 'INTERVAL': interval.toString(),
      if (until != null) 'UNTIL': _formatUntilDate(until),
      if (count != null) 'COUNT': count.toString(),
      if (byWeekDay != null && byWeekDay.isNotEmpty) 'BYDAY': _formatByWeekDay(byWeekDay),
      if (byMonthDay != null && byMonthDay.isNotEmpty) 'BYMONTHDAY': byMonthDay.join(','),
      if (byMonth != null && byMonth.isNotEmpty) 'BYMONTH': byMonth.join(','),
    };

    return params.entries.map((e) => '${e.key}=${e.value}').join(';');
  }

  /// Convert RecurrenceFrequency enum to RRULE string
  static String _frequencyToString(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }

  /// Format DateTime to RRULE UNTIL format (YYYYMMDDTHHMMSSZ)
  static String _formatUntilDate(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}${_pad(utc.month)}${_pad(utc.day)}T'
        '${_pad(utc.hour)}${_pad(utc.minute)}${_pad(utc.second)}Z';
  }

  /// Format weekday list to BYDAY format (MO,TU,WE,TH,FR,SA,SU)
  static String _formatByWeekDay(List<int> weekDays) {
    const dayNames = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return weekDays.map((day) => dayNames[day % 7]).join(',');
  }

  /// Pad number with leading zero
  static String _pad(int number) {
    return number.toString().padLeft(2, '0');
  }

  /// Get human-readable description of recurrence rule
  static String getDescription(String? rruleString, String locale) {
    if (rruleString == null || rruleString.isEmpty) {
      return locale == 'ko' ? '반복 없음' : 'No recurrence';
    }

    final rule = parseRRule(rruleString);
    if (rule == null) {
      return locale == 'ko' ? '잘못된 반복 규칙' : 'Invalid recurrence';
    }

    // Parse frequency and interval
    final parts = rruleString.split(';');
    String? freq;
    int interval = 1;
    int? count;

    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length != 2) continue;

      switch (kv[0]) {
        case 'FREQ':
          freq = kv[1];
          break;
        case 'INTERVAL':
          interval = int.tryParse(kv[1]) ?? 1;
          break;
        case 'COUNT':
          count = int.tryParse(kv[1]);
          break;
      }
    }

    // Build description
    if (locale == 'ko') {
      String desc = '';
      if (interval > 1) {
        desc = '$interval';
      }

      switch (freq) {
        case 'DAILY':
          desc += interval > 1 ? '일마다' : '매일';
          break;
        case 'WEEKLY':
          desc += interval > 1 ? '주마다' : '매주';
          break;
        case 'MONTHLY':
          desc += interval > 1 ? '개월마다' : '매월';
          break;
        case 'YEARLY':
          desc += interval > 1 ? '년마다' : '매년';
          break;
        default:
          return '사용자 지정 반복';
      }

      if (count != null) {
        desc += ' ($count회)';
      }

      return desc;
    } else {
      // English
      String desc = '';
      if (interval > 1) {
        desc = 'Every $interval ';
      } else {
        desc = 'Every ';
      }

      switch (freq) {
        case 'DAILY':
          desc += interval > 1 ? 'days' : 'day';
          break;
        case 'WEEKLY':
          desc += interval > 1 ? 'weeks' : 'week';
          break;
        case 'MONTHLY':
          desc += interval > 1 ? 'months' : 'month';
          break;
        case 'YEARLY':
          desc += interval > 1 ? 'years' : 'year';
          break;
        default:
          return 'Custom recurrence';
      }

      if (count != null) {
        desc += ' ($count times)';
      }

      return desc;
    }
  }
}

/// Recurrence frequency options
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}
