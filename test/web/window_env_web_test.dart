@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/config/supabase_config_web.dart';
import 'package:web/web.dart' as web;

/// DTA-1-2: `window.ENV` 읽기 경로 검증.
///
/// `SupabaseConfig`는 `window.ENV`를 못 읽으면 하드코딩 fallback으로 조용히
/// 내려간다. 즉 이 경로가 깨져도 앱은 아무 오류 없이 동작하는 것처럼 보인다.
/// 그래서 읽기 성공 / 키 누락 / ENV 자체 부재 세 경로를 모두 못박아 둔다.
///
/// 비밀값이 필요 없도록 고유한 sentinel 값을 쓴다.
///
/// 실행: flutter test --platform chrome test/web/window_env_web_test.dart
void main() {
  const sentinel = 'SENTINEL_SUPABASE_URL_7f3a';

  void clearEnv() {
    web.window.delete('ENV'.toJS);
  }

  setUp(clearEnv);
  tearDown(clearEnv);

  test('window.ENV가 없으면 null을 돌려준다 (fallback으로 내려감)', () {
    expect(getEnvFromWindow('SUPABASE_URL'), isNull);
  });

  test('window.ENV는 있으나 키가 없으면 null을 돌려준다', () {
    final env = JSObject();
    env.setProperty('SOMETHING_ELSE'.toJS, 'x'.toJS);
    web.window.setProperty('ENV'.toJS, env);

    expect(getEnvFromWindow('SUPABASE_URL'), isNull);
  });

  test('window.ENV에 값이 있으면 그 값을 그대로 돌려준다', () {
    final env = JSObject();
    env.setProperty('SUPABASE_URL'.toJS, sentinel.toJS);
    web.window.setProperty('ENV'.toJS, env);

    expect(getEnvFromWindow('SUPABASE_URL'), sentinel);
  });

  test('빈 문자열은 값이 없는 것으로 취급한다', () {
    final env = JSObject();
    env.setProperty('SUPABASE_URL'.toJS, ''.toJS);
    web.window.setProperty('ENV'.toJS, env);

    expect(getEnvFromWindow('SUPABASE_URL'), isNull);
  });
}
