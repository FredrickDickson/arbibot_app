import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar for legal professionals
/// Implements professional minimalism with authority and precision
/// Supports various configurations for different screen contexts
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar title
  final String? title;

  /// Optional subtitle for context
  final String? subtitle;

  /// Leading widget (typically back button or menu)
  final Widget? leading;

  /// Action widgets on the right side
  final List<Widget>? actions;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// App bar variant
  final AppBarVariant variant;

  /// Custom background color
  final Color? backgroundColor;

  /// Whether to center the title
  final bool centerTitle;

  /// Bottom widget (typically TabBar)
  final PreferredSizeWidget? bottom;

  /// Elevation override
  final double? elevation;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.variant = AppBarVariant.standard,
    this.backgroundColor,
    this.centerTitle = false,
    this.bottom,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final colorScheme = theme.colorScheme;

    // Determine background color based on variant
    final bgColor =
        backgroundColor ??
        (variant == AppBarVariant.transparent
            ? Colors.transparent
            : variant == AppBarVariant.surface
            ? colorScheme.surface
            : appBarTheme.backgroundColor ?? colorScheme.primary);

    // Determine foreground color
    final fgColor = variant == AppBarVariant.surface
        ? colorScheme.onSurface
        : appBarTheme.foregroundColor ?? colorScheme.onPrimary;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation ?? (variant == AppBarVariant.transparent ? 0 : 2.0),
      shadowColor: colorScheme.shadow,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      systemOverlayStyle: _getSystemOverlayStyle(context, variant),
      leading: leading,
      title: _buildTitle(context, fgColor),
      actions: actions,
      bottom: bottom,
    );
  }

  /// Build title widget with optional subtitle
  Widget? _buildTitle(BuildContext context, Color foregroundColor) {
    if (title == null) return null;

    final theme = Theme.of(context);

    if (subtitle != null) {
      // Title with subtitle layout
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            title!,
            style:
                theme.appBarTheme.titleTextStyle?.copyWith(
                  color: foregroundColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  color: foregroundColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style:
                theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ) ??
                TextStyle(
                  color: foregroundColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
          ),
        ],
      );
    }

    // Standard title
    return Text(
      title!,
      style:
          theme.appBarTheme.titleTextStyle?.copyWith(color: foregroundColor) ??
          TextStyle(
            color: foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  /// Get system overlay style based on variant
  SystemUiOverlayStyle _getSystemOverlayStyle(
    BuildContext context,
    AppBarVariant variant,
  ) {
    final brightness = Theme.of(context).brightness;

    if (variant == AppBarVariant.transparent) {
      return brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light;
    }

    if (variant == AppBarVariant.surface) {
      return brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light;
    }

    // Standard variant with primary color
    return SystemUiOverlayStyle.light;
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final baseHeight = variant == AppBarVariant.compact ? 48.0 : 56.0;
    return Size.fromHeight(baseHeight + bottomHeight);
  }

  /// Create a standard app bar with back button
  factory CustomAppBar.withBackButton({
    required BuildContext context,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    AppBarVariant variant = AppBarVariant.standard,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      variant: variant,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onBackPressed != null) {
            onBackPressed();
          } else {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Back',
      ),
    );
  }

  /// Create a search app bar
  factory CustomAppBar.search({
    required BuildContext context,
    required String hintText,
    required ValueChanged<String> onSearchChanged,
    VoidCallback? onSearchClear,
    List<Widget>? actions,
  }) {
    return CustomAppBar(
      variant: AppBarVariant.surface,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      actions: [
        Expanded(
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        if (onSearchClear != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              HapticFeedback.lightImpact();
              onSearchClear();
            },
            tooltip: 'Clear',
          ),
        ...?actions,
      ],
    );
  }
}

/// App bar display variants
enum AppBarVariant {
  /// Standard app bar with primary color background (56dp height)
  standard,

  /// Compact app bar with reduced height (48dp height)
  compact,

  /// Surface colored app bar for secondary screens
  surface,

  /// Transparent app bar for overlay contexts
  transparent,
}
