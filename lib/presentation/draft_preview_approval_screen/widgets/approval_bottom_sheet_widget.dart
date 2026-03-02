import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';

/// Approval workflow bottom sheet with three explicit options
/// Requires confirmation modal with legal responsibility acknowledgment
class ApprovalBottomSheetWidget extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onRequestRevisions;
  final VoidCallback onReject;

  const ApprovalBottomSheetWidget({
    super.key,
    required this.onApprove,
    required this.onRequestRevisions,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Title
              Text(
                'Review Draft Document',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),

              // Description
              Text(
                'Choose an action for this legal draft. All actions require confirmation and acknowledgment of legal responsibility.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 3.h),

              // Approve button
              _buildActionButton(
                context: context,
                theme: theme,
                icon: 'check_circle',
                label: 'Approve for Use',
                description: 'Accept this draft as final document',
                color: AppTheme.successLight,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  _showConfirmationDialog(
                    context: context,
                    title: 'Approve Draft Document',
                    message:
                        'By approving this draft, you acknowledge that you have reviewed the content and accept legal responsibility for its use. This action cannot be undone.',
                    confirmText: 'Approve',
                    confirmColor: AppTheme.successLight,
                    onConfirm: onApprove,
                  );
                },
              ),
              SizedBox(height: 2.h),

              // Request revisions button
              _buildActionButton(
                context: context,
                theme: theme,
                icon: 'edit',
                label: 'Request Revisions',
                description: 'Send back for modifications',
                color: AppTheme.warningLight,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  _showConfirmationDialog(
                    context: context,
                    title: 'Request Revisions',
                    message:
                        'This draft will be marked for revision. You can add comments and annotations to guide the changes needed.',
                    confirmText: 'Request Revisions',
                    confirmColor: AppTheme.warningLight,
                    onConfirm: onRequestRevisions,
                  );
                },
              ),
              SizedBox(height: 2.h),

              // Reject button
              _buildActionButton(
                context: context,
                theme: theme,
                icon: 'cancel',
                label: 'Reject Draft',
                description: 'Discard this document',
                color: AppTheme.errorLight,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  _showConfirmationDialog(
                    context: context,
                    title: 'Reject Draft Document',
                    message:
                        'This draft will be permanently discarded. This action cannot be undone. Are you sure you want to proceed?',
                    confirmText: 'Reject',
                    confirmColor: AppTheme.errorLight,
                    onConfirm: onReject,
                  );
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ThemeData theme,
    required String icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(iconName: icon, color: color, size: 24),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => _ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _ConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  State<_ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<_ConfirmationDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          SizedBox(height: 2.h),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _acknowledged = !_acknowledged);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 6.w,
                  height: 6.w,
                  child: Checkbox(
                    value: _acknowledged,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => _acknowledged = value ?? false);
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'I acknowledge legal responsibility for this action',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: _acknowledged
              ? () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  widget.onConfirm();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
