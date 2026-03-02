import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Citation list widget with source verification and legal authority rankings
/// Displays detailed citation information with swipe-up interaction
class CitationListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> citations;
  final Function(Map<String, dynamic>) onCitationTap;

  const CitationListWidget({
    super.key,
    required this.citations,
    required this.onCitationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'gavel',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Legal Citations (${citations.length})',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: theme.colorScheme.outline, height: 1),

            // Citations list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                itemCount: citations.length,
                separatorBuilder: (context, index) => SizedBox(height: 2.h),
                itemBuilder: (context, index) {
                  final citation = citations[index];
                  return _buildCitationCard(theme, citation);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationCard(ThemeData theme, Map<String, dynamic> citation) {
    final authority = citation['authority'] as String? ?? 'medium';
    final verified = citation['verified'] as bool? ?? true;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onCitationTap(citation);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Citation header with badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    citation['title'] as String? ?? 'Legal Citation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                _buildAuthorityBadge(theme, authority),
              ],
            ),
            SizedBox(height: 1.h),

            // Citation reference
            Text(
              citation['reference'] as String? ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),

            // Citation details
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Text(
                  citation['year'] as String? ?? '2025',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 3.w),
                CustomIconWidget(
                  iconName: 'location_on',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Text(
                  citation['jurisdiction'] as String? ?? 'Ghana',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (verified)
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'verified',
                        color: AppTheme.successLight,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Verified',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.successLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 1.h),

            // Page reference
            if (citation['page'] != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Page ${citation['page']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorityBadge(ThemeData theme, String authority) {
    Color badgeColor;
    String badgeText;

    switch (authority.toLowerCase()) {
      case 'high':
        badgeColor = AppTheme.successLight;
        badgeText = 'High Authority';
        break;
      case 'medium':
        badgeColor = AppTheme.warningLight;
        badgeText = 'Medium Authority';
        break;
      case 'low':
        badgeColor = theme.colorScheme.onSurfaceVariant;
        badgeText = 'Low Authority';
        break;
      default:
        badgeColor = theme.colorScheme.onSurfaceVariant;
        badgeText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
