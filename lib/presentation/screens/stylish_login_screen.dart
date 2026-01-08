/// Stylish login screen with animated background and modern UI.
///
/// Features:
/// - Animated gradient background
/// - Glassmorphic card design
/// - Email/password authentication
/// - Google OAuth (all platforms)
/// - Apple Sign In (iOS/macOS)
/// - Kakao OAuth (Korean market)
/// - Remember me option
/// - Sign up mode toggle
///
/// Platform-specific:
/// - iOS: Shows native Apple Sign In button
/// - Android/Web: Hides Apple Sign In
///
/// See also:
/// - [LoginScreen] for standard login UI
/// - [OAuthCallbackScreen] for OAuth completion
library;

import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/config/oauth_redirect.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/core/theme/app_colors.dart';

/// Stylish login screen with animated UI and multiple auth options.
class StylishLoginScreen extends ConsumerStatefulWidget {
  const StylishLoginScreen({super.key});

  @override
  ConsumerState<StylishLoginScreen> createState() => _StylishLoginScreenState();
}

class _StylishLoginScreenState extends ConsumerState<StylishLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _rememberMe = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('email_password_required'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      logger.d('🔐 로그인 시도: ${_emailController.text.trim()}');
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      logger.d('✅ 로그인 응답: user=${response.user?.id}, session=${response.session?.accessToken != null}');

      if (mounted && response.user != null) {
        logger.d('✅ 로그인 성공 - StreamProvider가 자동으로 업데이트합니다');
        _showSnackBar('login_success'.tr(), isSuccess: true);
        // No need to invalidate - StreamProvider will auto-update
      }
    } catch (e) {
      logger.d('❌ 로그인 에러: $e');
      if (mounted) {
        _showSnackBar('${'login_failed'.tr()}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('email_password_required'.tr());
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('password_min_length'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (response.user != null) {
          _showSnackBar('signup_success'.tr(), isSuccess: true);
          setState(() => _isSignUpMode = false);
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${'sign_up_failed'.tr()}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // On iOS, don't use redirectTo - let Supabase SDK handle it with platformDefault
      // This uses ASWebAuthenticationSession which properly maintains PKCE state
      final isIOS = !kIsWeb && Platform.isIOS;

      if (isIOS) {
        // iOS: Use externalApplication to open Safari
        // Safari will show "Open in DoDo?" prompt when redirecting to custom URL scheme
        // DeepLinkService will receive the callback and exchange code for session
        final redirectUrl = oauthRedirectUrl();
        logger.d('🔗 Google OAuth: Using externalApplication for iOS with redirect: $redirectUrl');
        final response = await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
        logger.d('🔗 Google OAuth response: $response');
        // externalApplication opens Safari, DeepLinkService handles the callback
        // Reset loading state - auth stream will handle navigation
        if (mounted) {
          setState(() => _isLoading = false);
        }
        // Don't show error for iOS - the response can be false but auth still succeeds via callback
        return;
      } else {
        // Other platforms: Use custom redirect URL
        final redirectUrl = oauthRedirectUrl();
        logger.d('🔗 Google OAuth redirectTo: $redirectUrl');

        final response = redirectUrl == null
            ? await Supabase.instance.client.auth.signInWithOAuth(
                OAuthProvider.google,
                authScreenLaunchMode: LaunchMode.inAppWebView,
              )
            : await Supabase.instance.client.auth.signInWithOAuth(
                OAuthProvider.google,
                redirectTo: redirectUrl,
                authScreenLaunchMode: LaunchMode.inAppWebView,
              );

        if (!response) {
          throw 'google_login_failed'.tr();
        }
      }
    } catch (e) {
      // On iOS, Safari session closure can throw errors even on successful auth
      // DeepLinkService will handle the callback, so we ignore errors on iOS
      final isIOS = !kIsWeb && Platform.isIOS;
      if (mounted) {
        if (!isIOS) {
          _showSnackBar('${'google_login_failed'.tr()}: ${e.toString()}');
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);

    try {
      // On iOS, don't use redirectTo - let Supabase SDK handle it with platformDefault
      // This uses ASWebAuthenticationSession which properly maintains PKCE state
      final isIOS = !kIsWeb && Platform.isIOS;

      if (isIOS) {
        // iOS: Use externalApplication to open Safari
        // Safari will show "Open in DoDo?" prompt when redirecting to custom URL scheme
        // DeepLinkService will receive the callback and exchange code for session
        final redirectUrl = oauthRedirectUrl(provider: OAuthProvider.kakao);
        logger.d('🔗 Kakao OAuth: Using externalApplication for iOS with redirect: $redirectUrl');
        final response = await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.kakao,
          redirectTo: redirectUrl,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
        logger.d('🔗 Kakao OAuth response: $response');
        // externalApplication opens Safari, DeepLinkService handles the callback
        // Reset loading state - auth stream will handle navigation
        if (mounted) {
          setState(() => _isLoading = false);
        }
        // Don't show error for iOS - the response can be false but auth still succeeds via callback
        return;
      } else {
        // Other platforms: Use custom redirect URL
        final redirectUrl = oauthRedirectUrl(provider: OAuthProvider.kakao);
        logger.d('🔗 Kakao OAuth redirectTo: $redirectUrl');

        final response = redirectUrl == null
            ? await Supabase.instance.client.auth.signInWithOAuth(
                OAuthProvider.kakao,
                authScreenLaunchMode: LaunchMode.externalApplication,
              )
            : await Supabase.instance.client.auth.signInWithOAuth(
                OAuthProvider.kakao,
                redirectTo: redirectUrl,
                authScreenLaunchMode: LaunchMode.externalApplication,
              );

        if (!response) {
          throw 'kakao_login_failed'.tr();
        }
      }
    } catch (e) {
      // On iOS, Safari session closure can throw errors even on successful auth
      // DeepLinkService will handle the callback, so we ignore errors on iOS
      final isIOS = !kIsWeb && Platform.isIOS;
      if (mounted) {
        if (!isIOS) {
          _showSnackBar('${'kakao_login_failed'.tr()}: ${e.toString()}');
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      logger.d('🍎 Starting Apple Sign In...');

      // Request Apple Sign In credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      logger.d('🍎 Apple Sign In credential received');
      logger.d('🍎 identityToken: ${credential.identityToken != null}');
      logger.d('🍎 authorizationCode: ${credential.authorizationCode}');

      // Sign in to Supabase with Apple credentials
      final authResponse = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        accessToken: credential.authorizationCode,
      );

      logger.d('✅ Apple Sign In 응답: user=${authResponse.user?.id}, session=${authResponse.session?.accessToken != null}');

      if (mounted && authResponse.user != null) {
        logger.d('✅ Apple Sign In 성공 - StreamProvider가 자동으로 업데이트합니다');
        _showSnackBar('login_success'.tr(), isSuccess: true);
      }
    } catch (e) {
      logger.e('❌ Apple Sign In 에러: $e');
      if (mounted) {
        _showSnackBar('${'apple_login_failed'.tr()}: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('enter_email_for_reset'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: oauthRedirectUrl(),
      );

      if (mounted) {
        _showSnackBar(
          'reset_password_email_sent'.tr(),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${'reset_password_failed'.tr()}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Dynamic Colors
    final gradientColors = isDark
        ? [
            const Color(0xFF1E293B), // Slate 800
            const Color(0xFF0F172A), // Slate 900
            const Color(0xFF020617), // Slate 950
          ]
        : [
            const Color(0xFFF0F9FF), // Sky 50
            const Color(0xFFE0F2FE), // Sky 100
            const Color(0xFFBAE6FD), // Sky 200
          ];

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF475569);
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.7);
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5);
    final inputFillColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);
    final inputBorderColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1);
    final inputHintColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4);
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5);

    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),

          // Theme Toggle Button (Top Right)
          Positioned(
            top: 48,
            right: 24,
            child: _buildThemeToggleButton(isDark),
          ),

          // Floating Orbs
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              const orbOpacity = 0.2;
              return Stack(
                children: [
                  _buildFloatingOrb(
                    color: const Color(0xFF475569).withValues(alpha: orbOpacity),
                    offset: Offset(
                      100 * math.sin(_animationController.value * 2 * math.pi),
                      -100 * math.cos(_animationController.value * 2 * math.pi),
                    ),
                    top: 80,
                    left: 80,
                  ),
                  _buildFloatingOrb(
                    color: const Color(0xFF334155).withValues(alpha: orbOpacity),
                    offset: Offset(
                      -100 * math.sin(_animationController.value * 2 * math.pi * 0.75),
                      100 * math.cos(_animationController.value * 2 * math.pi * 0.75),
                    ),
                    bottom: 80,
                    right: 80,
                  ),
                  _buildFloatingOrb(
                    color: const Color(0xFF1E293B).withValues(alpha: orbOpacity),
                    offset: Offset(
                      200 * math.sin(_animationController.value * 2 * math.pi * 0.9),
                      200 * math.cos(_animationController.value * 2 * math.pi * 0.9),
                    ),
                    top: MediaQuery.of(context).size.height / 2,
                    left: MediaQuery.of(context).size.width / 2,
                  ),
                ],
              );
            },
          ),

          // Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 24,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Stack(
                        children: [
                          // Main content
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            // App Icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              'Todo App',
                              style: TextStyle(
                                fontSize: AppColors.scaledFontSize(28),
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'login_subtitle'.tr(),
                              style: TextStyle(
                                fontSize: AppColors.scaledFontSize(14),
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Email Input
                            _buildInputField(
                              controller: _emailController,
                              hintText: 'email'.tr(),
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              fillColor: inputFillColor,
                              borderColor: inputBorderColor,
                              hintColor: inputHintColor,
                              iconColor: iconColor,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 12),

                            // Password Input
                            _buildInputField(
                              controller: _passwordController,
                              hintText: 'password'.tr(),
                              icon: Icons.lock_outline,
                              obscureText: true,
                              onSubmitted: (_) => _isSignUpMode
                                  ? _signUpWithEmail()
                                  : _signInWithEmail(),
                              fillColor: inputFillColor,
                              borderColor: inputBorderColor,
                              hintColor: inputHintColor,
                              iconColor: iconColor,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 12),

                            // Remember Me & Forgot Password (only show in login mode)
                            if (!_isSignUpMode)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Remember Me Checkbox
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: _isLoading
                                              ? null
                                              : (value) {
                                                  setState(() => _rememberMe = value ?? false);
                                                },
                                          fillColor: WidgetStateProperty.resolveWith<Color>(
                                            (states) {
                                              if (states.contains(WidgetState.disabled)) {
                                                return inputBorderColor;
                                              }
                                              return states.contains(WidgetState.selected)
                                                  ? const Color(0xFF3B82F6)
                                                  : inputBorderColor;
                                            },
                                          ),
                                          checkColor: Colors.white,
                                          side: BorderSide(
                                            color: inputBorderColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'remember_me'.tr(),
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: AppColors.scaledFontSize(14),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Forgot Password Link
                                  TextButton(
                                    onPressed: _isLoading ? null : _resetPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'forgot_password'.tr(),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: AppColors.scaledFontSize(14),
                                        decoration: TextDecoration.underline,
                                        decorationColor: subTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            SizedBox(height: _isSignUpMode ? 20 : 12),

                            // Login/SignUp Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (_isSignUpMode
                                        ? _signUpWithEmail
                                        : _signInWithEmail),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: Colors.blue.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isSignUpMode ? 'sign_up'.tr() : 'login'.tr(),
                                        style: TextStyle(
                                          fontSize: AppColors.scaledFontSize(16),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Toggle Sign Up/Login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUpMode
                                      ? 'already_have_account'.tr()
                                      : 'dont_have_account'.tr(),
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: AppColors.scaledFontSize(14),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() =>
                                              _isSignUpMode = !_isSignUpMode);
                                          _passwordController.clear();
                                        },
                                  child: Text(
                                    _isSignUpMode ? 'login'.tr() : 'sign_up'.tr(),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppColors.scaledFontSize(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Divider
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: inputBorderColor,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'or'.tr(),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: AppColors.scaledFontSize(13),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: inputBorderColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Social Login Buttons
                            _buildSocialButton(
                              label: 'google_login'.tr(),
                              icon: Icons.g_mobiledata,
                              color: Colors.white,
                              textColor: Colors.black87,
                              onPressed: _signInWithGoogle,
                            ),
                            const SizedBox(height: 12),
                            _buildSocialButton(
                              label: 'kakao_login'.tr(),
                              icon: Icons.chat_bubble,
                              color: const Color(0xFFFEE500),
                              textColor: Colors.black87,
                              onPressed: _signInWithKakao,
                            ),
                            // Apple Login (iOS only)
                            if (!kIsWeb && Platform.isIOS) ...[
                              const SizedBox(height: 12),
                              _buildSocialButton(
                                label: 'apple_login'.tr(),
                                icon: Icons.apple,
                                color: Colors.black,
                                textColor: Colors.white,
                                onPressed: _signInWithApple,
                              ),
                            ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Theme Toggle Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: textColor,
              ),
              style: IconButton.styleFrom(
                backgroundColor: isDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingOrb({
    required Color color,
    required Offset offset,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top != null ? top + offset.dy : null,
      bottom: bottom != null ? bottom + offset.dy : null,
      left: left != null ? left + offset.dx : null,
      right: right != null ? right + offset.dx : null,
      child: Container(
        width: 288,
        height: 288,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Function(String)? onSubmitted,
    required Color fillColor,
    required Color borderColor,
    required Color hintColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: !_isLoading,
        onSubmitted: onSubmitted,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(icon, color: iconColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: TextStyle(
            fontSize: AppColors.scaledFontSize(16),
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 라이트 모드 버튼
              _buildThemeModeButton(
                icon: Icons.wb_sunny,
                isSelected: !isDark,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                },
                isDark: isDark,
              ),
              // 다크 모드 버튼
              _buildThemeModeButton(
                icon: Icons.nightlight_round,
                isSelected: isDark,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF2563EB).withValues(alpha: 0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF2563EB))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
