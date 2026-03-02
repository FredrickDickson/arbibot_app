import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Individual conversation card widget with swipe actions
/// Displays legal conversation details with confidence indicators
class ConversationCardWidget extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final bool isSelected;

  const ConversationCardWidget({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onPin,
    required this.onArchive,
    required this.onExport,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Slidable(
      key: ValueKey(conversation['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onPin(),
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            icon: Icons.push_pin,
            label: 'Pin',
          ),
          SlidableAction(
            onPressed: (_) => onArchive(),
            backgroundColor: colorScheme.tertiary,
            foregroundColor: colorScheme.onTertiary,
            icon: Icons.archive,
            label: 'Archive',
          ),
          SlidableAction(
            onPressed: (_) => onExport(),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.file_download,
            label: 'Export',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        elevation: isSelected ? 4.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLegalTopicIcon(context),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            conversation['lastMessage'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (conversation['isPinned'] == true)
                      Padding(
                        padding: EdgeInsets.only(left: 2.w),
                        child: CustomIconWidget(
                          iconName: 'push_pin',
                          color: colorScheme.primary,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildConfidenceBadge(context),
                    Text(
                      conversation['timestamp'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalTopicIcon(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topic = conversation['legalTopic'] as String;

    IconData iconData;
    Color iconColor;

    switch (topic) {
      case 'contract':
        iconData = Icons.description;
        iconColor = colorScheme.primary;
        break;
      case 'tort':
        iconData = Icons.gavel;
        iconColor = colorScheme.secondary;
        break;
      case 'constitutional':
        iconData = Icons.account_balance;
        iconColor = colorScheme.tertiary;
        break;
      case 'criminal':
        iconData = Icons.security;
        iconColor = colorScheme.error;
        break;
      default:
        iconData = Icons.article;
        iconColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomIconWidget(
        iconName: iconData.codePoint.toString(),
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final confidence = conversation['confidence'] as String;

    Color badgeColor;
    String badgeText;

    switch (confidence) {
      case 'high':
        badgeColor = colorScheme.secondary;
        badgeText = 'High Confidence';
        break;
      case 'medium':
        badgeColor = colorScheme.tertiary;
        badgeText = 'Medium Confidence';
        break;
      case 'low':
        badgeColor = colorScheme.error;
        badgeText = 'Low Confidence';
        break;
      default:
        badgeColor = colorScheme.onSurfaceVariant;
        badgeText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w500,
          fontSize: 9.sp,
        ),
      ),
    );
  }
}
