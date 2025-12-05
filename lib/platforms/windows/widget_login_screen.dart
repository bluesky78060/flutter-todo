/// Windows Widget Login Screen
///
/// A compact login screen for the Windows desktop widget.
/// Allows users to authenticate to sync their todos with Supabase.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:todo_app/core/config/oauth_redirect.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';

/// Compact login screen for the Windows widget
class WidgetLoginScreen extends ConsumerStatefulWidget {
  const WidgetLoginScreen({super.key});

  @override
  ConsumerState<WidgetLoginScreen> createState() => _WidgetLoginScreenState();
}

class _WidgetLoginScreenState extends ConsumerState<WidgetLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isOAuthLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  /// Close the widget window
  Future<void> _closeWidget() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.close();
    }
  }

  /// Google OAuth login
  Future<void> _loginWithGoogle() async {
    logger.d('🚀 Widget: Google login button clicked');
    setState(() {
      _isOAuthLoading = true;
      _errorMessage = null;
    });

    try {
      final redirectUrl = oauthRedirectUrl(provider: OAuthProvider.google);
      logger.d('🔗 Widget: Google OAuth redirectTo: $redirectUrl');

      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      logger.d('📱 Widget: Google OAuth response: $response');

      if (!response) {
        logger.e('❌ Widget: Google OAuth returned false');
        throw 'google_login_failed'.tr();
      }

      logger.d('✅ Widget: Google OAuth redirect initiated successfully');
    } catch (e, stackTrace) {
      logger.e('❌ Widget: Google OAuth error: $e');
      logger.e('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'google_login_failed'.tr();
          _isOAuthLoading = false;
        });
      }
    }
  }

  /// Kakao OAuth login
  Future<void> _loginWithKakao() async {
    logger.d('🚀 Widget: Kakao login button clicked');
    setState(() {
      _isOAuthLoading = true;
      _errorMessage = null;
    });

    try {
      final redirectUrl = oauthRedirectUrl(provider: OAuthProvider.kakao);
      logger.d('🔗 Widget: Kakao OAuth redirectTo: $redirectUrl');

      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      logger.d('📱 Widget: Kakao OAuth response: $response');

      if (!response) {
        logger.e('❌ Widget: Kakao OAuth returned false');
        throw 'kakao_login_failed'.tr();
      }

      logger.d('✅ Widget: Kakao OAuth redirect initiated successfully');
    } catch (e, stackTrace) {
      logger.e('❌ Widget: Kakao OAuth error: $e');
      logger.e('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'kakao_login_failed'.tr();
          _isOAuthLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'email_password_required'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authActions = ref.read(authActionsProvider);
      final error = await authActions.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (error != null) {
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      }
      // If login successful, the auth stream will automatically update
      // and the widget will switch to the calendar view
    } catch (e) {
      setState(() {
        _errorMessage = 'login_failed'.tr();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final primaryColor = ref.watch(primaryColorProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkBackground.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _closeWidget,
                  icon: Icon(
                    FluentIcons.dismiss_24_regular,
                    size: 20,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                  tooltip: 'close'.tr(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
            // App icon and title
            Icon(
              FluentIcons.calendar_24_filled,
              size: 48,
              color: primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'DoDo Calendar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDarkMode),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'login_to_sync'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondary(isDarkMode),
              ),
            ),
            const SizedBox(height: 20),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getText(isDarkMode),
              ),
              decoration: InputDecoration(
                hintText: 'email'.tr(),
                hintStyle: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  FluentIcons.mail_24_regular,
                  size: 18,
                  color: AppColors.getTextSecondary(isDarkMode),
                ),
                filled: true,
                fillColor: AppColors.getInput(isDarkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 12),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getText(isDarkMode),
              ),
              decoration: InputDecoration(
                hintText: 'password'.tr(),
                hintStyle: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  FluentIcons.lock_closed_24_regular,
                  size: 18,
                  color: AppColors.getTextSecondary(isDarkMode),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? FluentIcons.eye_24_regular
                        : FluentIcons.eye_off_24_regular,
                    size: 18,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColors.getInput(isDarkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.warning_24_regular,
                      size: 16,
                      color: AppColors.dangerRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.dangerRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isOAuthLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'login'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider with "or" text
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getTextSecondary(isDarkMode),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Google login button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading || _isOAuthLoading ? null : _loginWithGoogle,
                icon: _isOAuthLoading
                    ? const SizedBox.shrink()
                    : Image.asset(
                        'assets/icon/google_logo.png',
                        width: 18,
                        height: 18,
                      ),
                label: _isOAuthLoading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.getText(isDarkMode),
                          ),
                        ),
                      )
                    : Text(
                        'google_login'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getText(isDarkMode),
                        ),
                      ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(
                    color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Kakao login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _isOAuthLoading ? null : _loginWithKakao,
                icon: _isOAuthLoading
                    ? const SizedBox.shrink()
                    : Image.asset(
                        'assets/icon/kakao_logo.png',
                        width: 18,
                        height: 18,
                      ),
                label: _isOAuthLoading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3C1E1E),
                          ),
                        ),
                      )
                    : Text(
                        'kakao_login'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3C1E1E),
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info text
            Text(
              'widget_login_info'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.getTextSecondary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
