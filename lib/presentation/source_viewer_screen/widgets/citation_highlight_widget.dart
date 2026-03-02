import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';

/// Citation Highlight Widget - Displays highlighted citation sections
/// Implements color-coded confidence indicators for legal citations
class CitationHighlightWidget extends StatelessWidget {
  final Map<String, dynamic> citation;
  final VoidCallback onTap;

  const CitationHighlightWidget({
    super.key,
    required this.citation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = citation["confidence"] as String;
    final highlightColor = _getHighlightColor(confidence);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: highlightColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlightColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Citation header
            Row(
              children: [
                // Confidence indicator
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    confidence.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),

                // Section reference
                Expanded(
                  child: Text(
                    citation["section"] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Tap indicator
                CustomIconWidget(
                  iconName: 'info_outline',
                  color: highlightColor,
                  size: 18,
                ),
              ],
            ),

            SizedBox(height: 1.h),

            // Citation text
            Text(
              citation["text"] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11.sp,
                height: 1.5,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 1.h),

            // Query context
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'search',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    'Related to: ${citation["queryContext"]}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10.sp,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get highlight color based on confidence level
  Color _getHighlightColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return const Color(0xFF4A6741); // Success green
      case 'medium':
        return const Color(0xFFB8860B); // Warning amber
      case 'low':
        return const Color(0xFF8B2635); // Error burgundy
      default:
        return const Color(0xFF4A6741);
    }
  }
}
