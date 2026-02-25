import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'exit_layout_behavior.dart';
import 'internals/motion_item_wrapper.dart';
import 'internals/sliver_child_tracker.dart';
import 'motion_spring.dart';
import 'scroll_aware_motion_layout.dart';
import 'stagger.dart';
import 'transitions/fade_transition.dart';
import 'transitions/motion_transition.dart';

/// A scrollable list that automatically animates its children.
///
/// [MotionListView] provides two constructors:
///
/// * The default constructor takes explicit [children] and wraps them in
///   a scrollable [ScrollAwareMotionLayout]. Best for small-to-medium lists
///   where full FLIP animations (move, enter, exit, stagger) are desired.
///
/// * [MotionListView.builder] creates items lazily using [itemBuilder],
///   similar to [ListView.builder]. It requires [keyBuilder] for diff-based
///   animation. Enter animations play when items first scroll into view.
///   Exit animations play when items are removed from data.
///
/// {@tool snippet}
/// ```dart
/// MotionListView(
///   enterTransition: const FadeSlideIn(),
///   staggerDuration: const Duration(milliseconds: 50),
///   children: [
///     for (final item in items)
///       ListTile(key: ValueKey(item.id), title: Text(item.name)),
///   ],
/// )
/// ```
/// {@end-tool}
class MotionListView extends StatefulWidget {
  /// Creates a scrollable animated list from explicit [children].
  ///
  /// All children must have unique [Key]s. Wraps children in a
  /// [ScrollAwareMotionLayout] for full FLIP animation support.
  const MotionListView({
    super.key,
    required List<Widget> this.children,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
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
    this.visibilityThreshold = 0.1,
    this.animateOnce = true,
  }) : itemCount = null,
       itemBuilder = null,
       keyBuilder = null;

  /// Creates a scrollable animated list from a builder.
  ///
  /// [keyBuilder] is required so the widget can track items across rebuilds
  /// for diff-based animation. Each key must be unique.
  ///
  /// Items are built lazily (only visible items + buffer). Enter animations
  /// play when items first scroll into view. Exit animations play when
  /// items are removed from the data.
  const MotionListView.builder({
    super.key,
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    required Key Function(int index) this.keyBuilder,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
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
    this.visibilityThreshold = 0.1,
    this.animateOnce = true,
  }) : children = null;

  // --- Data ---

  /// Explicit children list (children constructor).
  final List<Widget>? children;

  /// Number of items (builder constructor).
  final int? itemCount;

  /// Builder for items (builder constructor).
  final IndexedWidgetBuilder? itemBuilder;

  /// Key builder for each item index (builder constructor, required for diff).
  final Key Function(int index)? keyBuilder;

  // --- Scroll parameters ---

  /// Scroll axis. Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether to reverse the scroll direction.
  final bool reverse;

  /// Scroll controller.
  final ScrollController? controller;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Content padding.
  final EdgeInsetsGeometry? padding;

  /// Whether the list should shrink-wrap.
  final bool shrinkWrap;

  // --- Animation parameters ---

  /// Duration of move animations. Defaults to 300ms.
  final Duration duration;

  /// Animation curve. Defaults to [Curves.easeInOut].
  final Curve curve;

  /// Enter transition.
  final MotionTransition? enterTransition;

  /// Exit transition.
  final MotionTransition? exitTransition;

  /// Overflow clipping. Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Whether animations are enabled.
  final bool? enabled;

  /// Minimum delta for move animation. Defaults to 0.5.
  final double moveThreshold;

  /// Duration for enter/exit transitions.
  final Duration? transitionDuration;

  /// Stagger delay between children.
  final Duration staggerDuration;

  /// Stagger cascade direction.
  final StaggerFrom staggerFrom;

  /// Spring configuration for moves.
  final MotionSpring? spring;

  /// Curve override for moves.
  final Curve? moveCurve;

  /// Curve override for enter.
  final Curve? enterCurve;

  /// Curve override for exit.
  final Curve? exitCurve;

  /// How exiting children affect layout.
  final ExitLayoutBehavior exitLayoutBehavior;

  // --- Callbacks ---

  /// Called when any animation starts.
  final VoidCallback? onAnimationStart;

  /// Called when all animations complete.
  final VoidCallback? onAnimationComplete;

  /// Called when a child enters.
  final ValueChanged<Key>? onChildEnter;

  /// Called when a child exits.
  final ValueChanged<Key>? onChildExit;

  /// Called when a child moves.
  final ValueChanged<Key>? onChildMove;

  // --- Scroll-triggered parameters ---

  /// Fraction of a child visible to trigger animation (0.0–1.0).
  final double visibilityThreshold;

  /// Whether to animate each child only once.
  final bool animateOnce;

  /// Whether this widget uses the builder constructor.
  bool get _isBuilder => itemBuilder != null;

  /// Effective enter transition.
  MotionTransition get _effectiveEnterTransition =>
      enterTransition ?? const FadeIn();

  /// Effective exit transition.
  MotionTransition get _effectiveExitTransition =>
      exitTransition ?? const FadeOut();

  /// Effective transition duration.
  Duration get _effectiveTransitionDuration => transitionDuration ?? duration;

  /// Effective enter curve.
  Curve get _effectiveEnterCurve => enterCurve ?? curve;

  /// Effective exit curve.
  Curve get _effectiveExitCurve => exitCurve ?? curve;

  @override
  State<MotionListView> createState() => _MotionListViewState();
}

class _MotionListViewState extends State<MotionListView> {
  // Builder mode state.
  SliverChildTracker? _tracker;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    if (widget._isBuilder) {
      _tracker = SliverChildTracker();
      _tracker!.initialize(
        List.generate(widget.itemCount!, (i) => widget.keyBuilder!(i)),
      );
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _isFirstBuild = false;
          if (!widget.animateOnce) {
            _tracker?.seenKeys.clear();
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MotionListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._isBuilder && _tracker != null) {
      _handleBuilderUpdate();
    }
  }

  void _handleBuilderUpdate() {
    final newKeys = List.generate(
      widget.itemCount!,
      (i) => widget.keyBuilder!(i),
    );

    if (_listsEqual(_tracker!.dataKeys, newKeys)) return;

    final diff = _tracker!.update(newKeys);

    // Notify exit callbacks.
    for (final key in diff.removed) {
      widget.onChildExit?.call(key);
    }

    // Remove exiting items that were never visible (no lastWidget).
    final toRemove = <Key>[];
    for (final item in _tracker!.displayItems) {
      if (item.state == DisplayItemState.exiting && item.lastWidget == null) {
        toRemove.add(item.key);
      }
    }
    for (final key in toRemove) {
      _tracker!.removeExited(key);
    }

    setState(() {});
  }

  static bool _listsEqual(List<Key> a, List<Key> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleExitComplete(Key key) {
    _tracker?.removeExited(key);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tracker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget._isBuilder ? _buildBuilderMode() : _buildChildrenMode();
  }

  // ---------------------------------------------------------------------------
  // Children mode — Tier 1
  // ---------------------------------------------------------------------------

  Widget _buildChildrenMode() {
    final isVertical = widget.scrollDirection == Axis.vertical;

    final Widget layoutChild;
    if (isVertical) {
      layoutChild = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children!,
      );
    } else {
      layoutChild = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children!,
      );
    }

    return SingleChildScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      child: ScrollAwareMotionLayout(
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
        visibilityThreshold: widget.visibilityThreshold,
        animateOnce: widget.animateOnce,
        child: layoutChild,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Builder mode — Tier 2
  // ---------------------------------------------------------------------------

  Widget _buildBuilderMode() {
    Widget sliver = SliverList(
      delegate: SliverChildBuilderDelegate(
        _buildDisplayItem,
        childCount: _tracker!.displayItems.length,
        findChildIndexCallback: _findChildIndex,
      ),
    );

    if (widget.padding != null) {
      sliver = SliverPadding(padding: widget.padding!, sliver: sliver);
    }

    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      slivers: [sliver],
    );
  }

  int? _findChildIndex(Key key) {
    for (int i = 0; i < _tracker!.displayItems.length; i++) {
      if (_tracker!.displayItems[i].key == key) return i;
    }
    return null;
  }

  Widget? _buildDisplayItem(BuildContext context, int index) {
    if (index >= _tracker!.displayItems.length) return null;

    final item = _tracker!.displayItems[index];

    Widget child;
    if (item.state == DisplayItemState.exiting) {
      child = item.lastWidget ?? const SizedBox.shrink();
    } else {
      child = widget.itemBuilder!(context, item.dataIndex);
      item.lastWidget = child;
    }

    // Determine if this item needs enter animation.
    final needsEnter =
        !_isFirstBuild &&
        !_tracker!.seenKeys.contains(item.key) &&
        item.state != DisplayItemState.exiting;

    // Track seen keys.
    if (_isFirstBuild || (needsEnter && widget.animateOnce)) {
      _tracker!.seenKeys.add(item.key);
    }

    return MotionItemWrapper(
      key: item.key,
      enterTransition: widget._effectiveEnterTransition,
      exitTransition: widget._effectiveExitTransition,
      duration: widget._effectiveTransitionDuration,
      enterCurve: widget._effectiveEnterCurve,
      exitCurve: widget._effectiveExitCurve,
      shouldEnter: needsEnter,
      isExiting: item.state == DisplayItemState.exiting,
      onExitComplete: () => _handleExitComplete(item.key),
      onEntered: needsEnter ? () => widget.onChildEnter?.call(item.key) : null,
      child: child,
    );
  }
}
