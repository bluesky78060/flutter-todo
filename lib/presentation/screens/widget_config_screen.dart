/// Home screen widget configuration screen (Android only).
///
/// Features:
/// - Enable/disable home screen widget
/// - Select widget view type (calendar or todo list)
/// - Preview widget appearance
/// - Manual widget refresh
///
/// Widget types:
/// - Calendar widget: Shows monthly view with todo counts
/// - Todo list widget: Shows today's todos with checkboxes
///
/// See also:
/// - [widgetServiceProvider] for widget data management
/// - [WidgetMethodChannelHandler] for native communication
/// - Android widget implementation in `android/app/src/main/kotlin/`
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/widget/widget_models.dart';
import 'package:todo_app/presentation/providers/widget_provider.dart';

/// Screen for configuring Android home screen widget settings.
class WidgetConfigScreen extends ConsumerWidget {
  const WidgetConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedViewType = ref.watch(widgetViewTypeProvider);
    final isEnabled = ref.watch(widgetEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('widget_settings')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Enable/Disable Widget Section
            _buildEnableSection(context, ref, isEnabled),

            const SizedBox(height: 24),

            // View Type Selection Section
            if (isEnabled)
              _buildViewTypeSection(context, ref, selectedViewType),
          ],
        ),
      ),
    );
  }

  /// Build enable/disable widget section
  Widget _buildEnableSection(
    BuildContext context,
    WidgetRef ref,
    bool isEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('widget_settings'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  isEnabled
                      ? tr('widget_enabled')
                      : tr('widget_disabled'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isEnabled,
            onChanged: (value) async {
              await ref.read(toggleWidgetEnabledProvider.future);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Build view type selection section
  Widget _buildViewTypeSection(
    BuildContext context,
    WidgetRef ref,
    WidgetViewType selectedViewType,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('widget_view_type'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildViewTypeOption(
            context,
            ref,
            WidgetViewType.today,
            tr('widget_today_tasks'),
            '📋 ${tr('widget_today_tasks_desc')}',
            selectedViewType,
          ),
          const SizedBox(height: 12),
          _buildViewTypeOption(
            context,
            ref,
            WidgetViewType.calendar,
            tr('widget_calendar'),
            '📅 ${tr('widget_calendar_desc')}',
            selectedViewType,
          ),
        ],
      ),
    );
  }

  /// Build individual view type option
  Widget _buildViewTypeOption(
    BuildContext context,
    WidgetRef ref,
    WidgetViewType viewType,
    String title,
    String description,
    WidgetViewType selectedViewType,
  ) {
    final isSelected = selectedViewType == viewType;

    return GestureDetector(
      onTap: () {
        // Navigate to theme settings for this widget type
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WidgetThemeConfigScreen(
              widgetType: viewType,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Radio<WidgetViewType>(
                value: viewType,
                groupValue: selectedViewType,
                onChanged: (value) {
                  // Navigate to theme settings for this widget type
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WidgetThemeConfigScreen(
                        widgetType: viewType,
                      ),
                    ),
                  );
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget theme configuration screen
class WidgetThemeConfigScreen extends ConsumerStatefulWidget {
  final WidgetViewType widgetType;

  const WidgetThemeConfigScreen({
    Key? key,
    required this.widgetType,
  }) : super(key: key);

  @override
  ConsumerState<WidgetThemeConfigScreen> createState() =>
      _WidgetThemeConfigScreenState();
}

class _WidgetThemeConfigScreenState
    extends ConsumerState<WidgetThemeConfigScreen> {
  String _selectedTheme = 'light';
  bool _isLoading = false;

  // Theme name keys for localization
  static const Map<String, String> _themeKeys = {
    'light': 'theme_light',
    'dark': 'theme_dark',
    'transparent': 'theme_transparent',
    'blue': 'theme_blue',
    'purple': 'theme_purple',
  };

  static const Map<String, Color> _themeColors = {
    'light': Colors.white,
    'dark': Color(0xFF303030),
    'transparent': Color(0x40000000),
    'blue': Color(0xFF1976D2),
    'purple': Color(0xFF7B1FA2),
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');
      final themeKey = widget.widgetType == WidgetViewType.today
          ? 'widget_theme'
          : 'calendar_theme';
      final theme = await HomeWidget.getWidgetData<String>(themeKey);
      if (theme != null && mounted) {
        setState(() {
          _selectedTheme = theme;
        });
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> _saveTheme(String theme) async {
    setState(() {
      _isLoading = true;
      _selectedTheme = theme;
    });

    try {
      await HomeWidget.setAppGroupId('group.dodo.widget');

      final themeKey = widget.widgetType == WidgetViewType.today
          ? 'widget_theme'
          : 'calendar_theme';

      await HomeWidget.saveWidgetData<String>(themeKey, theme);

      // Update the widget
      final widgetService = ref.read(widgetServiceProvider);
      await widgetService.updateWidget();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('theme_applied')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving theme: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('theme_apply_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.widgetType == WidgetViewType.today
        ? tr('widget_today_tasks')
        : tr('widget_calendar');

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('widget_config_title', namedArgs: {'title': title})),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme selection section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr('theme_select'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ..._themeKeys.entries.map((entry) {
                    return _buildThemeOption(
                      context,
                      entry.key,
                      tr(entry.value),
                      _themeColors[entry.key]!,
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Preview section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('preview'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        _buildPreview(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String themeKey,
    String themeName,
    Color themeColor,
  ) {
    final isSelected = _selectedTheme == themeKey;

    return InkWell(
      onTap: () => _saveTheme(themeKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: themeKey == 'light' ? Colors.grey[300]! : Colors.transparent,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                themeName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  /// Get current month name from translation
  String _getCurrentMonthName() {
    final now = DateTime.now();
    final monthKeys = [
      'month_january',
      'month_february',
      'month_march',
      'month_april',
      'month_may',
      'month_june',
      'month_july',
      'month_august',
      'month_september',
      'month_october',
      'month_november',
      'month_december',
    ];
    return tr(monthKeys[now.month - 1]);
  }

  Widget _buildPreview() {
    // blue and purple themes also have dark backgrounds requiring white text
    final isDark = _selectedTheme == 'dark' ||
                   _selectedTheme == 'transparent' ||
                   _selectedTheme == 'blue' ||
                   _selectedTheme == 'purple';
    final bgColor = _themeColors[_selectedTheme]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600]!;

    if (widget.widgetType == WidgetViewType.today) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: _selectedTheme == 'light'
              ? Border.all(color: Colors.grey[300]!)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('widget_today_tasks'),
              style: TextStyle(
                fontSize: AppColors.scaledFontSize(16),
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Divider(height: 16),
            _buildPreviewTodoItem('○  ${tr('widget_preview_task_1')}', '', textColor, subTextColor),
            _buildPreviewTodoItem('○  ${tr('widget_preview_task_2')}', '14:00', textColor, subTextColor),
            _buildPreviewTodoItem('○  ${tr('widget_preview_task_3')}', '', textColor, subTextColor),
            const SizedBox(height: 8),
            Center(
              child: Text(
                tr('tap_to_view_all'),
                style: TextStyle(
                  fontSize: AppColors.scaledFontSize(11),
                  color: subTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final now = DateTime.now();
      final monthYearText = tr('widget_preview_month_year', namedArgs: {
        'month': _getCurrentMonthName(),
        'year': now.year.toString(),
      });

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: _selectedTheme == 'light'
              ? Border.all(color: Colors.grey[300]!)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              monthYearText,
              style: TextStyle(
                fontSize: AppColors.scaledFontSize(16),
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                tr('day_sun'),
                tr('day_mon'),
                tr('day_tue'),
                tr('day_wed'),
                tr('day_thu'),
                tr('day_fri'),
                tr('day_sat'),
              ].asMap().entries.map((e) {
                    final i = e.key;
                    final d = e.value;
                    final dayColor = i == 0
                        ? (isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935)) // Sunday red
                        : i == 6
                            ? (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2)) // Saturday blue
                            : subTextColor;
                    return Text(
                      d,
                      style: TextStyle(
                        fontSize: AppColors.scaledFontSize(12),
                        fontWeight: FontWeight.bold,
                        color: dayColor,
                      ),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Sample calendar days
            Wrap(
              children: List.generate(7, (i) {
                final day = i + 1;
                final hasTask = day == 3 || day == 5;
                final dayColor = i == 0
                    ? (isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935)) // Sunday red
                    : i == 6
                        ? (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2)) // Saturday blue
                        : textColor;
                return SizedBox(
                  width: 40,
                  height: 32,
                  child: Center(
                    child: Text(
                      hasTask ? '$day●' : '$day',
                      style: TextStyle(
                        fontSize: AppColors.scaledFontSize(12),
                        color: dayColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPreviewTodoItem(
    String title,
    String time,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppColors.scaledFontSize(14),
                color: textColor,
              ),
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                fontSize: AppColors.scaledFontSize(12),
                color: subTextColor,
              ),
            ),
        ],
      ),
    );
  }
}
