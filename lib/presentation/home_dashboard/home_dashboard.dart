import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/services/auth_service.dart';
import 'package:arbibot/services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/responsive_shell.dart';
import '../../widgets/responsive_layout.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/quick_action_card_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/recent_activity_item_widget.dart';

/// Home Dashboard for ArbiBot - Legal Intelligence Platform
/// Provides quick access to legal research, document drafting, and recent materials
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentBottomNavIndex = 0;
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> _userData = {
    "name": "User",
    "title": "",
    "profileImage": "",
    "semanticLabel": "User profile",
  };

  List<Map<String, dynamic>> _quickStats = [
    {
      "label": "Recent Queries",
      "value": "0",
      "icon": "search",
      "color": Color(0xFF1E3A5F),
    },
    {
      "label": "Pending Drafts",
      "value": "0",
      "icon": "pending_actions",
      "color": Color(0xFF4A6741),
    },
    {
      "label": "Active Cases",
      "value": "0",
      "icon": "gavel",
      "color": Color(0xFFB8860B),
    },
  ];

  // Mock quick actions data
  final List<Map<String, dynamic>> _quickActions = [
    {
      "title": "Start Legal Research",
      "description": "Search Ghanaian statutes and case law",
      "icon": "search",
      "route": "/chat-list-screen",
      "flagIcon": "🇬🇭",
      "confidenceLevel": "high",
    },
    {
      "title": "Draft Document",
      "description": "Create legal opinions and submissions",
      "icon": "description",
      "route": "/draft-type-selection-screen",
      "flagIcon": "📄",
      "confidenceLevel": "high",
    },
    {
      "title": "Recent Citations",
      "description": "View your saved legal references",
      "icon": "bookmark",
      "route": "/documents-library-screen",
      "flagIcon": "🔖",
      "confidenceLevel": "high",
    },
  ];

  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final auth = context.read<AuthService>();
    final api = context.read<ApiService>();

    // Load profile
    final profile = await auth.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _userData = {
          'name': profile['full_name'] ?? 'User',
          'title': profile['title'] ?? '',
          'profileImage': '',
          'semanticLabel': 'User profile',
        };
      });
    }

    // Load stats and recent activity
    try {
      final conversations = await api.getConversations();
      final drafts = await api.getDrafts();
      final cases = await api.getCases();
      final documents = await api.getDocuments();

      if (!mounted) return;
      setState(() {
        _quickStats[0]['value'] = conversations.length.toString();
        _quickStats[1]['value'] = drafts.where((d) => d['status'] == 'draft' || d['status'] == 'pending_review').length.toString();
        _quickStats[2]['value'] = cases.length.toString();

        _recentActivities = documents.take(5).map((d) {
          return {
            'id': d['id'],
            'type': d['type'] ?? 'research',
            'title': d['title'] ?? 'Untitled',
            'subtitle': d['status'] ?? '',
            'timestamp': DateTime.tryParse(d['updated_at'] ?? d['created_at'] ?? '') ?? DateTime.now(),
            'confidenceLevel': 'high',
            'isPinned': false,
            'icon': (d['type'] ?? '').contains('draft') ? 'description' : 'search',
          };
        }).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Sort activities to show pinned items first
  void _sortActivitiesByPinned() {
    _recentActivities.sort((a, b) {
      if ((a["isPinned"] as bool) && !(b["isPinned"] as bool)) return -1;
      if (!(a["isPinned"] as bool) && (b["isPinned"] as bool)) return 1;
      return (b["timestamp"] as DateTime).compareTo(a["timestamp"] as DateTime);
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadDashboardData();
  }

  /// Handle quick action tap
  void _handleQuickActionTap(String route) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, route);
  }

  /// Handle activity item tap
  void _handleActivityTap(Map<String, dynamic> activity) {
    HapticFeedback.lightImpact();
    final type = activity["type"] as String;

    if (type == "research" || type == "citation") {
      Navigator.pushNamed(context, '/chat-screen');
    } else if (type == "draft") {
      Navigator.pushNamed(context, '/draft-preview-approval-screen');
    }
  }

  /// Handle activity item long press - show context menu
  void _handleActivityLongPress(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildContextMenu(activity),
    );
  }

  /// Build context menu for activity items
  Widget _buildContextMenu(Map<String, dynamic> activity) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CustomIconWidget(
              iconName: (activity["isPinned"] as bool)
                  ? 'push_pin'
                  : 'push_pin_outlined',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text((activity["isPinned"] as bool) ? 'Unpin' : 'Pin'),
            onTap: () {
              Navigator.pop(context);
              _togglePin(activity["id"] as String);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'ios_share',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: const Text('Export'),
            onTap: () {
              Navigator.pop(context);
              _exportActivity(activity);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'star_outline',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: const Text('Add to Favorites'),
            onTap: () {
              Navigator.pop(context);
              _addToFavorites(activity);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'archive',
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            title: const Text('Archive'),
            onTap: () {
              Navigator.pop(context);
              _archiveActivity(activity["id"] as String);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'delete_outline',
              color: theme.colorScheme.error,
              size: 24,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteActivity(activity["id"] as String);
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  /// Toggle pin status
  void _togglePin(String activityId) {
    setState(() {
      final index = _recentActivities.indexWhere((a) => a["id"] == activityId);
      if (index != -1) {
        _recentActivities[index]["isPinned"] =
            !(_recentActivities[index]["isPinned"] as bool);
        _sortActivitiesByPinned();
      }
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _recentActivities.firstWhere((a) => a["id"] == activityId)["isPinned"]
                  as bool
              ? 'Item pinned'
              : 'Item unpinned',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Export activity
  void _exportActivity(Map<String, dynamic> activity) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting "${activity["title"]}"...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Add to favorites
  void _addToFavorites(Map<String, dynamic> activity) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${activity["title"]}" to favorites'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Archive activity
  void _archiveActivity(String activityId) {
    setState(() {
      _recentActivities.removeWhere((a) => a["id"] == activityId);
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item archived'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }

  /// Delete activity
  void _deleteActivity(String activityId) {
    setState(() {
      _recentActivities.removeWhere((a) => a["id"] == activityId);
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Handle new research button tap
  void _handleNewResearch() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/chat-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveShell(
      currentIndex: _currentBottomNavIndex,
      onNavigationChanged: (index) {
        setState(() => _currentBottomNavIndex = index);
        HapticFeedback.lightImpact();
        switch (index) {
          case 0: break;
          case 1: Navigator.pushNamed(context, '/chat-list-screen'); break;
          case 2: Navigator.pushNamed(context, '/documents-library-screen'); break;
          case 3: Navigator.pushNamed(context, '/profile-settings-screen'); break;
        }
      },
      appBar: CustomAppBar(
        title: 'ArbiBot',
        variant: AppBarVariant.standard,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleNewResearch,
        icon: CustomIconWidget(
          iconName: 'add',
          color:
              theme.floatingActionButtonTheme.foregroundColor ??
              theme.colorScheme.onSecondary,
          size: 24,
        ),
        label: const Text('New Research'),
        tooltip: 'Start new legal research',
      ),
      body: ConstrainedContent(
        maxWidth: 960,
        child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Greeting Header
            SliverToBoxAdapter(
              child: GreetingHeaderWidget(
                userName: _userData["name"] as String,
                userTitle: _userData["title"] as String,
                profileImage: _userData["profileImage"] as String,
                semanticLabel: _userData["semanticLabel"] as String,
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(child: QuickStatsWidget(stats: _quickStats)),

            // Quick Actions Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 2.h),
                child: Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Quick Action Cards
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final action = _quickActions[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: QuickActionCardWidget(
                      title: action["title"] as String,
                      description: action["description"] as String,
                      icon: action["icon"] as String,
                      flagIcon: action["flagIcon"] as String,
                      confidenceLevel: action["confidenceLevel"] as String,
                      onTap: () =>
                          _handleQuickActionTap(action["route"] as String),
                    ),
                  );
                }, childCount: _quickActions.length),
              ),
            ),

            // Recent Activity Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(
                          context,
                          '/documents-library-screen',
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Activity List
            _recentActivities.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Column(
                          children: [
                            CustomIconWidget(
                              iconName: 'folder_open',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 48,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No recent activity',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final activity = _recentActivities[index];
                        return RecentActivityItemWidget(
                          activity: activity,
                          onTap: () => _handleActivityTap(activity),
                          onLongPress: () =>
                              _handleActivityLongPress(context, activity),
                        );
                      }, childCount: _recentActivities.length),
                    ),
                  ),
          ],
        ),
      ),
      ),
    );
  }
}
