import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Chat header widget showing conversation topic and confidence
/// Displays legal conversation context with visual indicators
class ChatHeaderWidget extends StatelessWidget {
  final String topic;
  final String? overallConfidence;

  const ChatHeaderWidget({
    super.key,
    required this.topic,
    this.overallConfidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                overallConfidence != null
                    ? SizedBox(width: 2.w)
                    : const SizedBox.shrink(),
                overallConfidence != null
                    ? _buildConfidenceIndicator(context, overallConfidence!)
                    : const SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Legal Research Conversation',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context, String confidence) {
    final theme = Theme.of(context);
    Color indicatorColor;

    confidence == 'high'
        ? indicatorColor = AppTheme.successLight
        : confidence == 'medium'
        ? indicatorColor = AppTheme.warningLight
        : indicatorColor = AppTheme.errorLight;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            confidence == 'high'
                ? 'High'
                : confidence == 'medium'
                ? 'Med'
                : 'Low',
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}
