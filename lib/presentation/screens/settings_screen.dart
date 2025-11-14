import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_app/core/services/backup_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/samsung_device_utils.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/backup_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _isSamsungDevice = false;
  String? _oneUIVersion;
  bool _isBatteryOptimizationIgnored = false;
  bool _isFoldableDevice = false;
  String? _deviceModel;

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
          _isFoldableDevice = isFoldable;
          _deviceModel = model;
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

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.getHeaderGradient(isDarkMode),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getInput(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        FluentIcons.arrow_left_24_regular,
                        color: AppColors.getText(isDarkMode),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'settings'.tr(),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Settings Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile Section
                  _buildSectionHeader('account'.tr()),
                  const SizedBox(height: 12),
                  _buildProfileCard(authState),
                  const SizedBox(height: 32),

                  // Data Management
                  _buildSectionHeader('data'.tr()),
                  const SizedBox(height: 12),
                  _buildDataCard(),
                  const SizedBox(height: 32),

                  // Samsung Device Info (only show for Samsung devices)
                  if (_isSamsungDevice) ...[
                    _buildSectionHeader('samsung_device_info'.tr()),
                    const SizedBox(height: 12),
                    _buildSamsungInfoCard(),
                    const SizedBox(height: 32),
                  ],

                  // Foldable Device Guidance (only show for Fold/Flip devices)
                  if (_isFoldableDevice) ...[
                    _buildSectionHeader('foldable_device_settings'.tr()),
                    const SizedBox(height: 12),
                    _buildFoldableGuidanceCard(),
                    const SizedBox(height: 32),
                  ],

                  // Categories Management
                  _buildSectionHeader('categories'.tr()),
                  const SizedBox(height: 12),
                  _buildCategoryCard(),
                  const SizedBox(height: 32),

                  // App Info
                  _buildSectionHeader('info'.tr()),
                  const SizedBox(height: 12),
                  _buildInfoCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Text(
      title,
      style: TextStyle(
        color: AppColors.getTextSecondary(isDarkMode),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileCard(AsyncValue authState) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: authState.when(
        data: (user) {
          if (user == null) {
            return Text(
              'login_required'.tr(),
              style: const TextStyle(color: AppColors.textGray),
            );
          }
          return Column(
            children: [
              // Profile Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User Info
              Text(
                user.name,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _showLogoutDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.sign_out_24_regular, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'logout'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(
          'error_occurred'.tr(),
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDataCard() {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FluentIcons.arrow_download_24_regular,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              'backup'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'backup_desc'.tr(),
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
            onTap: () {
              _handleBackup();
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          Divider(
            color: AppColors.getBorder(isDarkMode),
            height: 1,
            indent: 68,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FluentIcons.arrow_upload_24_regular,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              'restore'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'restore_desc'.tr(),
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
            onTap: () {
              _handleRestore();
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildSamsungInfoCard() {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FluentIcons.phone_24_regular,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              'samsung_device_detected'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'One UI ${_oneUIVersion ?? 'model_checking'.tr()}',
              style: const TextStyle(
                color: AppColors.successGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          Divider(
            color: AppColors.getBorder(isDarkMode),
            height: 1,
            indent: 68,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                FluentIcons.battery_saver_24_regular,
                color: _isBatteryOptimizationIgnored
                    ? AppColors.successGreen
                    : Colors.orange,
              ),
            ),
            title: Text(
              'battery_optimization_status'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _isBatteryOptimizationIgnored
                  ? 'battery_optimization_disabled'.tr()
                  : 'battery_optimization_enabled'.tr(),
              style: TextStyle(
                color: _isBatteryOptimizationIgnored
                    ? AppColors.successGreen
                    : Colors.orange,
                fontSize: 14,
              ),
            ),
            trailing: !_isBatteryOptimizationIgnored
                ? TextButton(
                    onPressed: () async {
                      await SamsungDeviceUtils.requestBatteryOptimizationExemption();
                      _loadDeviceInfo(); // Reload status
                    },
                    child: Text(
                      'settings'.tr(),
                      style: const TextStyle(color: AppColors.primaryBlue),
                    ),
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          Divider(
            color: AppColors.getBorder(isDarkMode),
            height: 1,
            indent: 68,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FluentIcons.info_24_regular,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              'notification_optimization_status'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'samsung_workaround_applied'.tr(),
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldableGuidanceCard() {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Model
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getInput(isDarkMode),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    FluentIcons.phone_tablet_24_regular,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'foldable_device_detected'.tr(),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _deviceModel ?? 'model_checking'.tr(),
                        style: const TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    FluentIcons.warning_24_regular,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'cover_screen_notification_notice'.tr(),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'cover_screen_notification_limitation'.tr(),
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDarkMode),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Guidance Title
            Text(
              'cover_screen_notification_guide'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Step 1
            _buildGuidanceStep(
              isDarkMode,
              '1',
              'step_1_aod_enable'.tr(),
              'step_1_aod_path'.tr(),
            ),
            const SizedBox(height: 8),

            // Step 2
            _buildGuidanceStep(
              isDarkMode,
              '2',
              'step_2_cover_screen'.tr(),
              'step_2_cover_screen_path'.tr(),
            ),
            const SizedBox(height: 8),

            // Step 3
            _buildGuidanceStep(
              isDarkMode,
              '3',
              'step_3_app_permissions'.tr(),
              'step_3_app_permissions_path'.tr(),
            ),
            const SizedBox(height: 16),

            // One UI 7/8 Additional Settings
            if (_oneUIVersion != null &&
                (double.tryParse(_oneUIVersion!.split('.')[0]) ?? 0) >= 7) ...[
              const Divider(height: 32),
              Text(
                'oneui_7_additional_settings'.tr(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Step 4 - Lock Screen Notification
              _buildGuidanceStep(
                isDarkMode,
                '4',
                'step_4_lock_screen_notification'.tr(),
                'step_4_lock_screen_path'.tr(),
              ),
              const SizedBox(height: 8),

              // Step 5 - DND Warning
              _buildGuidanceStep(
                isDarkMode,
                '5',
                'step_5_dnd_check'.tr(),
                'step_5_dnd_path'.tr(),
              ),
              const SizedBox(height: 16),

              // One UI 7/8 Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      FluentIcons.warning_24_regular,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'oneui_7_8_warning'.tr(),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    FluentIcons.info_24_regular,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'cover_screen_setup_complete'.tr(),
                      style: TextStyle(
                        color: AppColors.getTextSecondary(isDarkMode),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceStep(
    bool isDarkMode,
    String number,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard() {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.getInput(isDarkMode),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            FluentIcons.folder_24_regular,
            color: AppColors.primaryBlue,
          ),
        ),
        title: Text(
          'category_management'.tr(),
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'category_management_desc'.tr(),
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          FluentIcons.chevron_right_24_regular,
          color: AppColors.getTextSecondary(isDarkMode),
        ),
        onTap: () {
          context.push('/categories');
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FluentIcons.info_24_regular,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              'version_info'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _version.isNotEmpty ? 'v$_version ($_buildNumber)' : 'loading'.tr(),
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          Divider(
            color: AppColors.getBorder(isDarkMode),
            height: 1,
            indent: 68,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FluentIcons.document_text_24_regular,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              'open_source_licenses'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
            onTap: () {
              _showLicensePage();
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          Divider(
            color: AppColors.getBorder(isDarkMode),
            height: 1,
            indent: 68,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInput(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FluentIcons.mail_24_regular,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              'send_feedback'.tr(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              FluentIcons.chevron_right_24_regular,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
            onTap: () {
              _showComingSoonSnackBar('send_feedback'.tr());
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final isDarkMode = ref.watch(isDarkModeProvider);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.sign_out_24_regular,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'logout'.tr(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'logout_confirm'.tr(),
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextSecondary(isDarkMode),
                        side: BorderSide(
                          color: AppColors.getBorder(isDarkMode),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authActionsProvider).logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('logout'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLicensePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Theme(
          data: ThemeData.dark(),
          child: LicensePage(
            applicationName: 'DoDo',
            applicationVersion: _version.isNotEmpty ? '$_version+$_buildNumber' : '1.0.8+20',
            applicationLegalese: '© 2025 Lee Chan Hee (이찬희)\nAll Rights Reserved.\n\n'
                'DoDo is proprietary software.\n'
                'For personal use only.\n\n'
                'Contact: bluesky78060@gmail.com',
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('coming_soon'.tr(namedArgs: {'feature': feature})),
        backgroundColor: AppColors.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleBackup() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Export data
      final backupActions = ref.read(backupActionsProvider);
      final filePath = await backupActions.exportData();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog with share option
      if (mounted) {
        _showBackupSuccessDialog(filePath);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        _showErrorSnackBar('${'backup_failed'.tr()}: $e');
      }
    }
  }

  void _showBackupSuccessDialog(String filePath) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.checkmark_circle_24_filled,
                color: AppColors.successGreen,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'backup_complete'.tr(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'backup_file_saved'.tr(),
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                filePath.split('/').last,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextSecondary(isDarkMode),
                        side: BorderSide(
                          color: AppColors.getBorder(isDarkMode),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Share.shareXFiles(
                          [XFile(filePath)],
                          subject: 'backup_file'.tr(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('share'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRestore() async {
    // Show strategy selection dialog
    final strategy = await _showRestoreStrategyDialog();
    if (strategy == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Import data
      final backupActions = ref.read(backupActionsProvider);
      final message = await backupActions.importData(strategy);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Refresh todo list
      ref.invalidate(todosProvider);

      // Show success message
      if (mounted) {
        _showSuccessSnackBar(message);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        _showErrorSnackBar('${'restore_failed'.tr()}: $e');
      }
    }
  }

  Future<ImportStrategy?> _showRestoreStrategyDialog() async {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return showDialog<ImportStrategy>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.arrow_upload_24_regular,
                color: AppColors.primaryBlue,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'restore_method_select'.tr(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'restore_data_handling'.tr(),
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, ImportStrategy.overwrite);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'restore_overwrite'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'restore_delete_then_restore'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, ImportStrategy.merge);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'restore_merge'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'restore_merge_latest_first'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.getTextSecondary(isDarkMode),
                    side: BorderSide(
                      color: AppColors.getBorder(isDarkMode),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('cancel'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
