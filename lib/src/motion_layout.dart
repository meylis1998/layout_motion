import 'package:flutter/widgets.dart';

import 'exit_layout_behavior.dart';
import 'motion_layout_state.dart';
import 'motion_spring.dart';
import 'stagger.dart';
import 'transitions/motion_transition.dart';
import 'transitions/fade_transition.dart';

/// A widget that automatically animates layout changes in its child.
///
/// Wrap any [Column], [Row], [Wrap], [Stack], or [GridView] to get smooth
/// FLIP (First, Last, Invert, Play) animations whenever children are added,
/// removed, or reordered.
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
  /// The [child] must be a [Column], [Row], [Wrap], [Stack], or [GridView].
  const MotionLayout({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.enterTransition,
    this.exitTransition,
    this.clipBehavior = Clip.hardEdge,
    this.enabled,
    this.moveThreshold = 0.5,
    this.transitionDuration,
    this.staggerDuration = Duration.zero,
    this.staggerFrom = StaggerFrom.first,
    this.onAnimationStart,
    this.onAnimationComplete,
    this.onChildEnter,
    this.onChildExit,
    this.spring,
    this.moveCurve,
    this.enterCurve,
    this.exitCurve,
    this.onChildMove,
    this.exitLayoutBehavior = ExitLayoutBehavior.maintain,
    this.onReorder,
    this.dragDecorator,
    this.animateSizeChanges = false,
    this.sizeChangeThreshold = 1.0,
    this.onChildSizeChange,
    this.animateOnFirstBuild = false,
  }) : assert(moveThreshold > 0, 'moveThreshold must be greater than 0'),
       assert(
         sizeChangeThreshold > 0,
         'sizeChangeThreshold must be greater than 0',
       ),
       assert(
         child is Column ||
             child is Row ||
             child is Wrap ||
             child is Stack ||
             child is GridView,
         'MotionLayout child must be a Column, Row, Wrap, Stack, or GridView.',
       );

  /// The layout widget whose children will be animated.
  ///
  /// Must be a [Column], [Row], [Wrap], [Stack], or [GridView].
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
  /// When `null` (the default), animations are auto-detected from
  /// [MediaQuery.disableAnimations]. When `true`, animations are always
  /// enabled. When `false`, layout changes are instant (no animation overhead).
  final bool? enabled;

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

  /// Delay between each child's animation start.
  ///
  /// Applied to enter, exit, and move animations to create a cascading
  /// stagger effect. Default: [Duration.zero] (no stagger).
  final Duration staggerDuration;

  /// Direction of the stagger cascade.
  ///
  /// Controls which children animate first. Default: [StaggerFrom.first].
  final StaggerFrom staggerFrom;

  /// Called when any animation starts (at least one child begins animating).
  final VoidCallback? onAnimationStart;

  /// Called when all animations complete (no children animating).
  final VoidCallback? onAnimationComplete;

  /// Called when a specific child begins its enter animation.
  final ValueChanged<Key>? onChildEnter;

  /// Called when a specific child begins its exit animation.
  final ValueChanged<Key>? onChildExit;

  /// Optional spring configuration for physics-based move animations.
  ///
  /// When set, overrides [curve] (and [moveCurve]) for move animations.
  /// Enter/exit transitions still use their respective curves.
  final MotionSpring? spring;

  /// Optional curve override for move animations only.
  ///
  /// When null, falls back to [curve].
  final Curve? moveCurve;

  /// Optional curve override for enter transitions only.
  ///
  /// When null, falls back to [curve].
  final Curve? enterCurve;

  /// Optional curve override for exit transitions only.
  ///
  /// When null, falls back to [curve].
  final Curve? exitCurve;

  /// Called when a specific child begins its move animation.
  final ValueChanged<Key>? onChildMove;

  /// How exiting children affect the layout during their exit animation.
  ///
  /// Defaults to [ExitLayoutBehavior.maintain] (current behavior: exiting
  /// children remain in layout flow). Set to [ExitLayoutBehavior.pop] to
  /// immediately remove exiting children from flow while they animate out
  /// at their last known absolute position.
  final ExitLayoutBehavior exitLayoutBehavior;

  /// Called when children are reordered via drag.
  ///
  /// When non-null, children become reorderable via long-press drag.
  /// The callback receives the old and new indices of the dragged child.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Optional decorator for the dragged child during reorder.
  ///
  /// Receives the child widget and returns a decorated version.
  /// Defaults to adding a slight elevation effect.
  final Widget Function(Widget child)? dragDecorator;

  /// Whether to animate size changes for existing children (same key,
  /// different size).
  ///
  /// When true, children that change size will smoothly morph while
  /// siblings reflow to their new positions via FLIP. Useful for
  /// accordion/expand-collapse patterns.
  ///
  /// Defaults to `false`.
  final bool animateSizeChanges;

  /// Minimum size delta (in logical pixels) required to trigger a size
  /// morph animation. Size changes smaller than this are applied instantly.
  ///
  /// Must be greater than 0. Defaults to `1.0`.
  final double sizeChangeThreshold;

  /// Called when a specific child begins a size morph animation.
  final ValueChanged<Key>? onChildSizeChange;

  /// Whether children animate on the very first build.
  ///
  /// When `true` (the default), children play their enter transition on
  /// initial render. Set to `false` to suppress first-build animations,
  /// useful for scroll-aware layouts where enter animations should be
  /// triggered by viewport visibility instead.
  final bool animateOnFirstBuild;

  /// The effective move curve, falling back to [curve].
  Curve get effectiveMoveCurve => moveCurve ?? curve;

  /// The effective enter curve, falling back to [curve].
  Curve get effectiveEnterCurve => enterCurve ?? curve;

  /// The effective exit curve, falling back to [curve].
  Curve get effectiveExitCurve => exitCurve ?? curve;

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
