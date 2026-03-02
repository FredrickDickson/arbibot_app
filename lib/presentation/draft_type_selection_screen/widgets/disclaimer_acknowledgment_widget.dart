import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

/// Disclaimer acknowledgment checkbox with legal text
/// Required before enabling continue button
class DisclaimerAcknowledgmentWidget extends StatelessWidget {
  final bool isAcknowledged;
  final ValueChanged<bool?> onChanged;

  const DisclaimerAcknowledgmentWidget({
    super.key,
    required this.isAcknowledged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isAcknowledged,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              onChanged(value);
            },
            activeColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I acknowledge and agree:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'I understand that all generated documents are drafts requiring my professional review and approval. I accept full responsibility for any documents I choose to use in legal proceedings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 1.h),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showFullDisclaimer(context);
                  },
                  child: Text(
                    'Read Full Legal Disclaimer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legal Disclaimer'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI-Generated Legal Documents',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 1.h),
              Text(
                'ArbiBot provides AI-powered legal document drafting as a professional assistance tool. All generated documents are drafts requiring human review and approval.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Professional Responsibility',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 1.h),
              Text(
                'As a legal professional, you maintain full responsibility for:\n\n• Reviewing all AI-generated content for accuracy\n• Verifying legal citations and precedents\n• Ensuring compliance with Ghana legal standards\n• Making final decisions on document usage\n• Professional liability for all submitted documents',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'No Legal Advice',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 1.h),
              Text(
                'ArbiBot does not provide legal advice. All generated content is for professional drafting assistance only and must be reviewed by qualified legal professionals.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
