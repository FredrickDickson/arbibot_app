import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Message bubble widget for displaying user and AI messages
/// Implements distinct styling for user queries and AI responses
class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback? onCitationTap;
  final VoidCallback? onLongPress;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.onCitationTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message['isUser'] as bool? ?? false;
    final content = message['content'] as String? ?? '';
    final timestamp = message['timestamp'] as DateTime?;
    final confidence = message['confidence'] as String?;
    final citations = message['citations'] as List<dynamic>?;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 75.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: GestureDetector(
          onLongPress: !isUser ? onLongPress : null,
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: !isUser
                      ? Border.all(color: theme.colorScheme.outline, width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (!isUser && confidence != null) ...[
                      SizedBox(height: 1.h),
                      _buildConfidenceBadge(context, confidence),
                    ],
                    if (!isUser &&
                        citations != null &&
                        citations.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      _buildCitationPreview(context, citations),
                    ],
                  ],
                ),
              ),
              if (timestamp != null) ...[
                SizedBox(height: 0.5.h),
                Text(
                  _formatTimestamp(timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, String confidence) {
    final theme = Theme.of(context);
    Color badgeColor;
    String badgeText;

    confidence == 'high'
        ? badgeColor = AppTheme.successLight
        : confidence == 'medium'
        ? badgeColor = AppTheme.warningLight
        : badgeColor = AppTheme.errorLight;

    confidence == 'high'
        ? badgeText = 'High Confidence'
        : confidence == 'medium'
        ? badgeText = 'Medium Confidence'
        : badgeText = 'Low Confidence';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: confidence == 'high'
                ? 'check_circle'
                : confidence == 'medium'
                ? 'warning'
                : 'error',
            color: badgeColor,
            size: 12.sp,
          ),
          SizedBox(width: 1.w),
          Text(
            badgeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitationPreview(BuildContext context, List<dynamic> citations) {
    final theme = Theme.of(context);
    final citationCount = citations.length;

    return GestureDetector(
      onTap: onCitationTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'article',
              color: theme.colorScheme.primary,
              size: 16.sp,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                '$citationCount ${citationCount == 1 ? 'Citation' : 'Citations'} Available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.primary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    difference.inMinutes < 1
        ? 'Just now'
        : difference.inHours < 1
        ? '${difference.inMinutes}m ago'
        : difference.inDays < 1
        ? '${difference.inHours}h ago'
        : '${difference.inDays}d ago';

    return difference.inMinutes < 1
        ? 'Just now'
        : difference.inHours < 1
        ? '${difference.inMinutes}m ago'
        : difference.inDays < 1
        ? '${difference.inHours}h ago'
        : '${difference.inDays}d ago';
  }
}
