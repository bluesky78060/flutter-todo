// Stub file for non-web platforms
// This file is used when dart:html is not available

// Stub window object for non-web platforms
class Window {
  dynamic operator [](String key) {
    throw UnsupportedError('Web-only feature not available on this platform');
  }
}

final Window window = Window();
