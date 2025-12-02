/// Font size scale slider widget for theme customization.
///
/// Allows users to adjust the global font size scale from 0.8x to 1.5x.
/// Integrates with theme customization provider for saving selections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';

/// Widget for adjusting global font size scale (0.8 - 1.5).
class FontSizeSliderWidget extends ConsumerWidget {
  final bool isDarkMode;
  final VoidCallback? onScaleChanged;

  const FontSizeSliderWidget({
    required this.isDarkMode,
    this.onScaleChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(themeCustomizationProvider);
    final currentScale = customization.fontSizeScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display current scale
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getInput(isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(isDarkMode),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'font_size_label'.tr(),
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDarkMode),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(currentScale * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Preview text with current scale
              Text(
                'preview'.tr(),
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 14 * currentScale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: AppColors.primaryBlue,
            inactiveTrackColor: AppColors.getInput(isDarkMode),
            thumbColor: AppColors.primaryBlue,
          ),
          child: Slider(
            value: currentScale,
            min: 0.8,
            max: 1.5,
            divisions: 14, // (1.5 - 0.8) * 20 = 14 divisions
            onChanged: (value) async {
              await ref
                  .read(themeCustomizationProvider.notifier)
                  .setFontSizeScale(value);
              onScaleChanged?.call();
            },
          ),
        ),
        const SizedBox(height: 16),

        // Min/Max labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '80%',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '100%',
              style: TextStyle(
                color: AppColors.getText(isDarkMode),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '150%',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Reset to default button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              await ref
                  .read(themeCustomizationProvider.notifier)
                  .resetToDefaults();
              onScaleChanged?.call();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'reset_to_defaults'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
