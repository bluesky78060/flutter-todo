/// Responsive layout utilities for adaptive UI across devices.
///
/// Provides breakpoints and helpers for building responsive layouts
/// that adapt to different screen sizes (phone, tablet, desktop).
///
/// Usage:
/// ```dart
/// if (ResponsiveUtils.isTablet(context)) {
///   // Show split view layout
/// }
/// ```
///
/// See also:
/// - [ResponsiveBuilder] for declarative responsive layouts
/// - Material Design responsive layout guidelines
library;

import 'package:flutter/material.dart';

/// Device type classification based on screen width.
enum DeviceType {
  /// Phone: < 600dp
  phone,
  /// Tablet: 600dp - 1024dp
  tablet,
  /// Desktop: > 1024dp
  desktop,
}

/// Responsive layout utilities and breakpoints.
class ResponsiveUtils {
  ResponsiveUtils._();

  // Breakpoints (Material Design guidelines)
  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  /// Get the current device type based on screen width.
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneMaxWidth) {
      return DeviceType.phone;
    } else if (width < tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if the device is a phone.
  static bool isPhone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phone;
  }

  /// Check if the device is a tablet.
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if the device is a desktop.
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Check if the device is a tablet or larger.
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= phoneMaxWidth;
  }

  /// Check if the device is a desktop or larger.
  static bool isDesktopOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Get screen width.
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height.
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if the device is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if the device is in portrait orientation.
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get horizontal padding based on device type.
  static double getHorizontalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return 16;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
        return 32;
    }
  }

  /// Get the master panel width ratio for split view.
  static double getMasterPanelRatio(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1200) {
      return 0.3; // 30% for wide screens
    } else if (width >= tabletMaxWidth) {
      return 0.35; // 35% for desktop
    } else {
      return 0.4; // 40% for tablet
    }
  }

  /// Get max content width for centered layouts.
  static double? getMaxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return null; // Full width
      case DeviceType.tablet:
        return 800;
      case DeviceType.desktop:
        return 1200;
    }
  }
}

/// A builder widget for responsive layouts.
class ResponsiveBuilder extends StatelessWidget {
  /// Widget to show on phone screens.
  final Widget phone;

  /// Widget to show on tablet screens (optional, defaults to phone).
  final Widget? tablet;

  /// Widget to show on desktop screens (optional, defaults to tablet or phone).
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.phone:
        return phone;
    }
  }
}

/// A widget that provides split view layout for tablet/desktop.
class SplitView extends StatelessWidget {
  /// The master (left) panel widget.
  final Widget master;

  /// The detail (right) panel widget.
  final Widget detail;

  /// Master panel width ratio (0.0 - 1.0).
  final double? masterRatio;

  /// Divider widget between panels.
  final Widget? divider;

  const SplitView({
    super.key,
    required this.master,
    required this.detail,
    this.masterRatio,
    this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = masterRatio ?? ResponsiveUtils.getMasterPanelRatio(context);

    return Row(
      children: [
        SizedBox(
          width: ResponsiveUtils.screenWidth(context) * ratio,
          child: master,
        ),
        divider ?? const VerticalDivider(width: 1),
        Expanded(child: detail),
      ],
    );
  }
}

/// A widget that constrains content width on larger screens.
class ResponsiveContainer extends StatelessWidget {
  /// The child widget.
  final Widget child;

  /// Maximum width constraint.
  final double? maxWidth;

  /// Horizontal padding.
  final double? horizontalPadding;

  /// Background color.
  final Color? backgroundColor;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.horizontalPadding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveUtils.getMaxContentWidth(context);
    final effectivePadding = horizontalPadding ?? ResponsiveUtils.getHorizontalPadding(context);

    Widget content = child;

    if (effectiveMaxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: child,
        ),
      );
    }

    if (effectivePadding > 0) {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: effectivePadding),
        child: content,
      );
    }

    if (backgroundColor != null) {
      content = ColoredBox(
        color: backgroundColor!,
        child: content,
      );
    }

    return content;
  }
}
