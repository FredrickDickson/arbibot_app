import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/disclaimer_acknowledgment_widget.dart';
import './widgets/document_type_card_widget.dart';
import './widgets/legal_compliance_warning_widget.dart';

/// Draft Type Selection Screen for legal document generation
/// Enables legal professionals to choose document types with jurisdiction-specific templates
class DraftTypeSelectionScreen extends StatefulWidget {
  const DraftTypeSelectionScreen({super.key});

  @override
  State<DraftTypeSelectionScreen> createState() =>
      _DraftTypeSelectionScreenState();
}

class _DraftTypeSelectionScreenState extends State<DraftTypeSelectionScreen> {
  int? _selectedDocumentIndex;
  int? _expandedDocumentIndex;
  bool _isDisclaimerAcknowledged = false;

  final List<Map<String, dynamic>> _documentTypes = [
    {
      "title": "Statement of Case",
      "description":
          "Formal written statement outlining the facts, legal issues, and arguments for arbitration proceedings under Ghana's Alternative Dispute Resolution Act, 2010 (Act 798).",
      "iconName": "gavel",
      "useCases": [
        "Initiating arbitration proceedings with detailed factual background",
        "Responding to claims with comprehensive legal arguments",
        "Outlining contractual disputes and breach allegations",
        "Presenting evidence and witness statements in structured format",
      ],
      "estimatedTime": "15-20 minutes generation time",
    },
    {
      "title": "Legal Opinion",
      "description":
          "Professional legal analysis providing expert interpretation of Ghana law, case precedents, and statutory provisions relevant to specific legal questions or disputes.",
      "iconName": "balance",
      "useCases": [
        "Advising clients on legal rights and obligations under Ghana law",
        "Analyzing contractual terms and enforceability issues",
        "Evaluating litigation risks and potential outcomes",
        "Providing expert opinions on statutory interpretation",
      ],
      "estimatedTime": "10-15 minutes generation time",
    },
    {
      "title": "Submission",
      "description":
          "Formal written arguments submitted to arbitral tribunals or courts, presenting legal reasoning, case law citations, and statutory interpretations supporting your position.",
      "iconName": "description",
      "useCases": [
        "Final submissions to arbitral tribunals with legal authorities",
        "Written arguments on preliminary objections or jurisdictional issues",
        "Closing submissions summarizing evidence and legal positions",
        "Reply submissions addressing opposing party's arguments",
      ],
      "estimatedTime": "12-18 minutes generation time",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar.withBackButton(
        context: context,
        title: 'Select Document Type',
        subtitle: 'AI-Powered Legal Drafting',
        variant: AppBarVariant.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context),
                    SizedBox(height: 3.h),
                    _buildDocumentTypeCards(context),
                    SizedBox(height: 3.h),
                    const LegalComplianceWarningWidget(),
                    SizedBox(height: 3.h),
                    DisclaimerAcknowledgmentWidget(
                      isAcknowledged: _isDisclaimerAcknowledged,
                      onChanged: (value) {
                        setState(() {
                          _isDisclaimerAcknowledged = value ?? false;
                        });
                      },
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'auto_awesome',
                color: colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Ghana-Specific Legal Documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Generate professional legal documents tailored to Ghana\'s legal system with AI-powered drafting assistance. All documents include citation-backed legal reasoning and comply with local jurisdiction requirements.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildFeatureBadge(context, 'Citation-Backed', 'verified'),
              SizedBox(width: 2.w),
              _buildFeatureBadge(context, 'Draft Only', 'edit_note'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(
    BuildContext context,
    String label,
    String iconName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: colorScheme.primary,
            size: 14,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Document Type',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 2.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _documentTypes.length,
          separatorBuilder: (context, index) => SizedBox(height: 2.h),
          itemBuilder: (context, index) {
            final docType = _documentTypes[index];
            return DocumentTypeCardWidget(
              title: docType["title"] as String,
              description: docType["description"] as String,
              iconName: docType["iconName"] as String,
              useCases: (docType["useCases"] as List).cast<String>(),
              estimatedTime: docType["estimatedTime"] as String,
              isSelected: _selectedDocumentIndex == index,
              isExpanded: _expandedDocumentIndex == index,
              onTap: () {
                setState(() {
                  _selectedDocumentIndex = index;
                });
              },
              onExpand: () {
                setState(() {
                  _expandedDocumentIndex = _expandedDocumentIndex == index
                      ? null
                      : index;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool canContinue =
        _selectedDocumentIndex != null && _isDisclaimerAcknowledged;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canContinue)
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Select a document type and acknowledge the disclaimer to continue',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: canContinue
                  ? () {
                      HapticFeedback.mediumImpact();
                      _showLegalDisclaimerModal(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: canContinue
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                elevation: canContinue ? 2.0 : 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to Drafting',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: canContinue
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName: 'arrow_forward',
                    color: canContinue
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalDisclaimerModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning_amber',
              color: AppTheme.warningLight,
              size: 24,
            ),
            SizedBox(width: 2.w),
            const Expanded(child: Text('Legal Disclaimer')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningLight.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'You are about to generate an AI-powered legal document draft. Please review the following carefully:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              _buildDisclaimerPoint(
                context,
                'Draft Status',
                'All generated documents are drafts requiring your professional review and approval.',
              ),
              SizedBox(height: 1.5.h),
              _buildDisclaimerPoint(
                context,
                'Professional Responsibility',
                'You maintain full legal responsibility for all documents used in proceedings.',
              ),
              SizedBox(height: 1.5.h),
              _buildDisclaimerPoint(
                context,
                'Citation Verification',
                'All legal citations and precedents must be independently verified.',
              ),
              SizedBox(height: 1.5.h),
              _buildDisclaimerPoint(
                context,
                'No Legal Advice',
                'ArbiBot provides drafting assistance only, not legal advice.',
              ),
              SizedBox(height: 2.h),
              Text(
                'By proceeding, you acknowledge understanding and accepting these terms.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
              _proceedToDrafting(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('I Understand, Proceed'),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerPoint(
    BuildContext context,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 0.5.h),
          child: CustomIconWidget(
            iconName: 'check_circle',
            color: colorScheme.primary,
            size: 16,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _proceedToDrafting(BuildContext context) {
    final selectedDoc = _documentTypes[_selectedDocumentIndex!];

    Navigator.pushNamed(
      context,
      '/draft-preview-approval-screen',
      arguments: {
        'documentType': selectedDoc["title"],
        'documentIcon': selectedDoc["iconName"],
      },
    );
  }
}
