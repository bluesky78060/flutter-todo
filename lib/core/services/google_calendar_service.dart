import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// Google Calendar 연동 서비스
class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',  // 전체 캘린더 접근
      'https://www.googleapis.com/auth/calendar.events',  // 이벤트 접근
    ],
  );

  gcal.CalendarApi? _calendarApi;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Google Calendar에 연결
  Future<bool> connect() async {
    try {
      // 기존 로그인 상태 확인
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      // 로그인되어 있지 않으면 로그인 시도
      if (account == null) {
        account = await _googleSignIn.signIn();
      }

      if (account == null) {
        debugPrint('📅 GoogleCalendar: 로그인 취소됨');
        return false;
      }

      // Calendar scope 확인 (이미 초기화 시 요청했으므로 스킵 가능)
      debugPrint('📅 GoogleCalendar: 로그인 성공 - ${account.email}');

      // API 클라이언트 생성
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugPrint('📅 GoogleCalendar: HTTP 클라이언트 생성 실패');
        return false;
      }

      _calendarApi = gcal.CalendarApi(httpClient);
      _isConnected = true;
      debugPrint('📅 GoogleCalendar: 연결 성공 - ${account.email}');
      return true;
    } catch (e) {
      debugPrint('📅 GoogleCalendar: 연결 실패 - $e');
      _isConnected = false;
      return false;
    }
  }

  /// 연결 해제
  Future<void> disconnect() async {
    await _googleSignIn.signOut();
    _calendarApi = null;
    _isConnected = false;
    debugPrint('📅 GoogleCalendar: 연결 해제됨');
  }

  /// 현재 로그인된 계정 정보
  String? get currentUserEmail => _googleSignIn.currentUser?.email;

  /// Google Calendar에서 이벤트 가져오기
  Future<List<GoogleCalendarEvent>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isConnected || _calendarApi == null) {
      debugPrint('📅 GoogleCalendar: 연결되지 않음');
      return [];
    }

    try {
      final now = DateTime.now();
      final timeMin = startDate ?? now;
      final timeMax = endDate ?? now.add(const Duration(days: 30));

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: timeMin.toUtc(),
        timeMax: timeMax.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      final result = <GoogleCalendarEvent>[];
      for (final event in events.items ?? []) {
        if (event.summary != null) {
          result.add(GoogleCalendarEvent(
            id: event.id ?? '',
            title: event.summary ?? '',
            description: event.description,
            startTime: _parseEventTime(event.start),
            endTime: _parseEventTime(event.end),
            isAllDay: event.start?.date != null,
          ));
        }
      }

      debugPrint('📅 GoogleCalendar: ${result.length}개 이벤트 로드됨');
      return result;
    } catch (e) {
      debugPrint('📅 GoogleCalendar: 이벤트 로드 실패 - $e');
      return [];
    }
  }

  /// Todo를 Google Calendar에 추가
  Future<bool> addTodoToCalendar(Todo todo) async {
    if (!_isConnected || _calendarApi == null) {
      debugPrint('📅 GoogleCalendar: 연결되지 않음');
      return false;
    }

    if (todo.dueDate == null) {
      debugPrint('📅 GoogleCalendar: 마감일이 없는 할 일은 추가할 수 없음');
      return false;
    }

    try {
      final event = gcal.Event()
        ..summary = todo.title
        ..description = todo.description
        ..start = gcal.EventDateTime()
        ..end = gcal.EventDateTime();

      // 알림 시간이 있으면 특정 시간, 없으면 종일 이벤트
      if (todo.notificationTime != null) {
        event.start!.dateTime = todo.notificationTime;
        event.end!.dateTime = todo.notificationTime!.add(const Duration(hours: 1));
      } else {
        // 종일 이벤트
        final dateStr = todo.dueDate!.toIso8601String().split('T')[0];
        event.start!.date = DateTime.parse(dateStr);
        event.end!.date = DateTime.parse(dateStr);
      }

      await _calendarApi!.events.insert(event, 'primary');
      debugPrint('📅 GoogleCalendar: 이벤트 추가됨 - ${todo.title}');
      return true;
    } catch (e) {
      debugPrint('📅 GoogleCalendar: 이벤트 추가 실패 - $e');
      return false;
    }
  }

  /// 여러 Todo를 Google Calendar에 동기화
  Future<int> syncTodosToCalendar(List<Todo> todos) async {
    if (!_isConnected || _calendarApi == null) {
      return 0;
    }

    int successCount = 0;
    for (final todo in todos) {
      if (todo.dueDate != null && await addTodoToCalendar(todo)) {
        successCount++;
      }
    }

    debugPrint('📅 GoogleCalendar: $successCount/${todos.length} 할 일 동기화됨');
    return successCount;
  }

  DateTime? _parseEventTime(gcal.EventDateTime? eventDateTime) {
    if (eventDateTime == null) return null;
    if (eventDateTime.dateTime != null) {
      return eventDateTime.dateTime!.toLocal();
    }
    if (eventDateTime.date != null) {
      return eventDateTime.date;
    }
    return null;
  }
}

/// Google Calendar 이벤트 모델
class GoogleCalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isAllDay;

  GoogleCalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
  });

  @override
  String toString() => 'GoogleCalendarEvent($title, $startTime)';
}
