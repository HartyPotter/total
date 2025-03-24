import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:total_flutter/core/theme/app_theme.dart';

class AnimationUtils {
  // Predefined durations
  static const Duration defaultDuration = AppTheme.animationMedium;

  // Page transitions
  static Route<T> pageTransition<T>({
    required Widget page,
    bool fadeIn = true,
    bool slideUp = false,
    bool slideLeft = false,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset.zero;
        var end = Offset.zero;

        if (slideUp) {
          begin = const Offset(0.0, 0.3);
        } else if (slideLeft) {
          begin = const Offset(1.0, 0.0);
        }

        const curve = Curves.easeOutCubic;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: fadeIn ? animation : const AlwaysStoppedAnimation(1.0),
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: defaultDuration,
    );
  }

  // Widget extensions for consistent animations
  static Widget animateItem(Widget child, int index, {Duration? baseDelay}) {
    final delay = baseDelay ?? const Duration(milliseconds: 30);
    final itemDelay = delay * index;

    return child
        .animate()
        .fadeIn(
          delay: itemDelay,
          duration: defaultDuration,
        )
        .slideY(
          begin: 0.1,
          delay: itemDelay,
          duration: defaultDuration,
          curve: Curves.easeOutCubic,
        );
  }

  // Apply standard animations to list items
  static Widget animateListItem(Widget child, int index) {
    return animateItem(child, index);
  }

  // Apply standard animations to cards
  static Widget animateCard(Widget child, {int index = 0}) {
    return child
        .animate()
        .fadeIn(
          duration: defaultDuration,
          delay: Duration(milliseconds: 50 * index),
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: defaultDuration,
          curve: Curves.easeOutCubic,
          delay: Duration(milliseconds: 50 * index),
        );
  }

  // Apply standard animations to dialogs
  static Widget animateDialog(Widget child) {
    return child
        .animate()
        .fadeIn(
          duration: Duration(milliseconds: 200),
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
  }

  // Apply standard animations to form items
  static Widget animateFormItem(Widget child, int index) {
    return child
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: defaultDuration,
        )
        .slideY(
          begin: 0.05,
          delay: Duration(milliseconds: 50 * index),
          duration: defaultDuration,
          curve: Curves.easeOutCubic,
        );
  }
}
