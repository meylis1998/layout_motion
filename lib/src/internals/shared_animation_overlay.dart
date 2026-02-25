import 'package:flutter/widgets.dart';

import '../transitions/motion_transition.dart';

/// Manages overlay entries for shared element transition animations.
///
/// Creates a positioned proxy in the app's [Overlay] that interpolates
/// between [fromRect] and [toRect] while optionally cross-fading content.
class SharedAnimationOverlay {
  SharedAnimationOverlay._();

  /// Creates an [OverlayEntry] that animates a proxy widget from [fromRect]
  /// to [toRect] using the provided [controller] and [curve].
  ///
  /// If [transition] is provided, it is applied to the cross-fade between
  /// [fromChild] and [toChild]. Otherwise, a simple opacity cross-fade is used.
  static OverlayEntry create({
    required Rect fromRect,
    required Rect toRect,
    required Widget fromChild,
    required Widget toChild,
    required AnimationController controller,
    required Curve curve,
    MotionTransition? transition,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, _) {
            final t = curvedAnimation.value;
            final rect = Rect.lerp(fromRect, toRect, t)!;

            // Cross-fade content
            Widget content;
            if (transition != null) {
              content = Stack(
                fit: StackFit.passthrough,
                children: [
                  // Old child fading out
                  Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: SizedBox(
                      width: rect.width,
                      height: rect.height,
                      child: fromChild,
                    ),
                  ),
                  // New child via transition
                  transition.build(
                    context,
                    curvedAnimation,
                    SizedBox(
                      width: rect.width,
                      height: rect.height,
                      child: toChild,
                    ),
                  ),
                ],
              );
            } else {
              // Simple opacity cross-fade
              content = Stack(
                fit: StackFit.passthrough,
                children: [
                  Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: SizedBox(
                      width: rect.width,
                      height: rect.height,
                      child: fromChild,
                    ),
                  ),
                  Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: SizedBox(
                      width: rect.width,
                      height: rect.height,
                      child: toChild,
                    ),
                  ),
                ],
              );
            }

            return Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: content,
            );
          },
        );
      },
    );

    return entry;
  }
}
