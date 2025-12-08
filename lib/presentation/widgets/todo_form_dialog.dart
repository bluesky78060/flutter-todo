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
  final DateTime? initialDueDate; // 캘린더에서 선택한 날짜 (create mode only)
  final bool initialAllDay; // 하루 종일 옵션 초기값 (create mode only)

  const TodoFormDialog({
    super.key,
    this.existingTodo,
    this.initialDueDate,
    this.initialAllDay = false,
  });

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
      // Detect all-day event: dueDate exists and time is 00:00 or 23:59
      if (todo.dueDate != null &&
          ((todo.dueDate!.hour == 0 && todo.dueDate!.minute == 0) ||
           (todo.dueDate!.hour == 23 && todo.dueDate!.minute == 59))) {
        _isAllDay = true;
      }
    } else {
      // Create mode: apply initial values from calendar
      if (widget.initialDueDate != null) {
        _selectedDueDate = widget.initialDueDate;
        _isAllDay = widget.initialAllDay;
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
              primary: AppColors.primary,
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

    // If all-day is selected, set time to 23:59:59 (end of day) to avoid showing as overdue
    if (_isAllDay) {
      setState(() {
        _selectedDueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          23,
          59,
          59,
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
                      fontSize: AppColors.scaledFontSize(16),
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
                      style: TextStyle(color: AppColors.primary),
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
              fontSize: AppColors.scaledFontSize(18),
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
                  fontSize: AppColors.scaledFontSize(14),
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
                    fontSize: AppColors.scaledFontSize(13),
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
              primary: AppColors.primary,
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
                      fontSize: AppColors.scaledFontSize(16),
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
                      style: TextStyle(color: AppColors.primary),
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
                priority: _selectedPriority,
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    // Calculate max height considering keyboard
    final maxDialogHeight = screenHeight - keyboardHeight - 40; // 40 for safety margin

    return Dialog(
      backgroundColor: AppColors.getBackground(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: maxDialogHeight.clamp(300, screenHeight * 0.9),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header - centered title only
            Center(
              child: Text(
                _isEditMode ? 'edit_todo'.tr() : 'new_todo'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: AppColors.scaledFontSize(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title & Description Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getCard(isDarkMode),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Title Input
                  TextField(
                    controller: _titleController,
                    autofocus: !_isEditMode,
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: AppColors.scaledFontSize(16),
                    ),
                    decoration: InputDecoration(
                      hintText: 'title'.tr(),
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
                  Divider(
                    height: 1,
                    color: AppColors.getBorder(isDarkMode).withOpacity(0.3),
                  ),
                  // Description Input
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: AppColors.scaledFontSize(16),
                    ),
                    decoration: InputDecoration(
                      hintText: 'description'.tr(),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category, Due Date, All Day Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getCard(isDarkMode),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Category Row
                  ref.watch(categoriesProvider).when(
                    data: (categories) {
                      return _buildListTile(
                        isDarkMode: isDarkMode,
                        icon: FluentIcons.folder_24_regular,
                        title: 'category'.tr(),
                        value: _selectedCategoryId != null
                            ? categories.firstWhere(
                                (c) => c.id == _selectedCategoryId,
                                orElse: () => categories.first,
                              ).name
                            : 'none'.tr(),
                        onTap: () => _showCategoryPicker(categories, isDarkMode),
                        showDivider: true,
                      );
                    },
                    loading: () => _buildListTile(
                      isDarkMode: isDarkMode,
                      icon: FluentIcons.folder_24_regular,
                      title: 'category'.tr(),
                      value: '...',
                      onTap: null,
                      showDivider: true,
                    ),
                    error: (_, __) => _buildListTile(
                      isDarkMode: isDarkMode,
                      icon: FluentIcons.folder_24_regular,
                      title: 'category'.tr(),
                      value: 'error'.tr(),
                      onTap: null,
                      showDivider: true,
                    ),
                  ),
                  // Due Date Row
                  _buildListTile(
                    isDarkMode: isDarkMode,
                    icon: FluentIcons.calendar_24_regular,
                    title: 'due_date'.tr(),
                    value: _selectedDueDate != null
                        ? _formatShortDate(_selectedDueDate!)
                        : 'none'.tr(),
                    onTap: _selectDate,
                    showDivider: true,
                  ),
                  // All Day Toggle Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.clock_24_regular,
                          color: AppColors.getTextSecondary(isDarkMode),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'all_day'.tr(),
                            style: TextStyle(
                              color: AppColors.getText(isDarkMode),
                              fontSize: AppColors.scaledFontSize(16),
                            ),
                          ),
                        ),
                        Switch(
                          value: _isAllDay,
                          onChanged: (value) {
                            setState(() {
                              _isAllDay = value;
                              if (value && _selectedDueDate != null) {
                                _selectedDueDate = DateTime(
                                  _selectedDueDate!.year,
                                  _selectedDueDate!.month,
                                  _selectedDueDate!.day,
                                  23,
                                  59,
                                  59,
                                );
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Priority Selector - Standalone segment control
            Container(
              decoration: BoxDecoration(
                color: AppColors.getCard(isDarkMode),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  for (final priority in PriorityConstants.all)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPriority = priority;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedPriority == priority
                                ? AppColors.primary.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: _selectedPriority == priority
                                ? Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              PriorityConstants.getDisplayName(priority).tr(),
                              style: TextStyle(
                                color: _selectedPriority == priority
                                    ? AppColors.primary
                                    : AppColors.getTextSecondary(isDarkMode),
                                fontSize: AppColors.scaledFontSize(14),
                                fontWeight: _selectedPriority == priority
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification, Recurrence, Location Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getCard(isDarkMode),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Notification Row
                  _buildListTile(
                    isDarkMode: isDarkMode,
                    icon: FluentIcons.alert_24_regular,
                    title: 'notification'.tr(),
                    value: _selectedNotificationTime != null
                        ? _formatShortDateTime(_selectedNotificationTime!)
                        : 'none'.tr(),
                    onTap: _selectNotificationTime,
                    showDivider: true,
                  ),
                  // Recurrence Row
                  _buildListTile(
                    isDarkMode: isDarkMode,
                    icon: FluentIcons.arrow_repeat_all_24_regular,
                    title: 'recurrence'.tr(),
                    value: _recurrenceRule != null
                        ? RecurrenceUtils.getDescription(_recurrenceRule)
                        : 'no_repeat'.tr(),
                    onTap: _selectRecurrence,
                    showDivider: true,
                  ),
                  // Location Row
                  _buildListTile(
                    isDarkMode: isDarkMode,
                    icon: FluentIcons.location_24_regular,
                    title: 'location'.tr(),
                    value: _locationName ?? 'none'.tr(),
                    onTap: _selectLocation,
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // Attachments Section (Mobile only)
            if (!kIsWeb && _selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.getCard(isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: List.generate(_selectedFiles.length, (index) {
                    final file = _selectedFiles[index];
                    final fileName = file.path.split('/').last;
                    final isImage = fileName.toLowerCase().endsWith('.jpg') ||
                        fileName.toLowerCase().endsWith('.jpeg') ||
                        fileName.toLowerCase().endsWith('.png') ||
                        fileName.toLowerCase().endsWith('.gif');

                    return Container(
                      margin: EdgeInsets.only(bottom: index < _selectedFiles.length - 1 ? 8 : 0),
                      child: Row(
                        children: [
                          if (isImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    color: AppColors.getInput(isDarkMode),
                                    child: Icon(
                                      FluentIcons.image_24_regular,
                                      color: AppColors.getTextSecondary(isDarkMode),
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.getInput(isDarkMode),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                FluentIcons.document_24_regular,
                                color: AppColors.getTextSecondary(isDarkMode),
                                size: 20,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fileName,
                              style: TextStyle(
                                color: AppColors.getText(isDarkMode),
                                fontSize: AppColors.scaledFontSize(14),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showDeleteConfirmation(index),
                            icon: Icon(
                              FluentIcons.dismiss_circle_24_regular,
                              color: AppColors.getTextSecondary(isDarkMode),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],

            // Add attachment button (Mobile only)
            if (!kIsWeb) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickAttachment,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.getCard(isDarkMode),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FluentIcons.attach_24_regular,
                        color: AppColors.getTextSecondary(isDarkMode),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'attach_file'.tr(),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
                          fontSize: AppColors.scaledFontSize(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.getCard(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.getText(isDarkMode),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'cancel'.tr(),
                        style: TextStyle(
                          fontSize: AppColors.scaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: _save,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditMode ? 'save'.tr() : 'add'.tr(),
                        style: TextStyle(
                          fontSize: AppColors.scaledFontSize(16),
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

  // Helper method to build list tile style rows
  Widget _buildListTile({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.getTextSecondary(isDarkMode),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: AppColors.scaledFontSize(16),
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: AppColors.scaledFontSize(14),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  FluentIcons.chevron_right_24_regular,
                  color: AppColors.getTextSecondary(isDarkMode),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 50,
            color: AppColors.getBorder(isDarkMode).withOpacity(0.3),
          ),
      ],
    );
  }

  // Helper method to format short date
  String _formatShortDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to format short date time
  String _formatShortDateTime(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Show category picker bottom sheet
  Future<void> _showCategoryPicker(List<dynamic> categories, bool isDarkMode) async {
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
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorder(isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  FluentIcons.dismiss_circle_24_regular,
                  color: AppColors.getTextSecondary(isDarkMode),
                ),
                title: Text(
                  'no_category'.tr(),
                  style: TextStyle(color: AppColors.getText(isDarkMode)),
                ),
                onTap: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ...categories.map((category) {
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ColorUtils.parseColor(category.color),
                      shape: BoxShape.circle,
                    ),
                    child: category.icon != null
                        ? Center(
                            child: Text(
                              category.icon!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(color: AppColors.getText(isDarkMode)),
                  ),
                  trailing: _selectedCategoryId == category.id
                      ? Icon(
                          FluentIcons.checkmark_24_regular,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
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
