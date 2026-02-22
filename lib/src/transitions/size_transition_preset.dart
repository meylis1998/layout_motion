import 'package:flutter/widgets.dart';
import 'motion_transition.dart';

/// Grows the child in by animating its size along [axis].
///
/// Uses [SizeTransition] for an accordion/expand-collapse effect.
class SizeIn extends MotionTransition {
  const SizeIn({this.axis = Axis.vertical, this.axisAlignment = 0.0});

  /// The axis along which to animate size. Defaults to [Axis.vertical].
  final Axis axis;

  /// Where to align the child along the animated axis.
  /// -1.0 aligns at the start, 0.0 centers, 1.0 aligns at the end.
  final double axisAlignment;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      axis: axis,
      axisAlignment: axisAlignment,
      child: child,
    );
  }
}

/// Shrinks the child out by animating its size along [axis].
class SizeOut extends MotionTransition {
  const SizeOut({this.axis = Axis.vertical, this.axisAlignment = 0.0});

  /// The axis along which to animate size. Defaults to [Axis.vertical].
  final Axis axis;

  /// Where to align the child along the animated axis.
  final double axisAlignment;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      axis: axis,
      axisAlignment: axisAlignment,
      child: child,
    );
  }
}
