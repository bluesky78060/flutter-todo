import 'package:easy_localization/easy_localization.dart';
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
      // rrule package requires "RRULE:" prefix
      final rruleWithPrefix = rruleString.startsWith('RRULE:')
          ? rruleString
          : 'RRULE:$rruleString';
      return RecurrenceRule.fromString(rruleWithPrefix);
    } catch (e) {
      return null;
    }
  }

  /// Maximum number of occurrences to generate (safety limit)
  static const int maxOccurrences = 1000;

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

    // Enforce maximum count to prevent excessive memory usage
    final safeCount = count > maxOccurrences ? maxOccurrences : count;

    try {
      // Always start from the original startDate to get the recurrence sequence
      // Use .take() to prevent infinite iteration when RRULE has no COUNT/UNTIL
      final allOccurrences = rule
          .getInstances(
            start: startDate,
          )
          .take(safeCount * 2) // Take more than needed to allow for filtering
          .toList();

      // If 'after' is specified, filter to only get occurrences after that date
      if (after != null) {
        final filteredOccurrences = allOccurrences
            .where((occurrence) => occurrence.isAfter(after))
            .take(safeCount)
            .toList();
        return filteredOccurrences;
      }

      return allOccurrences.take(safeCount).toList();
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

    try {
      // Get instances starting from currentDate
      final instances = rule.getInstances(start: currentDate).take(1).toList();
      return instances.isEmpty;
    } catch (e) {
      // If there's an error, assume recurrence has ended
      return true;
    }
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
  static String getDescription(String? rruleString) {
    if (rruleString == null || rruleString.isEmpty) {
      return 'no_recurrence'.tr();
    }

    final rule = parseRRule(rruleString);
    if (rule == null) {
      return 'invalid_recurrence'.tr();
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

    // Build description using translation keys
    String desc = '';

    if (interval > 1) {
      desc = '$interval';

      switch (freq) {
        case 'DAILY':
          desc += '${'day_unit'.tr()}${'every_unit'.tr()}';
          break;
        case 'WEEKLY':
          desc += '${'week_unit'.tr()}${'every_unit'.tr()}';
          break;
        case 'MONTHLY':
          desc += '${'month_unit'.tr()}${'every_unit'.tr()}';
          break;
        case 'YEARLY':
          desc += '${'year_unit'.tr()}${'every_unit'.tr()}';
          break;
        default:
          return 'custom_recurrence'.tr();
      }
    } else {
      switch (freq) {
        case 'DAILY':
          desc = 'daily'.tr();
          break;
        case 'WEEKLY':
          desc = 'weekly'.tr();
          break;
        case 'MONTHLY':
          desc = 'monthly'.tr();
          break;
        case 'YEARLY':
          desc = 'yearly'.tr();
          break;
        default:
          return 'custom_recurrence'.tr();
      }
    }

    if (count != null) {
      desc += ' ($count${'times_unit'.tr()})';
    }

    return desc;
  }
}

/// Recurrence frequency options
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}
