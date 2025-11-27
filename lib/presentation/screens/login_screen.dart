import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/config/oauth_redirect.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUpMode = false; // 회원가입 모드 토글

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    logger.d('🚀 Google login button clicked');
    setState(() => _isLoading = true);

    try {
      // Supabase OAuth 플로우 사용 (웹에서 작동)
      final redirectUrl = oauthRedirectUrl();
      logger.d('🔗 Google OAuth redirectTo: $redirectUrl');
      logger.d('🔑 Supabase client initialized');

      final response = redirectUrl == null
          ? await Supabase.instance.client.auth.signInWithOAuth(
              OAuthProvider.google,
            )
          : await Supabase.instance.client.auth.signInWithOAuth(
              OAuthProvider.google,
              redirectTo: redirectUrl,
            );

      logger.d('📱 OAuth response: $response');

      if (!response) {
        logger.e('❌ OAuth returned false');
        throw 'google_login_failed'.tr();
      }

      logger.d('✅ OAuth redirect initiated successfully');
      // OAuth 플로우가 성공하면 자동으로 리디렉션됨
    } catch (e, stackTrace) {
      logger.e('❌ Google OAuth error: $e');
      logger.e('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'google_login_failed'.tr()}: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);

    try {
      // Kakao OAuth는 Supabase에서 제공하는 OAuth 플로우 사용
      final redirectUrl = oauthRedirectUrl();
      logger.d('🔗 Kakao OAuth redirectTo: $redirectUrl');

      final response = redirectUrl == null
          ? await Supabase.instance.client.auth.signInWithOAuth(
              OAuthProvider.kakao,
            )
          : await Supabase.instance.client.auth.signInWithOAuth(
              OAuthProvider.kakao,
              redirectTo: redirectUrl,
            );

      if (!response) {
        throw 'kakao_login_failed'.tr();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'kakao_login_failed'.tr()}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('email_password_required'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && response.user != null) {
        // 로그인 성공
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'login_failed'.tr()}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('email_password_required'.tr())),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('password_min_length'.tr())),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('signup_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _isSignUpMode = false);
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'sign_up_failed'.tr()}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getCard(isDarkMode),
        title: Text(
          'login'.tr(),
          style: TextStyle(color: AppColors.getText(isDarkMode)),
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.getText(isDarkMode),
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 앱 로고 또는 타이틀
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Todo App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(isDarkMode),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'login_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(isDarkMode),
                ),
              ),
              const SizedBox(height: 32),

              // 이메일 로그인 폼 (항상 표시)
              TextField(
                controller: _emailController,
                style: TextStyle(color: AppColors.getText(isDarkMode)),
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  labelStyle: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                  hintText: 'example@email.com',
                  hintStyle: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.getBorder(isDarkMode)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.getBorder(isDarkMode)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.getInput(isDarkMode),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                style: TextStyle(color: AppColors.getText(isDarkMode)),
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  labelStyle: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                  hintText: 'password_min_length'.tr(),
                  hintStyle: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.getBorder(isDarkMode)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.getBorder(isDarkMode)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.getInput(isDarkMode),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                ),
                obscureText: true,
                enabled: !_isLoading,
                onSubmitted: (_) =>
                    _isSignUpMode ? _signUpWithEmail() : _signInWithEmail(),
              ),
              const SizedBox(height: 24),

              // 로그인/회원가입 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isSignUpMode ? _signUpWithEmail : _signInWithEmail),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // 로그인/회원가입 전환
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUpMode
                        ? 'already_have_account'.tr()
                        : 'dont_have_account'.tr(),
                    style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _isSignUpMode = !_isSignUpMode);
                            _passwordController.clear();
                          },
                    child: Text(
                      _isSignUpMode ? 'login'.tr() : 'sign_up'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.getBorder(isDarkMode))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or'.tr(),
                      style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.getBorder(isDarkMode))),
                ],
              ),
              const SizedBox(height: 12),

              // SNS 로그인 버튼
              // Google 로그인 버튼
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.g_mobiledata, size: 24, color: AppColors.getText(isDarkMode)),
                ),
                label: Text(
                  'google_login'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getText(isDarkMode),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.getBorder(isDarkMode)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kakao 로그인 버튼
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithKakao,
                icon: const Icon(Icons.chat_bubble, size: 24, color: Colors.black87),
                label: Text(
                  'kakao_login'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
