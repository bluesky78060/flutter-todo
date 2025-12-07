/// Navigation item widget for bottom navigation.
///
/// Displays an icon with label and optional active indicator.
/// Used in bottom navigation bar of the todo list screen.
///
/// Example:
/// ```dart
/// NavItem(
///   icon: FluentIcons.home_24_regular,
///   label: 'Home',
///   isActive: true,
///   onTap: () { /* handle navigation */ },
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

/// Navigation item widget for app navigation bar.
class NavItem extends ConsumerWidget {
  /// Icon data for the navigation item
  final IconData icon;

  /// Label text displayed below the icon
  final String label;

  /// Whether this navigation item is currently active
  final bool isActive;

  /// Callback when the item is tapped
  final VoidCallback onTap;

  const NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(3),
                    ),
                  ),
                )
              else
                const SizedBox(height: 5),
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? AppColors.primary
                    : AppColors.getTextSecondary(isDarkMode),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.getTextSecondary(isDarkMode),
                  fontSize: AppColors.scaledFontSize(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
