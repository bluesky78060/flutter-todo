/// Windows Calendar Widget Window
///
/// A compact calendar widget for Windows desktop that displays:
/// - Monthly calendar view with todo markers
/// - Selected day's todo list
/// - Quick add functionality
///
/// Features:
/// - Transparent, frameless window
/// - Draggable header
/// - Always on top option
/// - System tray integration
/// - OAuth login (Google, Kakao)
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:window_manager/window_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/config/oauth_redirect.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/core/utils/color_utils.dart';

/// Resize direction for window resize handles
enum ResizeDirection {
  right,
  bottom,
  left,
  bottomRight,
  bottomLeft,
}

/// Calendar widget window for Windows desktop
class CalendarWidgetWindow extends ConsumerStatefulWidget {
  const CalendarWidgetWindow({super.key});

  @override
  ConsumerState<CalendarWidgetWindow> createState() => _CalendarWidgetWindowState();
}

class _CalendarWidgetWindowState extends ConsumerState<CalendarWidgetWindow>
    with WindowListener {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isAlwaysOnTop = true;
  bool _isResizing = false;
  bool _isTransparentMode = false;
  double _transparencyLevel = 0.7; // 0.3 ~ 1.0
  bool _showSettingsPanel = false; // Settings panel visibility

  // Text styling options
  Color? _customTextColor; // null means use default
  bool _isBoldText = false;

  // Preset colors for text
  static const List<Color> _presetColors = [
    Colors.white,
    Colors.black,
    Color(0xFFFF5252), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
  ];

  // Korean holidays (fixed dates)
  static final Map<String, String> _koreanHolidays = {
    '01-01': '신정',
    '03-01': '삼일절',
    '05-05': '어린이날',
    '06-06': '현충일',
    '08-15': '광복절',
    '10-03': '개천절',
    '10-09': '한글날',
    '12-25': '크리스마스',
  };

  // Lunar holidays (approximate dates for 2024-2030)
  static final Map<String, Map<String, String>> _lunarHolidays = {
    '2024': {
      '02-09': '설날 연휴',
      '02-10': '설날',
      '02-11': '설날 연휴',
      '02-12': '대체공휴일',
      '04-10': '21대 총선',
      '05-15': '부처님오신날',
      '09-16': '추석 연휴',
      '09-17': '추석',
      '09-18': '추석 연휴',
    },
    '2025': {
      '01-28': '설날 연휴',
      '01-29': '설날',
      '01-30': '설날 연휴',
      '05-05': '부처님오신날',
      '10-05': '추석 연휴',
      '10-06': '추석',
      '10-07': '추석 연휴',
      '10-08': '대체공휴일',
    },
    '2026': {
      '02-16': '설날 연휴',
      '02-17': '설날',
      '02-18': '설날 연휴',
      '05-24': '부처님오신날',
      '09-24': '추석 연휴',
      '09-25': '추석',
      '09-26': '추석 연휴',
    },
    '2027': {
      '02-05': '설날 연휴',
      '02-06': '설날',
      '02-07': '설날 연휴',
      '02-08': '대체공휴일',
      '05-13': '부처님오신날',
      '09-14': '추석 연휴',
      '09-15': '추석',
      '09-16': '추석 연휴',
    },
    '2028': {
      '01-25': '설날 연휴',
      '01-26': '설날',
      '01-27': '설날 연휴',
      '05-02': '부처님오신날',
      '10-02': '추석 연휴',
      '10-03': '추석',
      '10-04': '추석 연휴',
    },
    '2029': {
      '02-12': '설날 연휴',
      '02-13': '설날',
      '02-14': '설날 연휴',
      '05-20': '부처님오신날',
      '09-21': '추석 연휴',
      '09-22': '추석',
      '09-23': '추석 연휴',
      '09-24': '대체공휴일',
    },
    '2030': {
      '02-02': '설날 연휴',
      '02-03': '설날',
      '02-04': '설날 연휴',
      '05-09': '부처님오신날',
      '09-11': '추석 연휴',
      '09-12': '추석',
      '09-13': '추석 연휴',
    },
  };

  /// Get holiday name for a specific date
  String? _getHolidayName(DateTime date) {
    final monthDay = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Check fixed holidays first
    if (_koreanHolidays.containsKey(monthDay)) {
      return _koreanHolidays[monthDay];
    }

    // Check lunar holidays for the year
    final year = date.year.toString();
    if (_lunarHolidays.containsKey(year)) {
      if (_lunarHolidays[year]!.containsKey(monthDay)) {
        return _lunarHolidays[year]![monthDay];
      }
    }

    return null;
  }


  // Min/max window sizes for resizing
  static const double _minWidth = 320;
  static const double _minHeight = 500;
  static const double _maxWidth = 550;
  static const double _maxHeight = 800;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
      _initWindowSize();
    }
    _selectedDay = _focusedDay;
  }

  Future<void> _initWindowSize() async {
    await windowManager.setMinimumSize(const Size(_minWidth, _minHeight));
    await windowManager.setMaximumSize(const Size(_maxWidth, _maxHeight));
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final primaryColor = ref.watch(primaryColorProvider);
    final authState = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkBackground.withOpacity(_isTransparentMode ? _transparencyLevel : 0.95)
                  : Colors.white.withOpacity(_isTransparentMode ? _transparencyLevel : 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isTransparentMode ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: authState.when(
              data: (user) {
                if (user == null) {
                  // Show login screen
                  return Column(
                    children: [
                      _buildDragHeader(isDarkMode, primaryColor, showLogout: false),
                      Expanded(
                        child: _buildLoginScreen(isDarkMode, primaryColor),
                      ),
                    ],
                  );
                }
                // Show calendar content
                final todosAsync = ref.watch(todosProvider);
                return Column(
                  children: [
                    _buildDragHeader(isDarkMode, primaryColor, showLogout: true),
                    Expanded(
                      child: todosAsync.when(
                        data: (todos) => _buildCalendarContent(todos, isDarkMode, primaryColor),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(
                          child: Text(
                            'Error: $e',
                            style: TextStyle(color: AppColors.getText(isDarkMode)),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Column(
                children: [
                  _buildDragHeader(isDarkMode, primaryColor, showLogout: false),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (e, st) => Column(
                children: [
                  _buildDragHeader(isDarkMode, primaryColor, showLogout: false),
                  Expanded(
                    child: _buildLoginScreen(isDarkMode, primaryColor),
                  ),
                ],
              ),
            ),
          ),
          // Resize handles
          ..._buildResizeHandles(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildDragHeader(bool isDarkMode, Color primaryColor, {bool showLogout = true}) {
    return GestureDetector(
      onPanStart: (_) {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          windowManager.startDragging();
        }
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _isTransparentMode
              ? primaryColor.withOpacity(_transparencyLevel)
              : primaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            const Icon(FluentIcons.calendar_24_regular, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'DoDo Calendar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            // Logout button (only show when logged in)
            if (showLogout) ...[
              // Refresh button
              _buildWindowButton(
                FluentIcons.arrow_sync_24_regular,
                () {
                  ref.invalidate(todosProvider);
                },
              ),
              const SizedBox(width: 4),
              _buildWindowButton(
                FluentIcons.sign_out_24_regular,
                () => _showLogoutConfirmDialog(),
              ),
              const SizedBox(width: 4),
            ],
            // Exit button (only show on login screen)
            if (!showLogout) ...[
              _buildWindowButton(
                FluentIcons.power_24_regular,
                () => _showExitConfirmDialog(),
              ),
              const SizedBox(width: 4),
            ],
            // Transparent mode toggle (click: toggle, long press: show settings panel)
            _buildWindowButton(
              _isTransparentMode
                  ? FluentIcons.drop_24_filled
                  : FluentIcons.drop_24_regular,
              () {
                setState(() {
                  if (_isTransparentMode) {
                    // Toggle settings panel when already in transparent mode
                    _showSettingsPanel = !_showSettingsPanel;
                  } else {
                    // Enable transparent mode
                    _isTransparentMode = true;
                    _showSettingsPanel = true;
                  }
                });
              },
              onLongPress: () {
                // Disable transparent mode completely
                setState(() {
                  _isTransparentMode = false;
                  _showSettingsPanel = false;
                });
              },
            ),
            const SizedBox(width: 4),
            // Always on top toggle
            _buildWindowButton(
              _isAlwaysOnTop
                  ? FluentIcons.pin_24_filled
                  : FluentIcons.pin_24_regular,
              () async {
                setState(() => _isAlwaysOnTop = !_isAlwaysOnTop);
                if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                  await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
                }
              },
            ),
            const SizedBox(width: 4),
            // Minimize button
            _buildWindowButton(
              FluentIcons.subtract_24_regular,
              () {
                if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                  windowManager.minimize();
                }
              },
            ),
            const SizedBox(width: 4),
            // Close/Hide button
            _buildWindowButton(
              FluentIcons.dismiss_24_regular,
              () {
                if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                  windowManager.hide();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowButton(IconData icon, VoidCallback onPressed, {VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  // Build inline settings panel (gauge-style)
  Widget _buildSettingsPanel(bool isDarkMode, Color primaryColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _showSettingsPanel ? null : 0,
      child: _showSettingsPanel
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    children: [
                      Icon(FluentIcons.settings_24_regular,
                          color: primaryColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '위젯 설정',
                        style: TextStyle(
                          color: _customTextColor ?? AppColors.getText(isDarkMode),
                          fontSize: 11,
                          fontWeight: _isBoldText ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showSettingsPanel = false),
                        child: Icon(FluentIcons.dismiss_12_regular,
                            color: AppColors.getTextSecondary(isDarkMode),
                            size: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Transparency slider (gauge style)
                  Row(
                    children: [
                      Icon(FluentIcons.drop_12_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
                          size: 12),
                      const SizedBox(width: 6),
                      Text(
                        '투명도',
                        style: TextStyle(
                          color: _customTextColor ?? AppColors.getText(isDarkMode),
                          fontSize: 10,
                          fontWeight: _isBoldText ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(_transparencyLevel * 100).toInt()}%',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Transparency gauge
                  SizedBox(
                    height: 20,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14),
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: primaryColor.withOpacity(0.2),
                        thumbColor: primaryColor,
                        overlayColor: primaryColor.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _transparencyLevel,
                        min: 0.3,
                        max: 1.0,
                        divisions: 7,
                        onChanged: (value) {
                          setState(() => _transparencyLevel = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Text color selection
                  Row(
                    children: [
                      Icon(FluentIcons.color_24_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
                          size: 12),
                      const SizedBox(width: 6),
                      Text(
                        '글씨 색상',
                        style: TextStyle(
                          color: _customTextColor ?? AppColors.getText(isDarkMode),
                          fontSize: 10,
                          fontWeight: _isBoldText ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      // Reset button
                      if (_customTextColor != null)
                        GestureDetector(
                          onTap: () => setState(() => _customTextColor = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '초기화',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Color palette
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _presetColors.map((color) {
                      final isSelected = _customTextColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _customTextColor = color),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (color == Colors.white
                                      ? Colors.grey.shade400
                                      : Colors.transparent),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  FluentIcons.checkmark_12_filled,
                                  size: 12,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Bold text toggle
                  Row(
                    children: [
                      Icon(FluentIcons.text_bold_16_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
                          size: 12),
                      const SizedBox(width: 6),
                      Text(
                        '굵은 글씨',
                        style: TextStyle(
                          color: _customTextColor ?? AppColors.getText(isDarkMode),
                          fontSize: 10,
                          fontWeight: _isBoldText ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _isBoldText = !_isBoldText),
                        child: Container(
                          width: 36,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: _isBoldText
                                ? primaryColor
                                : AppColors.getTextSecondary(isDarkMode)
                                    .withOpacity(0.3),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 150),
                            alignment: _isBoldText
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  List<Widget> _buildResizeHandles(bool isDarkMode) {
    const handleSize = 12.0;
    const hitArea = 8.0;
    final handleColor = isDarkMode
        ? Colors.white.withOpacity(0.3)
        : Colors.grey.withOpacity(0.4);

    return [
      // Right edge
      Positioned(
        right: 0,
        top: handleSize,
        bottom: handleSize,
        width: hitArea,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onPanUpdate: (details) => _handleResize(details, ResizeDirection.right),
          ),
        ),
      ),
      // Bottom edge
      Positioned(
        left: handleSize,
        right: handleSize,
        bottom: 0,
        height: hitArea,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: GestureDetector(
            onPanUpdate: (details) => _handleResize(details, ResizeDirection.bottom),
          ),
        ),
      ),
      // Left edge
      Positioned(
        left: 0,
        top: handleSize,
        bottom: handleSize,
        width: hitArea,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onPanUpdate: (details) => _handleResize(details, ResizeDirection.left),
          ),
        ),
      ),
      // Bottom-right corner (main resize handle)
      Positioned(
        right: 0,
        bottom: 0,
        width: handleSize + 4,
        height: handleSize + 4,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: GestureDetector(
            onPanUpdate: (details) => _handleResize(details, ResizeDirection.bottomRight),
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(2),
              child: Icon(
                FluentIcons.resize_large_24_regular,
                size: 10,
                color: handleColor,
              ),
            ),
          ),
        ),
      ),
      // Bottom-left corner
      Positioned(
        left: 0,
        bottom: 0,
        width: handleSize,
        height: handleSize,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownLeft,
          child: GestureDetector(
            onPanUpdate: (details) => _handleResize(details, ResizeDirection.bottomLeft),
          ),
        ),
      ),
    ];
  }

  Future<void> _handleResize(DragUpdateDetails details, ResizeDirection direction) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    if (_isResizing) return;

    _isResizing = true;

    try {
      final currentSize = await windowManager.getSize();
      final currentPosition = await windowManager.getPosition();

      double newWidth = currentSize.width;
      double newHeight = currentSize.height;
      double newX = currentPosition.dx;
      double newY = currentPosition.dy;

      switch (direction) {
        case ResizeDirection.right:
          newWidth += details.delta.dx;
          break;
        case ResizeDirection.bottom:
          newHeight += details.delta.dy;
          break;
        case ResizeDirection.left:
          newWidth -= details.delta.dx;
          newX += details.delta.dx;
          break;
        case ResizeDirection.bottomRight:
          newWidth += details.delta.dx;
          newHeight += details.delta.dy;
          break;
        case ResizeDirection.bottomLeft:
          newWidth -= details.delta.dx;
          newHeight += details.delta.dy;
          newX += details.delta.dx;
          break;
      }

      // Clamp to min/max sizes
      newWidth = newWidth.clamp(_minWidth, _maxWidth);
      newHeight = newHeight.clamp(_minHeight, _maxHeight);

      await windowManager.setBounds(
        Rect.fromLTWH(newX, newY, newWidth, newHeight),
      );
    } finally {
      _isResizing = false;
    }
  }

  Widget _buildCalendarContent(List<Todo> todos, bool isDarkMode, Color primaryColor) {
    final eventsByDate = _groupTodosByDate(todos);

    // Determine text color based on settings
    final textColor = _customTextColor ?? AppColors.getText(isDarkMode);
    final textSecondaryColor = _customTextColor?.withOpacity(0.7) ?? AppColors.getTextSecondary(isDarkMode);
    final fontWeight = _isBoldText ? FontWeight.bold : FontWeight.normal;

    return Column(
      children: [
        // Settings panel (shows when transparent mode is active and panel is visible)
        if (_isTransparentMode)
          _buildSettingsPanel(isDarkMode, primaryColor),

        // Compact calendar
        TableCalendar<Todo>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          availableCalendarFormats: const {
            CalendarFormat.month: '월',
            CalendarFormat.twoWeeks: '2주',
            CalendarFormat.week: '주',
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },

          // Compact style with custom text settings
          calendarStyle: CalendarStyle(
            cellMargin: const EdgeInsets.all(2),
            todayDecoration: BoxDecoration(
              color: primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.dangerRed,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerSize: 4,
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: fontWeight,
            ),
            weekendTextStyle: TextStyle(
              fontSize: 11,
              color: _customTextColor ?? Colors.red.shade300,
              fontWeight: fontWeight,
            ),
            todayTextStyle: TextStyle(
              fontSize: 11,
              fontWeight: _isBoldText ? FontWeight.w900 : FontWeight.bold,
              color: textColor,
            ),
            selectedTextStyle: TextStyle(
              fontSize: 11,
              fontWeight: _isBoldText ? FontWeight.w900 : FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Header style with custom text settings
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: primaryColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: TextStyle(
              fontSize: 11,
              color: primaryColor,
              fontWeight: fontWeight,
            ),
            formatButtonPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leftChevronPadding: EdgeInsets.zero,
            rightChevronPadding: EdgeInsets.zero,
            leftChevronMargin: const EdgeInsets.only(left: 8),
            rightChevronMargin: const EdgeInsets.only(right: 8),
            headerPadding: const EdgeInsets.symmetric(vertical: 8),
            titleTextStyle: TextStyle(
              fontSize: 13,
              fontWeight: _isBoldText ? FontWeight.w900 : FontWeight.bold,
              color: textColor,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              size: 18,
              color: textColor,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              size: 18,
              color: textColor,
            ),
          ),

          // Days of week style with custom text settings
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 10,
              color: textSecondaryColor,
              fontWeight: fontWeight,
            ),
            weekendStyle: TextStyle(
              fontSize: 10,
              color: _customTextColor ?? Colors.red.shade300,
              fontWeight: fontWeight,
            ),
          ),

          // Event loader
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return eventsByDate[normalizedDay] ?? [];
          },

          // Custom calendar builders for holidays
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final holidayName = _getHolidayName(day);
              final isWeekend = day.weekday == DateTime.sunday;

              if (holidayName != null || isWeekend) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _customTextColor ?? Colors.red.shade400,
                      fontWeight: fontWeight,
                    ),
                  ),
                );
              }
              return null;
            },
            todayBuilder: (context, day, focusedDay) {
              final holidayName = _getHolidayName(day);
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _isBoldText ? FontWeight.w900 : FontWeight.bold,
                      color: holidayName != null
                          ? (_customTextColor ?? Colors.red.shade400)
                          : textColor,
                    ),
                  ),
                ),
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return const SizedBox.shrink();
            },
          ),

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),

        // Divider
        Divider(height: 1, color: AppColors.getBorder(isDarkMode)),

        // Selected day's todos
        Expanded(
          child: _buildSelectedDayTodos(
            eventsByDate,
            isDarkMode,
            primaryColor,
          ),
        ),
      ],
    );
  }

  Map<DateTime, List<Todo>> _groupTodosByDate(List<Todo> todos) {
    final grouped = <DateTime, List<Todo>>{};
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final todo in todos) {
      final date = todo.dueDate != null
          ? DateTime(
              todo.dueDate!.year,
              todo.dueDate!.month,
              todo.dueDate!.day,
            )
          : today; // dueDate가 없으면 오늘 날짜에 표시
      grouped.putIfAbsent(date, () => []).add(todo);
    }
    return grouped;
  }

  Widget _buildSelectedDayTodos(
    Map<DateTime, List<Todo>> eventsByDate,
    bool isDarkMode,
    Color primaryColor,
  ) {
    final selectedDate = _selectedDay ?? _focusedDay;
    final normalizedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final todos = eventsByDate[normalizedDate] ?? [];

    // Apply custom text styling
    final textColor = _customTextColor ?? AppColors.getText(isDarkMode);
    final textSecondaryColor = _customTextColor?.withOpacity(0.7) ?? AppColors.getTextSecondary(isDarkMode);
    final fontWeight = _isBoldText ? FontWeight.bold : FontWeight.normal;

    // Check for holiday
    final holidayName = _getHolidayName(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('M/d (E)', context.locale.languageCode)
                          .format(selectedDate),
                      style: TextStyle(
                        fontWeight: _isBoldText ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 12,
                        color: holidayName != null
                            ? (_customTextColor ?? Colors.red.shade400)
                            : textColor,
                      ),
                    ),
                    // Show holiday name if exists
                    if (holidayName != null)
                      Text(
                        holidayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: _customTextColor ?? Colors.red.shade400,
                          fontWeight: fontWeight,
                        ),
                      ),
                  ],
                ),
              ),
              // Quick add button
              InkWell(
                onTap: () => _showQuickAddDialog(selectedDate, isDarkMode, primaryColor),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.add_24_regular, size: 12, color: primaryColor),
                      const SizedBox(width: 2),
                      Text(
                        'add'.tr(),
                        style: TextStyle(
                          fontSize: 10,
                          color: primaryColor,
                          fontWeight: _isBoldText ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Todo list
          Expanded(
            child: todos.isEmpty
                ? Center(
                    child: Text(
                      'no_todos'.tr(),
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 11,
                        fontWeight: fontWeight,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: todos.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return _buildCompactTodoItem(
                        todos[index],
                        isDarkMode,
                        primaryColor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTodoItem(Todo todo, bool isDarkMode, Color primaryColor) {
    final hasDescription = todo.description.isNotEmpty;

    // Apply custom text color and font weight settings
    final textColor = _customTextColor ?? AppColors.getText(isDarkMode);
    final textSecondaryColor = _customTextColor?.withOpacity(0.7) ?? AppColors.getTextSecondary(isDarkMode);
    final fontWeight = _isBoldText ? FontWeight.bold : FontWeight.normal;

    return GestureDetector(
      onTap: () => _showTodoDetailDialog(todo, isDarkMode, primaryColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getInput(isDarkMode),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with checkbox, title, and time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion checkbox
                GestureDetector(
                  onTap: () {
                    // Toggle todo completion using updateTodo
                    final actions = ref.read(todoActionsProvider);
                    final updatedTodo = todo.copyWith(
                      isCompleted: !todo.isCompleted,
                      completedAt: !todo.isCompleted ? DateTime.now() : null,
                    );
                    actions.updateTodo(updatedTodo);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      todo.isCompleted
                          ? FluentIcons.checkmark_circle_24_filled
                          : FluentIcons.circle_24_regular,
                      size: 16,
                      color: todo.isCompleted ? primaryColor : textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Title
                Expanded(
                  child: Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: todo.isCompleted ? fontWeight : FontWeight.lerp(fontWeight, FontWeight.w500, 0.5),
                      color: todo.isCompleted ? textSecondaryColor : textColor,
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Time indicators (due time and notification time)
                if (todo.dueDate != null && (todo.dueDate!.hour != 0 || todo.dueDate!.minute != 0) || todo.notificationTime != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Due time
                        if (todo.dueDate != null && (todo.dueDate!.hour != 0 || todo.dueDate!.minute != 0))
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FluentIcons.clock_12_regular,
                                size: 10,
                                color: textSecondaryColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                DateFormat('HH:mm').format(todo.dueDate!),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: fontWeight,
                                  color: textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        // Notification time
                        if (todo.notificationTime != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FluentIcons.alert_12_regular,
                                size: 10,
                                color: primaryColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                DateFormat('HH:mm').format(todo.notificationTime!),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primaryColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            // Description (max 3 lines)
            if (hasDescription) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  todo.description,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: fontWeight,
                    color: textSecondaryColor,
                    height: 1.3,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show todo detail dialog with edit functionality
  void _showTodoDetailDialog(Todo todo, bool isDarkMode, Color primaryColor) {
    final categories = ref.read(categoriesProvider).value ?? [];

    showDialog(
      context: context,
      builder: (dialogContext) => _TodoDetailDialog(
        todo: todo,
        isDarkMode: isDarkMode,
        primaryColor: primaryColor,
        categories: categories,
        onUpdate: (updatedTodo) {
          final actions = ref.read(todoActionsProvider);
          actions.updateTodo(updatedTodo);
        },
        onDelete: () {
          final actions = ref.read(todoActionsProvider);
          actions.deleteTodo(todo.id);
        },
      ),
    );
  }

  void _showQuickAddDialog(DateTime date, bool isDarkMode, Color primaryColor) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedDueTime;
    TimeOfDay? selectedNotificationTime;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.getCard(isDarkMode),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            '${'add_todo'.tr()} - ${DateFormat('M/d').format(date)}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getText(isDarkMode),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title input
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getText(isDarkMode),
                  ),
                  decoration: InputDecoration(
                    hintText: 'title_hint'.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.getTextSecondary(isDarkMode),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.getInput(isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                // Description input
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getText(isDarkMode),
                  ),
                  decoration: InputDecoration(
                    hintText: 'description_hint'.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.getTextSecondary(isDarkMode),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.getInput(isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                // Due time selector
                _buildTimeSelector(
                  context: context,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  icon: FluentIcons.clock_24_regular,
                  label: 'due_time_optional'.tr(),
                  selectedTime: selectedDueTime,
                  onTimePicked: (time) => setDialogState(() => selectedDueTime = time),
                  onClear: () => setDialogState(() => selectedDueTime = null),
                ),
                const SizedBox(height: 8),
                // Notification time selector
                _buildTimeSelector(
                  context: context,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  icon: FluentIcons.alert_24_regular,
                  label: 'notification_time_optional'.tr(),
                  selectedTime: selectedNotificationTime,
                  onTimePicked: (time) => setDialogState(() => selectedNotificationTime = time),
                  onClear: () => setDialogState(() => selectedNotificationTime = null),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _addTodo(
                    date,
                    titleController.text,
                    descriptionController.text,
                    selectedDueTime,
                    selectedNotificationTime,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('add'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required BuildContext context,
    required bool isDarkMode,
    required Color primaryColor,
    required IconData icon,
    required String label,
    required TimeOfDay? selectedTime,
    required void Function(TimeOfDay) onTimePicked,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDarkMode
                    ? ColorScheme.dark(
                        primary: primaryColor,
                        surface: AppColors.darkBackground,
                      )
                    : ColorScheme.light(
                        primary: primaryColor,
                      ),
                // Fix text size for keyboard input mode
                textTheme: Theme.of(context).textTheme.copyWith(
                  displayLarge: const TextStyle(fontSize: 40),
                  displayMedium: const TextStyle(fontSize: 36),
                  headlineMedium: const TextStyle(fontSize: 28),
                ),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(0.85),
                ),
                child: child!,
              ),
            );
          },
        );
        if (picked != null) {
          onTimePicked(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.getInput(isDarkMode),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selectedTime != null
                  ? primaryColor
                  : AppColors.getTextSecondary(isDarkMode),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedTime != null
                    ? selectedTime.format(context)
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  color: selectedTime != null
                      ? AppColors.getText(isDarkMode)
                      : AppColors.getTextSecondary(isDarkMode),
                ),
              ),
            ),
            if (selectedTime != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  FluentIcons.dismiss_circle_24_regular,
                  size: 16,
                  color: AppColors.getTextSecondary(isDarkMode),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addTodo(
    DateTime date,
    String title,
    String description,
    TimeOfDay? dueTime,
    TimeOfDay? notificationTime,
  ) {
    final actions = ref.read(todoActionsProvider);

    // Create dueDate with time if selected
    DateTime dueDate = date;
    if (dueTime != null) {
      dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        dueTime.hour,
        dueTime.minute,
      );
    }

    // Create notification DateTime if time is selected
    DateTime? notificationDateTime;
    if (notificationTime != null) {
      notificationDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        notificationTime.hour,
        notificationTime.minute,
      );
    }

    actions.createTodo(
      title,
      description,
      dueDate,
      notificationTime: notificationDateTime,
    );
  }

  void _showLogoutConfirmDialog() {
    final themeMode = ref.read(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              FluentIcons.sign_out_24_regular,
              color: AppColors.dangerRed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'logout'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDarkMode),
              ),
            ),
          ],
        ),
        content: Text(
          'logout_confirm'.tr(),
          style: TextStyle(
            fontSize: 13,
            color: AppColors.getTextSecondary(isDarkMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // Perform logout
    await ref.read(authActionsProvider).logout();

    // Stay on login screen instead of hiding
    // Widget will auto-show login screen via authState watch
  }

  void _showExitConfirmDialog() {
    final themeMode = ref.read(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              FluentIcons.power_24_regular,
              color: AppColors.dangerRed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'exit'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDarkMode),
              ),
            ),
          ],
        ),
        content: Text(
          'exit_confirm'.tr(),
          style: TextStyle(
            fontSize: 13,
            color: AppColors.getTextSecondary(isDarkMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performExit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('exit'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performExit() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.close();
    }
  }

  // Login screen for unauthenticated users
  Widget _buildLoginScreen(bool isDarkMode, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // App icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              FluentIcons.checkmark_circle_24_filled,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            'login'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'login_subtitle'.tr(),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Email/Password Login Section
          _buildEmailLoginSection(isDarkMode, primaryColor),

          const SizedBox(height: 12),

          // Divider with "or"
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.getBorder(isDarkMode))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'or'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.getBorder(isDarkMode))),
            ],
          ),

          const SizedBox(height: 12),

          // Google Login Button
          _buildOAuthButton(
            label: 'google_login'.tr(),
            icon: FluentIcons.globe_24_regular,
            backgroundColor: Colors.white,
            textColor: Colors.black87,
            onPressed: _signInWithGoogle,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 8),

          // Kakao Login Button
          _buildOAuthButton(
            label: 'kakao_login'.tr(),
            icon: FluentIcons.chat_24_regular,
            backgroundColor: const Color(0xFFFEE500),
            textColor: Colors.black87,
            onPressed: _signInWithKakao,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  // Email login section with text fields
  Widget _buildEmailLoginSection(bool isDarkMode, Color primaryColor) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setLoginState) {
        return Column(
          children: [
            // Email input
            SizedBox(
              height: 38,
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getText(isDarkMode),
                ),
                decoration: InputDecoration(
                  hintText: 'email'.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    FluentIcons.mail_24_regular,
                    size: 16,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                  filled: true,
                  fillColor: AppColors.getInput(isDarkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Password input
            SizedBox(
              height: 38,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getText(isDarkMode),
                ),
                decoration: InputDecoration(
                  hintText: 'password'.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    FluentIcons.lock_closed_24_regular,
                    size: 16,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                  filled: true,
                  fillColor: AppColors.getInput(isDarkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onSubmitted: (_) => _signInWithEmail(emailController.text, passwordController.text),
              ),
            ),
            const SizedBox(height: 10),
            // Login button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () => _signInWithEmail(emailController.text, passwordController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'login'.tr(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // OAuth button builder
  Widget _buildOAuthButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Email/Password login
  Future<void> _signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('email_password_required'.tr());
      return;
    }

    try {
      logger.d('🔐 Widget login attempt: $email');
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      logger.d('✅ Widget login successful');
    } catch (e) {
      logger.e('❌ Widget login error: $e');
      if (mounted) {
        _showSnackBar('${'login_failed'.tr()}: ${e.toString()}');
      }
    }
  }

  // Google OAuth login
  Future<void> _signInWithGoogle() async {
    try {
      final redirectUrl = oauthRedirectUrl();
      logger.d('🔗 Google OAuth redirectTo: $redirectUrl');

      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!response) {
        throw 'google_login_failed'.tr();
      }
      logger.d('✅ Google OAuth initiated');
    } catch (e) {
      logger.e('❌ Google OAuth error: $e');
      if (mounted) {
        _showSnackBar('${'google_login_failed'.tr()}: ${e.toString()}');
      }
    }
  }

  // Kakao OAuth login
  Future<void> _signInWithKakao() async {
    try {
      final redirectUrl = oauthRedirectUrl();
      logger.d('🔗 Kakao OAuth redirectTo: $redirectUrl');

      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!response) {
        throw 'kakao_login_failed'.tr();
      }
      logger.d('✅ Kakao OAuth initiated');
    } catch (e) {
      logger.e('❌ Kakao OAuth error: $e');
      if (mounted) {
        _showSnackBar('${'kakao_login_failed'.tr()}: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Todo detail dialog with edit functionality
class _TodoDetailDialog extends StatefulWidget {
  final Todo todo;
  final bool isDarkMode;
  final Color primaryColor;
  final List<Category> categories;
  final void Function(Todo) onUpdate;
  final VoidCallback onDelete;

  const _TodoDetailDialog({
    required this.todo,
    required this.isDarkMode,
    required this.primaryColor,
    required this.categories,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_TodoDetailDialog> createState() => _TodoDetailDialogState();
}

class _TodoDetailDialogState extends State<_TodoDetailDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isCompleted;
  late DateTime? _dueDate;
  late TimeOfDay? _dueTime;
  late TimeOfDay? _notificationTime;
  late int? _categoryId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description);
    _isCompleted = widget.todo.isCompleted;
    _dueDate = widget.todo.dueDate;
    _dueTime = widget.todo.dueDate != null
        ? TimeOfDay(hour: widget.todo.dueDate!.hour, minute: widget.todo.dueDate!.minute)
        : null;
    _notificationTime = widget.todo.notificationTime != null
        ? TimeOfDay(hour: widget.todo.notificationTime!.hour, minute: widget.todo.notificationTime!.minute)
        : null;
    _categoryId = widget.todo.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_titleController.text.isEmpty) return;

    DateTime? newDueDate = _dueDate;
    if (_dueDate != null && _dueTime != null) {
      newDueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
    }

    DateTime? newNotificationTime;
    if (_notificationTime != null && _dueDate != null) {
      newNotificationTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _notificationTime!.hour,
        _notificationTime!.minute,
      );
    }

    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      isCompleted: _isCompleted,
      dueDate: newDueDate,
      notificationTime: newNotificationTime,
      categoryId: _categoryId,
      completedAt: _isCompleted ? (widget.todo.completedAt ?? DateTime.now()) : null,
    );

    widget.onUpdate(updatedTodo);
    Navigator.pop(context);
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(widget.isDarkMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(FluentIcons.delete_24_regular, color: AppColors.dangerRed, size: 20),
            const SizedBox(width: 8),
            Text(
              'delete_todo'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(widget.isDarkMode),
              ),
            ),
          ],
        ),
        content: Text(
          'delete_todo_confirm'.tr(),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondary(widget.isDarkMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: AppColors.getTextSecondary(widget.isDarkMode)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close detail dialog
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = _categoryId != null
        ? widget.categories.where((c) => c.id == _categoryId).firstOrNull
        : null;

    return AlertDialog(
      backgroundColor: AppColors.getCard(widget.isDarkMode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditMode ? 'edit_todo'.tr() : 'todo_detail'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getText(widget.isDarkMode),
                      ),
                    ),
                  ),
                  // Edit/Save toggle
                  IconButton(
                    onPressed: () {
                      if (_isEditMode) {
                        _saveChanges();
                      } else {
                        setState(() => _isEditMode = true);
                      }
                    },
                    icon: Icon(
                      _isEditMode ? FluentIcons.checkmark_24_regular : FluentIcons.edit_24_regular,
                      size: 18,
                      color: widget.primaryColor,
                    ),
                    tooltip: _isEditMode ? 'save'.tr() : 'edit'.tr(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  IconButton(
                    onPressed: _showDeleteConfirmation,
                    icon: const Icon(
                      FluentIcons.delete_24_regular,
                      size: 18,
                      color: AppColors.dangerRed,
                    ),
                    tooltip: 'delete'.tr(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      FluentIcons.dismiss_24_regular,
                      size: 18,
                      color: AppColors.getTextSecondary(widget.isDarkMode),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              if (_isEditMode)
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getText(widget.isDarkMode),
                  ),
                  decoration: InputDecoration(
                    hintText: 'title'.tr(),
                    hintStyle: TextStyle(color: AppColors.getTextSecondary(widget.isDarkMode)),
                    filled: true,
                    fillColor: AppColors.getInput(widget.isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                )
              else
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isCompleted = !_isCompleted);
                        // Auto-save completion status
                        final updatedTodo = widget.todo.copyWith(
                          isCompleted: _isCompleted,
                          completedAt: _isCompleted ? DateTime.now() : null,
                        );
                        widget.onUpdate(updatedTodo);
                      },
                      child: Icon(
                        _isCompleted
                            ? FluentIcons.checkmark_circle_24_filled
                            : FluentIcons.circle_24_regular,
                        size: 20,
                        color: _isCompleted
                            ? widget.primaryColor
                            : AppColors.getTextSecondary(widget.isDarkMode),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.todo.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isCompleted
                              ? AppColors.getTextSecondary(widget.isDarkMode)
                              : AppColors.getText(widget.isDarkMode),
                          decoration: _isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Description
              if (_isEditMode)
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getText(widget.isDarkMode),
                  ),
                  decoration: InputDecoration(
                    hintText: 'description'.tr(),
                    hintStyle: TextStyle(color: AppColors.getTextSecondary(widget.isDarkMode)),
                    filled: true,
                    fillColor: AppColors.getInput(widget.isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                )
              else if (widget.todo.description.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.getInput(widget.isDarkMode),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.todo.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(widget.isDarkMode),
                      height: 1.4,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Info rows
              _buildInfoRow(
                icon: FluentIcons.calendar_24_regular,
                label: 'due_date'.tr(),
                value: _dueDate != null
                    ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                    : 'none'.tr(),
                onTap: _isEditMode ? _selectDate : null,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: FluentIcons.clock_24_regular,
                label: 'due_time'.tr(),
                value: _dueTime != null
                    ? _dueTime!.format(context)
                    : 'none'.tr(),
                onTap: _isEditMode ? _selectDueTime : null,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: FluentIcons.alert_24_regular,
                label: 'notification'.tr(),
                value: _notificationTime != null
                    ? _notificationTime!.format(context)
                    : 'none'.tr(),
                onTap: _isEditMode ? _selectNotificationTime : null,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: FluentIcons.folder_24_regular,
                label: 'category'.tr(),
                value: category?.name ?? 'none'.tr(),
                valueColor: category != null ? ColorUtils.parseColor(category.color) : null,
                onTap: _isEditMode ? _selectCategory : null,
              ),

              // Created/Completed info
              const SizedBox(height: 12),
              Divider(color: AppColors.getBorder(widget.isDarkMode)),
              const SizedBox(height: 8),
              Text(
                '${'created_at'.tr()}: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.todo.createdAt)}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.getTextSecondary(widget.isDarkMode),
                ),
              ),
              if (widget.todo.completedAt != null)
                Text(
                  '${'completed_at'.tr()}: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.todo.completedAt!)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.getTextSecondary(widget.isDarkMode),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getInput(widget.isDarkMode),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.getTextSecondary(widget.isDarkMode),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.getTextSecondary(widget.isDarkMode),
              ),
            ),
            const Spacer(),
            if (valueColor != null)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: valueColor,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.getText(widget.isDarkMode),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                FluentIcons.chevron_right_12_regular,
                size: 12,
                color: AppColors.getTextSecondary(widget.isDarkMode),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: widget.isDarkMode
                ? ColorScheme.dark(primary: widget.primaryColor)
                : ColorScheme.light(primary: widget.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: widget.isDarkMode
                ? ColorScheme.dark(primary: widget.primaryColor)
                : ColorScheme.light(primary: widget.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _selectNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: widget.isDarkMode
                ? ColorScheme.dark(primary: widget.primaryColor)
                : ColorScheme.light(primary: widget.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _notificationTime = picked);
    }
  }

  void _selectCategory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCard(widget.isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorder(widget.isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // No category option
              ListTile(
                leading: Icon(
                  FluentIcons.dismiss_circle_24_regular,
                  color: AppColors.getTextSecondary(widget.isDarkMode),
                ),
                title: Text(
                  'no_category'.tr(),
                  style: TextStyle(color: AppColors.getText(widget.isDarkMode)),
                ),
                trailing: _categoryId == null
                    ? Icon(FluentIcons.checkmark_24_regular, color: widget.primaryColor)
                    : null,
                onTap: () {
                  setState(() => _categoryId = null);
                  Navigator.pop(context);
                },
              ),
              // Category list
              ...widget.categories.map((category) {
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ColorUtils.parseColor(category.color),
                      shape: BoxShape.circle,
                    ),
                    child: category.icon != null
                        ? Center(child: Text(category.icon!, style: const TextStyle(fontSize: 12)))
                        : null,
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(color: AppColors.getText(widget.isDarkMode)),
                  ),
                  trailing: _categoryId == category.id
                      ? Icon(FluentIcons.checkmark_24_regular, color: widget.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _categoryId = category.id);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
