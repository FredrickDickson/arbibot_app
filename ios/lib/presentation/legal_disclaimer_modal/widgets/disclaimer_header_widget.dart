import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Header widget for legal disclaimer modal
/// Displays warning icon, title, and optional close button
class DisclaimerHeaderWidget extends StatelessWidget {
  final VoidCallback? onClose;

  const DisclaimerHeaderWidget({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.colorScheme.outline, width: 1.0),
      ),
      child: Row(
        children: [
          // Warning Icon
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.warningLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'warning_amber_rounded',
                color: AppTheme.warningLight,
                size: 24,
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Legal Notice',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Ghana Bar Association Compliance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Close Button (disabled until acknowledgment)
          if (onClose != null)
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onClose!();
              },
              icon: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              tooltip: 'Close',
            )
          else
            IconButton(
              onPressed: null,
              icon: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
