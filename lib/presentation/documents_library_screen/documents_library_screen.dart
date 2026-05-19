import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/responsive_shell.dart';
import '../../widgets/responsive_layout.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';
import './widgets/document_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/section_header_widget.dart';

/// Documents Library Screen
/// Manages saved research materials and approved legal drafts
/// Implements professional organization with swipe actions and filtering
class DocumentsLibraryScreen extends StatefulWidget {
  const DocumentsLibraryScreen({super.key});

  @override
  State<DocumentsLibraryScreen> createState() => _DocumentsLibraryScreenState();
}

class _DocumentsLibraryScreenState extends State<DocumentsLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController sourceController = TextEditingController(text: 'statute');
  final TextEditingController jurisdictionController = TextEditingController();
  final List<String> _activeFilters = [];
  bool _isMultiSelectMode = false;
  final Set<int> _selectedDocuments = {};
  String _searchQuery = '';
  List<Map<String, dynamic>> _allDocuments = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final api = context.read<ApiService>();
      final docs = await api.getDocuments();
      if (!mounted) return;
      setState(() {
        _allDocuments = docs.asMap().entries.map((e) {
          final d = e.value;
          final type = d['type'] ?? 'draft';
          String category = 'Research Materials';
          String typeLabel = 'Research Material';
          if (type == 'draft') {
            category = 'Approved Drafts';
            typeLabel = 'Approved Draft';
          } else if (type == 'negotiation') {
            category = 'Citations';
            typeLabel = 'Negotiation Analysis';
          }
          return {
            'id': e.key + 1,
            'title': d['title'] ?? 'Untitled',
            'type': typeLabel,
            'date': _formatDate(d['updated_at'] ?? d['created_at']),
            'confidence': 'High',
            'status': d['status'] ?? 'approved',
            'isShared': false,
            'category': category,
          };
        }).toList();
      });
    } catch (_) {}
  }

  String _formatDate(String? ts) {
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return ts;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  List<Map<String, dynamic>> get _filteredDocuments {
    List<Map<String, dynamic>> filtered = _allDocuments;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final title = (doc['title'] as String).toLowerCase();
        final type = (doc['type'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || type.contains(query);
      }).toList();
    }

    // Apply active filters
    if (_activeFilters.isNotEmpty) {
      filtered = filtered.where((doc) {
        return _activeFilters.any((filter) {
          return (doc['type'] as String).contains(filter) ||
              (doc['confidence'] as String).contains(filter) ||
              (doc['status'] as String).contains(filter);
        });
      }).toList();
    }

    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedDocuments {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Research Materials': [],
      'Approved Drafts': [],
      'Citations': [],
    };

    for (var doc in _filteredDocuments) {
      final category = doc['category'] as String;
      grouped[category]?.add(doc);
    }

    return grouped;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ResponsiveShell(
      currentIndex: 2,
      onNavigationChanged: _handleBottomNavigation,
      appBar: _isMultiSelectMode
          ? _buildMultiSelectAppBar()
          : _buildStandardAppBar(),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleImportDocument,
              icon: CustomIconWidget(
                iconName: 'add',
                size: 20.sp,
                color: colorScheme.onSecondary,
              ),
              label: Text(
                'Import',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: colorScheme.secondary,
            ),
      body: ConstrainedContent(
        maxWidth: 960,
        child: SafeArea(
        child:
            _filteredDocuments.isEmpty &&
                _searchQuery.isEmpty &&
                _activeFilters.isEmpty
            ? EmptyStateWidget(
                onStartResearching: () {
                  Navigator.pushNamed(context, '/chat-list-screen');
                },
              )
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                color: colorScheme.primary,
                child: Column(
                  children: [
                    SearchBarWidget(
                      searchController: _searchController,
                      onSearchChanged: _handleSearchChanged,
                      onFilterTap: _showFilterBottomSheet,
                      hasActiveFilters: _activeFilters.isNotEmpty,
                    ),
                    FilterChipsWidget(
                      activeFilters: _activeFilters,
                      onRemoveFilter: _removeFilter,
                      onClearAll: _clearAllFilters,
                    ),
                    Expanded(
                      child: _filteredDocuments.isEmpty
                          ? _buildNoResultsWidget()
                          : _buildDocumentsList(),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildStandardAppBar() {
    return CustomAppBar(
      title: 'Documents Library',
      variant: AppBarVariant.surface,
      actions: [
        IconButton(
          icon: CustomIconWidget(
            iconName: 'more_vert',
            size: 20.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: _showMoreOptions,
          tooltip: 'More options',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildMultiSelectAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: colorScheme.primaryContainer,
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: 'close',
          size: 20.sp,
          color: colorScheme.onPrimaryContainer,
        ),
        onPressed: _exitMultiSelectMode,
      ),
      title: Text(
        '${_selectedDocuments.length} selected',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: CustomIconWidget(
            iconName: 'share',
            size: 20.sp,
            color: colorScheme.onPrimaryContainer,
          ),
          onPressed: _handleBatchShare,
          tooltip: 'Share selected',
        ),
        IconButton(
          icon: CustomIconWidget(
            iconName: 'download',
            size: 20.sp,
            color: colorScheme.onPrimaryContainer,
          ),
          onPressed: _handleBatchExport,
          tooltip: 'Export selected',
        ),
        IconButton(
          icon: CustomIconWidget(
            iconName: 'archive',
            size: 20.sp,
            color: colorScheme.onPrimaryContainer,
          ),
          onPressed: _handleBatchArchive,
          tooltip: 'Archive selected',
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 10.h),
      itemCount: _calculateListItemCount(),
      itemBuilder: (context, index) {
        return _buildListItem(index);
      },
    );
  }

  int _calculateListItemCount() {
    int count = 0;
    _groupedDocuments.forEach((category, documents) {
      if (documents.isNotEmpty) {
        count++; // Header
        count += documents.length; // Documents
      }
    });
    return count;
  }

  Widget _buildListItem(int index) {
    int currentIndex = 0;

    for (var entry in _groupedDocuments.entries) {
      final category = entry.key;
      final documents = entry.value;

      if (documents.isEmpty) continue;

      if (currentIndex == index) {
        return SectionHeaderWidget(
          title: category,
          count: documents.length,
          onViewAll: () => _handleViewAllCategory(category),
        );
      }
      currentIndex++;

      final docIndex = index - currentIndex;
      if (docIndex >= 0 && docIndex < documents.length) {
        final document = documents[docIndex];
        return _buildDocumentCard(document);
      }
      currentIndex += documents.length;
    }

    return const SizedBox.shrink();
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final isSelected = _selectedDocuments.contains(document['id']);

    return GestureDetector(
      onLongPress: () => _handleLongPress(document['id'] as int),
      child: Stack(
        children: [
          DocumentCardWidget(
            document: document,
            onTap: () => _handleDocumentTap(document),
            onShare: () => _handleShare(document),
            onExport: () => _handleExport(document),
            onArchive: () => _handleArchive(document),
            onDelete: () => _handleDelete(document),
          ),
          if (_isMultiSelectMode)
            Positioned(
              top: 2.h,
              right: 6.w,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) =>
                    _toggleDocumentSelection(document['id'] as int),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              size: 60.sp,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Documents Found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _clearAllFilters();
                setState(() => _searchQuery = '');
              },
              child: Text('Clear Search & Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filter Documents',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 20.sp,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildFilterSection('Document Type', [
              'Research Material',
              'Approved Draft',
              'Citation',
            ]),
            SizedBox(height: 2.h),
            _buildFilterSection('Confidence Level', ['High', 'Medium', 'Low']),
            SizedBox(height: 2.h),
            _buildFilterSection('Status', ['approved', 'draft', 'shared']),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _clearAllFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            final isSelected = _activeFilters.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selected
                      ? _activeFilters.add(option)
                      : _activeFilters.remove(option);
                });
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _removeFilter(String filter) {
    setState(() => _activeFilters.remove(filter));
  }

  void _clearAllFilters() {
    setState(() => _activeFilters.clear());
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Library synced successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDocumentTap(Map<String, dynamic> document) {
    if (_isMultiSelectMode) {
      _toggleDocumentSelection(document['id'] as int);
    } else {
      Navigator.pushNamed(
        context,
        '/source-viewer-screen',
        arguments: document,
      );
    }
  }

  void _handleLongPress(int documentId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMultiSelectMode = true;
      _selectedDocuments.add(documentId);
    });
  }

  void _toggleDocumentSelection(int documentId) {
    setState(() {
      _selectedDocuments.contains(documentId)
          ? _selectedDocuments.remove(documentId)
          : _selectedDocuments.add(documentId);

      if (_selectedDocuments.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedDocuments.clear();
    });
  }

  void _handleShare(Map<String, dynamic> document) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${document['title']}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExport(Map<String, dynamic> document) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting "${document['title']}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleArchive(Map<String, dynamic> document) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived "${document['title']}"'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }

  void _handleDelete(Map<String, dynamic> document) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${document['title']}"'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBatchShare() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${_selectedDocuments.length} documents'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _exitMultiSelectMode();
  }

  void _handleBatchExport() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${_selectedDocuments.length} documents'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _exitMultiSelectMode();
  }

  void _handleBatchArchive() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived ${_selectedDocuments.length} documents'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
    _exitMultiSelectMode();
  }

  void _handleImportDocument() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'description',
                size: 24.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Upload PDF Document'),
              subtitle: const Text('Ingest for RAG (Ghanaian legal sources)'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadDocument();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'text_snippet',
                size: 24.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Paste Text Content'),
              subtitle: const Text('Ingest plain text for RAG'),
              onTap: () {
                Navigator.pop(context);
                _showTextIngestionDialog();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                size: 24.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Scan Document'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera scanning coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Show dialog to get document metadata
        if (!mounted) return;
        _showDocumentMetadataDialog(file, fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDocumentMetadataDialog(File file, String fileName) {
    final titleController = TextEditingController(text: fileName.replaceAll(RegExp(r'\.(pdf|txt|md)$'), ''));
    final sourceTypeController = TextEditingController(text: 'statute');
    final jurisdictionController = TextEditingController(text: 'GH');
    bool useOcr = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Document Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'Enter document title',
                ),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String>(
                value: 'statute',
                decoration: const InputDecoration(
                  labelText: 'Source Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'statute', child: Text('Statute')),
                  DropdownMenuItem(value: 'case_law', child: Text('Case Law')),
                  DropdownMenuItem(value: 'regulation', child: Text('Regulation')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    sourceController.text = value;
                  }
                },
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: jurisdictionController,
                decoration: const InputDecoration(
                  labelText: 'Jurisdiction',
                  hintText: 'e.g., GH, US, UK',
                ),
              ),
              SizedBox(height: 1.h),
              SwitchListTile(
                title: const Text('Use OCR (for scanned PDFs)'),
                subtitle: const Text('Slower but extracts text from images'),
                value: useOcr,
                onChanged: (value) {
                  setDialogState(() => useOcr = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _uploadDocument(
                  file,
                  titleController.text,
                  sourceController.text,
                  jurisdictionController.text,
                  useOcr,
                );
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(
    File file,
    String title,
    String sourceType,
    String jurisdiction,
    bool useOcr,
  ) async {
    setState(() => _isUploading = true);

    try {
      final api = context.read<ApiService>();
      final result = await api.uploadDocument(
        file: file,
        title: title,
        sourceType: sourceType,
        jurisdiction: jurisdiction,
        useOcr: useOcr,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document uploaded successfully (${result['chunk_count']} chunks)'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchDocuments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showTextIngestionDialog() {
    final textController = TextEditingController();
    final titleController = TextEditingController();
    final sourceTypeController = TextEditingController(text: 'statute');
    final jurisdictionController = TextEditingController(text: 'GH');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingest Text Content'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'Enter document title',
                ),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String>(
                value: 'statute',
                decoration: const InputDecoration(
                  labelText: 'Source Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'statute', child: Text('Statute')),
                  DropdownMenuItem(value: 'case_law', child: Text('Case Law')),
                  DropdownMenuItem(value: 'regulation', child: Text('Regulation')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    sourceController.text = value;
                  }
                },
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: jurisdictionController,
                decoration: const InputDecoration(
                  labelText: 'Jurisdiction',
                  hintText: 'e.g., GH, US, UK',
                ),
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: textController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Text Content',
                  hintText: 'Paste legal text here...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _ingestText(
                textController.text,
                titleController.text,
                sourceController.text,
                jurisdictionController.text,
              );
            },
            child: const Text('Ingest'),
          ),
        ],
      ),
    );
  }

  Future<void> _ingestText(
    String text,
    String title,
    String sourceType,
    String jurisdiction,
  ) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final api = context.read<ApiService>();
      final result = await api.ingestText(
        text: text,
        title: title,
        sourceType: sourceType,
        jurisdiction: jurisdiction,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text ingested successfully (${result['chunk_count']} chunks)'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchDocuments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingestion failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'sort',
                size: 24.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Sort Documents'),
              onTap: () {
                Navigator.pop(context);
                _showSortOptions();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'sync',
                size: 24.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Sync Library'),
              onTap: () {
                Navigator.pop(context);
                _handleRefresh();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'settings',
                size: 24.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Library Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile-settings-screen');
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2.h),
            ListTile(
              title: const Text('Date (Newest First)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Date (Oldest First)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Title (A-Z)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Title (Z-A)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Confidence Level'),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _handleViewAllCategory(String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing all $category'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    final routes = [
      '/home-dashboard',
      '/chat-list-screen',
      '/documents-library-screen',
      '/profile-settings-screen',
    ];

    if (index != 2) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}
