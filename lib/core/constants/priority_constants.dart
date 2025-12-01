/// Priority levels for todo notifications and organization.
///
/// These constants define the three-tier priority system used throughout
/// the app for notification channels, sorting, and user interface display.
class PriorityConstants {
  /// Low priority notifications
  static const String low = 'low';

  /// Medium priority notifications (default)
  static const String medium = 'medium';

  /// High priority notifications
  static const String high = 'high';

  /// All valid priority levels
  static const List<String> all = [low, medium, high];

  /// Default priority level for new todos
  static const String defaultPriority = medium;

  /// Get display name for priority level
  static String getDisplayName(String priority) {
    switch (priority) {
      case low:
        return 'priority_low';
      case high:
        return 'priority_high';
      case medium:
      default:
        return 'priority_medium';
    }
  }

  /// Priority order for sorting (highest to lowest)
  static const Map<String, int> priorityOrder = {
    high: 3,
    medium: 2,
    low: 1,
  };

  /// Get priority level from numeric value
  static String fromInt(int value) {
    switch (value) {
      case 3:
        return high;
      case 1:
        return low;
      case 2:
      default:
        return medium;
    }
  }

  /// Get numeric value for priority level
  static int toInt(String priority) {
    return priorityOrder[priority] ?? 2;
  }

  /// Compare two priority levels (-1 if first < second, 0 if equal, 1 if first > second)
  static int compare(String priority1, String priority2) {
    final value1 = toInt(priority1);
    final value2 = toInt(priority2);
    if (value1 < value2) return -1;
    if (value1 > value2) return 1;
    return 0;
  }
}
