import 'package:flutter/material.dart';

/// Responsive breakpoints for adaptive layout
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double maxContentWidth = 840;
}

/// Helper to determine current layout type
enum LayoutType { mobile, tablet, desktop }

LayoutType getLayoutType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < ResponsiveBreakpoints.mobile) return LayoutType.mobile;
  if (width < ResponsiveBreakpoints.tablet) return LayoutType.tablet;
  return LayoutType.desktop;
}

bool isMobile(BuildContext context) =>
    getLayoutType(context) == LayoutType.mobile;

bool isTablet(BuildContext context) =>
    getLayoutType(context) == LayoutType.tablet;

bool isDesktop(BuildContext context) =>
    getLayoutType(context) == LayoutType.desktop;

/// Wraps content with a constrained max width and centers it.
/// Used to prevent content from stretching across very wide screens.
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
