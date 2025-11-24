import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

/// Dialog for configuring recurrence settings
class RecurrenceSettingsDialog extends ConsumerStatefulWidget {
  final String? initialRRule;
  final Function(String? rrule) onSave;

  const RecurrenceSettingsDialog({
    super.key,
    this.initialRRule,
    required this.onSave,
  });

  @override
  ConsumerState<RecurrenceSettingsDialog> createState() => _RecurrenceSettingsDialogState();
}

class _RecurrenceSettingsDialogState extends ConsumerState<RecurrenceSettingsDialog> {
  RecurrenceFrequency _frequency = RecurrenceFrequency.daily;
  int _interval = 1;
  DateTime? _untilDate;
  int? _count;
  Set<int> _selectedWeekDays = {}; // 0 = Monday, 6 = Sunday
  bool _hasEndDate = false;
  bool _useCount = false;

  @override
  void initState() {
    super.initState();
    _parseInitialRRule();
  }

  void _parseInitialRRule() {
    if (widget.initialRRule == null || widget.initialRRule!.isEmpty) {
      return;
    }

    final parts = widget.initialRRule!.split(';');
    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length != 2) continue;

      switch (kv[0]) {
        case 'FREQ':
          _frequency = _parseFrequency(kv[1]);
          break;
        case 'INTERVAL':
          _interval = int.tryParse(kv[1]) ?? 1;
          break;
        case 'UNTIL':
          _hasEndDate = true;
          _useCount = false;
          // Parse UNTIL date (simplified)
          break;
        case 'COUNT':
          _count = int.tryParse(kv[1]);
          _useCount = true;
          _hasEndDate = false;
          break;
        case 'BYDAY':
          _selectedWeekDays = _parseByDay(kv[1]);
          break;
      }
    }
  }

  RecurrenceFrequency _parseFrequency(String freq) {
    switch (freq) {
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      case 'YEARLY':
        return RecurrenceFrequency.yearly;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  Set<int> _parseByDay(String byDay) {
    const dayMap = {
      'MO': 0,
      'TU': 1,
      'WE': 2,
      'TH': 3,
      'FR': 4,
      'SA': 5,
      'SU': 6,
    };

    final days = byDay.split(',');
    return days.map((d) => dayMap[d] ?? 0).toSet();
  }

  String _buildRRule() {
    return RecurrenceUtils.createRRule(
      frequency: _frequency,
      interval: _interval,
      until: _hasEndDate ? _untilDate : null,
      count: _useCount ? _count : null,
      byWeekDay: _frequency == RecurrenceFrequency.weekly && _selectedWeekDays.isNotEmpty
          ? _selectedWeekDays.toList()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Dialog(
      backgroundColor: AppColors.getCard(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              children: [
                const Icon(
                  FluentIcons.arrow_repeat_all_24_regular,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'recurrence_settings'.tr(),
                  style: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    FluentIcons.dismiss_24_regular,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Frequency Selector
            _buildFrequencySelector(isDarkMode),
            const SizedBox(height: 20),

            // Interval Selector
            _buildIntervalSelector(isDarkMode),
            const SizedBox(height: 20),

            // Week Days (only for weekly)
            if (_frequency == RecurrenceFrequency.weekly) ...[
              _buildWeekDaySelector(isDarkMode),
              const SizedBox(height: 20),
            ],

            // End Date Options
            _buildEndDateOptions(isDarkMode),
            const SizedBox(height: 24),

            // Preview
            _buildPreview(isDarkMode),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // No Repeat Button
                TextButton(
                  onPressed: () {
                    widget.onSave(null);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.getTextSecondary(isDarkMode),
                  ),
                  child: Text('no_recurrence'.tr()),
                ),
                const SizedBox(width: 12),
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.getTextSecondary(isDarkMode),
                  ),
                  child: Text('cancel'.tr()),
                ),
                const SizedBox(width: 12),
                // Save Button
                ElevatedButton(
                  onPressed: () {
                    final rrule = _buildRRule();
                    widget.onSave(rrule);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('save'.tr()),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurrence_frequency'.tr(),
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFrequencyChip('daily'.tr(), RecurrenceFrequency.daily, isDarkMode),
            _buildFrequencyChip('weekly'.tr(), RecurrenceFrequency.weekly, isDarkMode),
            _buildFrequencyChip('monthly'.tr(), RecurrenceFrequency.monthly, isDarkMode),
            _buildFrequencyChip('yearly'.tr(), RecurrenceFrequency.yearly, isDarkMode),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyChip(String label, RecurrenceFrequency frequency, bool isDarkMode) {
    final isSelected = _frequency == frequency;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _frequency = frequency;
        });
      },
      backgroundColor: AppColors.getBackground(isDarkMode),
      selectedColor: AppColors.primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlue : AppColors.getTextSecondary(isDarkMode),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : AppColors.getTextSecondary(isDarkMode).withOpacity(0.3),
      ),
    );
  }

  Widget _buildIntervalSelector(bool isDarkMode) {
    String unit;
    switch (_frequency) {
      case RecurrenceFrequency.daily:
        unit = 'day_unit'.tr();
        break;
      case RecurrenceFrequency.weekly:
        unit = 'week_unit'.tr();
        break;
      case RecurrenceFrequency.monthly:
        unit = 'month_unit'.tr();
        break;
      case RecurrenceFrequency.yearly:
        unit = 'year_unit'.tr();
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurrence_interval'.tr(),
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(FluentIcons.subtract_circle_24_regular),
              color: AppColors.primaryBlue,
              onPressed: _interval > 1
                  ? () => setState(() => _interval--)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDarkMode),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.3),
                ),
              ),
              child: Text(
                '$_interval $unit ${'every_unit'.tr()}',
                style: TextStyle(
                  color: AppColors.getText(isDarkMode),
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(FluentIcons.add_circle_24_regular),
              color: AppColors.primaryBlue,
              onPressed: _interval < 99
                  ? () => setState(() => _interval++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDaySelector(bool isDarkMode) {
    final weekDays = ['mon'.tr(), 'tue'.tr(), 'wed'.tr(), 'thu'.tr(), 'fri'.tr(), 'sat'.tr(), 'sun'.tr()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurrence_days'.tr(),
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _selectedWeekDays.contains(index);
            return FilterChip(
              label: Text(weekDays[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekDays.add(index);
                  } else {
                    _selectedWeekDays.remove(index);
                  }
                });
              },
              backgroundColor: AppColors.getBackground(isDarkMode),
              selectedColor: AppColors.primaryBlue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryBlue : AppColors.getTextSecondary(isDarkMode),
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primaryBlue : AppColors.getTextSecondary(isDarkMode).withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEndDateOptions(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'end_condition'.tr(),
          style: TextStyle(
            color: AppColors.getTextSecondary(isDarkMode),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        // Never ends
        RadioListTile<String>(
          title: Text(
            'no_end'.tr(),
            style: TextStyle(color: AppColors.getText(isDarkMode)),
          ),
          value: 'never',
          groupValue: !_hasEndDate && !_useCount ? 'never' : (_hasEndDate ? 'until' : 'count'),
          onChanged: (value) {
            setState(() {
              _hasEndDate = false;
              _useCount = false;
              _untilDate = null;
              _count = null;
            });
          },
          activeColor: AppColors.primaryBlue,
        ),

        // End after count
        RadioListTile<String>(
          title: Row(
            children: [
              Text(
                'repeat_count'.tr(),
                style: TextStyle(color: AppColors.getText(isDarkMode)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: TextField(
                  enabled: _useCount,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.getText(isDarkMode)),
                  decoration: InputDecoration(
                    hintText: '10',
                    hintStyle: TextStyle(color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.getTextSecondary(isDarkMode).withOpacity(0.3)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _count = int.tryParse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'times_unit'.tr(),
                style: TextStyle(color: AppColors.getText(isDarkMode)),
              ),
            ],
          ),
          value: 'count',
          groupValue: !_hasEndDate && !_useCount ? 'never' : (_hasEndDate ? 'until' : 'count'),
          onChanged: (value) {
            setState(() {
              _useCount = true;
              _hasEndDate = false;
              _untilDate = null;
              if (_count == null) _count = 10;
            });
          },
          activeColor: AppColors.primaryBlue,
        ),

        // End on date
        RadioListTile<String>(
          title: Row(
            children: [
              Text(
                'end_date'.tr(),
                style: TextStyle(color: AppColors.getText(isDarkMode)),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _hasEndDate ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _untilDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (date != null) {
                    setState(() {
                      _untilDate = date;
                    });
                  }
                } : null,
                child: Text(
                  _untilDate != null
                      ? '${_untilDate!.year}.${_untilDate!.month}.${_untilDate!.day}'
                      : 'select_date'.tr(),
                  style: TextStyle(
                    color: _hasEndDate ? AppColors.primaryBlue : AppColors.getTextSecondary(isDarkMode),
                  ),
                ),
              ),
            ],
          ),
          value: 'until',
          groupValue: !_hasEndDate && !_useCount ? 'never' : (_hasEndDate ? 'until' : 'count'),
          onChanged: (value) {
            setState(() {
              _hasEndDate = true;
              _useCount = false;
              _count = null;
              if (_untilDate == null) {
                _untilDate = DateTime.now().add(const Duration(days: 30));
              }
            });
          },
          activeColor: AppColors.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildPreview(bool isDarkMode) {
    final rrule = _buildRRule();
    final description = RecurrenceUtils.getDescription(rrule);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getBackground(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.info_24_regular,
            color: AppColors.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'preview'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDarkMode),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.getText(isDarkMode),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
