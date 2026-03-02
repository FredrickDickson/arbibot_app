import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import './citation_highlight_widget.dart';

/// PDF Viewer Widget - Displays legal documents with citation highlighting
/// Implements professional document viewing with pinch-to-zoom and smooth scrolling
class PdfViewerWidget extends StatefulWidget {
  final String documentUrl;
  final int currentPage;
  final List<Map<String, dynamic>> citations;
  final String searchQuery;
  final Function(int) onPageChanged;
  final Function(Map<String, dynamic>) onCitationTap;
  final Function(String) onTextSelection;

  const PdfViewerWidget({
    super.key,
    required this.documentUrl,
    required this.currentPage,
    required this.citations,
    required this.searchQuery,
    required this.onPageChanged,
    required this.onCitationTap,
    required this.onTextSelection,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  // Mock PDF pages with legal content
  final List<Map<String, dynamic>> _pdfPages = [
    {
      "page": 1,
      "content":
          "ALTERNATIVE DISPUTE RESOLUTION ACT, 2010 (ACT 798)\n\nAn Act to provide for alternative dispute resolution and for related purposes.\n\nPassed by Parliament and assented to by the President:\n\nPART I - PRELIMINARY\n\nSection 1 - Interpretation\nIn this Act, unless the context otherwise requires—\n\n\"arbitration\" means any arbitration whether or not administered by a permanent arbitral institution;\n\n\"arbitral tribunal\" means a sole arbitrator or a panel of arbitrators;\n\n\"court\" means the High Court or any other court of competent jurisdiction;",
    },
    {
      "page": 12,
      "content":
          "PART VI - JURISDICTION OF ARBITRAL TRIBUNAL\n\nSection 78 - Competence of arbitral tribunal to rule on its jurisdiction\n\n(1) The arbitral tribunal may rule on its own jurisdiction, including any objections with respect to the existence or validity of the arbitration agreement.\n\n(2) For the purposes of subsection (1), an arbitration clause which forms part of a contract shall be treated as an agreement independent of the other terms of the contract.\n\n(3) A decision by the arbitral tribunal that the contract is null and void shall not entail ipso jure the invalidity of the arbitration clause.",
    },
    {
      "page": 18,
      "content":
          "PART VIII - RECOGNITION AND ENFORCEMENT OF AWARDS\n\nSection 92 - Recognition and enforcement\n\n(1) An arbitral award, irrespective of the country in which it was made, shall be recognized as binding and, upon application in writing to the Court, shall be enforced subject to the provisions of this section and section 93.\n\n(2) The party relying on an award or applying for its enforcement shall supply the original award or a copy of it.\n\n(3) If the award is not made in English, the Court may request the party to supply a translation of it into English certified by an official or sworn translator or by a diplomatic or consular agent.",
    },
    {
      "page": 24,
      "content":
          "PART IX - SETTING ASIDE OF AWARD\n\nSection 105 - Application for setting aside as exclusive recourse against arbitral award\n\n(1) Recourse to a Court against an arbitral award may be made only by an application for setting aside in accordance with subsections (2) and (3).\n\n(2) An arbitral award may be set aside by the Court only if—\n\n(a) the party making the application furnishes proof that a party to the arbitration agreement was under some incapacity; or the arbitration agreement is not valid under the law to which the parties have subjected it or, failing any indication of that law, under the law of Ghana;",
    },
  ];

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 3.0,
        onInteractionUpdate: (details) {
          setState(() {
            _currentScale = _transformationController.value.getMaxScaleOnAxis();
          });
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Current page content
              _buildPageContent(context),

              // Page indicator
              _buildPageIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build page content with citation highlights
  Widget _buildPageContent(BuildContext context) {
    final theme = Theme.of(context);
    final currentPageData = _pdfPages.firstWhere(
      (page) => page["page"] == widget.currentPage,
      orElse: () => _pdfPages.first,
    );

    // Get citations for current page
    final pageCitations = widget.citations
        .where((c) => c["page"] == widget.currentPage)
        .toList();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 80.h),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page number
          Text(
            'Page ${widget.currentPage}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 2.h),

          // Document content with highlights
          _buildContentWithHighlights(
            context,
            currentPageData["content"] as String,
            pageCitations,
          ),
        ],
      ),
    );
  }

  /// Build content with citation highlights
  Widget _buildContentWithHighlights(
    BuildContext context,
    String content,
    List<Map<String, dynamic>> citations,
  ) {
    final theme = Theme.of(context);

    if (citations.isEmpty) {
      return SelectableText(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12.sp,
          height: 1.6,
          color: Colors.black87,
        ),
        onSelectionChanged: (selection, cause) {
          if (selection.start != selection.end) {
            final selectedText = content.substring(
              selection.start,
              selection.end,
            );
            widget.onTextSelection(selectedText);
          }
        },
      );
    }

    // Build content with citation highlights
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content
        SelectableText(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12.sp,
            height: 1.6,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 3.h),

        // Citation highlights
        ...citations.map(
          (citation) => Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: CitationHighlightWidget(
              citation: citation,
              onTap: () => widget.onCitationTap(citation),
            ),
          ),
        ),
      ],
    );
  }

  /// Build page indicator
  Widget _buildPageIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page
          IconButton(
            icon: CustomIconWidget(
              iconName: 'chevron_left',
              color: widget.currentPage > 1
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              size: 24,
            ),
            onPressed: widget.currentPage > 1
                ? () => widget.onPageChanged(widget.currentPage - 1)
                : null,
          ),

          // Page info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Page ${widget.currentPage} of ${_pdfPages.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 11.sp,
              ),
            ),
          ),

          // Next page
          IconButton(
            icon: CustomIconWidget(
              iconName: 'chevron_right',
              color: widget.currentPage < _pdfPages.length
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              size: 24,
            ),
            onPressed: widget.currentPage < _pdfPages.length
                ? () => widget.onPageChanged(widget.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
