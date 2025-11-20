// Stub file for non-web platforms
// This file is used when dart:js_interop is not available

// Stub classes that mimic the js_interop types
class JSPromise {}
class JSAny {}

// Stub global context
class _GlobalContextStub {
  dynamic callMethod(dynamic method, dynamic arg) {
    throw UnsupportedError('Web-only feature not available on this platform');
  }
}

final globalContext = _GlobalContextStub();

// Stub extension for String
extension StringToJSStub on String {
  dynamic get toJS => this;
}
