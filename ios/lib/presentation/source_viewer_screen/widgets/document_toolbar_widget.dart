import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Document Toolbar Widget - Floating toolbar for document navigation
/// Provides controls for citation navigation, search, and page jumping
class DocumentToolbarWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPreviousCitation;
  final VoidCallback onNextCitation;
  final VoidCallback onSearch;
  final VoidCallback onPageJump;
  final bool isSearching;

  const DocumentToolbarWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPreviousCitation,
    required this.onNextCitation,
    required this.onSearch,
    required this.onPageJump,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous citation
          _buildToolbarButton(
            context,
            icon: 'arrow_back',
            label: 'Prev',
            onTap: onPreviousCitation,
          ),

          // Vertical divider
          Container(
            width: 1,
            height: 4.h,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),

          // Next citation
          _buildToolbarButton(
            context,
            icon: 'arrow_forward',
            label: 'Next',
            onTap: onNextCitation,
          ),

          // Vertical divider
          Container(
            width: 1,
            height: 4.h,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),

          // Search
          _buildToolbarButton(
            context,
            icon: 'search',
            label: 'Search',
            onTap: onSearch,
            isActive: isSearching,
          ),

          // Vertical divider
          Container(
            width: 1,
            height: 4.h,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),

          // Page jump
          _buildToolbarButton(
            context,
            icon: 'format_list_numbered',
            label: 'Jump',
            onTap: onPageJump,
          ),
        ],
      ),
    );
  }

  /// Build toolbar button
  Widget _buildToolbarButton(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              size: 22,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 10.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
