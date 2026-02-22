import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Fades and scales the child in simultaneously.
///
/// Combines [FadeTransition] and [ScaleTransition] for a modal/dialog-like
/// entrance effect.
class FadeScaleIn extends MotionTransition {
  const FadeScaleIn({this.scale = 0.8})
    : assert(scale > 0, 'scale must be positive');

  /// The starting scale value. Defaults to 0.8.
  final double scale;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: scale, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }
}

/// Fades and scales the child out simultaneously.
class FadeScaleOut extends MotionTransition {
  const FadeScaleOut({this.scale = 0.8})
    : assert(scale > 0, 'scale must be positive');

  /// The ending scale value. Defaults to 0.8.
  final double scale;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: scale, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }
}
