import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';

/// Document preview widget with professional legal formatting
/// Displays generated content with confidence indicators and citation references
class DocumentPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> draftData;
  final double zoomLevel;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const DocumentPreviewWidget({
    super.key,
    required this.draftData,
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = (draftData['sections'] as List?) ?? [];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surface,
      child: Stack(
        children: [
          // Document content with scroll
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Draft watermark
                _buildDraftWatermark(theme),
                SizedBox(height: 2.h),

                // Document title
                Text(
                  draftData['title'] as String? ?? 'Legal Document Draft',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: (18 * zoomLevel).sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),

                // Document metadata
                _buildMetadata(theme),
                SizedBox(height: 3.h),

                // Document sections
                ...sections.map((section) => _buildSection(theme, section)),

                SizedBox(height: 10.h),
              ],
            ),
          ),

          // Zoom controls
          Positioned(
            right: 4.w,
            bottom: 12.h,
            child: _buildZoomControls(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftWatermark(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.warningLight.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.warningLight, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'warning_amber',
            color: AppTheme.warningLight,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Text(
            'DRAFT ONLY - NOT FOR LEGAL USE',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.warningLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    final metadata = draftData['metadata'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataRow(
            theme,
            'Document Type',
            metadata['type'] as String? ?? 'Legal Opinion',
          ),
          SizedBox(height: 1.h),
          _buildMetadataRow(
            theme,
            'Generated',
            metadata['generated'] as String? ?? '30 Dec 2025, 21:57',
          ),
          SizedBox(height: 1.h),
          _buildMetadataRow(
            theme,
            'Jurisdiction',
            metadata['jurisdiction'] as String? ?? 'Ghana',
          ),
          SizedBox(height: 1.h),
          _buildMetadataRow(
            theme,
            'Citations',
            '${metadata['citationCount'] ?? 12} legal references',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30.w,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, Map<String, dynamic> section) {
    final confidence = section['confidence'] as String? ?? 'high';
    final content = section['content'] as String? ?? '';
    final citations = (section['citations'] as List?) ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with confidence badge
          Row(
            children: [
              Expanded(
                child: Text(
                  section['title'] as String? ?? 'Section',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: (16 * zoomLevel).sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _buildConfidenceBadge(theme, confidence),
            ],
          ),
          SizedBox(height: 1.h),

          // Section content
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: (14 * zoomLevel).sp,
              height: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),

          // Citations
          if (citations.isNotEmpty) ...[
            SizedBox(height: 2.h),
            _buildCitations(theme, citations),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(ThemeData theme, String confidence) {
    Color badgeColor;
    String badgeText;

    switch (confidence.toLowerCase()) {
      case 'high':
        badgeColor = AppTheme.successLight;
        badgeText = 'High Confidence';
        break;
      case 'medium':
        badgeColor = AppTheme.warningLight;
        badgeText = 'Medium Confidence';
        break;
      case 'low':
        badgeColor = AppTheme.errorLight;
        badgeText = 'Low Confidence';
        break;
      default:
        badgeColor = theme.colorScheme.onSurfaceVariant;
        badgeText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor, width: 1),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildCitations(ThemeData theme, List<dynamic> citations) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'gavel',
                color: theme.colorScheme.primary,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'Legal Citations',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...citations.map(
            (citation) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Text(
                '• ${citation as String}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: (12 * zoomLevel).sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onZoomIn,
            icon: CustomIconWidget(
              iconName: 'add',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Zoom In',
          ),
          Container(width: 1, height: 1.h, color: theme.colorScheme.outline),
          IconButton(
            onPressed: onZoomOut,
            icon: CustomIconWidget(
              iconName: 'remove',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }
}
