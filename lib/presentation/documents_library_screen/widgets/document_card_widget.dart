import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';

/// Individual document card widget with swipe actions
/// Displays document metadata, status, and confidence indicators
class DocumentCardWidget extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const DocumentCardWidget({
    super.key,
    required this.document,
    required this.onTap,
    required this.onShare,
    required this.onExport,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(document['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onShare(),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: Icons.share,
              label: 'Share',
              borderRadius: BorderRadius.circular(2.w),
            ),
            SlidableAction(
              onPressed: (_) => onExport(),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              icon: Icons.download,
              label: 'Export',
              borderRadius: BorderRadius.circular(2.w),
            ),
            SlidableAction(
              onPressed: (_) => onArchive(),
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              icon: Icons.archive,
              label: 'Archive',
              borderRadius: BorderRadius.circular(2.w),
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
              borderRadius: BorderRadius.circular(2.w),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2.w),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(color: colorScheme.outline, width: 1),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow,
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildDocumentTypeIcon(context),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            document['date'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(context),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    _buildConfidenceIndicator(context),
                    const Spacer(),
                    if (document['isShared'] == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'people',
                              size: 12.sp,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Shared',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  Widget _buildDocumentTypeIcon(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final type = document['type'] as String;

    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'Research Material':
        iconData = Icons.search;
        iconColor = colorScheme.primary;
        break;
      case 'Approved Draft':
        iconData = Icons.check_circle;
        iconColor = AppTheme.successLight;
        break;
      case 'Citation':
        iconData = Icons.format_quote;
        iconColor = colorScheme.secondary;
        break;
      default:
        iconData = Icons.description;
        iconColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: CustomIconWidget(
        iconName: iconData.codePoint.toString(),
        size: 20.sp,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = document['status'] as String;

    Color badgeColor;
    String badgeText;

    switch (status) {
      case 'draft':
        badgeColor = AppTheme.warningLight;
        badgeText = 'Draft';
        break;
      case 'approved':
        badgeColor = AppTheme.successLight;
        badgeText = 'Approved';
        break;
      case 'shared':
        badgeColor = colorScheme.primary;
        badgeText = 'Shared';
        break;
      default:
        badgeColor = colorScheme.onSurfaceVariant;
        badgeText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(1.w),
        border: Border.all(color: badgeColor, width: 1),
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

  Widget _buildConfidenceIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final confidence = document['confidence'] as String;

    Color indicatorColor;
    IconData iconData;

    switch (confidence) {
      case 'High':
        indicatorColor = AppTheme.successLight;
        iconData = Icons.check_circle;
        break;
      case 'Medium':
        indicatorColor = AppTheme.warningLight;
        iconData = Icons.warning;
        break;
      case 'Low':
        indicatorColor = colorScheme.error;
        iconData = Icons.error;
        break;
      default:
        indicatorColor = colorScheme.onSurfaceVariant;
        iconData = Icons.help;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: iconData.codePoint.toString(),
          size: 14.sp,
          color: indicatorColor,
        ),
        SizedBox(width: 1.w),
        Text(
          '$confidence Confidence',
          style: theme.textTheme.labelSmall?.copyWith(
            color: indicatorColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
