import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'exit_layout_behavior.dart';
import 'internals/animated_child_entry.dart';
import 'internals/child_differ.dart';
import 'internals/layout_cloner.dart';
import 'internals/layout_snapshot.dart';
import 'internals/drag_handler.dart';
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

  /// Drag handler for reorder support. Created when onReorder is non-null.
  MotionDragHandler? _dragHandler;

  /// Snapshot map captured at drag start for computing target indices.
  Map<Key, ChildSnapshot> _dragSnapshots = {};

  /// The keys in their current visual order during a drag operation.
  List<Key> _dragOrderedKeys = [];

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

    // Sync drag handler with onReorder availability.
    _syncDragHandler();

    if (!_effectiveEnabled || widget.duration == Duration.zero) {
      _handleInstantUpdate();
      return;
    }

    _handleAnimatedUpdate();
  }

  void _syncDragHandler() {
    if (widget.onReorder != null) {
      _dragHandler ??= MotionDragHandler();
    } else {
      _dragHandler?.reset();
      _dragHandler = null;
    }
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
    // In pop mode, capture absolute positions before starting exit.
    if (widget.exitLayoutBehavior == ExitLayoutBehavior.pop) {
      for (final key in diff.removed) {
        final entry = _entries[key];
        if (entry != null && entry.beforeSnapshot != null) {
          entry.exitAbsoluteOffset = entry.beforeSnapshot!.offset;
          entry.exitSize = entry.beforeSnapshot!.size;
        }
      }
    }
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
    // (Skip in pop mode — exiting children are positioned overlays.)
    if (widget.exitLayoutBehavior != ExitLayoutBehavior.pop) {
      for (final entry in _entries.values) {
        if (entry.state != ChildAnimationState.exiting) continue;
        final before = entry.beforeSnapshot;
        final after = afterSnapshots[entry.key];
        if (before == null || after == null) continue;

        final delta = before.offset - after.offset;
        entry.currentTranslationOffset = delta;
        anyMoveStarted = true;
      }
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
    widget.onChildMove?.call(entry.key);

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
      _syncDragHandler();
      _isFirstBuild = false;
    }

    // Build the merged children list.
    final mergedChildren = <Widget>[];
    final exitingOverlays = <Widget>[];
    final isPop = widget.exitLayoutBehavior == ExitLayoutBehavior.pop;

    // Determine the order: follow _previousKeys for ordering, then append exiting.
    final builtKeys = <Key>{};

    for (final key in _previousKeys) {
      final entry = _entries[key];
      if (entry == null) continue;
      builtKeys.add(key);
      mergedChildren.add(_buildChild(entry));
    }

    // Add exiting children — in pop mode, collect as positioned overlays;
    // in maintain mode, append to the cloned layout as before.
    for (final entry in _entries.values) {
      if (!builtKeys.contains(entry.key) &&
          entry.state == ChildAnimationState.exiting) {
        if (isPop && entry.exitAbsoluteOffset != null) {
          exitingOverlays.add(_buildPopExitChild(entry));
        } else {
          mergedChildren.add(_buildChild(entry));
        }
      }
    }

    final cloned = LayoutCloner.cloneWithChildren(widget.child, mergedChildren);
    Widget output = KeyedSubtree(key: _parentKey, child: cloned);

    // In pop mode, wrap in a Stack with exiting children as positioned overlays.
    if (isPop && exitingOverlays.isNotEmpty) {
      output = Stack(
        clipBehavior: Clip.none,
        children: [output, ...exitingOverlays],
      );
    }

    // Wrap in drag listener when reorder is enabled.
    if (_dragHandler != null) {
      output = _wrapWithDragListener(output);
    }

    // Render floating drag proxy during drag.
    if (_dragHandler != null && _dragHandler!.isDragging) {
      final dragEntry = _entries[_dragHandler!.draggedKey];
      if (dragEntry != null) {
        final parentRenderBox = _getParentRenderBox();
        // Build a keyless copy of the child for the drag proxy to avoid
        // duplicate keys in the widget tree.
        Widget dragProxy = _buildDragProxy(dragEntry);
        final dragSnap = _dragSnapshots[_dragHandler!.draggedKey];

        // Apply decorator or default elevation.
        if (widget.dragDecorator != null) {
          dragProxy = widget.dragDecorator!(dragProxy);
        }

        final dragOffset = parentRenderBox != null
            ? _dragHandler!.dragLocalOffset(parentRenderBox)
            : Offset.zero;

        output = Stack(
          clipBehavior: Clip.none,
          children: [
            output,
            Positioned(
              left: dragOffset.dx,
              top: dragOffset.dy,
              width: dragSnap?.size.width,
              height: dragSnap?.size.height,
              child: IgnorePointer(child: dragProxy),
            ),
          ],
        );
      }
    }

    return ClipRect(clipBehavior: widget.clipBehavior, child: output);
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

    // During drag, render a transparent placeholder for the dragged child
    // so that it maintains its space in the layout.
    final isDragged =
        _dragHandler != null &&
        _dragHandler!.isDragging &&
        entry.key == _dragHandler!.draggedKey;

    // Inner wrapper with GlobalKey for RenderBox position tracking.
    Widget child = KeyedSubtree(
      key: entry.globalKey,
      child: isDragged
          ? Opacity(opacity: 0.0, child: innerWidget)
          : innerWidget,
    );

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

    // Wrap with long-press gesture detector for drag-to-reorder.
    if (_dragHandler != null &&
        entry.state != ChildAnimationState.exiting &&
        !isDragged) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (details) {
          handleLongPressStart(details.globalPosition);
        },
        child: child,
      );
    }

    // Outer wrapper keyed with a _MotionChildKey so Column/Row/Wrap can
    // properly reconcile old and new children — this prevents GlobalKey
    // conflicts when the inner nesting depth changes (e.g., idle → exiting
    // adds wrappers). Using _MotionChildKey avoids duplicating the user's key.
    return KeyedSubtree(key: _MotionChildKey(entry.key), child: child);
  }

  /// Builds a keyless copy of a child widget for the floating drag proxy.
  /// Strips the user's key to avoid duplicate key conflicts in the tree.
  static Widget _buildDragProxy(AnimatedChildEntry entry) {
    final w = entry.widget is Positioned
        ? (entry.widget as Positioned).child
        : entry.widget;
    // Use SizedBox as a neutral wrapper that won't carry the user's key.
    return SizedBox(child: w);
  }

  /// Builds an exiting child as a positioned overlay for pop exit mode.
  Widget _buildPopExitChild(AnimatedChildEntry entry) {
    Widget child = KeyedSubtree(key: entry.globalKey, child: entry.widget);

    // Apply exit transition.
    if (entry.transitionCurvedAnimation != null) {
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

    return Positioned(
      key: _MotionChildKey(entry.key),
      left: entry.exitAbsoluteOffset!.dx,
      top: entry.exitAbsoluteOffset!.dy,
      width: entry.exitSize?.width,
      height: entry.exitSize?.height,
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Drag-to-reorder
  // ---------------------------------------------------------------------------

  Widget _wrapWithDragListener(Widget child) {
    return Listener(
      onPointerMove: _handleDragPointerMove,
      onPointerUp: _handleDragPointerUp,
      onPointerCancel: _handleDragPointerCancel,
      child: child,
    );
  }

  /// Hit-tests children to find which one was long-pressed.
  void handleLongPressStart(Offset globalPosition) {
    if (_dragHandler == null || !_effectiveEnabled) return;

    final parentRenderBox = _getParentRenderBox();
    if (parentRenderBox == null) return;

    final localPos = parentRenderBox.globalToLocal(globalPosition);

    // Capture current snapshots for all non-exiting children.
    final keyMap = <Key, GlobalKey>{};
    for (final key in _previousKeys) {
      final entry = _entries[key];
      if (entry != null && entry.state != ChildAnimationState.exiting) {
        keyMap[entry.key] = entry.globalKey;
      }
    }
    _dragSnapshots = LayoutSnapshotManager.capture(
      keyMap: keyMap,
      ancestor: parentRenderBox,
    );

    // Find the child under the pointer.
    for (int i = 0; i < _previousKeys.length; i++) {
      final key = _previousKeys[i];
      final snap = _dragSnapshots[key];
      if (snap == null) continue;

      final rect = Rect.fromLTWH(
        snap.offset.dx,
        snap.offset.dy,
        snap.size.width,
        snap.size.height,
      );
      if (rect.contains(localPos)) {
        final childLocalOffset = localPos - snap.offset;
        _dragHandler!.start(
          key: key,
          index: i,
          globalPosition: globalPosition,
          childLocalOffset: childLocalOffset,
        );
        _dragOrderedKeys = List<Key>.from(_previousKeys);

        // Capture before positions for FLIP on reorder.
        _captureBeforePositions();

        setState(() {});
        return;
      }
    }
  }

  void _handleDragPointerMove(PointerMoveEvent event) {
    if (_dragHandler == null || !_dragHandler!.isDragging) return;

    _dragHandler!.updatePosition(event.position);

    final parentRenderBox = _getParentRenderBox();
    if (parentRenderBox == null) return;

    final localPos = parentRenderBox.globalToLocal(event.position);

    // Determine layout axis.
    final isVertical = widget.child is Column;
    final isWrap = widget.child is Wrap;

    // Compute target index based on non-dragged children positions.
    // Use the current _dragSnapshots (which reflect current visual positions).
    final keysWithoutDragged = _dragOrderedKeys
        .where((k) => k != _dragHandler!.draggedKey)
        .toList();

    final newIndex = _dragHandler!.computeTargetIndex(
      localPosition: localPos,
      orderedKeys: keysWithoutDragged,
      snapshots: _dragSnapshots,
      isVertical: isVertical,
      isWrap: isWrap,
    );

    // Clamp to valid range.
    final clampedIndex = newIndex.clamp(0, _dragOrderedKeys.length - 1);

    if (clampedIndex != _dragHandler!.dragCurrentIndex) {
      // Capture before positions.
      _captureBeforePositions();

      // Reorder _dragOrderedKeys.
      final dragKey = _dragHandler!.draggedKey!;
      _dragOrderedKeys.remove(dragKey);
      _dragOrderedKeys.insert(clampedIndex, dragKey);
      _dragHandler!.dragCurrentIndex = clampedIndex;

      // Update _previousKeys to reflect the new visual order.
      _previousKeys = List<Key>.from(_dragOrderedKeys);

      // Rebuild to get new layout positions.
      setState(() {});

      // Schedule FLIP after layout.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _performDragFlip();
      });
    } else {
      // Just update the floating proxy position.
      setState(() {});
    }
  }

  /// Performs FLIP animation for non-dragged children during drag reorder.
  void _performDragFlip() {
    final parentRenderBox = _getParentRenderBox();
    if (parentRenderBox == null) return;

    final keyMap = <Key, GlobalKey>{};
    for (final entry in _entries.values) {
      if (entry.state != ChildAnimationState.removed &&
          entry.key != _dragHandler?.draggedKey) {
        keyMap[entry.key] = entry.globalKey;
      }
    }

    final afterSnapshots = LayoutSnapshotManager.capture(
      keyMap: keyMap,
      ancestor: parentRenderBox,
    );

    // Update _dragSnapshots with new positions for hit-testing.
    _dragSnapshots.addAll(afterSnapshots);

    bool anyMoveStarted = false;

    for (final key in _previousKeys) {
      if (key == _dragHandler?.draggedKey) continue;
      final entry = _entries[key];
      if (entry == null) continue;

      final before = entry.beforeSnapshot;
      final after = afterSnapshots[key];
      if (before == null || after == null) continue;

      final delta = before.offset - after.offset;
      if (delta.dx.abs() < widget.moveThreshold &&
          delta.dy.abs() < widget.moveThreshold) {
        entry.currentTranslationOffset = Offset.zero;
        continue;
      }

      _startMove(entry, delta);
      anyMoveStarted = true;
    }

    for (final entry in _entries.values) {
      entry.beforeSnapshot = null;
    }

    if (anyMoveStarted && mounted) {
      setState(() {});
    }
  }

  void _handleDragPointerUp(PointerUpEvent event) {
    _finishDrag();
  }

  void _handleDragPointerCancel(PointerCancelEvent event) {
    _cancelDrag();
  }

  void _finishDrag() {
    if (_dragHandler == null || !_dragHandler!.isDragging) return;

    final originalIndex = _dragHandler!.dragOriginalIndex;
    final finalIndex = _dragHandler!.dragCurrentIndex;

    _dragHandler!.reset();
    _dragSnapshots = {};
    _dragOrderedKeys = [];

    setState(() {});

    if (originalIndex != finalIndex) {
      widget.onReorder?.call(originalIndex, finalIndex);
    }
  }

  void _cancelDrag() {
    if (_dragHandler == null || !_dragHandler!.isDragging) return;

    // Restore original order.
    _dragHandler!.reset();
    _dragSnapshots = {};
    _dragOrderedKeys = [];

    setState(() {});
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
