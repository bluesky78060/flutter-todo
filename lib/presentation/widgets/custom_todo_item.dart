import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:easy_localization/easy_localization.dart';

class CustomTodoItem extends ConsumerStatefulWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CustomTodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  ConsumerState<CustomTodoItem> createState() => _CustomTodoItemState();
}

class _CustomTodoItemState extends ConsumerState<CustomTodoItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDueDate(DateTime date, {bool checkAllDay = false}) {
    final local = date.toLocal();
    // Check if this is an all-day event (time is 00:00)
    final isAllDay = checkAllDay && local.hour == 0 && local.minute == 0;
    if (isAllDay) {
      return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} (${'all_day'.tr()})';
    }
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: 8),
          transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isHovered ?
                    (isDarkMode ? Color(0xFF1A2936) : Color(0xFFF0F4F8)) :
                    AppColors.getBackground(isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Custom Checkbox
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: widget.todo.isCompleted
                              ? AppColors.primaryGradient
                              : null,
                          color: widget.todo.isCompleted
                              ? null
                              : Colors.transparent,
                          border: Border.all(
                            color: widget.todo.isCompleted
                                ? AppColors.primaryBlue
                                : AppColors.getBorder(isDarkMode),
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: widget.todo.isCompleted
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Todo Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.todo.title,
                            style: TextStyle(
                              color: AppColors.getText(isDarkMode),
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              decoration: widget.todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.getTextSecondary(isDarkMode),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.todo.description.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              widget.todo.description,
                              style: TextStyle(
                                color: AppColors.getTextSecondary(isDarkMode),
                                fontSize: 14,
                                decoration: widget.todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.getTextSecondary(isDarkMode),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (widget.todo.dueDate != null) ...[
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  FluentIcons.calendar_clock_24_regular,
                                  color: AppColors.primaryBlue,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _formatDueDate(widget.todo.dueDate!, checkAllDay: true),
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.todo.notificationTime != null) ...[
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  FluentIcons.alert_24_regular,
                                  color: AppColors.accentOrange,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'notification_prefix'.tr(namedArgs: {
                                      'time': _formatDueDate(widget.todo.notificationTime!)
                                    }),
                                    style: TextStyle(
                                      color: AppColors.accentOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.todo.recurrenceRule != null && widget.todo.recurrenceRule!.isNotEmpty) ...[
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  FluentIcons.arrow_repeat_all_24_regular,
                                  color: AppColors.primaryBlue,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'recurring'.tr(),
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Delete Button (always visible)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.getTextSecondary(isDarkMode),
                        size: 20,
                      ),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
