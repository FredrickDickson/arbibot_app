import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';

/// Empty state widget for documents library
/// Displays when no documents are available
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onStartResearching;

  const EmptyStateWidget({super.key, required this.onStartResearching});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageWidget(
              imageUrl:
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
              width: 50.w,
              height: 25.h,
              fit: BoxFit.contain,
              semanticLabel:
                  'Illustration of a person holding a magnifying glass over legal documents, representing legal research and document management',
            ),
            SizedBox(height: 4.h),
            Text(
              'No Documents Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Start researching to build your legal library with citation-backed materials and approved drafts',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: onStartResearching,
              icon: CustomIconWidget(
                iconName: 'search',
                size: 18.sp,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Start Researching',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
