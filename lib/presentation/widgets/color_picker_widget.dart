/// Color picker widget for theme customization.
///
/// Displays a grid of predefined colors that users can select from.
/// Integrates with theme customization provider for saving selections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';

/// Widget for selecting primary color from palette.
class ColorPickerWidget extends ConsumerWidget {
  final bool isDarkMode;
  final VoidCallback? onColorChanged;

  const ColorPickerWidget({
    required this.isDarkMode,
    this.onColorChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(themeCustomizationProvider);
    final currentColor = customization.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color palette grid
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: List.generate(
            ThemeColorPalette.colors.length,
            (index) {
              final color = ThemeColorPalette.colors[index];
              final isSelected = color.value == currentColor.value;

              return GestureDetector(
                onTap: () async {
                  await ref
                      .read(themeCustomizationProvider.notifier)
                      .setPrimaryColor(color);
                  onColorChanged?.call();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
