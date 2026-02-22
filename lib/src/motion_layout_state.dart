import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'internals/animated_child_entry.dart';
import 'internals/child_differ.dart';
import 'internals/layout_cloner.dart';
import 'internals/layout_snapshot.dart';
import 'motion_layout.dart';
import 'stagger.dart';

/// A private key type used to wrap each child at the top level of the
/// Column/Row/Wrap so that Flutter's element reconciliation can match
/// old and new children for the same logical item. This avoids GlobalKey
/// conflicts when the inner nesting depth changes (idle → exiting).
///
/// This is distinct from the user's [ValueKey] so that [Finder.byKey]
/// in tests only matches the user's widget, not our internal wrapper.
class _MotionChildKey extends ValueKey<Key> {
  const _MotionChildKey(super.value);
}

/// The state for [MotionLayout] implementing the FLIP animation engine.
///
/// FLIP = First, Last, Invert, Play:
/// 1. **First** — Capture "before" positions of all current children
/// 2. **Diff** — Compare old and new child keys
/// 3. **Build** — Return layout with merged children (current + exiting)
/// 4. **Last** — After layout, capture "after" positions
/// 5. **Invert** — Calculate position delta per child
/// 6. **Play** — Animate transform from delta to zero
class MotionLayoutState extends State<MotionLayout>
    with TickerProviderStateMixin {
  /// The parent RenderBox key for relative position calculations.
  final GlobalKey _parentKey = GlobalKey();

  /// Tracked children indexed by their user-provided key.
  final Map<Key, AnimatedChildEntry> _entries = {};

  /// Keys of the children from the previous build, in order.
  List<Key> _previousKeys = [];

  /// Whether this is the very first build (skip animations).
  bool _isFirstBuild = true;

  /// Controllers pending disposal (deferred to avoid disposing during listeners).
  final List<AnimationController> _pendingDisposal = [];

  /// Keys pending removal from [_entries] (deferred to avoid map mutation
  /// during iteration).
  final Set<Key> _pendingRemovals = {};

  /// Number of currently active animations (for lifecycle callbacks).
  int _activeAnimationCount = 0;

  // ---------------------------------------------------------------------------
  // Reduced-motion auto-detection (Feature 4)
  // ---------------------------------------------------------------------------

  /// Resolves the effective [enabled] value, respecting system accessibility.
  bool get _effectiveEnabled {
    if (widget.enabled != null) return widget.enabled!;
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return true;
    return !mq.disableAnimations;
  }

  // ---------------------------------------------------------------------------
  // Animation lifecycle callbacks (Feature 2)
  // ---------------------------------------------------------------------------

  void _incrementActiveAnimations() {
    final wasZero = _activeAnimationCount == 0;
    _activeAnimationCount++;
    if (wasZero) {
      widget.onAnimationStart?.call();
    }
  }

  void _decrementActiveAnimations() {
    _activeAnimationCount--;
    if (_activeAnimationCount <= 0) {
      _activeAnimationCount = 0;
      widget.onAnimationComplete?.call();
    }
  }

  // ---------------------------------------------------------------------------
  // Stagger computation (Feature 1)
  // ---------------------------------------------------------------------------

  Duration _computeStaggerDelay(int index, int total) {
    if (widget.staggerDuration == Duration.zero || total <= 1) {
      return Duration.zero;
    }
    final int staggerIndex;
    switch (widget.staggerFrom) {
      case StaggerFrom.first:
        staggerIndex = index;
      case StaggerFrom.last:
        staggerIndex = total - 1 - index;
      case StaggerFrom.center:
        final center = (total - 1) / 2;
        staggerIndex = (index - center).abs().round();
    }
    return widget.staggerDuration * staggerIndex;
  }

  // ---------------------------------------------------------------------------
  // didUpdateWidget
  // ---------------------------------------------------------------------------

  @override
  void didUpdateWidget(covariant MotionLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_effectiveEnabled || widget.duration == Duration.zero) {
      _handleInstantUpdate();
      return;
    }

    _handleAnimatedUpdate();
  }

  void _handleInstantUpdate() {
    // Dispose all controllers and clear animation state.
    for (final entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
    _flushPendingDisposals();
    _flushPendingRemovals();
    _activeAnimationCount = 0;

    // Re-initialize entries without animation.
    final children = LayoutCloner.getChildren(widget.child);
    _previousKeys = [];
    for (final child in children) {
      if (child.key != null) {
        final key = child.key!;
        _previousKeys.add(key);
        _entries[key] = AnimatedChildEntry.idle(key: key, widget: child);
      }
    }
  }

  void _handleAnimatedUpdate() {
    _flushPendingDisposals();
    _flushPendingRemovals();

    // --- FIRST: capture "before" positions ---
    _captureBeforePositions();

    // --- DIFF ---
    final newChildren = LayoutCloner.getChildren(widget.child);
    final newKeys = <Key>[];
    for (final child in newChildren) {
      if (child.key == null) {
        throw ArgumentError(
          'MotionLayout: All children must have a Key. '
          'Found a ${child.runtimeType} without a key.',
        );
      }
      final key = child.key!;
      if (newKeys.contains(key)) {
        throw ArgumentError(
          'MotionLayout: Duplicate key found: $key. '
          'Each child must have a unique Key.',
        );
      }
      newKeys.add(key);
    }

    final diff = ChildDiffer.diff(_previousKeys, newKeys);

    // --- Process removed children → start exit (with stagger) ---
    final removedList = diff.removed.toList();
    for (int i = 0; i < removedList.length; i++) {
      final key = removedList[i];
      final entry = _entries[key];
      if (entry != null && entry.state != ChildAnimationState.exiting) {
        final delay = _computeStaggerDelay(i, removedList.length);
        _startExit(entry, delay: delay);
      }
    }

    // --- Process added children → create entries (with stagger) ---
    final addedIndices = <int>[];
    for (int i = 0; i < newChildren.length; i++) {
      final key = newChildren[i].key!;
      if (diff.added.contains(key)) {
        addedIndices.add(i);
      }
    }

    for (int ai = 0; ai < addedIndices.length; ai++) {
      final childIndex = addedIndices[ai];
      final child = newChildren[childIndex];
      final key = child.key!;
      final delay = _computeStaggerDelay(ai, addedIndices.length);

      final existing = _entries[key];
      if (existing != null && existing.state == ChildAnimationState.exiting) {
        // Re-added during exit: cancel exit, restart as entering.
        _cancelTransition(existing);
        existing.widget = child;
        _startEnter(existing, delay: delay);
      } else {
        final entry = AnimatedChildEntry.idle(key: key, widget: child);
        _entries[key] = entry;
        if (!_isFirstBuild) {
          _startEnter(entry, delay: delay);
        }
      }
    }

    // Update existing children's widget references.
    for (final child in newChildren) {
      final key = child.key!;
      if (!diff.added.contains(key)) {
        _entries[key]?.widget = child;
      }
    }

    _previousKeys = newKeys;

    // --- Schedule LAST + INVERT + PLAY after layout ---
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _performFlipAfterLayout(diff);
    });
  }

  void _captureBeforePositions() {
    final parentRenderBox = _getParentRenderBox();
    if (parentRenderBox == null) return;

    final keyMap = <Key, GlobalKey>{};
    for (final entry in _entries.values) {
      if (entry.state != ChildAnimationState.removed) {
        keyMap[entry.key] = entry.globalKey;
      }
    }

    final snapshots = LayoutSnapshotManager.capture(
      keyMap: keyMap,
      ancestor: parentRenderBox,
    );

    for (final entry in _entries.values) {
      final snapshot = snapshots[entry.key];
      if (snapshot != null) {
        // Account for any in-progress move animation offset.
        entry.beforeSnapshot = ChildSnapshot(
          offset: snapshot.offset + entry.currentTranslationOffset,
          size: snapshot.size,
        );
      }
    }
  }

  void _performFlipAfterLayout(DiffResult diff) {
    final parentRenderBox = _getParentRenderBox();
    if (parentRenderBox == null) return;

    // --- LAST: capture "after" positions ---
    final keyMap = <Key, GlobalKey>{};
    for (final entry in _entries.values) {
      if (entry.state != ChildAnimationState.removed) {
        keyMap[entry.key] = entry.globalKey;
      }
    }

    final afterSnapshots = LayoutSnapshotManager.capture(
      keyMap: keyMap,
      ancestor: parentRenderBox,
    );

    // --- INVERT + PLAY (with stagger for moves) ---
    bool anyMoveStarted = false;
    final movedOrStable = {...diff.moved, ...diff.stable};
    final movedOrStableList = movedOrStable.toList();

    // Collect entries that need moving to compute stagger.
    final movingEntries = <MapEntry<AnimatedChildEntry, Offset>>[];

    for (final key in movedOrStableList) {
      final entry = _entries[key];
      if (entry == null) continue;

      final before = entry.beforeSnapshot;
      final after = afterSnapshots[key];
      if (before == null || after == null) continue;

      final delta = before.offset - after.offset;
      if (delta.dx.abs() < widget.moveThreshold &&
          delta.dy.abs() < widget.moveThreshold) {
        // No significant move — skip animation.
        entry.currentTranslationOffset = Offset.zero;
        continue;
      }

      movingEntries.add(MapEntry(entry, delta));
    }

    for (int i = 0; i < movingEntries.length; i++) {
      final e = movingEntries[i];
      final delay = _computeStaggerDelay(i, movingEntries.length);
      _startMove(e.key, e.value, delay: delay);
      anyMoveStarted = true;
    }

    // Snap exiting children to their pre-removal visual position so they
    // don't jump to the end of the layout during the exit transition.
    for (final entry in _entries.values) {
      if (entry.state != ChildAnimationState.exiting) continue;
      final before = entry.beforeSnapshot;
      final after = afterSnapshots[entry.key];
      if (before == null || after == null) continue;

      final delta = before.offset - after.offset;
      entry.currentTranslationOffset = delta;
      anyMoveStarted = true;
    }

    // Clear before snapshots.
    for (final entry in _entries.values) {
      entry.beforeSnapshot = null;
    }

    // Trigger one rebuild so AnimatedBuilder gets inserted into the tree.
    // Subsequent frame updates are handled by AnimatedBuilder without setState.
    if (anyMoveStarted && mounted) {
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // _startMove — with spring physics (Feature 5), per-child curves (Feature 7),
  //              stagger (Feature 1), and callbacks (Feature 2)
  // ---------------------------------------------------------------------------

  void _startMove(
    AnimatedChildEntry entry,
    Offset delta, {
    Duration delay = Duration.zero,
  }) {
    // Stop any in-progress move.
    if (entry.moveController != null) {
      entry.moveCurvedAnimation?.dispose();
      entry.moveCurvedAnimation = null;
      entry.moveAnimation = null;
      _pendingDisposal.add(entry.moveController!);
      entry.moveController = null;
    }
    entry.cancelStagger();

    final controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    entry.moveController = controller;

    // Choose animation source: spring or curve.
    Animation<double> animation;
    if (widget.spring != null) {
      // Spring mode — use raw controller (SpringSimulation provides its own easing).
      animation = controller;
      entry.moveCurvedAnimation = null;
    } else {
      // Curve mode — wrap in CurvedAnimation.
      final curved = CurvedAnimation(
        parent: controller,
        curve: widget.effectiveMoveCurve,
      );
      entry.moveCurvedAnimation = curved;
      animation = curved;
    }
    entry.moveAnimation = animation;

    entry.currentTranslationOffset = delta;

    // No setState — AnimatedBuilder in _buildChild handles scoped rebuild.
    animation.addListener(() {
      entry.currentTranslationOffset = Offset.lerp(
        delta,
        Offset.zero,
        animation.value,
      )!;
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        entry.currentTranslationOffset = Offset.zero;
        // Guard: only dispose if this controller is still the active one.
        if (entry.moveController == controller) {
          entry.moveCurvedAnimation?.dispose();
          entry.moveCurvedAnimation = null;
          entry.moveAnimation = null;
          _pendingDisposal.add(controller);
          entry.moveController = null;
        }
        _decrementActiveAnimations();
        if (mounted) setState(() {});
      }
    });

    _incrementActiveAnimations();

    void doForward() {
      if (!mounted) return;
      if (widget.spring != null) {
        final springDesc = widget.spring!.toSpringDescription();
        final simulation = SpringSimulation(springDesc, 0.0, 1.0, 0.0);
        controller.animateWith(simulation);
      } else {
        controller.forward();
      }
    }

    if (delay > Duration.zero) {
      entry.staggerTimer = Timer(delay, doForward);
    } else {
      doForward();
    }
  }

  // ---------------------------------------------------------------------------
  // _startEnter — with stagger (Feature 1), per-child curves (Feature 7),
  //               and callbacks (Feature 2)
  // ---------------------------------------------------------------------------

  void _startEnter(AnimatedChildEntry entry, {Duration delay = Duration.zero}) {
    entry.state = ChildAnimationState.entering;

    if (entry.transitionController != null) {
      entry.transitionCurvedAnimation?.dispose();
      entry.transitionCurvedAnimation = null;
      _pendingDisposal.add(entry.transitionController!);
      entry.transitionController = null;
    }
    entry.cancelStagger();

    final controller = AnimationController(
      duration: widget.effectiveTransitionDuration,
      vsync: this,
    );
    entry.transitionController = controller;
    entry.transitionCurvedAnimation = CurvedAnimation(
      parent: controller,
      curve: widget.effectiveEnterCurve,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        entry.state = ChildAnimationState.idle;
        if (entry.transitionController == controller) {
          entry.transitionCurvedAnimation?.dispose();
          entry.transitionCurvedAnimation = null;
          _pendingDisposal.add(controller);
          entry.transitionController = null;
        }
        _decrementActiveAnimations();
        if (mounted) setState(() {});
      }
    });

    _incrementActiveAnimations();
    widget.onChildEnter?.call(entry.key);

    if (delay > Duration.zero) {
      entry.staggerTimer = Timer(delay, () {
        if (mounted) controller.forward();
      });
    } else {
      controller.forward();
    }
  }

  // ---------------------------------------------------------------------------
  // _startExit — with stagger (Feature 1), per-child curves (Feature 7),
  //              and callbacks (Feature 2)
  // ---------------------------------------------------------------------------

  void _startExit(AnimatedChildEntry entry, {Duration delay = Duration.zero}) {
    entry.state = ChildAnimationState.exiting;

    // Stop any in-progress move animation so the exit position offset
    // (computed in _performFlipAfterLayout) won't be overridden.
    if (entry.moveController != null) {
      entry.moveCurvedAnimation?.dispose();
      entry.moveCurvedAnimation = null;
      entry.moveAnimation = null;
      _pendingDisposal.add(entry.moveController!);
      entry.moveController = null;
    }

    if (entry.transitionController != null) {
      entry.transitionCurvedAnimation?.dispose();
      entry.transitionCurvedAnimation = null;
      _pendingDisposal.add(entry.transitionController!);
      entry.transitionController = null;
    }
    entry.cancelStagger();

    final controller = AnimationController(
      duration: widget.effectiveTransitionDuration,
      vsync: this,
    );
    entry.transitionController = controller;
    entry.transitionCurvedAnimation = CurvedAnimation(
      parent: controller,
      curve: widget.effectiveExitCurve,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        entry.state = ChildAnimationState.removed;
        // Defer removal to avoid map mutation during iteration.
        _pendingRemovals.add(entry.key);
        // Defer disposal of both controllers.
        if (entry.moveController != null) {
          entry.moveCurvedAnimation?.dispose();
          entry.moveCurvedAnimation = null;
          entry.moveAnimation = null;
          _pendingDisposal.add(entry.moveController!);
          entry.moveController = null;
        }
        if (entry.transitionController == controller) {
          entry.transitionCurvedAnimation?.dispose();
          entry.transitionCurvedAnimation = null;
          _pendingDisposal.add(controller);
          entry.transitionController = null;
        }
        _decrementActiveAnimations();
        if (mounted) setState(() {});
      }
    });

    _incrementActiveAnimations();
    widget.onChildExit?.call(entry.key);

    // Use forward 0→1 for the controller. The exit transition receives
    // a reversed animation (1→0) so opacity/scale go from visible to gone.
    if (delay > Duration.zero) {
      entry.staggerTimer = Timer(delay, () {
        if (mounted) controller.forward();
      });
    } else {
      controller.forward();
    }
  }

  /// Cancels any active transition on [entry] without disposal conflicts.
  void _cancelTransition(AnimatedChildEntry entry) {
    entry.cancelStagger();
    if (entry.transitionController != null) {
      entry.transitionController!.stop();
      entry.transitionCurvedAnimation?.dispose();
      entry.transitionCurvedAnimation = null;
      _pendingDisposal.add(entry.transitionController!);
      entry.transitionController = null;
    }
  }

  /// Disposes controllers that were deferred from status listener callbacks.
  void _flushPendingDisposals() {
    for (final controller in _pendingDisposal) {
      controller.dispose();
    }
    _pendingDisposal.clear();
  }

  /// Removes entries that were deferred from status listener callbacks
  /// to avoid map mutation during iteration.
  void _flushPendingRemovals() {
    if (_pendingRemovals.isEmpty) return;
    for (final key in _pendingRemovals) {
      _entries.remove(key);
    }
    _pendingRemovals.clear();
  }

  RenderBox? _getParentRenderBox() {
    final renderObject = _parentKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _flushPendingDisposals();
    _flushPendingRemovals();

    if (_isFirstBuild) {
      _initializeEntries();
      _isFirstBuild = false;
    }

    // Build the merged children list: current children (wrapped) + exiting children.
    final mergedChildren = <Widget>[];

    // Determine the order: follow _previousKeys for ordering, then append exiting.
    final builtKeys = <Key>{};

    for (final key in _previousKeys) {
      final entry = _entries[key];
      if (entry == null) continue;
      builtKeys.add(key);
      mergedChildren.add(_buildChild(entry));
    }

    // Add exiting children that aren't in _previousKeys.
    for (final entry in _entries.values) {
      if (!builtKeys.contains(entry.key) &&
          entry.state == ChildAnimationState.exiting) {
        mergedChildren.add(_buildChild(entry));
      }
    }

    final cloned = LayoutCloner.cloneWithChildren(widget.child, mergedChildren);

    return ClipRect(
      clipBehavior: widget.clipBehavior,
      child: KeyedSubtree(key: _parentKey, child: cloned),
    );
  }

  Widget _buildChild(AnimatedChildEntry entry) {
    // If the widget is a Positioned (inside a Stack), apply transitions to
    // the Positioned's child and re-wrap with Positioned at the outer level.
    // Positioned must be a direct child of Stack — wrapping it inside
    // Transform or ScaleTransition breaks that Flutter invariant.
    final positioned = entry.widget is Positioned
        ? entry.widget as Positioned
        : null;
    final innerWidget = positioned?.child ?? entry.widget;

    // Inner wrapper with GlobalKey for RenderBox position tracking.
    Widget child = KeyedSubtree(key: entry.globalKey, child: innerWidget);

    // Apply move transform.
    // When an active move animation exists, use AnimatedBuilder to scope
    // rebuilds to just this child's subtree (avoids full tree setState).
    if (entry.moveAnimation != null) {
      child = AnimatedBuilder(
        animation: entry.moveAnimation!,
        child: child,
        builder: (context, childWidget) {
          final offset = entry.currentTranslationOffset;
          if (offset == Offset.zero) return childWidget!;
          return Transform.translate(offset: offset, child: childWidget);
        },
      );
    } else if (entry.currentTranslationOffset != Offset.zero) {
      child = Transform.translate(
        offset: entry.currentTranslationOffset,
        child: child,
      );
    }

    // Apply enter/exit transition using stored CurvedAnimation.
    if (entry.state == ChildAnimationState.entering &&
        entry.transitionCurvedAnimation != null) {
      child = widget.effectiveEnterTransition.build(
        context,
        entry.transitionCurvedAnimation!,
        child,
      );
    } else if (entry.state == ChildAnimationState.exiting &&
        entry.transitionCurvedAnimation != null) {
      // Exit controller goes forward 0→1, but transition needs 1→0.
      // Create a reversed animation so opacity/scale animate from visible to gone.
      final reversedAnimation = ReverseAnimation(
        entry.transitionCurvedAnimation!,
      );
      child = ExcludeSemantics(
        child: IgnorePointer(
          child: widget.effectiveExitTransition.build(
            context,
            reversedAnimation,
            child,
          ),
        ),
      );
    }

    // Re-wrap with Positioned so it remains a direct child of Stack.
    if (positioned != null) {
      child = Positioned(
        left: positioned.left,
        top: positioned.top,
        right: positioned.right,
        bottom: positioned.bottom,
        width: positioned.width,
        height: positioned.height,
        child: child,
      );
    }

    // Outer wrapper keyed with a _MotionChildKey so Column/Row/Wrap can
    // properly reconcile old and new children — this prevents GlobalKey
    // conflicts when the inner nesting depth changes (e.g., idle → exiting
    // adds wrappers). Using _MotionChildKey avoids duplicating the user's key.
    return KeyedSubtree(key: _MotionChildKey(entry.key), child: child);
  }

  void _initializeEntries() {
    final children = LayoutCloner.getChildren(widget.child);
    _previousKeys = [];

    for (final child in children) {
      if (child.key == null) {
        throw ArgumentError(
          'MotionLayout: All children must have a Key. '
          'Found a ${child.runtimeType} without a key.',
        );
      }
      final key = child.key!;
      if (_previousKeys.contains(key)) {
        throw ArgumentError(
          'MotionLayout: Duplicate key found: $key. '
          'Each child must have a unique Key.',
        );
      }
      _previousKeys.add(key);
      _entries[key] = AnimatedChildEntry.idle(key: key, widget: child);
    }
  }

  @override
  void dispose() {
    for (final entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
    _pendingRemovals.clear();
    _flushPendingDisposals();
    super.dispose();
  }
}
