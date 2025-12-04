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
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:window_manager/window_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';

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
  bool _isAlwaysOnTop = true;
  bool _isResizing = false;

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
    final todosAsync = ref.watch(todosProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkBackground.withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDragHeader(isDarkMode, primaryColor),
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
            ),
          ),
          // Resize handles
          ..._buildResizeHandles(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildDragHeader(bool isDarkMode, Color primaryColor) {
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
          color: primaryColor,
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
            // Logout button
            _buildWindowButton(
              FluentIcons.sign_out_24_regular,
              () => _showLogoutConfirmDialog(),
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

  Widget _buildWindowButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
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

    return Column(
      children: [
        // Compact calendar
        TableCalendar<Todo>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },

          // Compact style
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
              color: AppColors.getText(isDarkMode),
            ),
            weekendTextStyle: TextStyle(
              fontSize: 11,
              color: Colors.red.shade300,
            ),
            todayTextStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDarkMode),
            ),
            selectedTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Header style
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronPadding: EdgeInsets.zero,
            rightChevronPadding: EdgeInsets.zero,
            leftChevronMargin: const EdgeInsets.only(left: 8),
            rightChevronMargin: const EdgeInsets.only(right: 8),
            headerPadding: const EdgeInsets.symmetric(vertical: 8),
            titleTextStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDarkMode),
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              size: 18,
              color: AppColors.getText(isDarkMode),
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.getText(isDarkMode),
            ),
          ),

          // Days of week style
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 10,
              color: AppColors.getTextSecondary(isDarkMode),
            ),
            weekendStyle: TextStyle(
              fontSize: 10,
              color: Colors.red.shade300,
            ),
          ),

          // Event loader
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return eventsByDate[normalizedDay] ?? [];
          },

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
    for (final todo in todos) {
      if (todo.dueDate != null) {
        final date = DateTime(
          todo.dueDate!.year,
          todo.dueDate!.month,
          todo.dueDate!.day,
        );
        grouped.putIfAbsent(date, () => []).add(todo);
      }
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('M/d (E)', context.locale.languageCode)
                    .format(selectedDate),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.getText(isDarkMode),
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
                          fontWeight: FontWeight.w500,
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
                        color: AppColors.getTextSecondary(isDarkMode),
                        fontSize: 11,
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

    return Container(
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
                    color: todo.isCompleted ? primaryColor : AppColors.getTextSecondary(isDarkMode),
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
                    fontWeight: FontWeight.w500,
                    color: todo.isCompleted
                        ? AppColors.getTextSecondary(isDarkMode)
                        : AppColors.getText(isDarkMode),
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Time indicator
              if (todo.notificationTime != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.alert_12_regular,
                        size: 10,
                        color: AppColors.getTextSecondary(isDarkMode),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        DateFormat('HH:mm').format(todo.notificationTime!),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.getTextSecondary(isDarkMode),
                        ),
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
                  color: AppColors.getTextSecondary(isDarkMode),
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
    );
  }

  void _showQuickAddDialog(DateTime date, bool isDarkMode, Color primaryColor) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;

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
              // Notification time selector
              InkWell(
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
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
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
                        FluentIcons.alert_24_regular,
                        size: 16,
                        color: selectedTime != null
                            ? primaryColor
                            : AppColors.getTextSecondary(isDarkMode),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : 'notification_time_optional'.tr(),
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
                          onTap: () => setDialogState(() => selectedTime = null),
                          child: Icon(
                            FluentIcons.dismiss_circle_24_regular,
                            size: 16,
                            color: AppColors.getTextSecondary(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  _addTodo(date, titleController.text, descriptionController.text, selectedTime);
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

  void _addTodo(DateTime date, String title, String description, TimeOfDay? notificationTime) {
    final actions = ref.read(todoActionsProvider);

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
      date, // dueDate
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

    // Show login screen or close widget
    if (mounted && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Hide the calendar widget window after logout
      await windowManager.hide();
    }
  }
}
