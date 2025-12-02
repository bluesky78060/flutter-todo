/// Todo creation and editing form dialog.
///
/// Provides a comprehensive form for creating new todos or editing existing ones.
///
/// Features:
/// - Title and description input
/// - Category selection with color indicators
/// - Due date picker with all-day option
/// - Notification time scheduling
/// - Recurrence rule configuration (RRULE)
/// - Location-based reminder setup with geofencing
/// - File attachment support (camera, gallery, files)
///
/// Modes:
/// - **Create mode**: Pass `existingTodo: null` (default)
/// - **Edit mode**: Pass `existingTodo` with the todo to modify
///
/// See also:
/// - [RecurrenceSettingsDialog] for recurrence configuration
/// - [LocationPickerDialog] for geofence location selection
/// - [todosProvider] for todo state management
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';
import 'package:todo_app/core/utils/color_utils.dart';
import 'package:todo_app/core/constants/priority_constants.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/attachment_providers.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/widgets/recurrence_settings_dialog.dart';
import 'package:mime/mime.dart';
import 'package:todo_app/presentation/widgets/recurring_edit_dialog.dart';
import 'package:todo_app/presentation/widgets/location_picker_dialog.dart';
import 'package:todo_app/core/services/geofence_workmanager_service.dart';
import 'package:todo_app/core/services/attachment_service.dart';
import 'package:todo_app/presentation/providers/widget_provider.dart';

/// Dialog for creating or editing a todo item.
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
  String _selectedPriority = PriorityConstants.medium; // Priority field (default: medium)
  bool _isAllDay = false; // 하루 종일 옵션

  // Location fields
  double? _locationLatitude;
  double? _locationLongitude;
  String? _locationName;
  double? _locationRadius;

  // Attachment fields
  final List<File> _selectedFiles = [];

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
      _selectedPriority = todo.priority;
      _locationLatitude = todo.locationLatitude;
      _locationLongitude = todo.locationLongitude;
      _locationName = todo.locationName;
      _locationRadius = todo.locationRadius;
      // Detect all-day event: dueDate exists and time is 00:00
      if (todo.dueDate != null &&
          todo.dueDate!.hour == 0 &&
          todo.dueDate!.minute == 0) {
        _isAllDay = true;
      }
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

    final isDarkMode = ref.read(isDarkModeProvider);

    // Step 1: Select date using Material Design calendar
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.getText(isDarkMode),
              surface: AppColors.getCard(isDarkMode),
              onSurface: AppColors.getText(isDarkMode),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // If all-day is selected, set time to 00:00 and skip time picker
    if (_isAllDay) {
      setState(() {
        _selectedDueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          0,
          0,
        );
      });
      return;
    }

    // Step 2: Select time using Cupertino wheel picker (only when not all-day)
    final now = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.fromDateTime(_selectedDueDate ?? now.add(const Duration(minutes: 1)));

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCard(isDarkMode),
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
                      style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                    ),
                  ),
                  Text(
                    'select_notification_time'.tr(),
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
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

  String _formatDueDate(DateTime date, {bool isAllDay = false}) {
    if (isAllDay) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} (${'all_day'.tr()})';
    }
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

  Future<void> _pickAttachment() async {
    if (!mounted) return;

    final isDarkMode = ref.read(isDarkModeProvider);

    // On web, directly open file picker (camera/gallery not available)
    if (kIsWeb) {
      await _pickFile();
      return;
    }

    // Show attachment source selection for mobile platforms
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCard(isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  FluentIcons.camera_24_regular,
                  color: AppColors.getText(isDarkMode),
                ),
                title: Text(
                  'take_photo_with_camera'.tr(),
                  style: TextStyle(color: AppColors.getText(isDarkMode)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(
                  FluentIcons.image_24_regular,
                  color: AppColors.getText(isDarkMode),
                ),
                title: Text(
                  'choose_from_gallery'.tr(),
                  style: TextStyle(color: AppColors.getText(isDarkMode)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromGallery();
                },
              ),
              ListTile(
                leading: Icon(
                  FluentIcons.document_24_regular,
                  color: AppColors.getText(isDarkMode),
                ),
                title: Text(
                  'choose_file'.tr(),
                  style: TextStyle(color: AppColors.getText(isDarkMode)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFile();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    final attachmentService = ref.read(attachmentServiceProvider);
    final result = await attachmentService.pickImageFromCamera();

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('image_capture_failed'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (file) {
        // Validate file size and count
        final sizeError = attachmentService.validateFileSize(file);
        if (sizeError != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(sizeError.tr()),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        if (_selectedFiles.length >= AttachmentService.maxAttachmentsPerTodo) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('max_attachments_reached'.tr(args: ['${AttachmentService.maxAttachmentsPerTodo}'])),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.add(file);
        });
      },
    );
  }

  Future<void> _pickFromGallery() async {
    final attachmentService = ref.read(attachmentServiceProvider);
    final result = await attachmentService.pickImageFromGallery();

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('image_select_failed'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (file) {
        // Validate file size and count
        final sizeError = attachmentService.validateFileSize(file);
        if (sizeError != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(sizeError.tr()),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        if (_selectedFiles.length >= AttachmentService.maxAttachmentsPerTodo) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('max_attachments_reached'.tr(args: ['${AttachmentService.maxAttachmentsPerTodo}'])),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.add(file);
        });
      },
    );
  }

  Future<void> _pickFile() async {
    final attachmentService = ref.read(attachmentServiceProvider);

    // 파일 개수 제한 확인
    if (_selectedFiles.length >= AttachmentService.maxAttachmentsPerTodo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('max_attachments_reached'.tr(args: ['${AttachmentService.maxAttachmentsPerTodo}'])),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 웹 플랫폼과 모바일 플랫폼 구분 처리
    if (kIsWeb) {
      // 웹: 파일 바이트 데이터 사용
      final result = await attachmentService.pickFileWithBytes();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('file_select_failed'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        ((String fileName, Uint8List bytes) data) {
          // 파일 크기 검증 (바이트 길이로 확인)
          if (data.$2.length > AttachmentService.maxFileSizeBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('attachment_size_too_large'.tr()),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // 임시 파일 생성 (웹에서는 가상 File 객체 생성)
          setState(() {
            _selectedFiles.add(File(data.$1)); // 웹에서는 경로만 저장, 바이트는 나중에 처리
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('file_selected'.tr(namedArgs: {'fileName': data.$1})),
              ),
            );
          }
        },
      );
    } else {
      // 모바일: 기존 File 객체 사용
      final result = await attachmentService.pickFile();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('file_select_failed'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (file) {
          // 파일 크기 검증
          final sizeError = attachmentService.validateFileSize(file);
          if (sizeError != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sizeError.tr()),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          setState(() {
            _selectedFiles.add(file);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('file_selected'.tr(namedArgs: {'fileName': file.path.split('/').last})),
              ),
            );
          }
        },
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _showDeleteConfirmation(int index) async {
    final isDarkMode = ref.read(isDarkModeProvider);
    final fileName = _selectedFiles[index].path.split('/').last;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCard(isDarkMode),
          title: Text(
            'delete_attachment'.tr(),
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'confirm_delete_attachment'.tr(),
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getInput(isDarkMode),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fileName,
                  style: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'delete'.tr(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      _removeFile(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('attachment_deleted'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _previewImage(File file) {
    final isDarkMode = ref.read(isDarkModeProvider);
    final fileName = file.path.split('/').last;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCard(isDarkMode),
          title: Text(
            'view_attachment'.tr(),
            style: TextStyle(
              color: AppColors.getText(isDarkMode),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.getInput(isDarkMode),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: AppColors.getInput(isDarkMode),
                          child: Center(
                            child: Icon(
                              FluentIcons.image_24_regular,
                              color: AppColors.getTextSecondary(isDarkMode),
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fileName,
                  style: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'close'.tr(),
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectNotificationTime() async {
    if (!mounted) return;

    final isDarkMode = ref.read(isDarkModeProvider);

    // Step 1: Select date using Material Design calendar
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedNotificationTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.getText(isDarkMode),
              surface: AppColors.getCard(isDarkMode),
              onSurface: AppColors.getText(isDarkMode),
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
      backgroundColor: AppColors.getCard(isDarkMode),
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
                      style: TextStyle(color: AppColors.getTextSecondary(isDarkMode)),
                    ),
                  ),
                  Text(
                    'select_notification_time'.tr(),
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
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
            priority: _selectedPriority,
            locationLatitude: _locationLatitude,
            locationLongitude: _locationLongitude,
            locationName: _locationName,
            locationRadius: _locationRadius,
            position: existingTodo.position, // Preserve position when editing
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
            priority: _selectedPriority,
            locationLatitude: _locationLatitude,
            locationLongitude: _locationLongitude,
            locationName: _locationName,
            locationRadius: _locationRadius,
            position: existingTodo.position, // Preserve position when editing
          );
          await ref.read(todoActionsProvider).updateTodo(updatedTodo);
        }
      } else {
        // Create mode: create new todo
        // Need to capture todoId for attachment upload
        final repository = ref.read(todoRepositoryProvider);
        final result = await repository.createTodo(
          _titleController.text,
          _descriptionController.text,
          _selectedDueDate,
          categoryId: _selectedCategoryId,
          notificationTime: _selectedNotificationTime,
          recurrenceRule: _recurrenceRule,
          priority: _selectedPriority,
          locationLatitude: _locationLatitude,
          locationLongitude: _locationLongitude,
          locationName: _locationName,
          locationRadius: _locationRadius,
        );

        final todoId = result.fold(
          (failure) {
            throw Exception('Failed to create todo: $failure');
          },
          (id) => id,
        );

        // Schedule notification if needed (same logic as TodoActions)
        if (_selectedNotificationTime != null) {
          await ref.read(notificationServiceProvider).scheduleNotification(
                id: todoId,
                title: _titleController.text,
                body: _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : '',
                scheduledDate: _selectedNotificationTime!,
                priority: _selectedPriority ?? 'medium',
              );
        }

        // Upload attachments if any
        print('[TodoFormDialog] Checking upload conditions: filesCount=${_selectedFiles.length}');
        if (_selectedFiles.isNotEmpty) {
          print('[TodoFormDialog] Uploading ${_selectedFiles.length} attachments for new todo');
          await _uploadAttachments(todoId);
        }

        // Invalidate todosProvider to refresh the list immediately
        ref.invalidate(todosProvider);

        // Update home screen widget after todo creation
        try {
          final widgetService = ref.read(widgetServiceProvider);
          await widgetService.updateWidget();
          print('[TodoFormDialog] Widget updated after todo creation');
        } catch (e) {
          print('[TodoFormDialog] Widget update error: $e');
        }
      }

      // Upload attachments for edited todo
      print('[TodoFormDialog] Edit mode check: isEditMode=$_isEditMode, filesCount=${_selectedFiles.length}');
      if (_isEditMode && _selectedFiles.isNotEmpty) {
        print('[TodoFormDialog] Uploading ${_selectedFiles.length} attachments for edited todo');
        await _uploadAttachments(widget.existingTodo!.id);
      }

      // Check geofence immediately if location is set (non-web only)
      if (!kIsWeb && _locationLatitude != null && _locationLongitude != null) {
        GeofenceWorkManagerService.checkNow();
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

  /// Upload attachments to Supabase Storage and save metadata
  Future<void> _uploadAttachments(int todoId) async {
    print('[TodoFormDialog] Starting upload for ${_selectedFiles.length} files to todoId: $todoId');

    final attachmentService = ref.read(attachmentServiceProvider);
    final localRepo = ref.read(attachmentLocalRepositoryProvider);
    final remoteRepo = ref.read(attachmentRemoteRepositoryProvider);

    for (final file in _selectedFiles) {
      try {
        print('[TodoFormDialog] Uploading file: ${file.path}');

        // 1. Upload to Supabase Storage
        final uploadResult = await attachmentService.uploadFile(
          file: file,
          todoId: todoId,
        );

        final storagePath = uploadResult.fold(
          (failure) {
            throw Exception('Upload failed: $failure');
          },
          (path) => path,
        );

        // 2. Get file info
        final fileName = file.path.split('/').last;
        final fileSize = attachmentService.getFileSize(file);
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

        // 3. Save to local database
        final localResult = await localRepo.createAttachment(
          todoId: todoId,
          fileName: fileName,
          filePath: file.path,
          fileSize: fileSize,
          mimeType: mimeType,
          storagePath: storagePath,
        );

        await localResult.fold(
          (failure) {
            print('[TodoFormDialog] Failed to save attachment to local DB: $failure');
          },
          (_) {
            print('[TodoFormDialog] Attachment saved to local DB: $fileName');
          },
        );

        // 4. Save to remote database
        final remoteResult = await remoteRepo.createAttachment(
          todoId: todoId,
          fileName: fileName,
          filePath: file.path,
          fileSize: fileSize,
          mimeType: mimeType,
          storagePath: storagePath,
        );

        await remoteResult.fold(
          (failure) {
            print('[TodoFormDialog] Failed to save attachment to remote DB: $failure');
          },
          (_) {
            print('[TodoFormDialog] Attachment saved to remote DB: $fileName');
          },
        );
      } catch (e) {
        print('[TodoFormDialog] Failed to upload attachment: $e');
        // Continue with next file even if one fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Dialog(
      backgroundColor: AppColors.getCard(isDarkMode),
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
                  style: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    FluentIcons.dismiss_24_regular,
                    color: AppColors.getTextSecondary(isDarkMode),
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
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.getInput(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _titleController,
                    autofocus: !_isEditMode,
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'title_hint'.tr(),
                      hintStyle: TextStyle(
                        color: AppColors.getTextSecondary(isDarkMode),
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
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.getInput(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'description_hint'.tr(),
                      hintStyle: TextStyle(
                        color: AppColors.getTextSecondary(isDarkMode),
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
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ref.watch(categoriesProvider).when(
                  data: (categories) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.getInput(isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: AppColors.getCard(isDarkMode),
                          menuMaxHeight: 300,
                          icon: Icon(
                            FluentIcons.chevron_down_24_regular,
                            color: AppColors.getTextSecondary(isDarkMode),
                            size: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          hint: Text(
                            'select_category'.tr(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: 16,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'no_category'.tr(),
                                style: TextStyle(
                                  color: AppColors.getTextSecondary(isDarkMode),
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
                                        style: TextStyle(
                                          color: AppColors.getText(isDarkMode),
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
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
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
                      color: AppColors.getInput(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.calendar_24_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDueDate != null
                                ? _formatDueDate(_selectedDueDate!, isAllDay: _isAllDay)
                                : 'select_due_date'.tr(),
                            style: TextStyle(
                              color: _selectedDueDate != null
                                  ? AppColors.getText(isDarkMode)
                                  : AppColors.getTextSecondary(isDarkMode),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_selectedDueDate != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedDueDate = null;
                                _isAllDay = false;
                              });
                            },
                            icon: Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.getTextSecondary(isDarkMode),
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
                // All Day Toggle
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getInput(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.clock_24_regular,
                        color: AppColors.getTextSecondary(isDarkMode),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'all_day'.tr(),
                        style: TextStyle(
                          color: AppColors.getText(isDarkMode),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isAllDay,
                        onChanged: (value) {
                          setState(() {
                            _isAllDay = value;
                            // If turning on all-day and date is already selected, reset time to 00:00
                            if (value && _selectedDueDate != null) {
                              _selectedDueDate = DateTime(
                                _selectedDueDate!.year,
                                _selectedDueDate!.month,
                                _selectedDueDate!.day,
                                0,
                                0,
                              );
                            }
                          });
                        },
                        activeColor: AppColors.primaryBlue,
                        activeTrackColor: AppColors.primaryBlue.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Priority Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'priority_label'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final priority in PriorityConstants.all)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPriority = priority;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedPriority == priority
                                      ? AppColors.primaryBlue
                                      : AppColors.getInput(isDarkMode),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _selectedPriority == priority
                                      ? Border.all(
                                          color: AppColors.primaryBlue,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    PriorityConstants.getDisplayName(priority).tr(),
                                    style: TextStyle(
                                      color: _selectedPriority == priority
                                          ? Colors.white
                                          : AppColors.getText(isDarkMode),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
              ],
            ),
            const SizedBox(height: 20),

            // Notification Time Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'notification_time_optional'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
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
                      color: AppColors.getInput(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.alert_24_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedNotificationTime != null
                              ? _formatDueDate(_selectedNotificationTime!)
                              : 'select_notification_time'.tr(),
                          style: TextStyle(
                            color: _selectedNotificationTime != null
                                ? AppColors.getText(isDarkMode)
                                : AppColors.getTextSecondary(isDarkMode),
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
                            icon: Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.getTextSecondary(isDarkMode),
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
                  'recurrence_optional'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
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
                      color: AppColors.getInput(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.arrow_repeat_all_24_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
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
                                  ? AppColors.getText(isDarkMode)
                                  : AppColors.getTextSecondary(isDarkMode),
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
                            icon: Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.getTextSecondary(isDarkMode),
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
                  'location_based_reminder_optional'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
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
                      color: AppColors.getInput(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.location_24_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _locationName ?? 'set_location'.tr(),
                            style: TextStyle(
                              color: _locationName != null
                                  ? AppColors.getText(isDarkMode)
                                  : AppColors.getTextSecondary(isDarkMode),
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
                            icon: Icon(
                              FluentIcons.dismiss_24_regular,
                              color: AppColors.getTextSecondary(isDarkMode),
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

            // Attachments Section (Mobile only)
            if (!kIsWeb) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'attachments_optional'.tr(),
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDarkMode),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Add attachment button
                  InkWell(
                    onTap: _pickAttachment,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getInput(isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            FluentIcons.attach_24_regular,
                            color: AppColors.getTextSecondary(isDarkMode),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'attach_file'.tr(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Selected files list
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...List.generate(_selectedFiles.length, (index) {
                      final file = _selectedFiles[index];
                      final fileName = file.path.split('/').last;
                      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
                          fileName.toLowerCase().endsWith('.jpeg') ||
                          fileName.toLowerCase().endsWith('.png') ||
                          fileName.toLowerCase().endsWith('.gif');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.getInput(isDarkMode),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail or icon
                            if (isImage)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  file,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: AppColors.getCard(isDarkMode),
                                      child: Icon(
                                        FluentIcons.image_24_regular,
                                        color: AppColors.getTextSecondary(isDarkMode),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.getCard(isDarkMode),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  FluentIcons.document_24_regular,
                                  color: AppColors.getTextSecondary(isDarkMode),
                                ),
                              ),
                            const SizedBox(width: 12),
                            // File name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fileName,
                                    style: TextStyle(
                                      color: AppColors.getText(isDarkMode),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                                    style: TextStyle(
                                      color: AppColors.getTextSecondary(isDarkMode),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Preview button (for images, show in gallery)
                            if (isImage)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () => _previewImage(file),
                                  icon: Icon(
                                    FluentIcons.eye_24_regular,
                                    color: AppColors.primaryBlue,
                                    size: 18,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  tooltip: 'view_attachment'.tr(),
                                ),
                              ),
                            if (isImage) const SizedBox(width: 4),
                            // Delete button with confirmation
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () => _showDeleteConfirmation(index),
                                icon: Icon(
                                  FluentIcons.delete_24_regular,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: 'delete_attachment'.tr(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Action Buttons
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
