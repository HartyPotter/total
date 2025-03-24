import 'package:flutter/material.dart';
import 'package:total_flutter/core/theme/app_theme.dart';

enum AppButtonType { primary, secondary, text, outline }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isFullWidth;
  final bool isLoading;
  final Color? customColor;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.customColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access the theme
    final defaultBorderRadius =
        BorderRadius.circular(AppTheme.borderRadiusMedium);

    // Determine colors based on type
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor =
            customColor ?? theme.colorScheme.primary; // Use theme color
        textColor = theme.colorScheme.onPrimary; // Use theme color
        borderColor = null;
        break;
      case AppButtonType.secondary:
        backgroundColor = customColor?.withOpacity(0.1) ??
            theme.colorScheme.secondary.withOpacity(0.1); // Use theme color
        textColor =
            customColor ?? theme.colorScheme.secondary; // Use theme color
        borderColor = null;
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = customColor ?? theme.colorScheme.primary; // Use theme color
        borderColor =
            customColor ?? theme.colorScheme.primary; // Use theme color
        break;
      case AppButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = customColor ?? theme.colorScheme.primary; // Use theme color
        borderColor = null;
        break;
    }

    // Determine padding based on size
    EdgeInsetsGeometry padding;
    double iconSize;
    double fontSize;

    switch (size) {
      case AppButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXs,
        );
        iconSize = 16;
        fontSize = 12;
        break;
      case AppButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        );
        iconSize = 18;
        fontSize = 14;
        break;
      case AppButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl,
          vertical: AppTheme.spacingM,
        );
        iconSize = 22;
        fontSize = 16;
        break;
    }

    final isDisabled = onPressed == null || isLoading;

    // Build button
    return AnimatedContainer(
      duration: AppTheme.animationShort,
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: isDisabled
            ? (type == AppButtonType.text || type == AppButtonType.outline)
                ? Colors.transparent
                : backgroundColor.withOpacity(0.5)
            : backgroundColor,
        borderRadius: borderRadius ?? defaultBorderRadius,
        border: borderColor != null
            ? Border.all(
                color: isDisabled ? borderColor.withOpacity(0.5) : borderColor,
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: borderRadius ?? defaultBorderRadius,
          splashColor:
              type == AppButtonType.text || type == AppButtonType.outline
                  ? textColor.withOpacity(0.1)
                  : null,
          highlightColor:
              type == AppButtonType.text || type == AppButtonType.outline
                  ? textColor.withOpacity(0.05)
                  : null,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                ] else if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: iconSize,
                    color: isDisabled ? textColor.withOpacity(0.5) : textColor,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      // Use theme text style
                      color:
                          isDisabled ? textColor.withOpacity(0.5) : textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (trailingIcon != null && !isLoading) ...[
                  const SizedBox(width: AppTheme.spacingS),
                  Icon(
                    trailingIcon,
                    size: iconSize,
                    color: isDisabled ? textColor.withOpacity(0.5) : textColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
