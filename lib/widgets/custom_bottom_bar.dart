import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar for legal professionals
/// Implements Bottom-Heavy Thumb Zone Strategy for one-handed operation
/// Supports primary navigation between Home, Chat List, Documents, and Profile
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final ValueChanged<int> onTap;

  /// Navigation bar variant
  final BottomBarVariant variant;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.variant = BottomBarVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Navigation items based on Mobile Navigation Hierarchy
    final items = _getNavigationItems(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: variant == BottomBarVariant.compact ? 56 : 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _buildNavigationItem(
                context: context,
                item: items[index],
                isSelected: currentIndex == index,
                onTap: () {
                  // Haptic feedback for professional interaction
                  HapticFeedback.mediumImpact();
                  onTap(index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build individual navigation item with professional styling
  Widget _buildNavigationItem({
    required BuildContext context,
    required _NavigationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomNavTheme = theme.bottomNavigationBarTheme;

    final color = isSelected
        ? bottomNavTheme.selectedItemColor ?? colorScheme.primary
        : bottomNavTheme.unselectedItemColor ?? colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with scale animation
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(item.icon, size: 24, color: color),
              ),
              const SizedBox(height: 4),
              // Label with fade animation
              AnimatedOpacity(
                opacity: variant == BottomBarVariant.iconsOnly ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  item.label,
                  style:
                      (isSelected
                              ? bottomNavTheme.selectedLabelStyle
                              : bottomNavTheme.unselectedLabelStyle)
                          ?.copyWith(color: color) ??
                      TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: color,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get navigation items mapped to routes
  List<_NavigationItem> _getNavigationItems(BuildContext context) {
    return [
      _NavigationItem(
        icon: Icons.home_outlined,
        label: 'Home',
        route: '/home-dashboard',
      ),
      _NavigationItem(
        icon: Icons.chat_bubble_outline,
        label: 'Research',
        route: '/chat-list-screen',
      ),
      _NavigationItem(
        icon: Icons.folder_outlined,
        label: 'Documents',
        route: '/documents-library-screen',
      ),
      _NavigationItem(
        icon: Icons.person_outline,
        label: 'Profile',
        route: '/profile-settings-screen',
      ),
    ];
  }
}

/// Navigation item data class
class _NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Bottom bar display variants
enum BottomBarVariant {
  /// Standard bottom bar with icons and labels (64dp height)
  standard,

  /// Compact bottom bar with icons and labels (56dp height)
  compact,

  /// Icons only without labels (56dp height)
  iconsOnly,
}
