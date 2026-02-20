import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Slides the child in from [offset] (fractional, relative to child size).
class SlideIn extends MotionTransition {
  const SlideIn({this.offset = const Offset(0, 0.15)});

  final Offset offset;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(animation);
    return SlideTransition(position: offsetAnimation, child: child);
  }
}

/// Slides the child out toward [offset].
///
/// The Tween animates from [offset] to [Offset.zero], which looks like a
/// "slide in". However, the FLIP engine wraps exit animations in
/// [ReverseAnimation] (see `motion_layout_state.dart` `_buildChild`), so the
/// visual effect is [Offset.zero] → [offset] — i.e. the child slides out.
class SlideOut extends MotionTransition {
  const SlideOut({this.offset = const Offset(0, 0.15)});

  final Offset offset;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(animation);
    return SlideTransition(position: offsetAnimation, child: child);
  }
}
