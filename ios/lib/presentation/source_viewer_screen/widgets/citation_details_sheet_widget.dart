import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Citation Details Sheet Widget - Bottom sheet with citation metadata
/// Displays document metadata, publication date, authority ranking, and relevance score
class CitationDetailsSheetWidget extends StatelessWidget {
  final Map<String, dynamic> citation;
  final Map<String, dynamic> documentData;
  final VoidCallback onClose;

  const CitationDetailsSheetWidget({
    super.key,
    required this.citation,
    required this.documentData,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 35.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            offset: const Offset(0, -4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          _buildHandleBar(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Citation title
                  _buildSectionTitle(context, 'Citation Details'),
                  SizedBox(height: 2.h),

                  // Citation section
                  _buildDetailRow(
                    context,
                    'Section',
                    citation["section"] as String,
                    Icons.article_outlined,
                  ),

                  // Page reference
                  _buildDetailRow(
                    context,
                    'Page',
                    'Page ${citation["page"]}',
                    Icons.description_outlined,
                  ),

                  // Confidence level
                  _buildConfidenceRow(context),

                  SizedBox(height: 2.h),
                  Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: 2.h),

                  // Document metadata
                  _buildSectionTitle(context, 'Document Information'),
                  SizedBox(height: 2.h),

                  // Document type
                  _buildDetailRow(
                    context,
                    'Document Type',
                    documentData["documentType"] as String,
                    Icons.gavel,
                  ),

                  // Publication date
                  _buildDetailRow(
                    context,
                    'Publication Date',
                    _formatDate(documentData["publicationDate"] as String),
                    Icons.calendar_today_outlined,
                  ),

                  // Jurisdiction
                  _buildDetailRow(
                    context,
                    'Jurisdiction',
                    documentData["jurisdiction"] as String,
                    Icons.location_on_outlined,
                  ),

                  // Legal authority
                  _buildDetailRow(
                    context,
                    'Legal Authority',
                    documentData["authority"] as String,
                    Icons.verified_outlined,
                  ),

                  // Relevance score
                  _buildRelevanceRow(context),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build handle bar for swipe gesture
  Widget _buildHandleBar(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Center(
          child: Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: icon
                .toString()
                .split('.')
                .last
                .replaceAll('IconData(U+', '')
                .replaceAll(')', ''),
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build confidence row with visual indicator
  Widget _buildConfidenceRow(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = citation["confidence"] as String;
    final color = _getConfidenceColor(confidence);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: 'verified', color: color, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence Level',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        confidence.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build relevance score row
  Widget _buildRelevanceRow(BuildContext context) {
    final theme = Theme.of(context);
    final relevance = documentData["relevanceScore"] as double;
    final percentage = (relevance * 100).toInt();

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: 'analytics',
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relevance Score',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: relevance,
                          minHeight: 1.h,
                          backgroundColor: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get confidence color
  Color _getConfidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return const Color(0xFF4A6741);
      case 'medium':
        return const Color(0xFFB8860B);
      case 'low':
        return const Color(0xFF8B2635);
      default:
        return const Color(0xFF4A6741);
    }
  }

  /// Format date string
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
