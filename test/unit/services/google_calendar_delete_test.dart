/// DTA-3-3 / DTA-3-5 의 공통 토대인 삭제 라우팅 규칙 테스트.
///
/// 이 판정이 왜 중요한가: 반환값이 true 면 호출부가 googleEventId 를 비운다.
/// 판정이 틀리면 두 방향 모두 손해다.
///  - 일시적 실패를 true 로 치면: 이벤트는 남아 있는데 ID 를 잃어 고아가 된다.
///  - 이미 없는 것을 false 로 치면: 지울 수 없는 ID 를 영원히 붙들고 재시도한다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:todo_app/core/services/google_calendar_service.dart';

void main() {
  group('routeEventDelete', () {
    test('삭제에 성공하면 true 이고, 그 ID 로 호출한다', () async {
      final calls = <String>[];
      final ok = await GoogleCalendarService.routeEventDelete(
        eventId: 'evt-1',
        delete: (id) async => calls.add(id),
      );

      expect(ok, isTrue);
      expect(calls, ['evt-1']);
    });

    test('등록된 적 없는 할 일은 호출 없이 성공이다', () async {
      for (final id in <String?>[null, '']) {
        var called = false;
        final ok = await GoogleCalendarService.routeEventDelete(
          eventId: id,
          delete: (_) async => called = true,
        );

        expect(ok, isTrue, reason: 'eventId=$id');
        // 지울 게 없는데 API 를 부르면 불필요한 실패 지점이 생긴다.
        expect(called, isFalse, reason: 'eventId=$id');
      }
    });

    test('이미 없는 이벤트(404/410)는 성공으로 친다', () async {
      for (final status in [404, 410]) {
        final ok = await GoogleCalendarService.routeEventDelete(
          eventId: 'evt-1',
          delete: (_) async =>
              throw gcal.DetailedApiRequestError(status, 'gone'),
        );

        expect(ok, isTrue, reason: 'status=$status');
      }
    });

    test('일시적 실패는 성공으로 치지 않는다', () async {
      // 여기서 true 를 돌려주면 호출부가 ID 를 지우고, 캘린더에 남은
      // 이벤트는 다시 참조할 수 없게 된다.
      for (final status in [429, 500, 503, 401, 403]) {
        final ok = await GoogleCalendarService.routeEventDelete(
          eventId: 'evt-1',
          delete: (_) async =>
              throw gcal.DetailedApiRequestError(status, 'transient'),
        );

        expect(ok, isFalse, reason: 'status=$status');
      }
    });

    test('네트워크 오류는 성공으로 치지 않는다', () async {
      final ok = await GoogleCalendarService.routeEventDelete(
        eventId: 'evt-1',
        delete: (_) async => throw Exception('SocketException'),
      );

      expect(ok, isFalse);
    });
  });
}
