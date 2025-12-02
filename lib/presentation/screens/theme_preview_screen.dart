/// Theme preview screen for comparing light and dark mode appearances.
///
/// Features:
/// - Side-by-side or toggle comparison of themes
/// - Sample todo list preview in each theme
/// - Interactive toggle between light/dark modes
/// - Preview of all UI elements (cards, buttons, text)
///
/// Accessed from settings screen theme section.
///
/// See also:
/// - [themeProvider] for theme state management
/// - [AppColors] for theme color definitions
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

/// Screen for previewing light/dark theme appearances.
class ThemePreviewScreen extends ConsumerStatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  ConsumerState<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends ConsumerState<ThemePreviewScreen> {
  late bool _isDarkMode;

  // 샘플 데이터
  late final Category _sampleCategory;

  late final List<Todo> _sampleTodos;

  @override
  void initState() {
    super.initState();
    // Initialize with app's current dark mode state
    _isDarkMode = ref.read(isDarkModeProvider);
    _sampleCategory = Category(
      id: 1,
      userId: 'preview-user',
      name: 'preview_category_work'.tr(),
      color: '#2B8DEE',
      createdAt: DateTime.now(),
    );
    _sampleTodos = [
      Todo(
        id: 1,
        title: 'preview_todo_1'.tr(),
        description: 'preview_desc_1'.tr(),
        isCompleted: false,
        categoryId: 1,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        notificationTime: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      ),
      Todo(
        id: 2,
        title: 'preview_todo_2'.tr(),
        description: '',
        isCompleted: true,
        categoryId: 1,
        completedAt: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Todo(
        id: 3,
        title: 'preview_todo_3'.tr(),
        description: '',
        isCompleted: false,
        categoryId: 1,
        dueDate: DateTime.now().add(const Duration(hours: 5)),
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: AppColors.getBackground(_isDarkMode),
        appBar: AppBar(
          title: Text(
            'theme_preview'.tr(),
            style: TextStyle(
              color: AppColors.getText(_isDarkMode),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.getCard(_isDarkMode),
          elevation: 0,
          iconTheme: IconThemeData(
            color: AppColors.getText(_isDarkMode),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 테마 전환 카드
              _buildThemeToggleCard(),
              const SizedBox(height: 16),

              // 테마 정보 카드
              _buildInfoCard(),
              const SizedBox(height: 24),

              // 색상 팔레트
              _buildColorPalette(),
              const SizedBox(height: 24),

              // Todo 리스트 미리보기
              _buildTodoListPreview(),
              const SizedBox(height: 24),

              // 버튼 스타일 미리보기
              _buildButtonPreview(),
              const SizedBox(height: 24),

              // 입력 필드 미리보기
              _buildInputFieldPreview(),
              const SizedBox(height: 24),

              // 카테고리 칩 미리보기
              _buildCategoryChipPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleCard() {
    // Use dynamic primary color for gradient
    final primaryColor = AppColors.primary;
    final primaryDark = HSLColor.fromColor(primaryColor)
        .withLightness((HSLColor.fromColor(primaryColor).lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
    final primaryLight = HSLColor.fromColor(primaryColor)
        .withLightness((HSLColor.fromColor(primaryColor).lightness + 0.1).clamp(0.0, 1.0))
        .toColor();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _isDarkMode
            ? LinearGradient(
                colors: [primaryDark, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [primaryColor, primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
          // 왼쪽 아이콘
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isDarkMode
                  ? FluentIcons.weather_moon_24_filled
                  : FluentIcons.weather_sunny_24_filled,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // 중앙 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDarkMode ? 'dark_mode'.tr() : 'light_mode'.tr(),
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isDarkMode ? 'dark_theme_enabled'.tr() : 'light_theme_enabled'.tr(),
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(14),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽 토글 스위치
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 라이트 모드 버튼
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDarkMode = false;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isDarkMode
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      FluentIcons.weather_sunny_24_filled,
                      size: 20,
                      color: !_isDarkMode
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 다크 모드 버튼
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDarkMode = true;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      FluentIcons.weather_moon_24_filled,
                      size: 20,
                      color: _isDarkMode
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(_isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(_isDarkMode),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isDarkMode
                    ? FluentIcons.weather_moon_24_filled
                    : FluentIcons.weather_sunny_24_filled,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _isDarkMode ? 'dark_mode'.tr() : 'light_mode'.tr(),
                style: TextStyle(
                  fontSize: AppColors.scaledFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(_isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isDarkMode ? 'dark_theme_enabled'.tr() : 'light_theme_enabled'.tr(),
            style: TextStyle(
              fontSize: AppColors.scaledFontSize(14),
              color: AppColors.getTextSecondary(_isDarkMode),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'preview_color_palette'.tr(),
          style: TextStyle(
            fontSize: AppColors.scaledFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.getText(_isDarkMode),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCard(_isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(_isDarkMode),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildColorRow('Background', AppColors.getBackground(_isDarkMode)),
              const SizedBox(height: 12),
              _buildColorRow('Card Background', AppColors.getCard(_isDarkMode)),
              const SizedBox(height: 12),
              _buildColorRow('Input Field', AppColors.getInput(_isDarkMode)),
              const SizedBox(height: 12),
              _buildColorRow('Border', AppColors.getBorder(_isDarkMode)),
              const SizedBox(height: 12),
              _buildColorRow('Primary Text', AppColors.getText(_isDarkMode)),
              const SizedBox(height: 12),
              _buildColorRow(
                  'Secondary Text', AppColors.getTextSecondary(_isDarkMode)),
              const SizedBox(height: 12),
              _buildColorRow('primary_color'.tr(), AppColors.primary),
              const SizedBox(height: 12),
              _buildColorRow('Success Green', AppColors.successGreen),
              const SizedBox(height: 12),
              _buildColorRow('Danger Red', AppColors.dangerRed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.getBorder(_isDarkMode),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppColors.scaledFontSize(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.getText(_isDarkMode),
                ),
              ),
              Text(
                _colorToHex(color),
                style: TextStyle(
                  fontSize: AppColors.scaledFontSize(12),
                  color: AppColors.getTextSecondary(_isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Widget _buildTodoListPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Todo List Preview',
          style: TextStyle(
            fontSize: AppColors.scaledFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.getText(_isDarkMode),
          ),
        ),
        const SizedBox(height: 12),
        ..._sampleTodos.map((todo) => _buildTodoItem(todo)),
      ],
    );
  }

  Widget _buildTodoItem(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(_isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(_isDarkMode),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 완료 체크박스
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: todo.isCompleted
                  ? AppColors.successGreen
                  : AppColors.getInput(_isDarkMode),
              borderRadius: BorderRadius.circular(6),
              border: todo.isCompleted
                  ? null
                  : Border.all(
                      color: AppColors.getBorder(_isDarkMode),
                      width: 2,
                    ),
            ),
            child: todo.isCompleted
                ? Icon(
                    FluentIcons.checkmark_24_filled,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Todo 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.getText(_isDarkMode),
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (todo.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    todo.description!,
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(14),
                      color: AppColors.getTextSecondary(_isDarkMode),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (todo.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        FluentIcons.calendar_24_regular,
                        size: 14,
                        color: AppColors.getTextSecondary(_isDarkMode),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(todo.dueDate!),
                        style: TextStyle(
                          fontSize: AppColors.scaledFontSize(12),
                          color: AppColors.getTextSecondary(_isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 카테고리 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(int.parse(_sampleCategory.color.substring(1),
                      radix: 16) +
                  0xFF000000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _sampleCategory.name,
              style: TextStyle(
                fontSize: AppColors.scaledFontSize(12),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'preview_button_styles'.tr(),
          style: TextStyle(
            fontSize: AppColors.scaledFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.getText(_isDarkMode),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCard(_isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(_isDarkMode),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Primary 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Primary Button',
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Success 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Success Button',
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Danger 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Danger Button',
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Outlined 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Outlined Button',
                    style: TextStyle(
                      fontSize: AppColors.scaledFontSize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputFieldPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'preview_input_fields'.tr(),
          style: TextStyle(
            fontSize: AppColors.scaledFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.getText(_isDarkMode),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCard(_isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(_isDarkMode),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // 일반 입력 필드
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter todo title',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondary(_isDarkMode),
                  ),
                  filled: true,
                  fillColor: AppColors.getInput(_isDarkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getBorder(_isDarkMode),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getBorder(_isDarkMode),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: AppColors.getText(_isDarkMode),
                ),
              ),
              const SizedBox(height: 12),
              // 검색 입력 필드
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSecondary(_isDarkMode),
                  ),
                  prefixIcon: Icon(
                    FluentIcons.search_24_regular,
                    color: AppColors.getTextSecondary(_isDarkMode),
                  ),
                  filled: true,
                  fillColor: AppColors.getInput(_isDarkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getBorder(_isDarkMode),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getBorder(_isDarkMode),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: AppColors.getText(_isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChipPreview() {
    final categories = [
      ('preview_category_work'.tr(), '#2B8DEE'),
      ('preview_category_personal'.tr(), '#10B981'),
      ('preview_category_shopping'.tr(), '#FF9933'),
      ('preview_category_exercise'.tr(), '#EF4444'),
      ('preview_category_learning'.tr(), '#8B5CF6'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Chips',
          style: TextStyle(
            fontSize: AppColors.scaledFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.getText(_isDarkMode),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCard(_isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(_isDarkMode),
              width: 1,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final name = category.$1;
              final colorHex = category.$2;
              final color = Color(
                  int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: AppColors.scaledFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
