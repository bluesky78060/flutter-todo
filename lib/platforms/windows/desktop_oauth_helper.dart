/// Desktop OAuth Helper for Windows/macOS/Linux
///
/// Handles OAuth authentication for desktop platforms by:
/// 1. Starting a local HTTP server to receive the OAuth callback
/// 2. Opening the OAuth URL in the default browser
/// 3. Parsing the auth tokens from the callback URL
/// 4. Setting the session in Supabase
library;

import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Helper class for handling OAuth on desktop platforms
class DesktopOAuthHelper {
  HttpServer? _server;
  static const int _port = 54321; // Fixed port for OAuth callback
  static const String _redirectPath = '/auth/callback';

  /// Get the redirect URL for OAuth
  static String get redirectUrl => 'http://localhost:$_port$_redirectPath';

  /// Start OAuth flow for the given provider
  /// Returns true if successful, false otherwise
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      logger.d('🚀 DesktopOAuth: Starting OAuth flow for $provider');

      // Start local server to receive callback
      await _startServer();

      // Get the OAuth URL from Supabase
      final supabase = Supabase.instance.client;

      // Generate the OAuth URL using getOAuthSignInUrl
      final oauthResponse = await supabase.auth.getOAuthSignInUrl(
        provider: provider,
        redirectTo: redirectUrl,
      );

      final authUrl = oauthResponse.url;
      logger.d('🔗 DesktopOAuth: OAuth URL: $authUrl');

      // Open the URL in the default browser
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        logger.d('✅ DesktopOAuth: Browser opened');
        return true;
      } else {
        logger.e('❌ DesktopOAuth: Could not launch URL');
        await _stopServer();
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('❌ DesktopOAuth: Error starting OAuth: $e');
      logger.e('Stack trace: $stackTrace');
      await _stopServer();
      return false;
    }
  }

  /// Start the local HTTP server
  Future<void> _startServer() async {
    await _stopServer(); // Stop any existing server

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      logger.d('✅ DesktopOAuth: Server started on port $_port');

      _server!.listen((request) async {
        logger.d('📥 DesktopOAuth: Received request: ${request.uri}');

        if (request.uri.path == _redirectPath) {
          await _handleCallback(request);
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });
    } catch (e) {
      logger.e('❌ DesktopOAuth: Failed to start server: $e');
      rethrow;
    }
  }

  /// Handle the OAuth callback
  Future<void> _handleCallback(HttpRequest request) async {
    try {
      // The tokens come in the URL fragment (#access_token=...&refresh_token=...)
      // But HTTP servers can't see fragments, so Supabase redirects with query params
      final uri = request.uri;
      logger.d('📥 DesktopOAuth: Callback URI: $uri');

      // Check for error
      final error = uri.queryParameters['error'];
      if (error != null) {
        final errorDescription = uri.queryParameters['error_description'] ?? error;
        logger.e('❌ DesktopOAuth: OAuth error: $errorDescription');
        await _sendResponse(request, false, errorDescription);
        return;
      }

      // Get tokens from query parameters
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];

      if (accessToken != null && refreshToken != null) {
        logger.d('✅ DesktopOAuth: Tokens received');

        // Set the session in Supabase
        final response = await Supabase.instance.client.auth.setSession(refreshToken);

        if (response.session != null) {
          logger.d('✅ DesktopOAuth: Session set successfully');
          await _sendResponse(request, true, null);
        } else {
          logger.e('❌ DesktopOAuth: Failed to set session');
          await _sendResponse(request, false, 'Failed to set session');
        }
      } else {
        // Try to get the code for PKCE flow
        final code = uri.queryParameters['code'];
        if (code != null) {
          logger.d('🔄 DesktopOAuth: Exchanging code for session');
          try {
            await Supabase.instance.client.auth.exchangeCodeForSession(code);
            logger.d('✅ DesktopOAuth: Session obtained from code exchange');
            await _sendResponse(request, true, null);
          } catch (e) {
            logger.e('❌ DesktopOAuth: Code exchange failed: $e');
            await _sendResponse(request, false, e.toString());
          }
        } else {
          logger.e('❌ DesktopOAuth: No tokens or code in callback');
          await _sendResponse(request, false, 'No tokens received');
        }
      }
    } catch (e, stackTrace) {
      logger.e('❌ DesktopOAuth: Error handling callback: $e');
      logger.e('Stack trace: $stackTrace');
      await _sendResponse(request, false, e.toString());
    } finally {
      // Stop the server after handling the callback
      await _stopServer();
    }
  }

  /// Send response to browser and close the page
  Future<void> _sendResponse(HttpRequest request, bool success, String? error) async {
    final successTitle = tr('login_success_title');
    final failedTitle = tr('login_failed_title');
    final successMessage = tr('login_success_message');
    final unknownError = tr('login_unknown_error');

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${success ? successTitle : failedTitle}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: ${success ? '#e8f5e9' : '#ffebee'};
    }
    .container {
      text-align: center;
      padding: 40px;
      background: white;
      border-radius: 16px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    }
    h1 { color: ${success ? '#2e7d32' : '#c62828'}; }
    p { color: #666; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>${success ? '✅ $successTitle!' : '❌ $failedTitle'}</h1>
    <p>${success ? successMessage : (error ?? unknownError)}</p>
    ${success ? '<script>setTimeout(() => window.close(), 2000);</script>' : ''}
  </div>
</body>
</html>
''';

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }

  /// Stop the local HTTP server
  Future<void> _stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      logger.d('🛑 DesktopOAuth: Server stopped');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _stopServer();
  }
}
