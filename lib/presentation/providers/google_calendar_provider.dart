import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/google_calendar_service.dart';
import 'package:todo_app/domain/entities/todo.dart';

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

  /// Todo를 캘린더에 추가
  Future<bool> addTodoToCalendar(Todo todo) async {
    if (!state.isConnected) return false;
    return await _service.addTodoToCalendar(todo);
  }

  /// 여러 Todo 동기화
  Future<int> syncTodos(List<Todo> todos) async {
    if (!state.isConnected) return 0;
    return await _service.syncTodosToCalendar(todos);
  }
}

/// Google Calendar Provider
final googleCalendarProvider =
    NotifierProvider<GoogleCalendarNotifier, GoogleCalendarState>(() {
  return GoogleCalendarNotifier();
});
