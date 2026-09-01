/// DTA-3-9 회귀 방지.
///
/// 경위: DTA-3-8 에서 requestScopes 의 반환값을 실패 판정에 쓰던 것을 없애려고
/// 호출 자체를 지웠다. 그 결과 캘린더 스코프가 없는 기존 계정도 connect() 가
/// true 를 돌려주고, 실제 API 호출에서야 403 이 났다.
///
/// 지금은 실제 응답으로 판정한다. 그 분기가 권한 부족과 나머지 실패를 제대로
/// 가르는지가 이 테스트의 대상이다. 뭉뚱그리면 네트워크 장애를 "권한 없음" 으로
/// 표시해 사용자가 엉뚱한 곳을 고치게 된다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:todo_app/core/services/google_calendar_service.dart';

gcal.DetailedApiRequestError apiError(int? status) =>
    gcal.DetailedApiRequestError(status, 'test');

void main() {
  group('GoogleCalendarService.isInsufficientScope', () {
    test('403 은 권한 부족이다', () {
      expect(GoogleCalendarService.isInsufficientScope(apiError(403)), isTrue);
    });

    test('401 은 권한 부족이다', () {
      expect(GoogleCalendarService.isInsufficientScope(apiError(401)), isTrue);
    });

    test('404 / 500 은 권한 문제가 아니다', () {
      expect(GoogleCalendarService.isInsufficientScope(apiError(404)), isFalse);
      expect(GoogleCalendarService.isInsufficientScope(apiError(500)), isFalse);
    });

    test('status 가 없는 API 오류는 권한 문제로 단정하지 않는다', () {
      expect(GoogleCalendarService.isInsufficientScope(apiError(null)), isFalse);
    });

    test('네트워크 장애는 권한 문제가 아니다', () {
      // 이걸 true 로 판정하면 연결이 안 되는 진짜 이유(오프라인)를 감추고
      // 사용자에게 권한을 다시 부여하라고 잘못 안내하게 된다.
      expect(
        GoogleCalendarService.isInsufficientScope(
          Exception('SocketException: Failed host lookup'),
        ),
        isFalse,
      );
    });
  });

  group('GoogleCalendarService.calendarScopes', () {
    test('로그인 구성과 스코프 재요청이 같은 목록을 본다', () {
      // 두 곳에 따로 적어 두면 한쪽만 고쳐져 조용히 어긋난다.
      expect(
        GoogleCalendarService.calendarScopes,
        containsAll(<String>[
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events',
        ]),
      );
    });
  });
}
