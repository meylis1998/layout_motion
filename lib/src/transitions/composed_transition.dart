import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Composes multiple [MotionTransition]s so all effects apply simultaneously.
///
/// Created via the `+` operator on [MotionTransition]:
/// ```dart
/// enterTransition: const FadeIn() + const SlideIn() + const ScaleIn(),
/// ```
class ComposedTransition extends MotionTransition {
  const ComposedTransition(this.transitions);

  /// The transitions to compose, applied outermost-first.
  final List<MotionTransition> transitions;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    Widget result = child;
    for (int i = transitions.length - 1; i >= 0; i--) {
      result = transitions[i].build(context, animation, result);
    }
    return result;
  }
}
