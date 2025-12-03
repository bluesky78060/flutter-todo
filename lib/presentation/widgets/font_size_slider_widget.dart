/// Font size scale slider widget for theme customization.
///
/// Allows users to adjust the global font size scale from 0.8x to 1.5x.
/// Updates pending state only - use "Apply Theme" button to commit changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';

/// Widget for adjusting global font size scale (0.8 - 1.5).
/// Shows pending (preview) selection, not the applied theme.
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
    // Watch pending font scale (preview), not applied
    final currentScale = ref.watch(pendingFontScaleProvider);

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
                      fontSize: AppColors.scaledFontSize(13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(currentScale * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.getText(isDarkMode),
                      fontSize: AppColors.scaledFontSize(20),
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
                  fontSize: AppColors.scaledFontSize(14) * currentScale,
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
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.getInput(isDarkMode),
            thumbColor: AppColors.primary,
          ),
          child: Slider(
            value: currentScale,
            min: 0.8,
            max: 1.5,
            divisions: 14, // (1.5 - 0.8) * 20 = 14 divisions
            onChanged: (value) {
              // Update pending state only (not applied yet)
              ref
                  .read(themeCustomizationProvider.notifier)
                  .setPendingFontScale(value);
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
                fontSize: AppColors.scaledFontSize(12),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '100%',
              style: TextStyle(
                color: AppColors.getText(isDarkMode),
                fontSize: AppColors.scaledFontSize(12),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '150%',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDarkMode),
                fontSize: AppColors.scaledFontSize(12),
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
            onPressed: () {
              ref
                  .read(themeCustomizationProvider.notifier)
                  .resetPendingToDefaults();
              onScaleChanged?.call();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'reset_to_defaults'.tr(),
              style: TextStyle(
                fontSize: AppColors.scaledFontSize(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
