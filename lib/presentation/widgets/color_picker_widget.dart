/// Color picker widget for theme customization.
///
/// Displays a grid of predefined colors that users can select from.
/// Updates pending state only - use "Apply Theme" button to commit changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';

/// Widget for selecting primary color from palette.
/// Shows pending (preview) selection, not the applied theme.
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
    // Watch pending color (preview), not applied
    final pendingColor = ref.watch(pendingColorProvider);

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
              final isSelected = color.value == pendingColor.value;

              return GestureDetector(
                onTap: () {
                  // Update pending state only (not applied yet)
                  ref
                      .read(themeCustomizationProvider.notifier)
                      .setPendingColor(color);
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
