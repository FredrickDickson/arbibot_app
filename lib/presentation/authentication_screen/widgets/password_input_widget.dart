import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';

/// Password input field widget with visibility toggle
class PasswordInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isPasswordVisible;
  final bool enabled;
  final VoidCallback onVisibilityToggle;

  const PasswordInputWidget({
    super.key,
    required this.controller,
    required this.isPasswordVisible,
    required this.onVisibilityToggle,
    this.enabled = true,
  });

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: !isPasswordVisible,
          textInputAction: TextInputAction.done,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your secure password',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock_outline',
                size: 20,
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName: isPasswordVisible ? 'visibility_off' : 'visibility',
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      onVisibilityToggle();
                    }
                  : null,
            ),
            filled: true,
            fillColor: enabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.5.h,
            ),
          ),
          validator: _validatePassword,
        ),
        SizedBox(height: 0.5.h),
        Padding(
          padding: EdgeInsets.only(left: 2.w),
          child: Text(
            'Minimum 8 characters with mixed case and numbers',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
          ),
        ),
      ],
    );
  }
}
