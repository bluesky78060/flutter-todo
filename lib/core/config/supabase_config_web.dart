/// Web implementation for reading environment variables from `window.ENV`.
///
/// `window.ENV`는 `scripts/inject_env.sh`가 `web/index.template.html`에 주입한다.
/// 값을 읽지 못하면 [SupabaseConfig]가 하드코딩 fallback으로 조용히 내려가므로,
/// 이 경로가 깨져도 겉으로는 티가 나지 않는다. 변경 시 주의할 것.
///
/// 레거시 `dart:html` + `dart:js_util` 대신 `package:web` + `dart:js_interop`을 쓴다.
/// 레거시 API는 Wasm 컴파일이 불가능하다.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

String? getEnvFromWindow(String key) {
  try {
    // JSObject로 직접 받는다. JSAny로 받은 뒤 `is JSObject`로 좁히면
    // 플랫폼(JS/Wasm)마다 결과가 달라질 수 있다는 린트에 걸린다.
    final env = web.window.getProperty<JSObject?>('ENV'.toJS);
    if (env == null) {
      return null;
    }

    final value = env.getProperty<JSAny?>(key.toJS);
    if (value == null) {
      return null;
    }

    final result = value.dartify()?.toString();
    if (result == null || result.isEmpty) {
      return null;
    }
    return result;
  } catch (e) {
    // window.ENV가 없거나 형태가 다르면 fallback에 맡긴다.
    return null;
  }
}
