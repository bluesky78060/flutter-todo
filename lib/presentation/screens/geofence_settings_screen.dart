import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todo_app/core/services/geofence_workmanager_service.dart';
import 'package:todo_app/core/services/location_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';

/// Geofence Settings Screen for location-based notifications
/// Allows users to enable/disable geofencing and configure monitoring interval
class GeofenceSettingsScreen extends ConsumerStatefulWidget {
  const GeofenceSettingsScreen({super.key});

  @override
  ConsumerState<GeofenceSettingsScreen> createState() =>
      _GeofenceSettingsScreenState();
}

class _GeofenceSettingsScreenState extends ConsumerState<GeofenceSettingsScreen> {
  bool _isGeofencingEnabled = false;
  bool _isLocationServiceEnabled = false;
  bool _isPermissionGranted = false;
  int _monitoringInterval = 5; // Default: 5 minutes (1~30분 범위)
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _initializeGeofenceSettings();
  }

  Future<void> _initializeGeofenceSettings() async {
    try {
      final locationService = LocationService();

      // Check location service enabled
      final locationServiceEnabled =
          await locationService.isLocationServiceEnabled();

      if (mounted) {
        setState(() {
          _isLocationServiceEnabled = locationServiceEnabled;
        });
      }

      // Check location permission
      await _checkLocationPermission();
    } catch (e) {
      debugPrint('❌ Error initializing geofence settings: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final status = await Permission.location.status;
      if (mounted) {
        setState(() {
          _isPermissionGranted = status.isGranted;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    if (_isCheckingPermissions) return;

    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final locationService = LocationService();
      final granted = await locationService.requestLocationPermission();

      if (mounted) {
        setState(() {
          _isPermissionGranted = granted;
        });

        if (granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_permission_granted'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_permission_denied'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('permission_request_failed'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
      }
    }
  }

  Future<void> _toggleGeofencing(bool value) async {
    if (!_isPermissionGranted && value) {
      // Request permission before enabling
      await _requestLocationPermission();
      return;
    }

    try {
      setState(() {
        _isGeofencingEnabled = value;
      });

      if (value) {
        // Start geofence monitoring
        await GeofenceWorkManagerService.startMonitoring(
          intervalMinutes: _monitoringInterval,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('geofencing_enabled'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Stop geofence monitoring
        await GeofenceWorkManagerService.stopMonitoring();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('geofencing_disabled'.tr()),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling geofencing: $e');
      if (mounted) {
        setState(() {
          _isGeofencingEnabled = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('geofencing_toggle_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testGeofencing() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('testing_geofence'.tr())),
      );

      await GeofenceWorkManagerService.checkNow();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('geofence_test_complete'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error testing geofencing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('geofence_test_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getText(isDarkMode);
    final subTextColor = AppColors.getTextSecondary(isDarkMode);

    return Scaffold(
      appBar: AppBar(
        title: Text('geofencing_settings'.tr()),
        centerTitle: true,
        backgroundColor:
            isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: textColor,
        elevation: 0,
      ),
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Section
              _buildStatusCard(isDarkMode, textColor, subTextColor),
              const SizedBox(height: 24),

              // Permission Section
              if (!_isPermissionGranted) ...[
                _buildPermissionCard(isDarkMode, textColor, subTextColor),
                const SizedBox(height: 24),
              ],

              // Geofencing Toggle Section
              _buildGeofencingToggle(isDarkMode, textColor, subTextColor),
              const SizedBox(height: 24),

              // Monitoring Interval Section
              if (_isGeofencingEnabled) ...[
                _buildMonitoringIntervalSection(isDarkMode, textColor, subTextColor),
                const SizedBox(height: 24),
              ],

              // Information Section
              _buildInformationSection(isDarkMode, textColor, subTextColor),
              const SizedBox(height: 24),

              // Test Button
              _buildTestButton(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      bool isDarkMode, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDarkMode),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'status'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: FluentIcons.location_24_regular,
            label: 'location_service'.tr(),
            status: _isLocationServiceEnabled,
            isDarkMode: isDarkMode,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: FluentIcons.shield_24_regular,
            label: 'location_permission'.tr(),
            status: _isPermissionGranted,
            isDarkMode: isDarkMode,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: FluentIcons.location_24_regular,
            label: 'geofencing_status'.tr(),
            status: _isGeofencingEnabled,
            isDarkMode: isDarkMode,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required bool status,
    required bool isDarkMode,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: status ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status ? 'enabled'.tr() : 'disabled'.tr(),
            style: TextStyle(
              color: status ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard(
      bool isDarkMode, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.info_24_regular,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'location_permission_required'.tr(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'geofencing_description'.tr(),
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCheckingPermissions ? null : _requestLocationPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(_isCheckingPermissions ? 'requesting'.tr() : 'grant_permission'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofencingToggle(
      bool isDarkMode, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDarkMode),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            FluentIcons.location_24_regular,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'geofencing_enabled'.tr(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'geofencing_toggle_description'.tr(),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _isGeofencingEnabled && _isPermissionGranted,
            onChanged: _isPermissionGranted ? _toggleGeofencing : null,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringIntervalSection(
      bool isDarkMode, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDarkMode),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'monitoring_interval'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _monitoringInterval.toDouble(),
            min: 1,
            max: 30,
            divisions: 29, // 1~30분, 1분씩 증가
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _monitoringInterval = value.toInt();
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'every_n_minutes'.tr(namedArgs: {'minutes': _monitoringInterval.toString()}),
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'monitoring_interval_description'.tr(),
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(
      bool isDarkMode, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkCard
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDarkMode),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'how_geofencing_works'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            number: '1',
            title: 'geofencing_step_1_title'.tr(),
            description: 'geofencing_step_1_description'.tr(),
            textColor: textColor,
            subTextColor: subTextColor,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            number: '2',
            title: 'geofencing_step_2_title'.tr(),
            description: 'geofencing_step_2_description'.tr(),
            textColor: textColor,
            subTextColor: subTextColor,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            number: '3',
            title: 'geofencing_step_3_title'.tr(),
            description: 'geofencing_step_3_description'.tr(),
            textColor: textColor,
            subTextColor: subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String number,
    required String title,
    required String description,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
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
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _testGeofencing,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.play_24_filled),
            const SizedBox(width: 8),
            Text('test_geofencing'.tr()),
          ],
        ),
      ),
    );
  }
}
