import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';

/// Recent activity item widget with swipe actions
class RecentActivityItemWidget extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RecentActivityItemWidget({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getConfidenceColor(BuildContext context, String level) {
    final theme = Theme.of(context);
    switch (level.toLowerCase()) {
      case 'high':
        return AppTheme.successLight;
      case 'medium':
        return AppTheme.warningLight;
      case 'low':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidenceColor = _getConfidenceColor(
      context,
      activity["confidenceLevel"] as String,
    );
    final isPinned = activity["isPinned"] as bool;

    return Slidable(
      key: ValueKey(activity["id"]),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              // Share action
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.share,
            label: 'Share',
          ),
          SlidableAction(
            onPressed: (context) {
              // Archive action
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.archive,
            label: 'Archive',
          ),
          SlidableAction(
            onPressed: (context) {
              // Delete action
            },
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isPinned
              ? BorderSide(color: theme.colorScheme.primary, width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: activity["icon"] as String,
                      color: confidenceColor,
                      size: 24,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isPinned) ...[
                            CustomIconWidget(
                              iconName: 'push_pin',
                              color: theme.colorScheme.primary,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                          ],
                          Expanded(
                            child: Text(
                              activity["title"] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        activity["subtitle"] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _formatTimestamp(activity["timestamp"] as DateTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                // Confidence indicator
                Container(
                  width: 2.w,
                  height: 2.w,
                  decoration: BoxDecoration(
                    color: confidenceColor,
                    shape: BoxShape.circle,
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
