import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'responsive_layout.dart';

/// Navigation destination data
class _NavDestination {
  final IconData icon;
  final String label;
  final String route;

  const _NavDestination({
    required this.icon,
    required this.label,
    required this.route,
  });
}

const _destinations = [
  _NavDestination(icon: Icons.home_outlined, label: 'Home', route: '/home-dashboard'),
  _NavDestination(icon: Icons.chat_bubble_outline, label: 'Research', route: '/chat-list-screen'),
  _NavDestination(icon: Icons.folder_outlined, label: 'Documents', route: '/documents-library-screen'),
  _NavDestination(icon: Icons.person_outline, label: 'Profile', route: '/profile-settings-screen'),
];

/// Adaptive scaffold that switches between bottom nav (mobile),
/// NavigationRail (tablet), and full sidebar (desktop).
class ResponsiveShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const ResponsiveShell({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  void _onTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    if (index == currentIndex) return;
    onNavigationChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final layout = getLayoutType(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (layout == LayoutType.mobile) {
      // Mobile: standard scaffold with bottom nav
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: _buildBottomNav(context, theme, colorScheme),
      );
    }

    // Tablet/Desktop: scaffold with NavigationRail or sidebar
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (layout == LayoutType.desktop)
            _buildSidebar(context, theme, colorScheme)
          else
            _buildNavRail(context, theme, colorScheme),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// Mobile bottom navigation bar
  Widget _buildBottomNav(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final bottomNavTheme = theme.bottomNavigationBarTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_destinations.length, (i) {
              final isSelected = i == currentIndex;
              final color = isSelected
                  ? (bottomNavTheme.selectedItemColor ?? colorScheme.primary)
                  : (bottomNavTheme.unselectedItemColor ?? colorScheme.onSurfaceVariant);
              return Expanded(
                child: InkWell(
                  onTap: () => _onTap(context, i),
                  splashColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(_destinations[i].icon, size: 24, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _destinations[i].label,
                        style: (isSelected
                                ? bottomNavTheme.selectedLabelStyle
                                : bottomNavTheme.unselectedLabelStyle)
                            ?.copyWith(color: color) ??
                            TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              color: color,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Tablet NavigationRail
  Widget _buildNavRail(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) => _onTap(context, i),
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
      unselectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      destinations: _destinations
          .map((d) => NavigationRailDestination(
                icon: Icon(d.icon),
                label: Text(d.label),
              ))
          .toList(),
    );
  }

  /// Desktop sidebar with labels
  Widget _buildSidebar(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: 220,
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                'ArbiBot',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ..._destinations.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final isSelected = i == currentIndex;
              return _SidebarItem(
                icon: d.icon,
                label: d.label,
                isSelected: isSelected,
                onTap: () => _onTap(context, i),
                colorScheme: colorScheme,
                theme: theme,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
