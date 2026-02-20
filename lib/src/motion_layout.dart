import 'package:flutter/widgets.dart';

import 'motion_layout_state.dart';
import 'transitions/motion_transition.dart';
import 'transitions/fade_transition.dart';

/// A widget that automatically animates layout changes in its child.
///
/// Wrap any [Column], [Row], or [Wrap] to get smooth FLIP (First, Last,
/// Invert, Play) animations whenever children are added, removed, or
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
  /// The [child] must be a [Column], [Row], or [Wrap].
  const MotionLayout({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.enterTransition,
    this.exitTransition,
    this.clipBehavior = Clip.hardEdge,
    this.enabled = true,
  });

  /// The layout widget whose children will be animated.
  ///
  /// Must be a [Column], [Row], or [Wrap].
  final Widget child;

  /// Duration of move and enter/exit animations.
  ///
  /// Defaults to 300ms.
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

  /// The effective enter transition, falling back to [FadeIn].
  MotionTransition get effectiveEnterTransition =>
      enterTransition ?? const FadeIn();

  /// The effective exit transition, falling back to [FadeOut].
  MotionTransition get effectiveExitTransition =>
      exitTransition ?? const FadeOut();

  @override
  State<MotionLayout> createState() => MotionLayoutState();
}
