import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Fades the child in by animating opacity from 0 to 1.
class FadeIn extends MotionTransition {
  const FadeIn();

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// Fades the child out by animating opacity from 1 to 0.
class FadeOut extends MotionTransition {
  const FadeOut();

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}
