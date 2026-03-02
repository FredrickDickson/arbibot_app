import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/citation_details_sheet_widget.dart';
import './widgets/document_toolbar_widget.dart';
import './widgets/pdf_viewer_widget.dart';

/// Source Viewer Screen - Displays OCR-processed legal documents with citation highlighting
/// Implements professional legal document viewing with citation verification and navigation
class SourceViewerScreen extends StatefulWidget {
  const SourceViewerScreen({super.key});

  @override
  State<SourceViewerScreen> createState() => _SourceViewerScreenState();
}

class _SourceViewerScreenState extends State<SourceViewerScreen> {
  // Document state
  int _currentPage = 1;
  final int _totalPages = 45;
  bool _isBookmarked = false;
  bool _showCitationDetails = false;
  String _searchQuery = '';
  bool _isSearching = false;

  // Selected citation data
  Map<String, dynamic>? _selectedCitation;

  // Mock document data
  final Map<String, dynamic> _documentData = {
    "title": "Alternative Dispute Resolution Act, 2010 (Act 798)",
    "authority": "High",
    "publicationDate": "2010-05-15",
    "relevanceScore": 0.92,
    "documentType": "Statute",
    "jurisdiction": "Ghana",
    "citations": [
      {
        "id": "cite_1",
        "page": 12,
        "section": "Section 78",
        "text":
            "The arbitral tribunal may rule on its own jurisdiction, including any objections with respect to the existence or validity of the arbitration agreement.",
        "confidence": "high",
        "queryContext": "arbitral tribunal jurisdiction",
        "highlightColor": 0xFF4A6741,
      },
      {
        "id": "cite_2",
        "page": 18,
        "section": "Section 92",
        "text":
            "An arbitral award shall be recognized as binding and, upon application in writing to the Court, shall be enforced subject to the provisions of this section.",
        "confidence": "high",
        "queryContext": "enforcement of arbitral awards",
        "highlightColor": 0xFF4A6741,
      },
      {
        "id": "cite_3",
        "page": 24,
        "section": "Section 105",
        "text":
            "The Court may set aside an arbitral award only if the party making the application furnishes proof that a party to the arbitration agreement was under some incapacity.",
        "confidence": "medium",
        "queryContext": "setting aside arbitral awards",
        "highlightColor": 0xFFB8860B,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    // Set status bar style for professional appearance
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Main PDF viewer with citation highlights
          _buildPdfViewerSection(context),

          // Floating toolbar for navigation
          Positioned(
            bottom: _showCitationDetails ? 35.h : 8.h,
            left: 4.w,
            right: 4.w,
            child: DocumentToolbarWidget(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPreviousCitation: _navigateToPreviousCitation,
              onNextCitation: _navigateToNextCitation,
              onSearch: _toggleSearch,
              onPageJump: _showPageJumpDialog,
              isSearching: _isSearching,
            ),
          ),

          // Citation details bottom sheet
          if (_showCitationDetails && _selectedCitation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CitationDetailsSheetWidget(
                citation: _selectedCitation!,
                documentData: _documentData,
                onClose: () => setState(() => _showCitationDetails = false),
              ),
            ),

          // Search overlay
          if (_isSearching) _buildSearchOverlay(context),
        ],
      ),
    );
  }

  /// Build custom app bar with document title and actions
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAppBar(
      title: _documentData["title"] as String,
      subtitle: "Legal Authority: ${_documentData["authority"]}",
      variant: AppBarVariant.surface,
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        tooltip: 'Back',
      ),
      actions: [
        // Share document
        IconButton(
          icon: CustomIconWidget(
            iconName: 'share',
            color: theme.colorScheme.onSurface,
            size: 22,
          ),
          onPressed: _shareDocument,
          tooltip: 'Share Document',
        ),
        // Bookmark document
        IconButton(
          icon: CustomIconWidget(
            iconName: _isBookmarked ? 'bookmark' : 'bookmark_border',
            color: _isBookmarked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            size: 22,
          ),
          onPressed: _toggleBookmark,
          tooltip: _isBookmarked ? 'Remove Bookmark' : 'Bookmark Document',
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  /// Build PDF viewer section with citation highlights
  Widget _buildPdfViewerSection(BuildContext context) {
    return Column(
      children: [
        // Legal disclaimer banner
        _buildDisclaimerBanner(context),

        // Navigation breadcrumbs
        _buildBreadcrumbs(context),

        // PDF viewer with highlights
        Expanded(
          child: PdfViewerWidget(
            documentUrl: "https://example.com/legal-documents/act-798.pdf",
            currentPage: _currentPage,
            citations: (_documentData["citations"] as List)
                .cast<Map<String, dynamic>>(),
            searchQuery: _searchQuery,
            onPageChanged: (page) => setState(() => _currentPage = page),
            onCitationTap: _handleCitationTap,
            onTextSelection: _handleTextSelection,
          ),
        ),
      ],
    );
  }

  /// Build legal disclaimer banner
  Widget _buildDisclaimerBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.warningLight.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.warningLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'info_outline',
            color: AppTheme.warningLight,
            size: 18,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Legal Disclaimer: This document is for reference only. Verify authenticity with official sources.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warningLight,
                fontSize: 11.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation breadcrumbs
  Widget _buildBreadcrumbs(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Chat',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 11.sp,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            child: CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ),
          Text(
            'Citation #${_selectedCitation?["id"] ?? "1"}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 11.sp,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            child: CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ),
          Expanded(
            child: Text(
              'Page $_currentPage',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build search overlay
  Widget _buildSearchOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search input
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search legal terms...',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                    });
                  },
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (value) => _performSearch(value),
            ),

            // Search results count
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  '3 matches found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Handle citation tap
  void _handleCitationTap(Map<String, dynamic> citation) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedCitation = citation;
      _showCitationDetails = true;
      _currentPage = citation["page"] as int;
    });
  }

  /// Handle text selection
  void _handleTextSelection(String selectedText) {
    HapticFeedback.lightImpact();

    // Show citation context popup
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Copy with Citation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(selectedText, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 2.h),
            Text(
              'Citation: ${_documentData["title"]}, Page $_currentPage',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      '$selectedText\n\nSource: ${_documentData["title"]}, Page $_currentPage',
                ),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied with citation')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Navigate to previous citation
  void _navigateToPreviousCitation() {
    HapticFeedback.lightImpact();
    final citations = (_documentData["citations"] as List)
        .cast<Map<String, dynamic>>();
    final currentIndex = _selectedCitation != null
        ? citations.indexWhere((c) => c["id"] == _selectedCitation!["id"])
        : -1;

    if (currentIndex > 0) {
      _handleCitationTap(citations[currentIndex - 1]);
    } else if (citations.isNotEmpty) {
      _handleCitationTap(citations.last);
    }
  }

  /// Navigate to next citation
  void _navigateToNextCitation() {
    HapticFeedback.lightImpact();
    final citations = (_documentData["citations"] as List)
        .cast<Map<String, dynamic>>();
    final currentIndex = _selectedCitation != null
        ? citations.indexWhere((c) => c["id"] == _selectedCitation!["id"])
        : -1;

    if (currentIndex < citations.length - 1 && currentIndex >= 0) {
      _handleCitationTap(citations[currentIndex + 1]);
    } else if (citations.isNotEmpty) {
      _handleCitationTap(citations.first);
    }
  }

  /// Toggle search mode
  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() => _isSearching = !_isSearching);
  }

  /// Show page jump dialog
  void _showPageJumpDialog() {
    HapticFeedback.lightImpact();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Jump to Page',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-$_totalPages)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                setState(() => _currentPage = page);
                Navigator.pop(context);
              }
            },
            child: const Text('Jump'),
          ),
        ],
      ),
    );
  }

  /// Perform search
  void _performSearch(String query) {
    HapticFeedback.lightImpact();
    // Search implementation would highlight matching terms in PDF
    setState(() => _searchQuery = query);
  }

  /// Share document
  void _shareDocument() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${_documentData["title"]}'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  /// Toggle bookmark
  void _toggleBookmark() {
    HapticFeedback.mediumImpact();
    setState(() => _isBookmarked = !_isBookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? 'Document bookmarked' : 'Bookmark removed',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
