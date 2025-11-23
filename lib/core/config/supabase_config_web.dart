import 'dart:js_util' as js_util;
import 'dart:html' as html;

/// Web implementation for reading environment variables from window.ENV
String? getEnvFromWindow(String key) {
  try {
    final env = js_util.getProperty(html.window, 'ENV');
    if (env != null) {
      final value = js_util.getProperty(env, key);
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
  } catch (e) {
    // Return null on error
  }
  return null;
}