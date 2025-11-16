import 'package:flutter/foundation.dart';
// import 'package:sentry_flutter/sentry_flutter.dart'; // Temporarily disabled due to Kotlin version conflict
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Centralized error handling utility for the application
/// NOTE: Sentry integration is temporarily disabled due to build conflicts
class ErrorHandler {
  /// Report error to Sentry (production only)
  /// TODO: Re-enable after resolving Kotlin version conflict
  static Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    // Log error locally
    logger.e(
      context ?? 'Error occurred',
      error: error,
      stackTrace: stackTrace,
    );

    // Only report to Sentry in production (not debug mode)
    if (kDebugMode) {
      logger.d('Debug mode: Error not sent to Sentry');
      return;
    }

    // TODO: Re-enable Sentry after resolving Kotlin version conflict
    // try {
    //   await Sentry.captureException(
    //     error,
    //     stackTrace: stackTrace,
    //     hint: Hint.withMap({
    //       if (context != null) 'context': context,
    //       if (extras != null) ...extras,
    //     }),
    //   );
    //   logger.d('✅ Error reported to Sentry');
    // } catch (e) {
    //   logger.e('❌ Failed to report error to Sentry', error: e);
    // }
  }

  /// Report message to Sentry (for non-exception events)
  /// TODO: Re-enable after resolving Kotlin version conflict
  static Future<void> reportMessage(
    String message, {
    // SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    logger.i(message);

    if (kDebugMode) {
      return;
    }

    // TODO: Re-enable Sentry after resolving Kotlin version conflict
    // try {
    //   await Sentry.captureMessage(
    //     message,
    //     level: level,
    //     hint: Hint.withMap(extras ?? {}),
    //   );
    // } catch (e) {
    //   logger.e('❌ Failed to report message to Sentry', error: e);
    // }
  }

  /// Set user context for error tracking
  /// TODO: Re-enable after resolving Kotlin version conflict
  static Future<void> setUserContext({
    required String userId,
    String? email,
    String? username,
  }) async {
    if (kDebugMode) {
      return;
    }

    // TODO: Re-enable Sentry after resolving Kotlin version conflict
    // try {
    //   await Sentry.configureScope((scope) {
    //     scope.setUser(SentryUser(
    //       id: userId,
    //       email: email,
    //       username: username,
    //     ));
    //   });
    //   logger.d('✅ User context set for Sentry');
    // } catch (e) {
    //   logger.e('❌ Failed to set user context', error: e);
    // }
  }

  /// Clear user context (e.g., on logout)
  /// TODO: Re-enable after resolving Kotlin version conflict
  static Future<void> clearUserContext() async {
    if (kDebugMode) {
      return;
    }

    // TODO: Re-enable Sentry after resolving Kotlin version conflict
    // try {
    //   await Sentry.configureScope((scope) {
    //     scope.setUser(null);
    //   });
    //   logger.d('✅ User context cleared');
    // } catch (e) {
    //   logger.e('❌ Failed to clear user context', error: e);
    // }
  }

  /// Add breadcrumb for debugging context
  /// TODO: Re-enable after resolving Kotlin version conflict
  static void addBreadcrumb({
    required String message,
    String? category,
    // SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      logger.d('Breadcrumb: $message');
      return;
    }

    // TODO: Re-enable Sentry after resolving Kotlin version conflict
    // Sentry.addBreadcrumb(Breadcrumb(
    //   message: message,
    //   category: category,
    //   level: level,
    //   data: data,
    // ));
  }

  /// Get error message translation key from Failure
  static String getErrorMessageKey(Failure failure) {
    return switch (failure) {
      DatabaseFailure() => 'error_database',
      NetworkFailure() => 'error_network',
      ServerFailure() => 'error_server',
      CacheFailure() => 'error_cache',
      ValidationFailure() => 'error_validation',
      AuthenticationFailure() => 'error_authentication',
      _ => 'error_unknown',
    };
  }

  /// Handle and report Failure with translation key
  static Future<String> handleFailure(
    Failure failure, {
    String? context,
    StackTrace? stackTrace,
  }) async {
    final errorKey = getErrorMessageKey(failure);

    await reportError(
      failure,
      stackTrace ?? StackTrace.current,
      context: context,
      extras: {
        'failure_type': failure.runtimeType.toString(),
        'error_key': errorKey,
      },
    );

    return errorKey;
  }
}
