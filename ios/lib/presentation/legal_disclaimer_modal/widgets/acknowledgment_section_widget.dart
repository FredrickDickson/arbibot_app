import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Acknowledgment section widget for legal disclaimer
/// Contains mandatory checkboxes for user consent
class AcknowledgmentSectionWidget extends StatelessWidget {
  final bool aiContentAcknowledged;
  final bool professionalReviewAcknowledged;
  final bool responsibilityAccepted;
  final bool minimumReadingTimeElapsed;
  final ValueChanged<bool?> onAiContentChanged;
  final ValueChanged<bool?> onProfessionalReviewChanged;
  final ValueChanged<bool?> onResponsibilityChanged;

  const AcknowledgmentSectionWidget({
    super.key,
    required this.aiContentAcknowledged,
    required this.professionalReviewAcknowledged,
    required this.responsibilityAccepted,
    required this.minimumReadingTimeElapsed,
    required this.onAiContentChanged,
    required this.onProfessionalReviewChanged,
    required this.onResponsibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle_outline',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Mandatory Acknowledgments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Acknowledgment 1: AI-Generated Content
          _buildCheckboxItem(
            context: context,
            value: aiContentAcknowledged,
            onChanged: minimumReadingTimeElapsed ? onAiContentChanged : null,
            label: 'I understand this is AI-generated draft content',
            description:
                'All content is for informational purposes only and requires professional review.',
          ),

          SizedBox(height: 1.5.h),

          // Acknowledgment 2: Professional Review
          _buildCheckboxItem(
            context: context,
            value: professionalReviewAcknowledged,
            onChanged: minimumReadingTimeElapsed
                ? onProfessionalReviewChanged
                : null,
            label: 'I will conduct professional review before use',
            description:
                'I will verify all citations, legal arguments, and factual statements independently.',
          ),

          SizedBox(height: 1.5.h),

          // Acknowledgment 3: Responsibility
          _buildCheckboxItem(
            context: context,
            value: responsibilityAccepted,
            onChanged: minimumReadingTimeElapsed
                ? onResponsibilityChanged
                : null,
            label: 'I accept responsibility for final document accuracy',
            description:
                'I am solely responsible for all legal work product and client communications.',
          ),

          if (!minimumReadingTimeElapsed) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: AppTheme.warningLight,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Please read the disclaimer carefully before acknowledging',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build individual checkbox item
  Widget _buildCheckboxItem({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required String label,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onChanged != null;

    return InkWell(
      onTap: isEnabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: value
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: value
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline,
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            SizedBox(
              width: 6.w,
              height: 6.w,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),

            SizedBox(width: 2.w),

            // Label and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.sp,
                      color: isEnabled
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
