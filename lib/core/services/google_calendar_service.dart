import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:todo_app/core/utils/date_range_utils.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// Google Calendar 연동 서비스
class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  /// 캘린더 접근에 필요한 스코프. 생성자와 requestScopes 가 같은 목록을
  /// 봐야 하므로 상수로 둔다.
  static const List<String> calendarScopes = [
    'https://www.googleapis.com/auth/calendar', // 전체 캘린더 접근
    'https://www.googleapis.com/auth/calendar.events', // 이벤트 접근
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', ...calendarScopes],
  );

  gcal.CalendarApi? _calendarApi;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// 오류가 "캘린더 권한이 없다" 는 뜻인지 판정한다.
  ///
  /// 순수 함수로 분리한 이유는 실제 Google 호출 없이 이 분기를 테스트하기
  /// 위해서다. 권한 부족과 네트워크 장애를 뭉뚱그리면 사용자에게 틀린
  /// 원인이 표시된다.
  @visibleForTesting
  static bool isInsufficientScope(Object error) {
    if (error is gcal.DetailedApiRequestError) {
      return error.status == 401 || error.status == 403;
    }
    return false;
  }

  /// Google Calendar에 연결
  Future<bool> connect() async {
    try {
      // 기존 로그인 상태 확인
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      // 로그인되어 있지 않으면 로그인 시도
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('📅 GoogleCalendar: 로그인 취소됨');
        return false;
      }

      debugPrint('📅 GoogleCalendar: 로그인 성공 - ${account.email}');

      // 스코프 보충 시도. **반환값을 성공 판정에 쓰지 않는다.**
      //
      // 이 호출을 실패 판정에 쓰면 이미 승인한 사용자가 막힌다(DTA-3-8:
      // 중복 요청에 false 가 돌아와 로그인 전체가 실패로 처리됐다).
      // 반대로 호출을 아예 빼면 스코프 없는 기존 계정이 그대로 통과해
      // 나중에 403 을 만난다(DTA-3-9). 그래서 부르되 결과는 무시하고,
      // 아래에서 실제 응답으로 확인한다.
      try {
        await _googleSignIn.requestScopes(calendarScopes);
      } catch (e) {
        debugPrint('📅 GoogleCalendar: 스코프 요청 건너뜀 - $e');
      }

      // API 클라이언트 생성
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugPrint('📅 GoogleCalendar: HTTP 클라이언트 생성 실패');
        return false;
      }

      final api = gcal.CalendarApi(httpClient);

      // 권한이 실제로 있는지 가장 싼 호출로 확인한다.
      //
      // google_sign_in 의 canAccessScopes 는 쓸 수 없다 — 웹에만 구현되어
      // 있고 Android/iOS 에서는 플랫폼 인터페이스 기본 구현이
      // UnimplementedError 를 던진다. 불린을 믿는 대신 응답을 근거로 삼는다.
      try {
        await api.calendarList.list(maxResults: 1, $fields: 'items/id');
      } catch (e) {
        if (isInsufficientScope(e)) {
          debugPrint('📅 GoogleCalendar: 캘린더 권한이 부여되지 않았습니다 - $e');
          _isConnected = false;
          return false;
        }
        rethrow; // 네트워크 등 다른 실패는 아래 catch 가 처리한다
      }

      _calendarApi = api;
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
  /// Todo 하나를 Google Calendar 이벤트로 만든다.
  ///
  /// 순수 함수로 분리해 둔 이유는 실제 Google API 호출 없이 단위 테스트로
  /// 이벤트 구성을 검증하기 위해서다.
  @visibleForTesting
  static gcal.Event buildEvent(Todo todo) {
    final event = gcal.Event()
      ..summary = todo.title
      ..description = todo.description
      ..start = gcal.EventDateTime()
      ..end = gcal.EventDateTime();

    if (todo.isRanged) {
      // 범위 일정은 알림 유무와 무관하게 **종일 이벤트**로 보낸다.
      //
      // 여러 날에 걸친 일정은 본질적으로 종일 사건이고, 알림은 앱 로컬 알림이
      // 담당하므로 캘린더 이벤트의 시각과 무관하다.
      //
      // 이 분기가 없으면 알림이 있는 범위 일정(출장·여행 — 이 기능의 주 사용처)이
      // 아래 dateTime 갈래로 빠져 **1시간짜리 이벤트 하나**가 되어 버린다.
      event.start!.date = dateOnlyUtc(todo.startDate!);
      event.end!.date =
          _exclusiveEnd(dateOnlyUtc(todo.dueDate!));
    } else if (todo.notificationTime != null) {
      // 시간이 지정된 하루짜리 일정 — 1시간짜리로 만든다.
      event.start!.dateTime = todo.notificationTime;
      event.end!.dateTime = todo.notificationTime!.add(const Duration(hours: 1));
    } else {
      // 하루짜리 종일 이벤트.
      final startDay = dateOnlyUtc(todo.dueDate!);
      event.start!.date = startDay;
      event.end!.date = _exclusiveEnd(startDay);
    }

    return event;
  }

  /// 종일 이벤트의 `end.date` 를 만든다.
  ///
  /// Google Calendar API 에서 종일 이벤트의 `end.date` 는 **exclusive** 다.
  /// 8/21 하루짜리는 start=8/21, end=8/22 여야 한다.
  /// 예전에는 start 와 end 를 같은 날로 넣어 길이 0인 이벤트가 됐고,
  /// API 가 이를 거부해 등록이 조용히 실패했다.
  ///
  /// 단일 날짜에 하루를 더하는 것이라 `Duration` 사용이 안전하다.
  /// 기간 **열거**에 `Duration` 을 누적하면 DST 에서 깨진다 — [enumerateDays] 참조.
  static DateTime _exclusiveEnd(DateTime lastDayUtc) =>
      lastDayUtc.add(const Duration(days: 1));

  /// 이벤트를 어디로 보낼지(갱신 / 신규 생성) 결정하고 실제 호출을 수행한다.
  ///
  /// Google API 호출을 [update] / [insert] 콜백으로 받아 두었기 때문에
  /// 실제 네트워크 없이 **라우팅 규칙만** 단위 테스트로 검증할 수 있다.
  /// 이 라우팅이 이 기능의 중복 방지 전체를 떠받친다.
  ///
  /// 반환값은 이벤트 ID. 실패하면 `null`.
  @visibleForTesting
  static Future<String?> routeEventWrite({
    required gcal.Event event,
    required String? existingEventId,
    required Future<String?> Function(gcal.Event event, String eventId) update,
    required Future<String?> Function(gcal.Event event) insert,
  }) async {
    if (existingEventId != null && existingEventId.isNotEmpty) {
      try {
        final updatedId = await update(event, existingEventId);
        return updatedId ?? existingEventId;
      } on gcal.DetailedApiRequestError catch (e) {
        // 폴백은 **이벤트가 실제로 사라진 경우에만** 해야 한다.
        //
        // 404(없음)/410(삭제됨)이 아닌데도 insert 로 넘어가면,
        // 일시적 오류(429 quota, 500/503, 인증 만료)에서 같은 일정이 하나 더 생긴다.
        // 게다가 새로 만든 ID 가 기존 ID 를 덮어써서 원래 이벤트는 다시는
        // 참조할 수 없는 고아가 된다. 이후 동기화로도 정리되지 않는다.
        if (e.status != 404 && e.status != 410) {
          debugPrint(
              '📅 GoogleCalendar: 갱신 실패(일시적, status=${e.status}) - $e');
          return null;
        }
        debugPrint(
            '📅 GoogleCalendar: 캘린더에 이벤트가 없음(status=${e.status}), 재생성');
      } catch (e) {
        // 네트워크 타임아웃 등. 이벤트가 사라졌다는 근거가 없으므로 폴백하지 않는다.
        debugPrint('📅 GoogleCalendar: 갱신 실패(네트워크) - $e');
        return null;
      }
    }

    try {
      return await insert(event);
    } catch (e) {
      debugPrint('📅 GoogleCalendar: 이벤트 추가 실패 - $e');
      return null;
    }
  }

  /// Todo 를 캘린더에 등록하거나, 이미 등록돼 있으면 갱신한다.
  ///
  /// 반환값은 Google Calendar 이벤트 ID 다. 실패하면 `null`.
  /// 호출부는 이 ID 를 Todo 에 저장해 두었다가 다음 동기화 때 넘겨야
  /// 같은 일정이 중복 등록되지 않는다.
  Future<String?> addTodoToCalendar(Todo todo) async {
    if (!_isConnected || _calendarApi == null) {
      debugPrint('📅 GoogleCalendar: 연결되지 않음');
      return null;
    }

    if (todo.dueDate == null) {
      debugPrint('📅 GoogleCalendar: 마감일이 없는 할 일은 추가할 수 없음');
      return null;
    }

    return routeEventWrite(
      event: buildEvent(todo),
      existingEventId: todo.googleEventId,
      update: (event, eventId) async {
        final updated =
            await _calendarApi!.events.update(event, 'primary', eventId);
        debugPrint('📅 GoogleCalendar: 이벤트 갱신됨 - ${todo.title}');
        return updated.id;
      },
      insert: (event) async {
        final created = await _calendarApi!.events.insert(event, 'primary');
        debugPrint('📅 GoogleCalendar: 이벤트 추가됨 - ${todo.title}');
        return created.id;
      },
    );
  }

  /// 여러 Todo를 Google Calendar에 동기화한다.
  ///
  /// [onEventId] 는 등록/갱신에 성공한 Todo 의 이벤트 ID 를 돌려준다.
  /// 호출부가 이를 저장해야 다음 동기화에서 중복 등록이 일어나지 않는다.
  Future<CalendarSyncResult> syncTodosToCalendar(
    List<Todo> todos, {
    Future<void> Function(int todoId, String eventId)? onEventId,
  }) async {
    if (!_isConnected || _calendarApi == null) {
      return CalendarSyncResult(
        succeeded: 0,
        failed: 0,
        skipped: todos.length,
        notConnected: true,
      );
    }

    var succeeded = 0;
    var failed = 0;
    var skipped = 0;

    for (final todo in todos) {
      if (todo.dueDate == null) {
        skipped++;
        continue;
      }

      final eventId = await addTodoToCalendar(todo);
      if (eventId == null) {
        failed++;
        continue;
      }

      succeeded++;
      if (onEventId != null && eventId != todo.googleEventId) {
        try {
          await onEventId(todo.id, eventId);
        } catch (e) {
          // 이벤트는 등록됐지만 ID 저장에 실패한 경우다. 등록 자체는 성공이므로
          // succeeded 를 되돌리지 않는다. 다만 다음 동기화에서 중복이 생길 수 있다.
          debugPrint('📅 GoogleCalendar: 이벤트 ID 저장 실패 (todo=${todo.id}) - $e');
        }
      }
    }

    debugPrint(
        '📅 GoogleCalendar: 성공 $succeeded / 실패 $failed / 건너뜀 $skipped');
    return CalendarSyncResult(
      succeeded: succeeded,
      failed: failed,
      skipped: skipped,
    );
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

/// [GoogleCalendarService.syncTodosToCalendar] 의 결과.
///
/// 예전에는 성공 건수(int)만 돌려줘서 실패가 사용자에게 보이지 않았다.
class CalendarSyncResult {
  const CalendarSyncResult({
    required this.succeeded,
    required this.failed,
    required this.skipped,
    this.notConnected = false,
  });

  /// 등록 또는 갱신에 성공한 건수.
  final int succeeded;

  /// Google API 호출이 실패한 건수.
  final int failed;

  /// 마감일이 없어 대상에서 제외된 건수.
  final int skipped;

  /// 캘린더가 연결되어 있지 않아 아무것도 시도하지 못한 경우.
  final bool notConnected;

  bool get hasFailures => failed > 0;
}
