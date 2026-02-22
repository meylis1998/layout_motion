import 'package:flutter/widgets.dart';
import 'composed_transition.dart';

/// Base class for enter/exit transitions in [MotionLayout].
abstract class MotionTransition {
  const MotionTransition();

  /// Builds the transitioning widget.
  /// [animation] goes from 0.0 (start) to 1.0 (fully visible).
  /// For enter transitions, 0→1. For exit transitions, 1→0.
  Widget build(BuildContext context, Animation<double> animation, Widget child);

  /// Composes this transition with [other] so both effects apply simultaneously.
  ComposedTransition operator +(MotionTransition other) {
    if (this is ComposedTransition) {
      return ComposedTransition([
        ...(this as ComposedTransition).transitions,
        other,
      ]);
    }
    return ComposedTransition([this, other]);
  }
}
