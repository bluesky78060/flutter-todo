import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global app logger with production-safe configuration
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // Number of method calls to be displayed
    errorMethodCount: 5, // Number of method calls if stacktrace is provided
    lineLength: 80, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print emoji for each log
    dateTimeFormat: DateTimeFormat.onlyTime, // Time format
  ),
  level: kDebugMode ? Level.debug : Level.info, // Production vs Debug
  filter: ProductionFilter(), // Don't log in production release
);

/// Simple logger for less verbose output
final simpleLogger = Logger(
  printer: SimplePrinter(
    colors: true,
    printTime: true,
  ),
  level: kDebugMode ? Level.debug : Level.info,
  filter: ProductionFilter(),
);

/// Static logger wrapper for cleaner API
class AppLogger {
  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }
}
