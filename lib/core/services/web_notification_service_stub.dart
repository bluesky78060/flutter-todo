// Stub implementation for non-web platforms
class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  Future<void> initialize() async {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }

  Future<bool> requestPermission() async {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }

  bool areNotificationsEnabled() {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }

  void cancelNotification(int id) {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }

  void cancelAllNotifications() {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }

  int getPendingNotificationCount() {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }

  Future<void> showTestNotification() async {
    throw UnsupportedError('WebNotificationService is only available on web platform');
  }
}
