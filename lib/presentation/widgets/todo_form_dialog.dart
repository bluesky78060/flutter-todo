import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';
import 'package:todo_app/core/utils/color_utils.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/widgets/recurrence_settings_dialog.dart';
import 'package:todo_app/presentation/widgets/recurring_edit_dialog.dart';
import 'package:todo_app/presentation/widgets/location_picker_dialog.dart';

class TodoFormDialog extends ConsumerStatefulWidget {
  final Todo? existingTodo; // null = create mode, not null = edit mode

  const TodoFormDialog({super.key, this.existingTodo});

  @override
  ConsumerState<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends ConsumerState<TodoFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _selectedDueDate;
  DateTime? _selectedNotificationTime;
  int? _selectedCategoryId;
  String? _recurrenceRule;

  // Location fields
  double? _locationLatitude;
  double? _locationLongitude;
  String? _locationName;
  double? _locationRadius;

  bool get _isEditMode => widget.existingTodo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    // Initialize with existing data if in edit mode
    if (_isEditMode) {
      final todo = widget.existingTodo!;
      _titleController.text = todo.title;
      _descriptionController.text = todo.description;
      _selectedDueDate = todo.dueDate;
      _selectedNotificationTime = todo.notificationTime;
      _selectedCategoryId = todo.categoryId;
      _recurrenceRule = todo.recurrenceRule;
      _locationLatitude = todo.locationLatitude;
      _locationLongitude = todo.locationLongitude;
      _locationName = todo.locationName;
      _locationRadius = todo.locationRadius;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!mounted) return;

    // Step 1: Select date using Material Design calendar
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.textWhite,
              surface: AppColors.darkCard,
              onSurface: AppColors.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // Step 2: Select time using Cupertino wheel picker
    final now = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.fromDateTime(_selectedDueDate ?? now.add(const Duration(minutes: 1)));

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      builder: (BuildContext context) {
        DateTime tempTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          initialTime.hour,
          initialTime.minute,
        );

        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'cancel'.tr(),
                      style: const TextStyle(color: AppColors.textGray),
                    ),
                  ),
                  Text(
                    'select_notification_time'.tr(),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = tempTime;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'confirm'.tr(),
                      style: const TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newTime) {
                    tempTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      newTime.hour,
                      newTime.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDueDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectLocation() async {
    if (!mounted) return;

    final result = await showDialog<LocationPickerResult>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLatitude: _locationLatitude,
        initialLongitude: _locationLongitude,
        initialName: _locationName,
        initialRadius: _locationRadius,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _locationLatitude = result.latitude;
        _locationLongitude = result.longitude;
        _locationName = result.name;
        _locationRadius = result.radius;
      });
    }
  }

  Future<void> _selectRecurrence() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => RecurrenceSettingsDialog(
        initialRRule: _recurrenceRule,
        onSave: (rrule) {
          setState(() {
            _recurrenceRule = rrule;
          });
        },
      ),
    );
  }

  Future<void> _selectNotificationTime() async {
    if (!mounted) return;

    // Step 1: Select date using Material Design calendar
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedNotificationTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.textWhite,
              surface: AppColors.darkCard,
              onSurface: AppColors.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // Step 2: Select time using Cupertino wheel picker
    final now = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.fromDateTime(_selectedNotificationTime ?? now.add(const Duration(minutes: 1)));

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      builder: (BuildContext context) {
        DateTime tempTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          initialTime.hour,
          initialTime.minute,
        );

        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'cancel'.tr(),
                      style: const TextStyle(color: AppColors.textGray),
                    ),
                  ),
                  Text(
                    'select_notification_time'.tr(),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedNotificationTime = tempTime;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'confirm'.tr(),
                      style: const TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newTime) {
                    tempTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      newTime.hour,
                      newTime.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) return;

    try {
      if (_isEditMode) {
        // Edit mode: update existing todo
        final existingTodo = widget.existingTodo!;

        // Check if this is a recurring todo instance
        if (existingTodo.parentRecurringTodoId != null) {
          // Show recurring edit dialog
          final mode = await showDialog<RecurringEditMode>(
            context: context,
            builder: (context) => const RecurringEditDialog(),
          );

          if (mode == null) return; // User cancelled

          final updatedTodo = existingTodo.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            dueDate: _selectedDueDate,
            categoryId: _selectedCategoryId,
            notificationTime: _selectedNotificationTime,
            locationLatitude: _locationLatitude,
            locationLongitude: _locationLongitude,
            locationName: _locationName,
            locationRadius: _locationRadius,
          );

          await ref.read(todoActionsProvider).updateTodo(
            updatedTodo,
            recurringEditMode: mode,
          );
        } else {
          // Regular todo or master recurring todo
          final updatedTodo = existingTodo.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            dueDate: _selectedDueDate,
            categoryId: _selectedCategoryId,
            notificationTime: _selectedNotificationTime,
            recurrenceRule: _recurrenceRule,
            locationLatitude: _locationLatitude,
            locationLongitude: _locationLongitude,
            locationName: _locationName,
            locationRadius: _locationRadius,
          );
          await ref.read(todoActionsProvider).updateTodo(updatedTodo);
        }
      } else {
        // Create mode: create new todo
        await ref.read(todoActionsProvider).createTodo(
              _titleController.text,
              _descriptionController.text,
              _selectedDueDate,
              categoryId: _selectedCategoryId,
              notificationTime: _selectedNotificationTime,
              recurrenceRule: _recurrenceRule,
              locationLatitude: _locationLatitude,
              locationLongitude: _locationLongitude,
              locationName: _locationName,
              locationRadius: _locationRadius,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? 'edit_todo'.tr() : 'new_todo'.tr(),
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    FluentIcons.dismiss_24_regular,
                    color: AppColors.textGray,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'title'.tr(),
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _titleController,
                    autofocus: !_isEditMode,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'title_hint'.tr(),
                      hintStyle: const TextStyle(
                        color: AppColors.textGray,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'description_optional'.tr(),
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'description_hint'.tr(),
                      hintStyle: const TextStyle(
                        color: AppColors.textGray,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'category_optional'.tr(),
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ref.watch(categoriesProvider).when(
                  data: (categories) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkInput,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: AppColors.darkCard,
                          menuMaxHeight: 300,
                          icon: const Icon(
                            FluentIcons.chevron_down_24_regular,
                            color: AppColors.textGray,
                            size: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          hint: Text(
                            'select_category'.tr(),
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 16,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'no_category'.tr(),
                                style: const TextStyle(
                                  color: AppColors.textGray,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            ...categories.map((category) {
                              return DropdownMenuItem<int?>(
                                value: category.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: ColorUtils.parseColor(category.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (category.icon != null) ...[
                                      Text(
                                        category.icon!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        category.name,
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text(
                    '${'category_load_failed'.tr()}: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Due Date Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'due_date_optional'.tr(),
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkInput,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.calendar_24_regular,
                          color: AppColors.textGray,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDueDate != null
                              ? _formatDueDate(_selectedDueDate!)
                              : 'select_due_date'.tr(),
                          style: TextStyle(
                            color: _selectedDueDate != null
                                ? AppColors.textWhite
                                : AppColors.textGray,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDueDate != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedDueDate = null;
                              });
                            },
                            icon: const Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.textGray,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notification Time Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'notification_time_optional'.tr(),
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectNotificationTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkInput,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.alert_24_regular,
                          color: AppColors.textGray,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedNotificationTime != null
                              ? _formatDueDate(_selectedNotificationTime!)
                              : 'select_notification_time'.tr(),
                          style: TextStyle(
                            color: _selectedNotificationTime != null
                                ? AppColors.textWhite
                                : AppColors.textGray,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedNotificationTime != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedNotificationTime = null;
                              });
                            },
                            icon: const Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.textGray,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recurrence Settings
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.locale.languageCode == 'ko' ? '반복 설정 (선택사항)' : 'Recurrence (Optional)',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectRecurrence,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkInput,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.arrow_repeat_all_24_regular,
                          color: AppColors.textGray,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recurrenceRule != null
                                ? RecurrenceUtils.getDescription(_recurrenceRule)
                                : 'no_recurrence'.tr(),
                            style: TextStyle(
                              color: _recurrenceRule != null
                                  ? AppColors.textWhite
                                  : AppColors.textGray,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_recurrenceRule != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _recurrenceRule = null;
                              });
                            },
                            icon: const Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.textGray,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Location Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.locale.languageCode == 'ko' ? '위치 기반 알림 (선택사항)' : 'Location-based Reminder (Optional)',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkInput,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.location_24_regular,
                          color: AppColors.textGray,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _locationName ?? (context.locale.languageCode == 'ko' ? '위치 설정' : 'Set Location'),
                            style: TextStyle(
                              color: _locationName != null
                                  ? AppColors.textWhite
                                  : AppColors.textGray,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_locationName != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _locationLatitude = null;
                                _locationLongitude = null;
                                _locationName = null;
                                _locationRadius = null;
                              });
                            },
                            icon: const Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.textGray,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textGray,
                      side: const BorderSide(
                        color: AppColors.darkBorder,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'cancel'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditMode ? 'save'.tr() : 'add'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
}
