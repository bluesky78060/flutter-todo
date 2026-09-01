/// Google Calendar 서비스 프로바이더.
///
/// 별도 파일인 이유: 이 프로바이더는 google_calendar_provider.dart 안에
/// 있었는데, 그 파일이 todo_providers.dart 를 import 한다. 그래서
/// todo_providers 쪽에서 캘린더 서비스를 쓰려면 순환 import 가 됐다.
///
/// 아무것도 의존하지 않는 리프 프로바이더를 리프 파일로 내려 두면
/// 양쪽이 순환 없이 참조할 수 있다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/google_calendar_service.dart';

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});
