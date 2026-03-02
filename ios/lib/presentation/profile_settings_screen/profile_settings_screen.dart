import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/toggle_settings_item_widget.dart';

/// Profile & Settings Screen for legal professionals
/// Manages professional information, security settings, research preferences, and app configuration
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  int _currentBottomNavIndex = 3;

  // Mock user data
  final Map<String, dynamic> _userData = {
    "name": "Kwame Mensah",
    "membershipId": "GBA/2018/4521",
    "isVerified": true,
    "photoUrl":
        "https://img.rocket.new/generatedImages/rocket_gen_img_124d0847c-1766495625052.png",
    "practiceAreas": ["Commercial Law", "Arbitration", "Contract Law"],
    "yearsOfExperience": 7,
    "specializations": "International Arbitration, ADR",
  };

  // Settings state
  bool _biometricAuth = true;
  bool _autoSessionTimeout = true;
  bool _dataEncryption = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _offlineStorage = true;
  String _confidenceThreshold = "Medium";
  String _citationFormat = "Bluebook";
  String _sessionTimeout = "15 minutes";

  void _handleBottomNavTap(int index) {
    if (index == _currentBottomNavIndex) return;

    HapticFeedback.lightImpact();
    setState(() => _currentBottomNavIndex = index);

    final routes = [
      '/home-dashboard',
      '/chat-list-screen',
      '/documents-library-screen',
      '/profile-settings-screen',
    ];

    Navigator.pushReplacementNamed(context, routes[index]);
  }

  void _showConfidenceThresholdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidence Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['High', 'Medium', 'Low'].map((level) {
            return RadioListTile<String>(
              title: Text(level),
              value: level,
              groupValue: _confidenceThreshold,
              onChanged: (value) {
                setState(() => _confidenceThreshold = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCitationFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Citation Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Bluebook', 'OSCOLA', 'APA', 'MLA'].map((format) {
            return RadioListTile<String>(
              title: Text(format),
              value: format,
              groupValue: _citationFormat,
              onChanged: (value) {
                setState(() => _citationFormat = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSessionTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['5 minutes', '15 minutes', '30 minutes', '1 hour'].map((
            timeout,
          ) {
            return RadioListTile<String>(
              title: Text(timeout),
              value: timeout,
              groupValue: _sessionTimeout,
              onChanged: (value) {
                setState(() => _sessionTimeout = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showVerificationFlow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Professional Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To verify your professional status, please provide:'),
            SizedBox(height: 2.h),
            const Text('• Ghana Bar Association membership certificate'),
            const Text('• Valid practicing certificate'),
            const Text('• Professional identification'),
            SizedBox(height: 2.h),
            const Text(
              'Documents will be reviewed within 2-3 business days.',
              style: TextStyle(fontSize: 12),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification request submitted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Upload Documents'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? All unsaved data will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/authentication-screen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _exportAuditTrail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audit trail exported successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Profile & Settings',
        variant: AppBarVariant.surface,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'help_outline',
              color: theme.colorScheme.onSurface,
              size: 6.w,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeaderWidget(
                name: _userData["name"] as String,
                membershipId: _userData["membershipId"] as String,
                isVerified: _userData["isVerified"] as bool,
                photoUrl: _userData["photoUrl"] as String?,
                onPhotoTap: () {},
              ),
              SizedBox(height: 2.h),

              // Professional Information Section
              SettingsSectionWidget(
                title: 'Professional Information',
                children: [
                  SettingsItemWidget(
                    iconName: 'work_outline',
                    title: 'Practice Areas',
                    subtitle: (_userData["practiceAreas"] as List).join(', '),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit practice areas'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  SettingsItemWidget(
                    iconName: 'calendar_today',
                    title: 'Years of Experience',
                    subtitle: '${_userData["yearsOfExperience"]} years',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit experience'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  SettingsItemWidget(
                    iconName: 'school',
                    title: 'Specializations',
                    subtitle: _userData["specializations"] as String,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit specializations'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Security Settings Section
              SettingsSectionWidget(
                title: 'Security Settings',
                children: [
                  ToggleSettingsItemWidget(
                    iconName: 'fingerprint',
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face recognition',
                    value: _biometricAuth,
                    onChanged: (value) =>
                        setState(() => _biometricAuth = value),
                  ),
                  SettingsItemWidget(
                    iconName: 'timer',
                    title: 'Session Timeout',
                    subtitle: _sessionTimeout,
                    onTap: _showSessionTimeoutDialog,
                  ),
                  ToggleSettingsItemWidget(
                    iconName: 'lock',
                    title: 'Data Encryption',
                    subtitle: 'Encrypt sensitive legal documents',
                    value: _dataEncryption,
                    onChanged: (value) =>
                        setState(() => _dataEncryption = value),
                    showDivider: false,
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Research Preferences Section
              SettingsSectionWidget(
                title: 'Research Preferences',
                children: [
                  SettingsItemWidget(
                    iconName: 'speed',
                    title: 'Confidence Threshold',
                    subtitle: _confidenceThreshold,
                    onTap: _showConfidenceThresholdDialog,
                  ),
                  SettingsItemWidget(
                    iconName: 'format_quote',
                    title: 'Citation Format',
                    subtitle: _citationFormat,
                    onTap: _showCitationFormatDialog,
                  ),
                  SettingsItemWidget(
                    iconName: 'location_on',
                    title: 'Jurisdiction Focus',
                    subtitle: 'Ghana',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jurisdiction settings'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // App Settings Section
              SettingsSectionWidget(
                title: 'App Settings',
                children: [
                  ToggleSettingsItemWidget(
                    iconName: 'notifications',
                    title: 'Push Notifications',
                    subtitle: 'Draft approvals and research updates',
                    value: _pushNotifications,
                    onChanged: (value) =>
                        setState(() => _pushNotifications = value),
                  ),
                  ToggleSettingsItemWidget(
                    iconName: 'email',
                    title: 'Email Notifications',
                    subtitle: 'Receive updates via email',
                    value: _emailNotifications,
                    onChanged: (value) =>
                        setState(() => _emailNotifications = value),
                  ),
                  ToggleSettingsItemWidget(
                    iconName: 'cloud_download',
                    title: 'Offline Storage',
                    subtitle: 'Save documents for offline access',
                    value: _offlineStorage,
                    onChanged: (value) =>
                        setState(() => _offlineStorage = value),
                  ),
                  SettingsItemWidget(
                    iconName: 'file_download',
                    title: 'Export Format',
                    subtitle: 'PDF',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export format settings'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Legal Compliance Section
              SettingsSectionWidget(
                title: 'Legal Compliance',
                children: [
                  SettingsItemWidget(
                    iconName: 'policy',
                    title: 'Data Handling Policies',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('View data policies'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  SettingsItemWidget(
                    iconName: 'history',
                    title: 'Audit Trail',
                    subtitle: 'View research and drafting history',
                    onTap: _exportAuditTrail,
                  ),
                  SettingsItemWidget(
                    iconName: 'gavel',
                    title: 'Professional Responsibility',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('View professional guidelines'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // About Section
              SettingsSectionWidget(
                title: 'About',
                children: [
                  SettingsItemWidget(
                    iconName: 'info',
                    title: 'App Version',
                    subtitle: '1.0.0 (Build 2025.12.30)',
                    showDivider: true,
                  ),
                  SettingsItemWidget(
                    iconName: 'description',
                    title: 'Legal Disclaimers',
                    onTap: () {
                      Navigator.pushNamed(context, '/legal-disclaimer-modal');
                    },
                  ),
                  SettingsItemWidget(
                    iconName: 'verified_user',
                    title: 'Ghana Bar Association Partnership',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('View partnership details'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Verification Button
              if (!(_userData["isVerified"] as bool))
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showVerificationFlow,
                      icon: CustomIconWidget(
                        iconName: 'verified',
                        color: theme.colorScheme.onPrimary,
                        size: 5.w,
                      ),
                      label: const Text('Get Verified'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 2.h),

              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showLogoutConfirmation,
                    icon: CustomIconWidget(
                      iconName: 'logout',
                      color: AppTheme.errorLight,
                      size: 5.w,
                    ),
                    label: Text(
                      'Logout',
                      style: TextStyle(color: AppTheme.errorLight),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      side: const BorderSide(color: AppTheme.errorLight),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}
