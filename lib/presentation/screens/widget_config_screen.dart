import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/widget/widget_models.dart';
import 'package:todo_app/presentation/providers/widget_provider.dart';

/// Screen for configuring home screen widget settings
class WidgetConfigScreen extends ConsumerWidget {
  const WidgetConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetConfig = ref.watch(widgetConfigProvider);
    final selectedViewType = ref.watch(widgetViewTypeProvider);
    final isEnabled = ref.watch(widgetEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Enable/Disable Widget Section
            _buildEnableSection(context, ref, isEnabled),

            const SizedBox(height: 24),

            // View Type Selection Section
            if (isEnabled)
              _buildViewTypeSection(context, ref, selectedViewType),
          ],
        ),
      ),
    );
  }

  /// Build enable/disable widget section
  Widget _buildEnableSection(
    BuildContext context,
    WidgetRef ref,
    bool isEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home Screen Widget',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnabled
                        ? 'Widget is enabled'
                        : 'Widget is disabled',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) async {
                  await ref.read(toggleWidgetEnabledProvider.future);
                },
                activeColor: AppColors.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build view type selection section
  Widget _buildViewTypeSection(
    BuildContext context,
    WidgetRef ref,
    WidgetViewType selectedViewType,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display Mode',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildViewTypeOption(
            context,
            ref,
            WidgetViewType.today,
            'Today\'s Tasks',
            '📋 Shows today\'s incomplete tasks',
            selectedViewType == WidgetViewType.today,
          ),
          const SizedBox(height: 12),
          _buildViewTypeOption(
            context,
            ref,
            WidgetViewType.calendar,
            'Calendar View',
            '📅 Shows this month\'s tasks',
            selectedViewType == WidgetViewType.calendar,
          ),
        ],
      ),
    );
  }

  /// Build individual view type option
  Widget _buildViewTypeOption(
    BuildContext context,
    WidgetRef ref,
    WidgetViewType viewType,
    String title,
    String description,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(updateWidgetViewTypeProvider(viewType));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : null,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Radio<WidgetViewType>(
                value: viewType,
                groupValue: isSelected ? viewType : null,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(updateWidgetViewTypeProvider(value));
                  }
                },
                activeColor: AppColors.primaryBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
