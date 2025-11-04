import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

class TodoFormDialog extends ConsumerStatefulWidget {
  const TodoFormDialog({super.key});

  @override
  ConsumerState<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends ConsumerState<TodoFormDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  DateTime? _selectedNotificationTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!mounted) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: AppColors.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryBlue,
                surface: AppColors.darkCard,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDueDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectNotificationTime() async {
    if (!mounted) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedNotificationTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: AppColors.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedNotificationTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryBlue,
                surface: AppColors.darkCard,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedNotificationTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) return;
    await ref.read(todoActionsProvider).createTodo(
          _titleController.text,
          _descriptionController.text,
          _selectedDueDate,
          notificationTime: _selectedNotificationTime,
        );
    if (mounted) Navigator.of(context).pop();
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '새로운 할 일',
                  style: TextStyle(
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
                const Text(
                  '제목',
                  style: TextStyle(
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
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: '할 일 제목을 입력하세요',
                      hintStyle: TextStyle(
                        color: AppColors.textGray,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
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
                const Text(
                  '설명 (선택)',
                  style: TextStyle(
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
                    decoration: const InputDecoration(
                      hintText: '상세 설명을 입력하세요',
                      hintStyle: TextStyle(
                        color: AppColors.textGray,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Due Date Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '마감일 (선택)',
                  style: TextStyle(
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
                              : '마감일을 선택하세요',
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
            // Only show notification picker on mobile (not web)
            if (!kIsWeb) ...[
              const SizedBox(height: 20),

              // Notification Time Picker
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '알림 시간 (선택)',
                  style: TextStyle(
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
                              : '알림 시간을 선택하세요',
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
            ],
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
                    child: const Text(
                      '취소',
                      style: TextStyle(
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
                          color: AppColors.primaryBlue.withOpacity(0.3),
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
                      child: const Text(
                        '추가',
                        style: TextStyle(
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
    );
  }
}
