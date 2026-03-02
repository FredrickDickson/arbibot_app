import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';

/// Splash Screen for ArbiBot Legal Intelligence Application
/// Provides branded app launch experience while initializing legal services
/// and determining user authentication status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Initializing legal services...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  /// Setup fade-in animation for logo and content
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  /// Initialize app services and determine navigation route
  Future<void> _initializeApp() async {
    try {
      // Simulate checking authentication tokens
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _statusMessage = 'Loading user preferences...';
      });

      // Simulate loading user preferences
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _statusMessage = 'Fetching legal compliance...';
      });

      // Simulate fetching legal compliance configurations
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _statusMessage = 'Preparing cached documents...';
      });

      // Simulate preparing cached legal documents
      await Future.delayed(const Duration(milliseconds: 500));

      // Total initialization time: ~2.5 seconds
      // Determine navigation based on authentication status
      await _navigateToNextScreen();
    } catch (e) {
      // Handle initialization errors
      setState(() {
        _statusMessage = 'Initialization failed. Retrying...';
      });
      await Future.delayed(const Duration(seconds: 2));
      _initializeApp();
    }
  }

  /// Navigate to appropriate screen based on authentication status
  Future<void> _navigateToNextScreen() async {
    // Add smooth transition delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check authentication status (mock implementation)
    final bool isAuthenticated = await _checkAuthenticationStatus();
    final bool hasAcceptedDisclaimer = await _checkDisclaimerStatus();

    if (!mounted) return;

    if (isAuthenticated) {
      // Authenticated users go directly to home dashboard
      Navigator.pushReplacementNamed(context, '/home-dashboard');
    } else if (!hasAcceptedDisclaimer) {
      // New users see legal disclaimer modal first
      Navigator.pushReplacementNamed(context, '/legal-disclaimer-modal');
    } else {
      // Returning non-authenticated users reach login screen
      Navigator.pushReplacementNamed(context, '/authentication-screen');
    }
  }

  /// Mock authentication status check
  Future<bool> _checkAuthenticationStatus() async {
    // In production, check secure storage for auth tokens
    return false; // Default to not authenticated for demo
  }

  /// Mock disclaimer acceptance check
  Future<bool> _checkDisclaimerStatus() async {
    // In production, check if user has accepted legal disclaimer
    return false; // Default to not accepted for demo
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Set system UI overlay style for professional appearance
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colorScheme.primary, colorScheme.primaryContainer],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogo(context),
                SizedBox(height: 6.h),
                _buildAppName(context),
                SizedBox(height: 2.h),
                _buildTagline(context),
                const Spacer(flex: 2),
                _buildLoadingIndicator(context),
                SizedBox(height: 2.h),
                _buildStatusMessage(context),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build Ghana Legal Intelligence logo
  Widget _buildLogo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: colorScheme.shadow, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: 'gavel',
          size: 15.w,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  /// Build application name
  Widget _buildAppName(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      'ArbiBot',
      style: theme.textTheme.headlineLarge?.copyWith(
        color: colorScheme.onPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build tagline
  Widget _buildTagline(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      'Professional Legal Research Tool',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onPrimary.withValues(alpha: 0.8),
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 8.w,
      height: 8.w,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
      ),
    );
  }

  /// Build status message
  Widget _buildStatusMessage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _statusMessage,
        key: ValueKey<String>(_statusMessage),
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onPrimary.withValues(alpha: 0.7),
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
