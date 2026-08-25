import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/google_calendar_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

/// Google Calendar 연결 상태
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});

/// Google Calendar 연결 상태 관리
class GoogleCalendarState {
  final bool isConnected;
  final bool isLoading;
  final String? email;
  final String? error;
  final List<GoogleCalendarEvent> events;

  const GoogleCalendarState({
    this.isConnected = false,
    this.isLoading = false,
    this.email,
    this.error,
    this.events = const [],
  });

  GoogleCalendarState copyWith({
    bool? isConnected,
    bool? isLoading,
    String? email,
    String? error,
    List<GoogleCalendarEvent>? events,
  }) {
    return GoogleCalendarState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      error: error,
      events: events ?? this.events,
    );
  }
}

/// Google Calendar 상태 Notifier
class GoogleCalendarNotifier extends Notifier<GoogleCalendarState> {
  late final GoogleCalendarService _service;

  @override
  GoogleCalendarState build() {
    _service = ref.watch(googleCalendarServiceProvider);
    _checkInitialConnection();
    return const GoogleCalendarState();
  }

  Future<void> _checkInitialConnection() async {
    if (_service.isConnected) {
      state = state.copyWith(
        isConnected: true,
        email: _service.currentUserEmail,
      );
    }
  }

  /// Google Calendar에 연결
  Future<bool> connect() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.connect();
      if (success) {
        state = state.copyWith(
          isConnected: true,
          isLoading: false,
          email: _service.currentUserEmail,
        );
        return true;
      } else {
        state = state.copyWith(
          isConnected: false,
          isLoading: false,
          error: '연결에 실패했습니다',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 연결 해제
  Future<void> disconnect() async {
    state = state.copyWith(isLoading: true);
    await _service.disconnect();
    state = const GoogleCalendarState();
  }

  /// 이벤트 가져오기
  Future<void> fetchEvents({DateTime? startDate, DateTime? endDate}) async {
    if (!state.isConnected) return;

    state = state.copyWith(isLoading: true);

    try {
      final events = await _service.getEvents(
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        isLoading: false,
        events: events,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Todo를 캘린더에 추가하고 이벤트 ID를 돌려준다. 실패 시 null.
  Future<String?> addTodoToCalendar(Todo todo) async {
    if (!state.isConnected) return null;
    final eventId = await _service.addTodoToCalendar(todo);
    if (eventId != null && eventId != todo.googleEventId) {
      await _persistEventId(todo.id, eventId);
    }
    return eventId;
  }

  /// 마감일이 있는 미완료 할 일을 캘린더에 동기화한다.
  ///
  /// 할 일 목록을 **저장소에서 직접** 가져온다. `todosProvider` 를 쓰지 않는 이유가 둘 있다.
  ///
  /// 1. `todosProvider` 는 `todoFilterProvider`/`categoryFilterProvider`/`searchQueryProvider`
  ///    를 모두 watch 하는 **필터링된** 목록이다. 목록 화면에서 "완료" 필터나 검색어를
  ///    켜 둔 채 설정에 들어오면 동기화 대상이 그 필터에 좌우된다.
  /// 2. `todosProvider` 는 캐시를 유지하므로, 직전 동기화에서 저장한 `googleEventId` 가
  ///    메모리에 반영되지 않는다. 같은 세션에서 두 번 동기화하면 전부 새로 등록되어
  ///    **중복이 생긴다.** 매번 새로 읽으면 이 문제가 원천적으로 없다.
  Future<CalendarSyncResult> syncAllTodos() async {
    if (!state.isConnected) {
      return const CalendarSyncResult(
        succeeded: 0,
        failed: 0,
        skipped: 0,
        notConnected: true,
      );
    }

    final fetched =
        await ref.read(todoRepositoryProvider).getFilteredTodos('all');
    final todos = fetched.fold(
      // 실패를 빈 목록으로 바꾸면 안 된다. 그러면 호출부에는 "대상 0건"으로 보여
      // "등록할 할 일이 없습니다" 라는 **틀린 원인**이 사용자에게 표시된다.
      // 던져야 화면의 catch 가 calendar_sync_error 로 보여 준다.
      (failure) => throw Exception(failure),
      (list) => list,
    );

    // 반복 일정의 master 는 화면에도 안 보이는 템플릿이므로 캘린더에도 넣지 않는다.
    // 실제 일정은 생성된 인스턴스들이다.
    //
    // 1차 방어는 이미 `supabase_datasource.getFilteredTodos` 안에 있다.
    // 여기 조건이 추가로 잡는 것은 `recurrenceRule == ''` (빈 문자열)인 경우다.
    // datasource 는 `== null` 만 보므로 빈 문자열을 통과시킨다.
    bool isMasterRecurring(Todo t) =>
        t.recurrenceRule != null &&
        t.recurrenceRule!.isNotEmpty &&
        t.parentRecurringTodoId == null;

    final targets = todos
        .where((t) =>
            t.dueDate != null && !t.isCompleted && !isMasterRecurring(t))
        .toList(growable: false);

    final result = await _service.syncTodosToCalendar(
      targets,
      onEventId: _persistEventId,
    );

    // 저장한 이벤트 ID 를 UI 캐시에도 반영한다.
    //
    // 동기화 도중 사용자가 설정 화면을 벗어나면 이 provider 가 dispose 되어
    // StateError 가 난다. 등록은 이미 끝난 뒤이므로 결과 반환까지 날릴 이유가 없다.
    try {
      ref.invalidate(todosProvider);
    } catch (e) {
      debugPrint('📅 GoogleCalendar: todosProvider 무효화 생략 - $e');
    }

    // skipped 에 완료 항목까지 넣으면 오래 쓴 계정에서 숫자가 성공을 압도한다.
    // ("3개 등록했습니다 (200개는 대상이 아님)") 완료된 할 일은 애초에 등록 대상이
    // 아니라는 게 사용자에게도 자명하므로 세지 않는다.
    // 사용자가 알아야 할 것은 "등록하려 했는데 마감일이 없어 못 넣은" 건수다.
    final missingDueDate =
        todos.where((t) => t.dueDate == null && !t.isCompleted).length;

    return CalendarSyncResult(
      succeeded: result.succeeded,
      failed: result.failed,
      skipped: result.skipped + missingDueDate,
      notConnected: result.notConnected,
    );
  }

  /// 테스트에서 연결 상태를 강제하기 위한 지점.
  ///
  /// `connect()` 는 실제 Google OAuth 를 타므로 단위 테스트에서 쓸 수 없다.
  ///
  /// **한계**: notifier 의 상태만 바꾼다. [GoogleCalendarService] 싱글턴은 여전히
  /// 미연결이므로, 저장소 조회를 통과해 `_service.syncTodosToCalendar` 까지 가는
  /// 시나리오는 `notConnected: true` 로 조용히 빠져나간다. 그런 테스트를 쓰려면
  /// 서비스에 인터페이스를 도입해 주입해야 한다.
  @visibleForTesting
  void debugSetConnected({required bool isConnected}) {
    state = state.copyWith(isConnected: isConnected);
  }

  /// 이벤트 ID를 Supabase에 저장한다.
  ///
  /// 저장에 실패해도 예외를 밖으로 던지지 않는다. 이벤트 등록 자체는 이미
  /// 성공한 상태이므로 동기화를 실패로 만들 이유가 없다. 다만 다음 동기화에서
  /// 중복이 생길 수 있으므로 로그로 남긴다.
  ///
  /// `google_event_id` 컬럼이 아직 없는 프로젝트에서는 PostgREST 가
  /// `42703 column does not exist` 를 낸다. 그때도 동기화 자체는 성공이다.
  ///
  /// 방어를 **이 함수 안에** 둔 이유: 서비스 쪽 호출부에만 두면
  /// [addTodoToCalendar] 경로가 보호되지 않는다.
  Future<void> _persistEventId(int todoId, String eventId) async {
    try {
      final dataSource = ref.read(supabaseTodoDataSourceProvider);
      await dataSource.updateGoogleEventId(todoId, eventId);
    } catch (e) {
      debugPrint('📅 GoogleCalendar: 이벤트 ID 저장 실패 (todo=$todoId) - $e');
    }
  }
}

/// Google Calendar Provider
final googleCalendarProvider =
    NotifierProvider<GoogleCalendarNotifier, GoogleCalendarState>(() {
  return GoogleCalendarNotifier();
});
