import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Legal disclaimer banner for medium/low confidence responses
/// Shows warning message with explicit user acknowledgment
class LegalDisclaimerBannerWidget extends StatelessWidget {
  final String confidence;
  final VoidCallback onAcknowledge;

  const LegalDisclaimerBannerWidget({
    super.key,
    required this.confidence,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowConfidence = confidence == 'low';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isLowConfidence
            ? AppTheme.errorLight.withValues(alpha: 0.1)
            : AppTheme.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowConfidence ? AppTheme.errorLight : AppTheme.warningLight,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: isLowConfidence ? 'error' : 'warning',
                color: isLowConfidence
                    ? AppTheme.errorLight
                    : AppTheme.warningLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  isLowConfidence
                      ? 'Low Confidence Warning'
                      : 'Medium Confidence Notice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isLowConfidence
                        ? AppTheme.errorLight
                        : AppTheme.warningLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            isLowConfidence
                ? 'This response has low confidence and may not be accurate. Please verify all information with primary legal sources before relying on this content. This is a draft for reference only and should not be used as legal advice.'
                : 'This response has medium confidence. While generally reliable, please verify critical information with primary legal sources. This is a draft for reference only.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAcknowledge,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLowConfidence
                    ? AppTheme.errorLight
                    : AppTheme.warningLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'I Understand',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
