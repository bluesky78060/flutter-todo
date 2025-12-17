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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_app/core/services/backup_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/device_utils.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/backup_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';
import 'package:todo_app/presentation/screens/geofence_settings_screen.dart';
import 'package:todo_app/presentation/screens/profile_edit_screen.dart';
import 'package:todo_app/presentation/screens/widget_config_screen.dart';
import 'dart:io' show Platform;
import 'package:todo_app/presentation/providers/profile_provider.dart';
import 'package:todo_app/presentation/providers/view_mode_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/core/theme/app_colors.dart';

/// Settings screen with app preferences and account management.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';
  DeviceInfo? _deviceInfo;
  bool _isBatteryOptimizationIgnored = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadDeviceInfo();
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
      final deviceInfo = await DeviceUtils.getDeviceInfo();
      final batteryOptimized = await DeviceUtils.isIgnoringBatteryOptimizations();

      if (mounted) {
        setState(() {
          _deviceInfo = deviceInfo;
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
    final primaryColor = ref.watch(primaryColorProvider);
    final fontScale = ref.watch(fontSizeScaleProvider);
    final pendingColor = ref.watch(pendingColorProvider);
    final pendingFontScale = ref.watch(pendingFontScaleProvider);

    final backgroundColor = isDarkMode ? const Color(0xFF1a1a1a) : Colors.grey.shade50;
    final cardColor = isDarkMode ? const Color(0xFF2d2d2d) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.grey.shade900;
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'settings'.tr(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Settings List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Profile Section
                  _buildProfileSection(authState, isDarkMode, cardColor, textColor, subTextColor),
                  const SizedBox(height: 20),

                  // Theme Customization
                  _buildSectionTitle('theme_customization'.tr(), subTextColor),
                  const SizedBox(height: 8),
                  _buildCard(
                    cardColor: cardColor,
                    child: Column(
                      children: [
                        _buildLightModeToggle(isDarkMode, textColor, primaryColor),
                        Divider(color: dividerColor, height: 1),
                        const SizedBox(height: 16),
                        _buildColorPicker(textColor, pendingColor),
                        const SizedBox(height: 16),
                        _buildFontSizeSlider(textColor, pendingFontScale),
                        _buildApplyButton(isDarkMode),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display Settings
                  _buildSectionTitle('display_settings'.tr(), subTextColor),
                  const SizedBox(height: 8),
                  _buildCard(
                    cardColor: cardColor,
                    child: _buildViewModeRow(textColor, subTextColor),
                  ),
                  const SizedBox(height: 20),

                  // Data Section
                  _buildSectionTitle('data'.tr(), subTextColor),
                  const SizedBox(height: 8),
                  _buildCard(
                    cardColor: cardColor,
                    child: Column(
                      children: [
                        _buildSettingRow(
                          icon: Icons.cloud_upload,
                          title: 'backup_and_restore'.tr(),
                          onTap: () => _showBackupRestoreOptions(context),
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        Divider(color: dividerColor, height: 1),
                        _buildSettingRow(
                          icon: Icons.import_export,
                          title: 'export_data'.tr(),
                          onTap: _handleExport,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Other Settings
                  _buildSectionTitle('others'.tr(), subTextColor),
                  const SizedBox(height: 8),
                  _buildCard(
                    cardColor: cardColor,
                    child: Column(
                      children: [
                        _buildSettingRow(
                          icon: Icons.category,
                          title: 'category_management'.tr(),
                          onTap: () => context.push('/categories'),
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        Divider(color: dividerColor, height: 1),
                        _buildSettingRow(
                          icon: Icons.location_on,
                          title: 'location_based_notifications'.tr(),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const GeofenceSettingsScreen(),
                              ),
                            );
                          },
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        // Widget settings (Android only)
                        if (Platform.isAndroid) ...[
                          Divider(color: dividerColor, height: 1),
                          _buildSettingRow(
                            icon: Icons.widgets,
                            title: 'widget_settings'.tr(),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const WidgetConfigScreen(),
                                ),
                              );
                            },
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Section
                  _buildSectionTitle('info'.tr(), subTextColor),
                  const SizedBox(height: 8),
                  _buildCard(
                    cardColor: cardColor,
                    child: Column(
                      children: [
                        _buildSettingRow(
                          icon: Icons.description,
                          title: 'device_info'.tr(),
                          onTap: () => _showDeviceInfoDialog(isDarkMode),
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        Divider(color: dividerColor, height: 1),
                        _buildSettingRow(
                          icon: Icons.chat_bubble_outline,
                          title: 'send_feedback'.tr(),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('coming_soon'.tr().replaceFirst('{feature}', 'send_feedback'.tr()))),
                            );
                          },
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Version Info
                  _buildCard(
                    cardColor: cardColor,
                    child: _buildVersionInfo(textColor, subTextColor),
                  ),
                  const SizedBox(height: 20),

                  // Logout Section (if logged in)
                  authState.when(
                    data: (user) => user != null
                        ? Column(
                            children: [
                              _buildLogoutSection(isDarkMode, cardColor, textColor, subTextColor),
                              const SizedBox(height: 20),
                            ],
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCard({required Color cardColor, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildProfileSection(AsyncValue authState, bool isDarkMode, Color cardColor, Color textColor, Color subTextColor) {
    final profileState = ref.watch(profileProvider);

    return _buildCard(
      cardColor: cardColor,
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

          final displayName = profileState.displayName ?? user.displayName ?? user.name;
          final avatarUrl = profileState.avatarUrl ?? user.avatarUrl;

          return Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: avatarUrl == null
                      ? LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.deepOrange.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _navigateToProfileEdit(),
                child: Text(
                  'edit'.tr(),
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text('Error', style: TextStyle(color: textColor)),
      ),
    );
  }

  Widget _buildLogoutSection(bool isDarkMode, Color cardColor, Color textColor, Color subTextColor) {
    return _buildCard(
      cardColor: cardColor,
      child: InkWell(
        onTap: _showLogoutDialog,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 22),
              const SizedBox(width: 16),
              Text(
                'logout'.tr(),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    required Color textColor,
    required Color subTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: subTextColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: subTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLightModeToggle(bool isDarkMode, Color textColor, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: textColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'light_mode'.tr(),
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: !isDarkMode,
          onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
          activeColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildColorPicker(Color textColor, Color primaryColor) {
    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.red,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'primary_color'.tr(),
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: colors.map((color) {
            final isSelected = color.value == primaryColor.value;
            return GestureDetector(
              onTap: () => ref.read(themeCustomizationProvider.notifier).setPrimaryColor(color),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(Color textColor, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'font_size'.tr(),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(fontScale * 100).round()}%',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blue.withOpacity(0.2),
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: fontScale,
            min: 0.8,
            max: 1.2,
            divisions: 8,
            onChanged: (value) {
              ref.read(themeCustomizationProvider.notifier).setFontSizeScale(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('small'.tr(), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
            Text('default'.tr(), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
            Text('large'.tr(), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildApplyButton(bool isDarkMode) {
    final hasUnsavedChanges = ref.watch(hasUnsavedThemeChangesProvider);

    if (!hasUnsavedChanges) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ref.read(themeCustomizationProvider.notifier).applyTheme();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('theme_applied'.tr())),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('apply_theme'.tr()),
        ),
      ),
    );
  }

  Widget _buildViewModeRow(Color textColor, Color subTextColor) {
    final viewMode = ref.watch(viewModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingRow(
          icon: viewMode == ViewMode.calendar ? Icons.calendar_month : Icons.list,
          title: 'default_view'.tr(),
          onTap: () => _showViewModeOptions(context),
          textColor: textColor,
          subTextColor: subTextColor,
        ),
      ],
    );
  }

  Widget _buildVersionInfo(Color textColor, Color subTextColor) {
    return Row(
      children: [
        Icon(Icons.info_outline, color: subTextColor, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'app_version'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$_version ($_buildNumber)',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToProfileEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    );
  }

  void _showViewModeOptions(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final viewMode = ref.watch(viewModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF2d2d2d) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.calendar_month, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('calendar_view'.tr(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                trailing: viewMode == ViewMode.calendar ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(viewModeProvider.notifier).setViewMode(ViewMode.calendar);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.list, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('list_view'.tr(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                trailing: viewMode == ViewMode.list ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(viewModeProvider.notifier).setViewMode(ViewMode.list);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBackupRestoreOptions(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF2d2d2d) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.cloud_upload, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('backup'.tr(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _handleBackup();
                },
              ),
              ListTile(
                leading: Icon(Icons.cloud_download, color: isDarkMode ? Colors.white : Colors.black),
                title: Text('restore'.tr(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _handleRestore();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeviceInfoDialog(bool isDarkMode) {
    final info = _deviceInfo!;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(FluentIcons.phone_24_filled, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'device_info'.tr(),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDeviceInfoRow('device_type'.tr(), info.deviceType, textColor, subTextColor, isDarkMode),
              _buildDeviceInfoRow('manufacturer'.tr(), info.manufacturer, textColor, subTextColor, isDarkMode),
              _buildDeviceInfoRow('device_model'.tr(), info.model, textColor, subTextColor, isDarkMode),
              _buildDeviceInfoRow('os_version'.tr(), info.osVersion, textColor, subTextColor, isDarkMode),
              if (info.sdkVersion != null)
                _buildDeviceInfoRow('sdk_version'.tr(), info.sdkVersion!, textColor, subTextColor, isDarkMode),
              if (info.brand != null)
                _buildDeviceInfoRow('brand'.tr(), info.brand!, textColor, subTextColor, isDarkMode),
              if (info.device != null)
                _buildDeviceInfoRow('device_codename'.tr(), info.device!, textColor, subTextColor, isDarkMode),
              if (info.product != null)
                _buildDeviceInfoRow('product'.tr(), info.product!, textColor, subTextColor, isDarkMode),
              if (info.hardware != null)
                _buildDeviceInfoRow('hardware'.tr(), info.hardware!, textColor, subTextColor, isDarkMode),
              if (info.displayResolution != null)
                _buildDeviceInfoRow('display_resolution'.tr(), info.displayResolution!, textColor, subTextColor, isDarkMode),
              _buildDeviceInfoRow('physical_device'.tr(), info.isPhysicalDevice ? 'yes'.tr() : 'no'.tr(), textColor, subTextColor, isDarkMode),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr(), style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String value, Color textColor, Color subTextColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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
    final backupActions = ref.read(backupActionsProvider);
    try {
      final exportPath = await backupActions.exportData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('data_exported_successfully'.tr() + ': $exportPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('data_export_failed'.tr() + ': $e')),
        );
      }
    }
  }
}
