import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';

/// Login button widget with loading state
class LoginButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const LoginButtonWidget({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.primary.withValues(
            alpha: 0.5,
          ),
          disabledForegroundColor: theme.colorScheme.onPrimary.withValues(
            alpha: 0.5,
          ),
          elevation: 2,
          shadowColor: theme.colorScheme.shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'lock_open',
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Secure Login',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
