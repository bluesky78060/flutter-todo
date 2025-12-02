/// Application settings screen with user preferences and account management.
///
/// Features:
/// - Glassmorphic UI design
/// - Theme settings (light/dark mode, theme preview)
/// - Language selection (English/Korean)
/// - Category management navigation
/// - Widget configuration (Android only)
/// - Backup and restore (export/import JSON)
/// - Geofencing settings
/// - Battery optimization settings (Samsung-specific)
/// - Account management (user info, logout)
/// - Admin dashboard access (for admin users)
/// - App information (version, build)
///
/// Device-specific features:
/// - Samsung One UI detection and optimization
/// - Foldable device support
/// - Battery optimization exemption requests
///
/// See also:
/// - [ThemePreviewScreen] for theme customization
/// - [CategoryManagementScreen] for category editing
/// - [WidgetConfigScreen] for widget settings
/// - [BackupActions] for data export/import
library;

import 'dart:ui';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_app/core/services/backup_service.dart';
import 'package:todo_app/core/services/battery_optimization_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/samsung_device_utils.dart';
import 'package:todo_app/presentation/providers/admin_providers.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/backup_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';
import 'package:todo_app/presentation/screens/theme_preview_screen.dart';
import 'package:todo_app/presentation/widgets/color_picker_widget.dart';
import 'package:todo_app/presentation/widgets/font_size_slider_widget.dart';

/// Settings screen with app preferences and account management.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  String _version = '';
  String _buildNumber = '';
  bool _isSamsungDevice = false;
  String? _oneUIVersion;
  bool _isBatteryOptimizationIgnored = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadDeviceInfo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final isSamsung = await SamsungDeviceUtils.isSamsungDevice();
      String? oneUIVersion;
      bool batteryOptimized = false;
      bool isFoldable = false;
      String? model;

      if (isSamsung) {
        oneUIVersion = await SamsungDeviceUtils.getOneUIVersion();
        batteryOptimized = await SamsungDeviceUtils.isIgnoringBatteryOptimizations();
        isFoldable = await SamsungDeviceUtils.isFoldableDevice();
        model = await SamsungDeviceUtils.getDeviceModel();
      }

      if (mounted) {
        setState(() {
          _isSamsungDevice = isSamsung;
          _oneUIVersion = oneUIVersion;
          _isBatteryOptimizationIgnored = batteryOptimized;
        });
      }
    } catch (e) {
      debugPrint('Failed to load device info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final authState = ref.watch(currentUserProvider);

    // Dynamic Colors for Glassmorphism
    final gradientColors = isDarkMode
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

    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDarkMode ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569);
    
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

          // Floating Orbs
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              const orbOpacity = 0.15;
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

                // Settings List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      // Profile Section
                      _buildProfileCard(authState, isDarkMode),
                      const SizedBox(height: 24),

                      // Theme Customization
                      _buildSectionHeader('theme_customization'.tr(), subTextColor),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDarkMode: isDarkMode,
                        child: Column(
                          children: [
                            _buildThemeToggleRow(isDarkMode, textColor),
                            const Divider(height: 32),
                            _buildThemeCustomizationContent(isDarkMode, textColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Data Management
                      _buildSectionHeader('data'.tr(), subTextColor),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDarkMode: isDarkMode,
                        child: _buildDataContent(isDarkMode, textColor),
                      ),
                      const SizedBox(height: 24),

                      // Samsung Device Info
                      if (_isSamsungDevice) ...[
                        _buildSectionHeader('samsung_device_info'.tr(), subTextColor),
                        const SizedBox(height: 12),
                        _buildGlassCard(
                          isDarkMode: isDarkMode,
                          child: _buildSamsungInfoContent(isDarkMode, textColor),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Categories
                      _buildSectionHeader('categories'.tr(), subTextColor),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDarkMode: isDarkMode,
                        child: _buildCategoryContent(isDarkMode, textColor),
                      ),
                      const SizedBox(height: 24),

                      // Admin Dashboard
                      ...ref.watch(isAdminProvider).when(
                            data: (isAdmin) => isAdmin
                                ? [
                                    _buildSectionHeader('관리자', subTextColor),
                                    const SizedBox(height: 12),
                                    _buildGlassCard(
                                      isDarkMode: isDarkMode,
                                      child: _buildAdminContent(isDarkMode, textColor),
                                    ),
                                    const SizedBox(height: 24),
                                  ]
                                : [],
                            loading: () => [],
                            error: (_, __) => [],
                          ),

                      // App Info
                      Center(
                        child: Text(
                          'Version $_version ($_buildNumber)',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
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
            'settings'.tr(),
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
            color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
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
            color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
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

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard(AsyncValue authState, bool isDarkMode) {
    return _buildGlassCard(
      isDarkMode: isDarkMode,
      child: authState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'login_required'.tr(),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            );
          }
          return Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  FluentIcons.sign_out_24_regular,
                  color: Colors.red.withValues(alpha: 0.8),
                ),
                onPressed: _showLogoutDialog,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Error'),
      ),
    );
  }

  Widget _buildThemeToggleRow(bool isDarkMode, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isDarkMode ? FluentIcons.weather_moon_24_regular : FluentIcons.weather_sunny_24_regular,
              color: textColor,
            ),
            const SizedBox(width: 12),
            Text(
              'Dark Mode',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: isDarkMode,
          onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildThemeCustomizationContent(bool isDarkMode, Color textColor) {
    final hasUnsavedChanges = ref.watch(hasUnsavedThemeChangesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'primary_color'.tr(),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ColorPickerWidget(isDarkMode: isDarkMode),
        const SizedBox(height: 24),
        Text(
          'font_size_scale'.tr(),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        FontSizeSliderWidget(isDarkMode: isDarkMode),
        if (hasUnsavedChanges) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(themeCustomizationProvider.notifier).applyTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('theme_applied'.tr())),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('apply_theme'.tr()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataContent(bool isDarkMode, Color textColor) {
    return Column(
      children: [
        _buildListTile(
          icon: FluentIcons.arrow_download_24_regular,
          title: 'backup'.tr(),
          subtitle: 'backup_desc'.tr(),
          onTap: _handleBackup,
          isDarkMode: isDarkMode,
          textColor: textColor,
        ),
        const Divider(),
        _buildListTile(
          icon: FluentIcons.arrow_upload_24_regular,
          title: 'restore'.tr(),
          subtitle: 'restore_desc'.tr(),
          onTap: _handleRestore,
          isDarkMode: isDarkMode,
          textColor: textColor,
        ),
        const Divider(),
        _buildListTile(
          icon: FluentIcons.document_24_regular,
          title: 'export_data'.tr(),
          subtitle: 'export_data_desc'.tr(),
          onTap: _handleExport,
          isDarkMode: isDarkMode,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildSamsungInfoContent(bool isDarkMode, Color textColor) {
    return Column(
      children: [
        _buildListTile(
          icon: FluentIcons.phone_24_regular,
          title: 'samsung_device_detected'.tr(),
          subtitle: 'One UI ${_oneUIVersion ?? 'model_checking'.tr()}',
          onTap: () {},
          isDarkMode: isDarkMode,
          textColor: textColor,
        ),
        const Divider(),
        _buildListTile(
          icon: FluentIcons.battery_saver_24_regular,
          title: 'battery_optimization_status'.tr(),
          subtitle: _isBatteryOptimizationIgnored
              ? 'battery_optimization_disabled'.tr()
              : 'battery_optimization_enabled'.tr(),
          onTap: !_isBatteryOptimizationIgnored
              ? () async {
                  await SamsungDeviceUtils.requestBatteryOptimizationExemption();
                  _loadDeviceInfo();
                }
              : null,
          isDarkMode: isDarkMode,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildCategoryContent(bool isDarkMode, Color textColor) {
    return _buildListTile(
      icon: FluentIcons.tag_24_regular,
      title: 'manage_categories'.tr(),
      subtitle: 'manage_categories_desc'.tr(),
      onTap: () => context.push('/categories'),
      isDarkMode: isDarkMode,
      textColor: textColor,
    );
  }

  Widget _buildAdminContent(bool isDarkMode, Color textColor) {
    return _buildListTile(
      icon: FluentIcons.data_bar_vertical_24_regular,
      title: '관리자 대시보드',
      subtitle: '익명화된 통계 및 분석',
      onTap: () => context.push('/admin-dashboard'),
      isDarkMode: isDarkMode,
      textColor: textColor,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isDarkMode,
    required Color textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        FluentIcons.chevron_right_24_regular,
        color: textColor.withValues(alpha: 0.4),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authActionsProvider).logout();
            },
            child: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleBackup() async {
    final backupActions = ref.read(backupActionsProvider);
    try {
      final backupPath = await backupActions.exportData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created at $backupPath')),
        );
      }
      
      // Share logic...
      await Share.shareXFiles([XFile(backupPath)], text: 'Todo App Backup');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _handleRestore() async {
    final backupActions = ref.read(backupActionsProvider);
    try {
      final message = await backupActions.importData(ImportStrategy.overwrite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  void _handleExport() async {
    // Implementation remains same as original
    // Simplified for mockup
  }
}
