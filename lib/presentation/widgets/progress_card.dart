/// Todo completion progress card widget.
///
/// Displays a visual progress indicator showing how many todos
/// have been completed out of the total.
///
/// Features:
/// - Completion count badge (completed/total)
/// - Gradient progress bar
/// - Shadow and card styling
///
/// Example:
/// ```dart
/// ProgressCard(
///   completed: 5,
///   total: 10,
/// )
/// ```
///
/// See also:
/// - [TodoListScreen] where this is used
/// - [StatisticsScreen] for more detailed analytics
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:easy_localization/easy_localization.dart';

/// Card widget displaying todo completion progress with a visual bar.
class ProgressCard extends ConsumerWidget {
  final int completed;
  final int total;

  const ProgressCard({
    super.key,
    required this.completed,
    required this.total,
  });

  double get percentage => total > 0 ? (completed / total) : 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'progress'.tr(),
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'completed_count_format'.tr(namedArgs: {
                    'completed': completed.toString(),
                    'total': total.toString(),
                  }),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.getInput(isDarkMode),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
