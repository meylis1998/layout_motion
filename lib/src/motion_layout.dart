import 'package:flutter/widgets.dart';

import 'motion_layout_state.dart';
import 'transitions/motion_transition.dart';
import 'transitions/fade_transition.dart';

/// A widget that automatically animates layout changes in its child.
///
/// Wrap any [Column], [Row], [Wrap], or [Stack] to get smooth FLIP (First,
/// Last, Invert, Play) animations whenever children are added, removed, or
/// reordered.
///
/// Children **must** have unique [Key]s for the diff algorithm to track them.
///
/// {@tool snippet}
/// ```dart
/// MotionLayout(
///   child: Column(
///     children: [
///       for (final item in items)
///         ListTile(key: ValueKey(item.id), title: Text(item.name)),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
class MotionLayout extends StatefulWidget {
  /// Creates a [MotionLayout] that animates layout changes in [child].
  ///
  /// The [child] must be a [Column], [Row], [Wrap], or [Stack].
  const MotionLayout({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.enterTransition,
    this.exitTransition,
    this.clipBehavior = Clip.hardEdge,
    this.enabled = true,
    this.moveThreshold = 0.5,
    this.transitionDuration,
  }) : assert(moveThreshold > 0, 'moveThreshold must be greater than 0');

  /// The layout widget whose children will be animated.
  ///
  /// Must be a [Column], [Row], [Wrap], or [Stack].
  final Widget child;

  /// Duration of move animations.
  ///
  /// Also used as the fallback for enter/exit transitions when
  /// [transitionDuration] is not specified. Defaults to 300ms.
  final Duration duration;

  /// The animation curve for move animations.
  ///
  /// Defaults to [Curves.easeInOut].
  final Curve curve;

  /// Transition applied to children entering the layout.
  ///
  /// Defaults to [FadeIn] if not specified.
  final MotionTransition? enterTransition;

  /// Transition applied to children exiting the layout.
  ///
  /// Defaults to [FadeOut] if not specified.
  final MotionTransition? exitTransition;

  /// How to clip children during animation.
  ///
  /// Defaults to [Clip.hardEdge] to prevent overflow during moves.
  final Clip clipBehavior;

  /// Whether animations are enabled.
  ///
  /// When false, layout changes are instant (no animation overhead).
  /// Defaults to true.
  final bool enabled;

  /// Minimum position delta (in logical pixels) required to trigger a move
  /// animation. Moves smaller than this are applied instantly to avoid
  /// animating sub-pixel rounding differences across frames.
  ///
  /// Must be greater than 0. Defaults to `0.5`.
  final double moveThreshold;

  /// Duration of enter/exit transition animations.
  ///
  /// When null, falls back to [duration]. This allows move and transition
  /// animations to run at independent speeds.
  final Duration? transitionDuration;

  /// The effective transition duration, falling back to [duration].
  Duration get effectiveTransitionDuration => transitionDuration ?? duration;

  /// The effective enter transition, falling back to [FadeIn].
  MotionTransition get effectiveEnterTransition =>
      enterTransition ?? const FadeIn();

  /// The effective exit transition, falling back to [FadeOut].
  MotionTransition get effectiveExitTransition =>
      exitTransition ?? const FadeOut();

  @override
  State<MotionLayout> createState() => MotionLayoutState();
}
