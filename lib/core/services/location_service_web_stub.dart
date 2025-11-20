// Stub file for non-web platforms
// This file is used when dart:js_interop is not available

// Stub classes that mimic the js_interop types
class JSPromise {
  Future<dynamic> get toDart async => throw UnsupportedError('Web-only');
}

class JSAny {
  dynamic dartify() => throw UnsupportedError('Web-only');
}

// Stub global context
class _GlobalContextStub {
  JSPromise callMethod(dynamic method, dynamic arg) {
    throw UnsupportedError('Web-only feature not available on this platform');
  }
}

final globalContext = _GlobalContextStub();

// Stub extension for String
extension StringToJSStub on String {
  String get toJS => this;
}
