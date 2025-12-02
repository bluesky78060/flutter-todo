/// Category management screen for CRUD operations on todo categories.
///
/// Features:
/// - List all categories with color indicators
/// - Create new categories with custom colors
/// - Edit existing category names and colors
/// - Delete categories (with confirmation)
/// - Color picker with predefined palette
///
/// Accessed from settings screen.
///
/// See also:
/// - [categoriesProvider] for category data
/// - [CategoryActions] for CRUD operations
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

/// Screen for managing todo categories.
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

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
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'category_management'.tr(),
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: AppColors.scaledFontSize(24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        FluentIcons.add_24_regular,
                        color: Colors.white,
                      ),
                      onPressed: () => _showCategoryDialog(context, ref),
                    ),
                  ),
                ],
              ),
            ),

            // Categories List
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FluentIcons.folder_24_regular,
                            size: 64,
                            color: AppColors.getTextSecondary(isDarkMode),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_categories'.tr(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: AppColors.scaledFontSize(16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'add_category_hint'.tr(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDarkMode),
                              fontSize: AppColors.scaledFontSize(14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryItem(
                        context,
                        ref,
                        category,
                        isDarkMode,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'error_prefix'.tr(namedArgs: {'error': error.toString()}),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    WidgetRef ref,
    Category category,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _parseColor(category.color).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              category.icon ?? '📁',
              style: TextStyle(fontSize: AppColors.scaledFontSize(24)),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            color: AppColors.getText(isDarkMode),
            fontSize: AppColors.scaledFontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('yyyy-MM-dd').format(category.createdAt.toLocal()),
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: AppColors.scaledFontSize(14),
          ),
        ),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                FluentIcons.edit_24_regular,
                color: AppColors.primary,
              ),
              onPressed: () => _showCategoryDialog(
                context,
                ref,
                category: category,
              ),
            ),
            IconButton(
              icon: Icon(
                FluentIcons.delete_24_regular,
                color: Colors.red,
              ),
              onPressed: () => _showDeleteDialog(context, ref, category),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Normalize color string: remove 0xFF prefix and ensure # is present
      String normalized = colorString
          .replaceAll('0xFF', '')
          .replaceAll('0xff', '')
          .trim();

      if (!normalized.startsWith('#')) {
        normalized = '#$normalized';
      }

      final hexString = normalized.replaceAll('#', '');
      return Color(int.parse('0xFF$hexString', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(category: category),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
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
                FluentIcons.delete_24_regular,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'delete_category'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: AppColors.scaledFontSize(20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'confirm_delete_category_name'.tr(namedArgs: {'name': category.name}),
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: AppColors.scaledFontSize(16),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Row(
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
                        padding: EdgeInsets.symmetric(vertical: 12),
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
                      onPressed: () async {
                        try {
                          await ref
                              .read(categoryActionsProvider)
                              .deleteCategory(category.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('category_deleted'.tr()),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('delete_failed'.tr(namedArgs: {'error': e.toString()})),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('delete'.tr()),
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

class CategoryDialog extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryDialog({super.key, this.category});

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  late TextEditingController _nameController;
  String _selectedColor = '#3B82F6';
  String _selectedIcon = '📁';

  final List<String> _colors = [
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Orange
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#F97316', // Orange
  ];

  final List<String> _icons = [
    '📁', '💼', '🏠', '🎯', '💡', '🎨', '📚', '🏃',
    '🍔', '🎵', '✈️', '🎮', '💰', '🏋️', '🧘', '🎬',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    if (widget.category != null) {
      _selectedColor = _normalizeColor(widget.category!.color);
      _selectedIcon = widget.category!.icon ?? '📁';
    }
  }

  // Normalize color string to #RRGGBB format
  String _normalizeColor(String color) {
    // Remove any 0xFF prefix and ensure # is present
    String normalized = color
        .replaceAll('0xFF', '')
        .replaceAll('0xff', '')
        .trim();

    if (!normalized.startsWith('#')) {
      normalized = '#$normalized';
    }

    return normalized.toUpperCase();
  }

  // Parse color string safely to Color object
  Color _parseColorInDialog(String colorString) {
    try {
      // Remove any whitespace
      String normalized = colorString.trim();

      // Remove 0xFF or 0xff prefix if present
      if (normalized.startsWith('0xFF') || normalized.startsWith('0xff')) {
        normalized = normalized.substring(4);
      }

      // Add # prefix if not present
      if (!normalized.startsWith('#')) {
        normalized = '#$normalized';
      }

      // Remove # and parse hex
      final hexString = normalized.replaceFirst('#', '');

      // Validate hex string length (should be 6 characters: RRGGBB)
      if (hexString.length != 6) {
        print('⚠️ Invalid color hex length: $colorString -> $hexString');
        return AppColors.primary;
      }

      // Parse and create Color
      final colorValue = int.parse(hexString, radix: 16);
      final color = Color(0xFF000000 | colorValue);

      print('✅ Parsed color: $colorString -> ${color.value.toRadixString(16)}');
      return color;
    } catch (e) {
      print('❌ Failed to parse color: $colorString, error: $e');
      return AppColors.primary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Dialog(
      backgroundColor: AppColors.getCard(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category == null ? 'new_category'.tr() : 'edit_category'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: AppColors.scaledFontSize(20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Name Input
              Text(
                'name'.tr(),
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: AppColors.scaledFontSize(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                ),
                decoration: InputDecoration(
                  hintText: 'category_name_hint'.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                  filled: true,
                  fillColor: AppColors.getInput(isDarkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Color Picker
              Text(
                'color'.tr(),
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: AppColors.scaledFontSize(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  final parsedColor = _parseColorInDialog(color);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: parsedColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              FluentIcons.checkmark_24_filled,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Icon Picker
              Text(
                'icon'.tr(),
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: AppColors.scaledFontSize(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.getInput(isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: TextStyle(fontSize: AppColors.scaledFontSize(24)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Buttons
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
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.category == null ? 'add'.tr() : 'save'.tr()),
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

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('category_name_empty'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('login_required'.tr());
      }

      if (widget.category == null) {
        // Create new category
        await ref.read(categoryActionsProvider).createCategory(
              currentUser.uuid,  // ✅ Use Supabase UUID instead of id
              _nameController.text.trim(),
              _selectedColor,
              _selectedIcon,
            );
      } else {
        // Update existing category
        await ref.read(categoryActionsProvider).updateCategory(
              widget.category!.copyWith(
                name: _nameController.text.trim(),
                color: _selectedColor,
                icon: _selectedIcon,
              ),
            );
      }

      // Check mounted before navigation
      if (!mounted) return;

      // Pop dialog first
      Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category == null
                  ? 'category_added'.tr()
                  : 'category_updated'.tr(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_prefix'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
