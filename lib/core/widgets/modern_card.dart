import 'package:flutter/material.dart';
import 'package:total_flutter/core/theme/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final Color? backgroundColor;
  final Color? shadowColor;
  final BorderRadius? borderRadius;
  final bool hasBorder;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    required this.margin,
    this.padding,
    this.elevation = AppTheme.elevationSmall,
    this.backgroundColor,
    this.shadowColor,
    this.borderRadius,
    this.hasBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius =
        BorderRadius.circular(AppTheme.borderRadiusMedium);

    return AnimatedContainer(
      duration: AppTheme.animationShort,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardTheme.color,
        borderRadius: borderRadius ?? defaultBorderRadius,
        border: hasBorder
            ? Border.all(
                color: borderColor ?? AppTheme.dividerColor,
                width: borderWidth,
              )
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: (shadowColor ?? Colors.black).withOpacity(0.08),
                  blurRadius: elevation * 2,
                  spreadRadius: elevation / 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? defaultBorderRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? defaultBorderRadius,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
