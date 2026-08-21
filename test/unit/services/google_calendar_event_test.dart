import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:todo_app/core/services/google_calendar_service.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// DTA-3-1 회귀 방지.
///
/// 실제 Google API 를 부르지 않고 **이벤트 객체 구성**만 검증한다.
/// 이 티켓의 핵심 버그는 종일 이벤트의 `end.date` 를 `start.date` 와 같게 넣어
/// 길이 0인 이벤트를 만든 것이었다. Google Calendar API 에서 종일 이벤트의
/// `end.date` 는 exclusive 다.
void main() {
  Todo makeTodo({
    DateTime? dueDate,
    DateTime? notificationTime,
    String title = 'Test Todo',
  }) {
    return Todo(
      id: 1,
      title: title,
      description: 'Description',
      isCompleted: false,
      createdAt: DateTime(2025, 1, 1),
      dueDate: dueDate,
      notificationTime: notificationTime,
    );
  }

  group('GoogleCalendarService.buildEvent — 종일 이벤트', () {
    test('end.date 는 start.date 의 다음 날이다 (exclusive)', () {
      final event = GoogleCalendarService.buildEvent(
        makeTodo(dueDate: DateTime(2025, 8, 21, 14, 30)),
      );

      expect(event.start!.date, DateTime.utc(2025, 8, 21));
      expect(
        event.end!.date,
        DateTime.utc(2025, 8, 22),
        reason: 'end.date 가 start.date 와 같으면 길이 0인 이벤트가 되어 '
            'Google API 가 거부한다',
      );
    });

    test('start 와 end 가 같은 날이면 안 된다', () {
      final event = GoogleCalendarService.buildEvent(
        makeTodo(dueDate: DateTime(2025, 12, 31)),
      );

      expect(event.start!.date, isNot(equals(event.end!.date)));
    });

    test('마감일의 시각 부분은 버리고 날짜만 쓴다', () {
      final event = GoogleCalendarService.buildEvent(
        makeTodo(dueDate: DateTime(2025, 8, 21, 23, 59, 59)),
      );

      expect(event.start!.date, DateTime.utc(2025, 8, 21));
    });

    test('월말을 넘어가도 다음 달 1일로 넘어간다', () {
      final event = GoogleCalendarService.buildEvent(
        makeTodo(dueDate: DateTime(2025, 2, 28)),
      );

      expect(event.end!.date, DateTime.utc(2025, 3, 1));
    });

    test('종일 이벤트는 dateTime 을 쓰지 않는다', () {
      final event = GoogleCalendarService.buildEvent(
        makeTodo(dueDate: DateTime(2025, 8, 21)),
      );

      expect(event.start!.dateTime, isNull);
      expect(event.end!.dateTime, isNull);
    });
  });

  group('GoogleCalendarService.buildEvent — 시간 지정 이벤트', () {
    test('알림 시간이 있으면 1시간짜리 dateTime 이벤트가 된다', () {
      final notificationTime = DateTime(2025, 8, 21, 9, 0);
      final event = GoogleCalendarService.buildEvent(
        makeTodo(
          dueDate: DateTime(2025, 8, 21),
          notificationTime: notificationTime,
        ),
      );

      expect(event.start!.dateTime, notificationTime);
      expect(event.end!.dateTime, DateTime(2025, 8, 21, 10, 0));
    });

    test('시간 지정 이벤트는 date 를 쓰지 않는다', () {
      final event = GoogleCalendarService.buildEvent(
        makeTodo(
          dueDate: DateTime(2025, 8, 21),
          notificationTime: DateTime(2025, 8, 21, 9, 0),
        ),
      );

      expect(event.start!.date, isNull);
      expect(event.end!.date, isNull);
    });
  });

  group('GoogleCalendarService.routeEventWrite — 중복 방지 라우팅', _routingTests);

  group('GoogleCalendarService.buildEvent — 공통', () {
    test('제목과 설명이 그대로 실린다', () {
      final event = GoogleCalendarService.buildEvent(
        makeTodo(dueDate: DateTime(2025, 8, 21), title: '치과 예약'),
      );

      expect(event.summary, '치과 예약');
      expect(event.description, 'Description');
    });
  });
}

/// DTA-3-1 코드 리뷰 CRITICAL-1 / CRITICAL-2 회귀 방지.
///
/// 중복 등록을 막는 것은 결국 "갱신할 것인가 새로 만들 것인가"라는 라우팅 하나다.
/// [GoogleCalendarService.routeEventWrite] 는 실제 API 호출을 콜백으로 받으므로
/// 네트워크 없이 이 규칙만 검증할 수 있다.
void _routingTests() {
  gcal.Event dummyEvent() => gcal.Event()..summary = 'x';

  test('이벤트 ID가 없으면 insert 를 부른다', () async {
    var inserted = false;
    var updated = false;

    final id = await GoogleCalendarService.routeEventWrite(
      event: dummyEvent(),
      existingEventId: null,
      update: (_, __) async {
        updated = true;
        return 'should-not-happen';
      },
      insert: (_) async {
        inserted = true;
        return 'new-id';
      },
    );

    expect(inserted, isTrue);
    expect(updated, isFalse);
    expect(id, 'new-id');
  });

  test('이벤트 ID가 있으면 update 를 부르고 insert 는 부르지 않는다', () async {
    var inserted = false;
    String? updatedWith;

    final id = await GoogleCalendarService.routeEventWrite(
      event: dummyEvent(),
      existingEventId: 'existing-id',
      update: (_, eventId) async {
        updatedWith = eventId;
        return eventId;
      },
      insert: (_) async {
        inserted = true;
        return 'new-id';
      },
    );

    expect(
      updatedWith,
      'existing-id',
      reason: '2회차 동기화는 반드시 update 경로를 타야 한다. '
          'insert 로 가면 캘린더에 같은 일정이 하나 더 생긴다',
    );
    expect(inserted, isFalse);
    expect(id, 'existing-id');
  });

  test('빈 문자열 ID 는 없는 것으로 보고 insert 한다', () async {
    var inserted = false;

    await GoogleCalendarService.routeEventWrite(
      event: dummyEvent(),
      existingEventId: '',
      update: (_, __) async => fail('빈 ID 로 update 를 부르면 안 된다'),
      insert: (_) async {
        inserted = true;
        return 'new-id';
      },
    );

    expect(inserted, isTrue);
  });

  group('update 실패 시 폴백 판단 — CRITICAL-2', () {
    Future<String?> routeWithUpdateError(Object error, {required void Function() onInsert}) {
      return GoogleCalendarService.routeEventWrite(
        event: dummyEvent(),
        existingEventId: 'existing-id',
        update: (_, __) async => throw error,
        insert: (_) async {
          onInsert();
          return 'new-id';
        },
      );
    }

    test('404 면 이벤트가 사라진 것이므로 insert 로 재생성한다', () async {
      var inserted = false;
      final id = await routeWithUpdateError(
        gcal.DetailedApiRequestError(404, 'Not Found'),
        onInsert: () => inserted = true,
      );

      expect(inserted, isTrue);
      expect(id, 'new-id');
    });

    test('410 이면 삭제된 것이므로 insert 로 재생성한다', () async {
      var inserted = false;
      await routeWithUpdateError(
        gcal.DetailedApiRequestError(410, 'Gone'),
        onInsert: () => inserted = true,
      );

      expect(inserted, isTrue);
    });

    test('429(quota) 에서는 insert 하지 않는다', () async {
      var inserted = false;
      final id = await routeWithUpdateError(
        gcal.DetailedApiRequestError(429, 'Rate Limit Exceeded'),
        onInsert: () => inserted = true,
      );

      expect(
        inserted,
        isFalse,
        reason: '일시적 오류에서 insert 로 폴백하면 중복 이벤트가 생기고 '
            '원본은 ID 를 잃어 영구 고아가 된다',
      );
      expect(id, isNull, reason: '실패로 집계되어야 한다');
    });

    test('500 에서는 insert 하지 않는다', () async {
      var inserted = false;
      final id = await routeWithUpdateError(
        gcal.DetailedApiRequestError(500, 'Internal Error'),
        onInsert: () => inserted = true,
      );

      expect(inserted, isFalse);
      expect(id, isNull);
    });

    test('네트워크 오류(비 API 예외)에서도 insert 하지 않는다', () async {
      var inserted = false;
      final id = await routeWithUpdateError(
        const SocketException('Connection timed out'),
        onInsert: () => inserted = true,
      );

      expect(
        inserted,
        isFalse,
        reason: '타임아웃은 이벤트가 사라졌다는 근거가 아니다',
      );
      expect(id, isNull);
    });
  });

  test('insert 자체가 실패하면 null 을 돌려준다', () async {
    final id = await GoogleCalendarService.routeEventWrite(
      event: dummyEvent(),
      existingEventId: null,
      update: (_, __) async => fail('update 를 부르면 안 된다'),
      insert: (_) async => throw gcal.DetailedApiRequestError(403, 'Forbidden'),
    );

    expect(id, isNull);
  });
}
