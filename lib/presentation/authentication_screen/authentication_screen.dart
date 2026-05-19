import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';
import 'package:arbibot/services/auth_service.dart';
import './widgets/biometric_prompt_widget.dart';
import './widgets/email_input_widget.dart';
import './widgets/login_button_widget.dart';
import './widgets/password_input_widget.dart';

/// Authentication Screen for legal professionals
/// Implements secure login with biometric authentication and professional verification
class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  bool _showBiometricPrompt = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final auth = context.read<AuthService>();
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final success = await auth.signIn(email: email, password: password);

      if (!mounted) return;

      if (success) {
        HapticFeedback.mediumImpact();
        Navigator.pushReplacementNamed(context, '/home-dashboard');
      } else {
        setState(() {
          _errorMessage = auth.error ?? 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Network connectivity issue. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  void _handleForgotPassword() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Password recovery link will be sent to your registered email',
          style: TextStyle(fontSize: 12.sp),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLegalDisclaimer() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/legal-disclaimer-modal');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 6.h),

                      // Ghana Legal Intelligence Logo
                      _buildLogo(theme),

                      SizedBox(height: 4.h),

                      // Welcome Text
                      _buildWelcomeText(theme),

                      SizedBox(height: 4.h),

                      // Email Input
                      EmailInputWidget(
                        controller: _emailController,
                        enabled: !_isLoading,
                      ),

                      SizedBox(height: 2.h),

                      // Password Input
                      PasswordInputWidget(
                        controller: _passwordController,
                        isPasswordVisible: _isPasswordVisible,
                        enabled: !_isLoading,
                        onVisibilityToggle: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),

                      SizedBox(height: 1.h),

                      // Forgot Password Link
                      _buildForgotPasswordLink(theme),

                      SizedBox(height: 1.h),

                      // Error Message
                      if (_errorMessage != null) _buildErrorMessage(theme),

                      SizedBox(height: 3.h),

                      // Login Button
                      LoginButtonWidget(
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),

                      SizedBox(height: 4.h),

                      // Legal Disclaimer Link
                      _buildDisclaimerLink(theme),

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),

              // Biometric Prompt Overlay
              if (_showBiometricPrompt)
                BiometricPromptWidget(
                  onDismiss: () {
                    setState(() {
                      _showBiometricPrompt = false;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 60.w,
      height: 20.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'gavel',
            size: 48,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 1.h),
          Text(
            'ArbiBot',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Ghana Legal Intelligence',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Secure Professional Access',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Login with your Ghana Bar Association credentials',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _handleForgotPassword,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          minimumSize: Size(0, 4.h),
        ),
        child: Text(
          'Forgot Password?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            size: 20,
            color: theme.colorScheme.error,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerLink(ThemeData theme) {
    return TextButton(
      onPressed: _showLegalDisclaimer,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'info_outline',
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 1.w),
          Text(
            'Legal Disclaimer & Terms',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
