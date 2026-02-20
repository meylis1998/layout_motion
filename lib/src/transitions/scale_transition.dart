import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Scales the child in from [scale] to 1.0.
class ScaleIn extends MotionTransition {
  const ScaleIn({this.scale = 0.8})
    : assert(scale > 0, 'scale must be positive');

  /// The scale value at the start of the enter animation.
  ///
  /// Defaults to 0.8. The child scales from this value to 1.0.
  final double scale;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    final scaleAnimation = Tween<double>(
      begin: scale,
      end: 1.0,
    ).animate(animation);
    return ScaleTransition(scale: scaleAnimation, child: child);
  }
}

/// Scales the child out from 1.0 to [scale].
class ScaleOut extends MotionTransition {
  const ScaleOut({this.scale = 0.8})
    : assert(scale > 0, 'scale must be positive');

  /// The scale value at the end of the exit animation.
  ///
  /// Defaults to 0.8. The child scales from 1.0 to this value.
  final double scale;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    final scaleAnimation = Tween<double>(
      begin: scale,
      end: 1.0,
    ).animate(animation);
    return ScaleTransition(scale: scaleAnimation, child: child);
  }
}
