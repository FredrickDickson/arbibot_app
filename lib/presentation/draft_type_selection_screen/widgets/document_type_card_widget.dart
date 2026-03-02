import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/widgets/custom_icon_widget.dart';

/// Individual document type card with professional legal styling
/// Implements expandable card pattern for detailed template information
class DocumentTypeCardWidget extends StatefulWidget {
  final String title;
  final String description;
  final String iconName;
  final List<String> useCases;
  final String estimatedTime;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onExpand;
  final bool isExpanded;

  const DocumentTypeCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.useCases,
    required this.estimatedTime,
    required this.isSelected,
    required this.onTap,
    required this.onExpand,
    required this.isExpanded,
  });

  @override
  State<DocumentTypeCardWidget> createState() => _DocumentTypeCardWidgetState();
}

class _DocumentTypeCardWidgetState extends State<DocumentTypeCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(DocumentTypeCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded
          ? _animationController.forward()
          : _animationController.reverse();
    }
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

    return Card(
      elevation: widget.isSelected ? 4.0 : 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: widget.isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: widget.iconName,
                      color: widget.isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: widget.isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          widget.estimatedTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: CustomIconWidget(
                        iconName: 'expand_more',
                        color: colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onExpand();
                    },
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                widget.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                    SizedBox(height: 2.h),
                    Text(
                      'Typical Use Cases:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...widget.useCases.map(
                      (useCase) => Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 0.5.h),
                              child: CustomIconWidget(
                                iconName: 'check_circle',
                                color: colorScheme.primary,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                useCase,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'info_outline',
                            color: colorScheme.primary,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Ghana-specific legal formatting and jurisdiction requirements applied',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
