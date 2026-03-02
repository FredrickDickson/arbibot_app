import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';

/// Professional profile header with photo, name, and verification status
class ProfileHeaderWidget extends StatefulWidget {
  final String name;
  final String membershipId;
  final bool isVerified;
  final String? photoUrl;
  final VoidCallback onPhotoTap;

  const ProfileHeaderWidget({
    super.key,
    required this.name,
    required this.membershipId,
    required this.isVerified,
    this.photoUrl,
    required this.onPhotoTap,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _handlePhotoSelection() async {
    HapticFeedback.mediumImpact();

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        final XFile? image = result == 'camera'
            ? await _picker.pickImage(source: ImageSource.camera)
            : await _picker.pickImage(source: ImageSource.gallery);

        if (image != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update photo. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _handlePhotoSelection,
                child: Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.onPrimary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.photoUrl != null
                        ? CustomImageWidget(
                            imageUrl: widget.photoUrl!,
                            width: 25.w,
                            height: 25.w,
                            fit: BoxFit.cover,
                            semanticLabel:
                                "Professional profile photo of ${widget.name}",
                          )
                        : Container(
                            color: theme.colorScheme.surface,
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'person',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 12.w,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _handlePhotoSelection,
                  child: Container(
                    padding: EdgeInsets.all(1.5.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.onPrimary,
                        width: 2,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: theme.colorScheme.onSecondary,
                      size: 4.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GBA ID: ${widget.membershipId}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
              if (widget.isVerified) ...[
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'verified',
                        color: Colors.white,
                        size: 3.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Verified',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
