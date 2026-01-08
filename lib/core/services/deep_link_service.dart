/// Deep link handling service for iOS OAuth callbacks.
///
/// This service listens for deep link URLs from iOS native code
/// and forwards them to Supabase for OAuth session handling.
///
/// Required for iOS where app_links plugin is not available.
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Service to handle deep links from iOS native code.
class DeepLinkService {
  static const _channel = MethodChannel('kr.bluesky.dodo/deeplink');
  static bool _isInitialized = false;
  static final _sessionController = StreamController<Session>.broadcast();

  /// Stream of successful sessions from deep links.
  static Stream<Session> get onSession => _sessionController.stream;

  /// Initialize the deep link listener.
  /// Should be called once during app startup.
  static void initialize() {
    if (_isInitialized) {
      logger.d('🔗 DeepLinkService: Already initialized');
      return;
    }

    // Only initialize on iOS
    if (kIsWeb || !Platform.isIOS) {
      logger.d('🔗 DeepLinkService: Skipping - not iOS');
      return;
    }

    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
    logger.d('🔗 DeepLinkService: Initialized for iOS');
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLink':
        final url = call.arguments as String?;
        if (url != null) {
          logger.d('🔗 DeepLinkService: Received URL: $url');
          await _handleDeepLink(url);
        }
        break;
      default:
        logger.w('🔗 DeepLinkService: Unknown method ${call.method}');
    }
  }

  static Future<void> _handleDeepLink(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      logger.d('🔗 DeepLinkService: Parsing URI: $uri');
      logger.d('🔗 DeepLinkService: Query params: ${uri.queryParameters}');

      // Check if this is an OAuth callback with code
      final code = uri.queryParameters['code'];
      if (code == null) {
        logger.w('🔗 DeepLinkService: No code in URL, ignoring');
        return;
      }

      logger.d('🔗 DeepLinkService: Found auth code, attempting session exchange...');

      try {
        // Try to exchange the code for a session using Supabase
        // This will work if we have the PKCE code verifier stored
        final response = await Supabase.instance.client.auth.getSessionFromUrl(
          uri,
          storeSession: true,
        );

        final session = response.session;
        logger.d('🔗 DeepLinkService: Session exchange result:');
        logger.d('   - User ID: ${session.user.id}');
        logger.d('   - Access token length: ${session.accessToken.length}');

        logger.d('✅ DeepLinkService: OAuth login successful!');
        _sessionController.add(session);
      } catch (sessionError) {
        // If session exchange fails (e.g., PKCE verifier not found),
        // it might be because the SDK already handled it or there's a state mismatch.
        // Log the error but don't treat it as fatal - the auth state listener
        // might still pick up the session change.
        logger.w('🔗 DeepLinkService: Session exchange failed: $sessionError');
        logger.d('🔗 DeepLinkService: Auth state listener may handle session update');
      }

    } catch (e, stackTrace) {
      logger.e('❌ DeepLinkService: Error handling deep link',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose the service resources.
  static void dispose() {
    _sessionController.close();
    _isInitialized = false;
  }
}
