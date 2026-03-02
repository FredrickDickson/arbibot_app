import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Message input widget for composing legal queries
/// Includes text field, send button, and attachment icon
class MessageInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final bool isEnabled;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.isEnabled = true,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    hasText != _hasText ? setState(() => _hasText = hasText) : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            widget.onAttachment != null
                ? IconButton(
                    icon: CustomIconWidget(
                      iconName: 'attach_file',
                      color: widget.isEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                      size: 24,
                    ),
                    onPressed: widget.isEnabled
                        ? () {
                            HapticFeedback.lightImpact();
                            widget.onAttachment!();
                          }
                        : null,
                    tooltip: 'Attach Document',
                  )
                : const SizedBox.shrink(),
            SizedBox(width: 2.w),
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 6.h, maxHeight: 20.h),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Ask a legal question...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _hasText && widget.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: CustomIconWidget(
                  iconName: 'send',
                  color: _hasText && widget.isEnabled
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                  size: 20,
                ),
                onPressed: _hasText && widget.isEnabled
                    ? () {
                        HapticFeedback.mediumImpact();
                        widget.onSend();
                      }
                    : null,
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
