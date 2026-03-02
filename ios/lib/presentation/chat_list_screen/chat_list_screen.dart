import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/conversation_card_widget.dart';
import './widgets/delete_confirmation_dialog.dart';
import './widgets/empty_state_widget.dart';
import './widgets/search_bar_widget.dart';

/// Chat List Screen for managing legal research conversations
/// Implements bottom tab navigation with Research tab active
/// Supports conversation organization, search, and batch operations
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedConversations = {};
  bool _isMultiSelectMode = false;
  bool _isRefreshing = false;
  String _searchQuery = '';

  // Mock data for legal conversations
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 1,
      'title': 'Contract Law: Breach of Agreement',
      'lastMessage':
          'What are the remedies for breach of contract under Ghanaian law?',
      'timestamp': '2 hours ago',
      'legalTopic': 'contract',
      'confidence': 'high',
      'isPinned': true,
    },
    {
      'id': 2,
      'title': 'Tort Law: Negligence Claims',
      'lastMessage':
          'Explain the elements of negligence in personal injury cases.',
      'timestamp': '5 hours ago',
      'legalTopic': 'tort',
      'confidence': 'high',
      'isPinned': false,
    },
    {
      'id': 3,
      'title': 'Constitutional Law: Fundamental Rights',
      'lastMessage':
          'What are the fundamental human rights protected under the 1992 Constitution?',
      'timestamp': 'Yesterday',
      'legalTopic': 'constitutional',
      'confidence': 'medium',
      'isPinned': false,
    },
    {
      'id': 4,
      'title': 'Criminal Law: Theft Offences',
      'lastMessage':
          'What is the legal definition of theft under the Criminal Offences Act?',
      'timestamp': '2 days ago',
      'legalTopic': 'criminal',
      'confidence': 'high',
      'isPinned': false,
    },
    {
      'id': 5,
      'title': 'Land Law: Property Disputes',
      'lastMessage': 'How are land disputes resolved in Ghana?',
      'timestamp': '3 days ago',
      'legalTopic': 'contract',
      'confidence': 'medium',
      'isPinned': false,
    },
    {
      'id': 6,
      'title': 'Family Law: Divorce Proceedings',
      'lastMessage': 'What are the grounds for divorce under Ghanaian law?',
      'timestamp': '1 week ago',
      'legalTopic': 'constitutional',
      'confidence': 'low',
      'isPinned': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) {
      return _conversations;
    }
    return _conversations.where((conversation) {
      final title = (conversation['title'] as String).toLowerCase();
      final lastMessage = (conversation['lastMessage'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversations synced successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleSearch(String query) {
    setState(() => _searchQuery = query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _handleConversationTap(int conversationId) {
    if (_isMultiSelectMode) {
      setState(() {
        _selectedConversations.contains(conversationId)
            ? _selectedConversations.remove(conversationId)
            : _selectedConversations.add(conversationId);
      });
    } else {
      HapticFeedback.lightImpact();
      Navigator.pushNamed(context, '/chat-screen', arguments: conversationId);
    }
  }

  void _handleConversationLongPress(int conversationId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMultiSelectMode = true;
      _selectedConversations.add(conversationId);
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedConversations.clear();
    });
  }

  void _handlePin(int conversationId) {
    HapticFeedback.lightImpact();
    setState(() {
      final conversation = _conversations.firstWhere(
        (c) => c['id'] == conversationId,
      );
      conversation['isPinned'] = !(conversation['isPinned'] as bool);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _conversations.firstWhere(
                    (c) => c['id'] == conversationId,
                  )['isPinned']
                  as bool
              ? 'Conversation pinned'
              : 'Conversation unpinned',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleArchive(int conversationId) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation archived'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleExport(int conversationId) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting research data...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleDelete(int conversationId) {
    final conversation = _conversations.firstWhere(
      (c) => c['id'] == conversationId,
    );
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        conversationTitle: conversation['title'] as String,
        onConfirm: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _conversations.removeWhere((c) => c['id'] == conversationId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _handleBatchArchive() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedConversations.length} conversations archived',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    _exitMultiSelectMode();
  }

  void _handleBatchExport() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exporting ${_selectedConversations.length} conversations...',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    _exitMultiSelectMode();
  }

  void _handleBatchShare() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sharing ${_selectedConversations.length} conversations...',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    _exitMultiSelectMode();
  }

  void _handleNewQuery() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/chat-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _isMultiSelectMode
          ? AppBar(
              leading: IconButton(
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: _exitMultiSelectMode,
              ),
              title: Text(
                '${_selectedConversations.length} selected',
                style: theme.textTheme.titleLarge,
              ),
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'archive',
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: _handleBatchArchive,
                  tooltip: 'Archive',
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'file_download',
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: _handleBatchExport,
                  tooltip: 'Export',
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'share',
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: _handleBatchShare,
                  tooltip: 'Share',
                ),
              ],
            )
          : AppBar(
              title: Text('Legal Research', style: theme.textTheme.titleLarge),
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'notifications_outlined',
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                  tooltip: 'Notifications',
                ),
              ],
            ),
      body: SafeArea(
        child: _conversations.isEmpty
            ? EmptyStateWidget(onStartResearch: _handleNewQuery)
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                color: colorScheme.primary,
                child: Column(
                  children: [
                    SearchBarWidget(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      onClear: _clearSearch,
                    ),
                    Expanded(
                      child: _filteredConversations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'search_off',
                                    color: colorScheme.onSurfaceVariant,
                                    size: 48,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'No conversations found',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'Try adjusting your search query',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredConversations.length,
                              itemBuilder: (context, index) {
                                final conversation =
                                    _filteredConversations[index];
                                final conversationId =
                                    conversation['id'] as int;
                                return GestureDetector(
                                  onLongPress: () =>
                                      _handleConversationLongPress(
                                        conversationId,
                                      ),
                                  child: ConversationCardWidget(
                                    conversation: conversation,
                                    onTap: () =>
                                        _handleConversationTap(conversationId),
                                    onPin: () => _handlePin(conversationId),
                                    onArchive: () =>
                                        _handleArchive(conversationId),
                                    onExport: () =>
                                        _handleExport(conversationId),
                                    onDelete: () =>
                                        _handleDelete(conversationId),
                                    isSelected: _selectedConversations.contains(
                                      conversationId,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleNewQuery,
              icon: CustomIconWidget(
                iconName: 'add',
                color: colorScheme.onSecondary,
                size: 24,
              ),
              label: Text(
                'New Legal Query',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSecondary,
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
        onTap: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home-dashboard');
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(
                context,
                '/documents-library-screen',
              );
              break;
            case 3:
              Navigator.pushReplacementNamed(
                context,
                '/profile-settings-screen',
              );
              break;
          }
        },
      ),
    );
  }
}
