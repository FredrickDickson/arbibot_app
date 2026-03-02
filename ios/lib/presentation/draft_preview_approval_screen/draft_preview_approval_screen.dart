import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/approval_bottom_sheet_widget.dart';
import './widgets/citation_list_widget.dart';
import './widgets/document_preview_widget.dart';

/// Draft Preview & Approval Screen
/// Enables legal professionals to review and approve AI-generated legal documents
/// with mandatory human oversight workflow
class DraftPreviewApprovalScreen extends StatefulWidget {
  const DraftPreviewApprovalScreen({super.key});

  @override
  State<DraftPreviewApprovalScreen> createState() =>
      _DraftPreviewApprovalScreenState();
}

class _DraftPreviewApprovalScreenState
    extends State<DraftPreviewApprovalScreen> {
  double _zoomLevel = 1.0;
  bool _showLegalDisclaimer = true;

  // Mock draft data
  final Map<String, dynamic> _draftData = {
    "title": "Legal Opinion on Arbitration Jurisdiction",
    "metadata": {
      "type": "Legal Opinion",
      "generated": "30 Dec 2025, 21:57",
      "jurisdiction": "Ghana",
      "citationCount": 12,
    },
    "sections": [
      {
        "title": "1. Introduction and Background",
        "confidence": "high",
        "content":
            "This legal opinion addresses the jurisdictional issues arising in the matter of ABC Corporation v. XYZ Limited, concerning the arbitration agreement contained in the commercial contract dated 15 March 2024. The parties entered into a comprehensive supply agreement governed by Ghanaian law, which included an arbitration clause providing for dispute resolution under the Alternative Dispute Resolution Act, 2010 (Act 798).",
        "citations": [
          "Alternative Dispute Resolution Act, 2010 (Act 798), Section 3",
          "Ghana Arbitration Centre Rules, 2020, Rule 5.1",
        ],
      },
      {
        "title": "2. Legal Framework and Applicable Law",
        "confidence": "high",
        "content":
            "The legal framework governing arbitration in Ghana is primarily established by the Alternative Dispute Resolution Act, 2010 (Act 798), which provides comprehensive provisions for arbitration proceedings. Section 3 of Act 798 establishes the fundamental principle of party autonomy in arbitration, allowing parties to determine the rules and procedures governing their arbitration. The Act is supplemented by the Ghana Arbitration Centre Rules, which provide detailed procedural guidelines for institutional arbitration.",
        "citations": [
          "Alternative Dispute Resolution Act, 2010 (Act 798), Sections 3-7",
          "Ghana Arbitration Centre Rules, 2020, Rules 5-12",
          "Constitution of Ghana, 1992, Article 125",
        ],
      },
      {
        "title": "3. Analysis of Jurisdictional Issues",
        "confidence": "medium",
        "content":
            "The jurisdictional question in this matter centers on whether the arbitration tribunal has competence to determine disputes arising from the alleged breach of the supply agreement. Under the principle of kompetenz-kompetenz, established in Section 15 of Act 798, the arbitral tribunal has the authority to rule on its own jurisdiction, including any objections with respect to the existence or validity of the arbitration agreement. This principle is consistent with international arbitration practice and has been affirmed by Ghanaian courts in several precedents.",
        "citations": [
          "Alternative Dispute Resolution Act, 2010 (Act 798), Section 15",
          "Republic v. High Court (Commercial Division); Ex parte Societe Generale [2012] SCGLR 123",
          "Ghana Commercial Bank v. Chanrai [2003-2004] SCGLR 456",
        ],
      },
      {
        "title": "4. Conclusion and Recommendations",
        "confidence": "high",
        "content":
            "Based on the foregoing analysis, it is my professional opinion that the arbitration tribunal has jurisdiction to hear and determine the disputes arising from the supply agreement. The arbitration clause in the contract is valid and enforceable under Ghanaian law, and the parties are bound by their agreement to arbitrate. I recommend that the parties proceed with the arbitration in accordance with the Alternative Dispute Resolution Act, 2010 (Act 798) and the applicable arbitration rules. Any challenges to jurisdiction should be raised at the earliest opportunity in accordance with Section 15 of Act 798.",
        "citations": [
          "Alternative Dispute Resolution Act, 2010 (Act 798), Sections 15, 52",
          "Ghana Arbitration Centre Rules, 2020, Rule 23",
        ],
      },
    ],
  };

  // Mock citations data
  final List<Map<String, dynamic>> _citations = [
    {
      "title": "Alternative Dispute Resolution Act, 2010",
      "reference": "Act 798, Section 3",
      "year": "2010",
      "jurisdiction": "Ghana",
      "authority": "high",
      "verified": true,
      "page": "12",
    },
    {
      "title": "Ghana Arbitration Centre Rules",
      "reference": "GAC Rules 2020, Rule 5.1",
      "year": "2020",
      "jurisdiction": "Ghana",
      "authority": "high",
      "verified": true,
      "page": "8",
    },
    {
      "title": "Constitution of Ghana",
      "reference": "1992 Constitution, Article 125",
      "year": "1992",
      "jurisdiction": "Ghana",
      "authority": "high",
      "verified": true,
      "page": "89",
    },
    {
      "title": "Republic v. High Court (Commercial Division)",
      "reference": "Ex parte Societe Generale [2012] SCGLR 123",
      "year": "2012",
      "jurisdiction": "Ghana",
      "authority": "high",
      "verified": true,
      "page": "145",
    },
    {
      "title": "Ghana Commercial Bank v. Chanrai",
      "reference": "[2003-2004] SCGLR 456",
      "year": "2003",
      "jurisdiction": "Ghana",
      "authority": "medium",
      "verified": true,
      "page": "478",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showLegalDisclaimer) {
        _showDisclaimerDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar.withBackButton(
        context: context,
        title: 'Draft Preview',
        subtitle: _draftData['metadata']['type'] as String? ?? 'Legal Document',
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showShareOptions();
            },
            icon: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSearchDialog();
            },
            icon: CustomIconWidget(
              iconName: 'search',
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            tooltip: 'Search',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Document preview
          DocumentPreviewWidget(
            draftData: _draftData,
            zoomLevel: _zoomLevel,
            onZoomIn: _handleZoomIn,
            onZoomOut: _handleZoomOut,
          ),

          // Floating action button for citations
          Positioned(
            right: 4.w,
            bottom: 2.h,
            child: FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showCitationsList();
              },
              backgroundColor: theme.colorScheme.primary,
              icon: CustomIconWidget(
                iconName: 'gavel',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              label: Text(
                'Citations',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(theme),
    );
  }

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showAnnotationDialog();
                  },
                  icon: CustomIconWidget(
                    iconName: 'comment',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  label: const Text('Comment'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showApprovalBottomSheet();
                  },
                  icon: CustomIconWidget(
                    iconName: 'rate_review',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: const Text('Review Actions'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleZoomIn() {
    if (_zoomLevel < 2.0) {
      setState(() => _zoomLevel += 0.1);
      HapticFeedback.lightImpact();
    }
  }

  void _handleZoomOut() {
    if (_zoomLevel > 0.5) {
      setState(() => _zoomLevel -= 0.1);
      HapticFeedback.lightImpact();
    }
  }

  void _showApprovalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApprovalBottomSheetWidget(
        onApprove: _handleApprove,
        onRequestRevisions: _handleRequestRevisions,
        onReject: _handleReject,
      ),
    );
  }

  void _showCitationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => CitationListWidget(
          citations: _citations,
          onCitationTap: (citation) {
            Navigator.pop(context);
            _navigateToSourceViewer(citation);
          },
        ),
      ),
    );
  }

  void _handleApprove() {
    Fluttertoast.showToast(
      msg: "Draft approved successfully. Document saved to library.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.successLight,
      textColor: Colors.white,
    );
    Navigator.pushReplacementNamed(context, '/documents-library-screen');
  }

  void _handleRequestRevisions() {
    Fluttertoast.showToast(
      msg: "Revision request submitted. You can add comments and annotations.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.warningLight,
      textColor: Colors.white,
    );
  }

  void _handleReject() {
    Fluttertoast.showToast(
      msg: "Draft rejected and discarded.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.errorLight,
      textColor: Colors.white,
    );
    Navigator.pop(context);
  }

  void _navigateToSourceViewer(Map<String, dynamic> citation) {
    Navigator.pushNamed(context, '/source-viewer-screen', arguments: citation);
  }

  void _showDisclaimerDialog() {
    final theme = Theme.of(context);

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
            const Text('Legal Disclaimer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is an AI-generated draft document and should not be used as final legal advice without professional review.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.errorLight.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.errorLight, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'By proceeding, you acknowledge that:\n• This draft requires human review\n• You accept legal responsibility for its use\n• All citations must be independently verified',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorLight,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _showLegalDisclaimer = false);
              Navigator.pop(context);
            },
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'email',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Share via Email'),
              onTap: () {
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Email sharing feature");
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "PDF export feature");
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: const Text('Copy to Clipboard'),
              onTap: () {
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Copied to clipboard");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search in Document'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: CustomIconWidget(
              iconName: 'search',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            Fluttertoast.showToast(msg: "Searching for: $value");
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAnnotationDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your comment or annotation...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Comment added successfully");
            },
            child: const Text('Add Comment'),
          ),
        ],
      ),
    );
  }
}
