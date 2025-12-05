/// Profile editing screen for managing user profile.
///
/// Features:
/// - Display name editing
/// - Avatar image upload (gallery/camera)
/// - Avatar removal
/// - Profile preview
///
/// Uses Glassmorphic UI design consistent with Settings screen.
library;

import 'dart:ui';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/profile_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Profile editing screen widget.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _displayNameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isEditing = false;
  bool _isSettingPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _displayNameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Initialize with current display name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(profileProvider);
      final authState = ref.read(currentUserProvider);
      authState.whenData((user) {
        if (user != null) {
          _displayNameController.text =
              profileState.displayName ?? user.name;
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(currentUserProvider);

    final gradientColors = isDarkMode
        ? [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
            const Color(0xFF020617),
          ]
        : [
            const Color(0xFFF0F9FF),
            const Color(0xFFE0F2FE),
            const Color(0xFFBAE6FD),
          ];

    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final subTextColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),

          // Floating Orbs
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              const orbOpacity = 0.15;
              return Stack(
                children: [
                  _buildFloatingOrb(
                    color: AppColors.primary.withValues(alpha: orbOpacity),
                    offset: Offset(
                      80 * math.sin(_animationController.value * 2 * math.pi),
                      -80 * math.cos(_animationController.value * 2 * math.pi),
                    ),
                    top: 120,
                    right: 40,
                  ),
                ],
              );
            },
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, isDarkMode, textColor),

                // Profile Content
                Expanded(
                  child: authState.when(
                    data: (user) {
                      if (user == null) {
                        return Center(
                          child: Text(
                            'login_required'.tr(),
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Avatar Section
                            _buildAvatarSection(
                              isDarkMode,
                              textColor,
                              profileState,
                              user.displayName ?? user.name,
                              user.avatarUrl,
                            ),
                            const SizedBox(height: 32),

                            // Display Name Section
                            _buildDisplayNameSection(
                              isDarkMode,
                              textColor,
                              subTextColor,
                              profileState,
                              user.displayName ?? user.name,
                            ),
                            const SizedBox(height: 24),

                            // Email Section (read-only)
                            _buildEmailSection(
                              isDarkMode,
                              textColor,
                              subTextColor,
                              user.email,
                            ),
                            const SizedBox(height: 24),

                            // Password Section (for SNS login users)
                            _buildPasswordSection(
                              isDarkMode,
                              textColor,
                              subTextColor,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Text(
                        'error_loading_profile'.tr(),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (profileState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
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
        width: 200,
        height: 200,
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

  Widget _buildHeader(BuildContext context, bool isDarkMode, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildGlassIconButton(
            icon: FluentIcons.arrow_left_24_regular,
            onPressed: () => Navigator.pop(context),
            isDarkMode: isDarkMode,
            color: textColor,
          ),
          const SizedBox(width: 16),
          Text(
            'edit_profile'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required bool isDarkMode, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
    bool isDarkMode,
    Color textColor,
    ProfileState profileState,
    String fallbackName,
    String? userAvatarUrl,
  ) {
    final avatarUrl = profileState.avatarUrl ?? userAvatarUrl;
    final displayName = profileState.displayName ?? fallbackName;

    return _buildGlassCard(
      isDarkMode: isDarkMode,
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _showAvatarOptions,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: avatarUrl == null ? AppColors.primaryGradient : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(displayName),
                          ),
                        )
                      : _buildAvatarPlaceholder(displayName),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      FluentIcons.camera_24_filled,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'tap_to_change_photo'.tr(),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDisplayNameSection(
    bool isDarkMode,
    Color textColor,
    Color subTextColor,
    ProfileState profileState,
    String fallbackName,
  ) {
    return _buildGlassCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FluentIcons.person_24_regular,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'display_name'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'enter_display_name'.tr(),
              hintStyle: TextStyle(color: subTextColor),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (_) => setState(() => _isEditing = true),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEditing ? _saveDisplayName : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('save_changes'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(
    bool isDarkMode,
    Color textColor,
    Color subTextColor,
    String email,
  ) {
    return _buildGlassCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FluentIcons.mail_24_regular,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'email'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              email,
              style: TextStyle(color: subTextColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'email_cannot_be_changed'.tr(),
            style: TextStyle(
              color: subTextColor.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(
    bool isDarkMode,
    Color textColor,
    Color subTextColor,
  ) {
    return _buildGlassCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FluentIcons.key_24_regular,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'set_password'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'set_password_description'.tr(),
            style: TextStyle(
              color: subTextColor.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // New Password Field
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'new_password'.tr(),
              hintStyle: TextStyle(color: subTextColor),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? FluentIcons.eye_24_regular
                      : FluentIcons.eye_off_24_regular,
                  color: subTextColor,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Confirm Password Field
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'confirm_password'.tr(),
              hintStyle: TextStyle(color: subTextColor),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? FluentIcons.eye_24_regular
                      : FluentIcons.eye_off_24_regular,
                  color: subTextColor,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSettingPassword ? null : _setPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSettingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('set_password'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate password length
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('password_min_length'.tr())),
      );
      return;
    }

    // Validate passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('passwords_not_match'.tr())),
      );
      return;
    }

    setState(() => _isSettingPassword = true);

    try {
      logger.d('🔐 Setting password for user');
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      logger.d('✅ Password set successfully');

      if (mounted) {
        // Clear password fields
        _passwordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('password_set_success'.tr())),
        );
      }
    } catch (e) {
      logger.e('❌ Failed to set password: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'password_set_failed'.tr()}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettingPassword = false);
      }
    }
  }

  void _showAvatarOptions() {
    final isDarkMode = ref.read(isDarkModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGlassCard(
        isDarkMode: isDarkMode,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'change_profile_photo'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            if (!kIsWeb) ...[
              _buildAvatarOption(
                icon: FluentIcons.camera_24_regular,
                title: 'take_photo'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarFromCamera();
                },
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
            ],
            _buildAvatarOption(
              icon: FluentIcons.image_24_regular,
              title: 'choose_from_gallery'.tr(),
              onTap: () {
                Navigator.pop(context);
                _pickAvatarFromGallery();
              },
              isDarkMode: isDarkMode,
            ),
            Builder(builder: (context) {
              final profileState = ref.read(profileProvider);
              final authState = ref.read(currentUserProvider);
              final hasAvatar = profileState.avatarUrl != null ||
                  (authState.value?.avatarUrl != null);
              if (!hasAvatar) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 12),
                  _buildAvatarOption(
                    icon: FluentIcons.delete_24_regular,
                    title: 'remove_photo'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      _removeAvatar();
                    },
                    isDarkMode: isDarkMode,
                    isDestructive: true,
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red
        : (isDarkMode ? Colors.white : Colors.black);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDisplayName() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('display_name_required'.tr())),
      );
      return;
    }

    final success =
        await ref.read(profileProvider.notifier).updateDisplayName(displayName);

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_updated'.tr())),
        );
      } else {
        final error = ref.read(profileProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'update_failed'.tr())),
        );
      }
    }
  }

  Future<void> _pickAvatarFromGallery() async {
    if (kIsWeb) {
      // Web: use file_picker with bytes
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final success = await ref
              .read(profileProvider.notifier)
              .uploadAvatarFromBytes(file.bytes!, file.name);

          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('avatar_updated'.tr())),
            );
          }
        }
      }
    } else {
      // Mobile: use image_picker
      final success =
          await ref.read(profileProvider.notifier).pickAndUploadAvatar();

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('avatar_updated'.tr())),
        );
      }
    }
  }

  Future<void> _pickAvatarFromCamera() async {
    final success =
        await ref.read(profileProvider.notifier).pickAndUploadAvatarFromCamera();

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('avatar_updated'.tr())),
      );
    }
  }

  Future<void> _removeAvatar() async {
    final success = await ref.read(profileProvider.notifier).removeAvatar();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('avatar_removed'.tr())),
        );
      } else {
        final error = ref.read(profileProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'remove_failed'.tr())),
        );
      }
    }
  }
}
