import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './widgets/acknowledgment_section_widget.dart';
import './widgets/disclaimer_content_widget.dart';
import './widgets/disclaimer_header_widget.dart';

/// Legal Disclaimer Modal enforces mandatory compliance warnings and professional responsibility acknowledgments
/// Implements Ghana Bar Association compliance standards with audit trail logging
class LegalDisclaimerModal extends StatefulWidget {
  const LegalDisclaimerModal({super.key});

  @override
  State<LegalDisclaimerModal> createState() => _LegalDisclaimerModalState();
}

class _LegalDisclaimerModalState extends State<LegalDisclaimerModal> {
  final ScrollController _scrollController = ScrollController();

  // Acknowledgment checkboxes state
  bool _aiContentAcknowledged = false;
  bool _professionalReviewAcknowledged = false;
  bool _responsibilityAccepted = false;

  // Reading time tracking
  bool _minimumReadingTimeElapsed = false;
  DateTime? _modalOpenTime;

  // Minimum reading time in seconds (30 seconds for legal compliance)
  static const int _minimumReadingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _modalOpenTime = DateTime.now();
    _startReadingTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Start timer to track minimum reading time
  void _startReadingTimer() {
    Future.delayed(const Duration(seconds: _minimumReadingSeconds), () {
      if (mounted) {
        setState(() {
          _minimumReadingTimeElapsed = true;
        });
      }
    });
  }

  /// Check if all acknowledgments are completed
  bool get _allAcknowledgmentsCompleted {
    return _aiContentAcknowledged &&
        _professionalReviewAcknowledged &&
        _responsibilityAccepted &&
        _minimumReadingTimeElapsed;
  }

  /// Handle acknowledgment and continue
  void _handleAcknowledgment() {
    if (!_allAcknowledgmentsCompleted) return;

    // Log acknowledgment for audit compliance
    _logDisclaimerAcknowledgment();

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Navigate to home dashboard
    Navigator.pushReplacementNamed(context, '/home-dashboard');
  }

  /// Log disclaimer acknowledgment for professional compliance tracking
  void _logDisclaimerAcknowledgment() {
    final timestamp = DateTime.now();
    final readingDuration = timestamp.difference(_modalOpenTime!);

    debugPrint('Legal Disclaimer Acknowledged:');
    debugPrint('Timestamp: $timestamp');
    debugPrint('Reading Duration: ${readingDuration.inSeconds} seconds');
    debugPrint('AI Content: $_aiContentAcknowledged');
    debugPrint('Professional Review: $_professionalReviewAcknowledged');
    debugPrint('Responsibility: $_responsibilityAccepted');
  }

  /// Handle learn more navigation
  void _handleLearnMore() {
    HapticFeedback.lightImpact();
    // In production, this would open Ghana Bar Association guidelines
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Professional Resources',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Ghana Bar Association Guidelines:\n\n'
          '• Professional Responsibility Standards\n'
          '• AI-Assisted Legal Practice Guidelines\n'
          '• Document Review Requirements\n'
          '• Client Communication Standards\n\n'
          'For detailed information, visit the Ghana Bar Association website.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal without acknowledgment
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Column(
              children: [
                // Header Section
                DisclaimerHeaderWidget(
                  onClose: _allAcknowledgmentsCompleted
                      ? () => Navigator.pop(context)
                      : null,
                ),

                SizedBox(height: 2.h),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Disclaimer Content
                        DisclaimerContentWidget(onLearnMore: _handleLearnMore),

                        SizedBox(height: 3.h),

                        // Acknowledgment Section
                        AcknowledgmentSectionWidget(
                          aiContentAcknowledged: _aiContentAcknowledged,
                          professionalReviewAcknowledged:
                              _professionalReviewAcknowledged,
                          responsibilityAccepted: _responsibilityAccepted,
                          minimumReadingTimeElapsed: _minimumReadingTimeElapsed,
                          onAiContentChanged: (value) {
                            setState(
                              () => _aiContentAcknowledged = value ?? false,
                            );
                          },
                          onProfessionalReviewChanged: (value) {
                            setState(
                              () => _professionalReviewAcknowledged =
                                  value ?? false,
                            );
                          },
                          onResponsibilityChanged: (value) {
                            setState(
                              () => _responsibilityAccepted = value ?? false,
                            );
                          },
                        ),

                        SizedBox(height: 3.h),

                        // Primary Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 6.h,
                          child: ElevatedButton(
                            onPressed: _allAcknowledgmentsCompleted
                                ? _handleAcknowledgment
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _allAcknowledgmentsCompleted
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                              foregroundColor: _allAcknowledgmentsCompleted
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                              elevation: _allAcknowledgmentsCompleted
                                  ? 2.0
                                  : 0.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'I Acknowledge and Continue',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: _allAcknowledgmentsCompleted
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 2.h),

                        // Reading Time Indicator
                        if (!_minimumReadingTimeElapsed)
                          Center(
                            child: Text(
                              'Please read the disclaimer carefully ($_minimumReadingSeconds seconds minimum)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
