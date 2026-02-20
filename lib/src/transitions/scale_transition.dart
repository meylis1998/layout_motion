import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Scales the child in from [beginScale] to 1.0.
class ScaleIn extends MotionTransition {
  const ScaleIn({this.beginScale = 0.8});

  final double beginScale;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    final scaleAnimation = Tween<double>(
      begin: beginScale,
      end: 1.0,
    ).animate(animation);
    return ScaleTransition(scale: scaleAnimation, child: child);
  }
}

/// Scales the child out from 1.0 to [endScale].
class ScaleOut extends MotionTransition {
  const ScaleOut({this.endScale = 0.8});

  final double endScale;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    final scaleAnimation = Tween<double>(
      begin: endScale,
      end: 1.0,
    ).animate(animation);
    return ScaleTransition(scale: scaleAnimation, child: child);
  }
}
