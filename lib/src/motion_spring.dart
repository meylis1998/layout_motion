import 'package:flutter/physics.dart';

/// Spring configuration for physics-based move animations.
///
/// Provides named presets and custom configuration. When set on
/// [MotionLayout.spring], overrides [MotionLayout.curve] for move
/// animations. Enter/exit transitions still use [curve].
class MotionSpring {
  const MotionSpring({
    this.stiffness = 200.0,
    this.damping = 20.0,
    this.mass = 1.0,
  }) : assert(stiffness > 0, 'stiffness must be positive'),
       assert(damping > 0, 'damping must be positive'),
       assert(mass > 0, 'mass must be positive');

  /// The stiffness of the spring.
  final double stiffness;

  /// The damping coefficient of the spring.
  final double damping;

  /// The mass of the object attached to the spring.
  final double mass;

  /// Gentle spring with minimal bounce.
  static const gentle = MotionSpring(stiffness: 120, damping: 20, mass: 1);

  /// Standard spring with natural feel.
  static const smooth = MotionSpring(stiffness: 200, damping: 22, mass: 1);

  /// Bouncy spring with visible overshoot.
  static const bouncy = MotionSpring(stiffness: 300, damping: 15, mass: 1);

  /// Stiff spring that settles quickly.
  static const stiff = MotionSpring(stiffness: 400, damping: 30, mass: 1);

  /// Converts to a [SpringDescription] for use with Flutter's physics engine.
  SpringDescription toSpringDescription() =>
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping);
}
