// Stub file for non-web platforms
// This file is used when dart:html and dart:js_util are not available

// Stub window object for non-web platforms
class _WindowStub {
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('Web-only feature not available on this platform');
  }
}

final window = _WindowStub();

// Stub for js_util functions
T getProperty<T>(Object o, String name) {
  throw UnsupportedError('Web-only feature not available on this platform');
}
