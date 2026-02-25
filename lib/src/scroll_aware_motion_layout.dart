import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'internals/animated_child_entry.dart';
import 'internals/layout_snapshot.dart';
import 'internals/viewport_detector.dart';
import 'motion_layout.dart';
import 'motion_layout_state.dart';
import 'motion_spring.dart';
import 'stagger.dart';
import 'exit_layout_behavior.dart';
import 'transitions/motion_transition.dart';

/// A [MotionLayout] variant that triggers enter animations when children
/// first scroll into the viewport.
///
/// Wrap any [Column], [Row], [Wrap], [Stack], or [GridView] inside a
/// [ScrollView] to get scroll-triggered entrance animations. Children
/// that are off-screen on first build appear instantly when scrolled into
/// view (with their enter transition).
///
/// {@tool snippet}
/// ```dart
/// SingleChildScrollView(
///   child: ScrollAwareMotionLayout(
///     visibilityThreshold: 0.1,
///     enterTransition: const FadeSlideIn(),
///     staggerDuration: const Duration(milliseconds: 80),
///     child: Column(
///       children: [
///         for (final item in items)
///           ListTile(key: ValueKey(item.id), title: Text(item.name)),
///       ],
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
class ScrollAwareMotionLayout extends StatefulWidget {
  const ScrollAwareMotionLayout({
    super.key,
    required this.child,
    this.visibilityThreshold = 0.1,
    this.animateOnce = true,
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
    this.spring,
    this.moveCurve,
    this.enterCurve,
    this.exitCurve,
    this.exitLayoutBehavior = ExitLayoutBehavior.maintain,
    this.onAnimationStart,
    this.onAnimationComplete,
    this.onChildEnter,
    this.onChildExit,
    this.onChildMove,
  });

  /// The layout widget whose children will be animated.
  final Widget child;

  /// Fraction of a child that must be visible to trigger its animation.
  ///
  /// - `0.0` = any pixel visible triggers animation
  /// - `1.0` = child must be fully visible
  ///
  /// Defaults to `0.1`.
  final double visibilityThreshold;

  /// Whether to animate each child only once.
  ///
  /// When `true` (the default), a child that has already played its enter
  /// animation will not re-animate when scrolled back into view.
  /// When `false`, children re-animate every time they enter the viewport.
  final bool animateOnce;

  /// Duration of move animations. Defaults to 300ms.
  final Duration duration;

  /// The animation curve. Defaults to [Curves.easeInOut].
  final Curve curve;

  /// Transition for children entering the layout.
  final MotionTransition? enterTransition;

  /// Transition for children exiting the layout.
  final MotionTransition? exitTransition;

  /// Overflow clipping. Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Whether animations are enabled.
  final bool? enabled;

  /// Minimum pixel delta for move animation. Defaults to 0.5.
  final double moveThreshold;

  /// Duration for enter/exit transitions.
  final Duration? transitionDuration;

  /// Delay between each child's animation.
  final Duration staggerDuration;

  /// Direction of the stagger cascade.
  final StaggerFrom staggerFrom;

  /// Spring configuration for move animations.
  final MotionSpring? spring;

  /// Curve override for move animations.
  final Curve? moveCurve;

  /// Curve override for enter transitions.
  final Curve? enterCurve;

  /// Curve override for exit transitions.
  final Curve? exitCurve;

  /// How exiting children affect layout flow.
  final ExitLayoutBehavior exitLayoutBehavior;

  /// Called when any animation starts.
  final VoidCallback? onAnimationStart;

  /// Called when all animations complete.
  final VoidCallback? onAnimationComplete;

  /// Called when a child begins entering.
  final ValueChanged<Key>? onChildEnter;

  /// Called when a child begins exiting.
  final ValueChanged<Key>? onChildExit;

  /// Called when a child begins moving.
  final ValueChanged<Key>? onChildMove;

  @override
  State<ScrollAwareMotionLayout> createState() =>
      _ScrollAwareMotionLayoutState();
}

class _ScrollAwareMotionLayoutState extends State<ScrollAwareMotionLayout> {
  final GlobalKey<MotionLayoutState> _motionKey = GlobalKey();
  final GlobalKey _parentKey = GlobalKey();

  /// Children whose enter animation has already been triggered.
  final Set<Key> _seenKeys = {};

  /// Whether the initial visibility check has been performed.
  bool _initialCheckDone = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: KeyedSubtree(
        key: _parentKey,
        child: MotionLayout(
          key: _motionKey,
          duration: widget.duration,
          curve: widget.curve,
          enterTransition: widget.enterTransition,
          exitTransition: widget.exitTransition,
          clipBehavior: widget.clipBehavior,
          enabled: widget.enabled,
          moveThreshold: widget.moveThreshold,
          transitionDuration: widget.transitionDuration,
          staggerDuration: widget.staggerDuration,
          staggerFrom: widget.staggerFrom,
          spring: widget.spring,
          moveCurve: widget.moveCurve,
          enterCurve: widget.enterCurve,
          exitCurve: widget.exitCurve,
          exitLayoutBehavior: widget.exitLayoutBehavior,
          onAnimationStart: widget.onAnimationStart,
          onAnimationComplete: widget.onAnimationComplete,
          onChildEnter: widget.onChildEnter,
          onChildExit: widget.onChildExit,
          onChildMove: widget.onChildMove,
          // Suppress first-build enter animation — we trigger it on scroll.
          animateOnFirstBuild: false,
          child: widget.child,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Schedule initial visibility check after first layout.
    if (!_initialCheckDone) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initialCheckDone = true;
          _checkVisibility();
        }
      });
    }
  }

  void _checkVisibility() {
    final motionState = _motionKey.currentState;
    if (motionState == null) return;

    final parentRenderBox = _parentKey.currentContext?.findRenderObject();
    if (parentRenderBox is! RenderBox || !parentRenderBox.hasSize) return;

    // Find the nearest scrollable ancestor to get viewport metrics.
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;

    final position = scrollable.position;
    final viewportExtent = position.viewportDimension;
    final scrollDirection = scrollable.axisDirection;
    final axis =
        scrollDirection == AxisDirection.up ||
            scrollDirection == AxisDirection.down
        ? Axis.vertical
        : Axis.horizontal;

    // Capture current child positions relative to parent.
    final keyMap = <Key, GlobalKey>{};
    for (final entry in motionState.entries.values) {
      if (entry.state == ChildAnimationState.idle) {
        keyMap[entry.key] = entry.globalKey;
      }
    }

    if (keyMap.isEmpty) return;

    // Capture positions relative to the scrollable viewport.
    final scrollRenderBox = scrollable.context.findRenderObject();
    if (scrollRenderBox is! RenderBox || !scrollRenderBox.hasSize) return;

    final snapshots = LayoutSnapshotManager.capture(
      keyMap: keyMap,
      ancestor: scrollRenderBox,
    );

    final visibleKeys = ViewportDetector.visibleChildren(
      snapshots: snapshots,
      scrollOffset: 0, // Positions are already relative to viewport.
      viewportExtent: viewportExtent,
      scrollDirection: axis,
      visibilityThreshold: widget.visibilityThreshold,
    );

    // Trigger enter animation for newly visible, unseen children.
    final newlyVisible = <Key>[];
    for (final key in visibleKeys) {
      if (widget.animateOnce && _seenKeys.contains(key)) continue;
      if (!_seenKeys.contains(key)) {
        newlyVisible.add(key);
        _seenKeys.add(key);
      }
    }

    if (newlyVisible.isEmpty) return;

    // Trigger enter animations by calling _startEnter on each entry.
    for (int i = 0; i < newlyVisible.length; i++) {
      final entry = motionState.entries[newlyVisible[i]];
      if (entry != null && entry.state == ChildAnimationState.idle) {
        final delay = widget.staggerDuration * i;
        motionState.triggerEnter(entry, delay: delay);
      }
    }
  }
}
