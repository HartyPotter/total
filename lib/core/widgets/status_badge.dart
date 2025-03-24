import 'package:flutter/material.dart';
import 'package:total_flutter/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool isOutlined;
  final double? width;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isOutlined ? color.withOpacity(0.1) : color,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isOutlined ? color : Colors.white,
            ),
            const SizedBox(width: AppTheme.spacingXs),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isOutlined ? color : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
