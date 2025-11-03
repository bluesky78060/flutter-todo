import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      _showSnackBar('이메일과 비밀번호를 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && response.user != null) {
        // 로그인 성공 - 자동 리디렉션
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('로그인 실패: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('이메일과 비밀번호를 입력해주세요');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('비밀번호는 최소 6자 이상이어야 합니다');
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
          _showSnackBar('회원가입 성공! 이제 로그인할 수 있습니다.', isSuccess: true);
          setState(() => _isSignUpMode = false);
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('회원가입 실패: ${e.toString()}');
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
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://fascinating-peony-8bbb51.netlify.app',
      );

      if (!response) {
        throw 'Google 로그인 실패';
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Google 로그인 실패: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: 'https://fascinating-peony-8bbb51.netlify.app',
      );

      if (!response) {
        throw 'Kakao 로그인 실패';
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Kakao 로그인 실패: ${e.toString()}');
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
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1), // Indigo
                  Color(0xFF9333EA), // Purple
                  Color(0xFFEC4899), // Pink
                ],
              ),
            ),
          ),

          // Floating Orbs
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildFloatingOrb(
                    color: Colors.purple.withOpacity(0.3),
                    offset: Offset(
                      100 * math.sin(_animationController.value * 2 * math.pi),
                      -100 * math.cos(_animationController.value * 2 * math.pi),
                    ),
                    top: 80,
                    left: 80,
                  ),
                  _buildFloatingOrb(
                    color: Colors.pink.withOpacity(0.3),
                    offset: Offset(
                      -100 * math.sin(_animationController.value * 2 * math.pi * 0.75),
                      100 * math.cos(_animationController.value * 2 * math.pi * 0.75),
                    ),
                    bottom: 80,
                    right: 80,
                  ),
                  _buildFloatingOrb(
                    color: Colors.blue.withOpacity(0.3),
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
                  shadowColor: Colors.black.withOpacity(0.3),
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
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
                                    color: Colors.blue.withOpacity(0.3),
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
                            const SizedBox(height: 16),

                            // Title
                            const Text(
                              'Todo App',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '소셜 계정으로 간편하게 로그인하세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Email Input
                            _buildInputField(
                              controller: _emailController,
                              hintText: '이메일',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // Password Input
                            _buildInputField(
                              controller: _passwordController,
                              hintText: '비밀번호',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              onSubmitted: (_) => _isSignUpMode
                                  ? _signUpWithEmail()
                                  : _signInWithEmail(),
                            ),
                            const SizedBox(height: 24),

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
                                  shadowColor: Colors.blue.withOpacity(0.5),
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
                                        _isSignUpMode ? '회원가입' : '로그인',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Toggle Sign Up/Login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUpMode
                                      ? '이미 계정이 있으신가요?'
                                      : '계정이 없으신가요?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
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
                                    _isSignUpMode ? '로그인' : '회원가입',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Divider
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '또는',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Social Login Buttons
                            _buildSocialButton(
                              label: 'Google로 로그인',
                              icon: Icons.g_mobiledata,
                              color: Colors.white,
                              textColor: Colors.black87,
                              onPressed: _signInWithGoogle,
                            ),
                            const SizedBox(height: 12),
                            _buildSocialButton(
                              label: 'Kakao로 로그인',
                              icon: Icons.chat_bubble,
                              color: const Color(0xFFFEE500),
                              textColor: Colors.black87,
                              onPressed: _signInWithKakao,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: !_isLoading,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
