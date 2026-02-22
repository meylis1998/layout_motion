import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Fades and slides the child in simultaneously.
///
/// Combines [FadeTransition] and [SlideTransition] for a polished
/// entrance effect. This is the most commonly used animation pattern.
class FadeSlideIn extends MotionTransition {
  const FadeSlideIn({this.offset = const Offset(0, 0.15)});

  /// The starting offset (fractional, relative to child size).
  /// Defaults to slightly below: `Offset(0, 0.15)`.
  final Offset offset;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Fades and slides the child out simultaneously.
class FadeSlideOut extends MotionTransition {
  const FadeSlideOut({this.offset = const Offset(0, 0.15)});

  /// The ending offset (fractional, relative to child size).
  /// Defaults to slightly below: `Offset(0, 0.15)`.
  final Offset offset;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
