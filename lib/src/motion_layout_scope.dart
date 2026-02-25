import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'internals/shared_animation_overlay.dart';
import 'motion_spring.dart';
import 'transitions/motion_transition.dart';

/// A registration entry in the shared layout registry.
class _LayoutIdRegistration {
  _LayoutIdRegistration({
    required this.globalKey,
    required this.child,
  });

  final GlobalKey globalKey;
  final Widget child;
}

/// A snapshot stored in the graveyard when a [MotionLayoutId] unmounts.
class _LayoutIdSnapshot {
  _LayoutIdSnapshot({
    required this.rect,
    required this.child,
    required this.timer,
  });

  /// Global position and size at the time of unmount.
  final Rect rect;

  /// The widget that was being displayed.
  final Widget child;

  /// Cleanup timer — removes the entry if no match within the timeout.
  final Timer timer;
}

/// An active shared animation.
class _SharedAnimation {
  _SharedAnimation({
    required this.controller,
    required this.entry,
    required this.targetKey,
  });

  final AnimationController controller;
  final OverlayEntry entry;
  final (Object?, Object) targetKey;
}

/// Coordinates shared element transitions across the widget tree.
///
/// Wrap a subtree with [MotionLayoutScope] and mark widgets with
/// [MotionLayoutId]. When a widget with a given id unmounts and another
/// with the same id mounts, an overlay animation smoothly transitions
/// between the two positions.
///
/// {@tool snippet}
/// ```dart
/// MotionLayoutScope(
///   duration: const Duration(milliseconds: 400),
///   curve: Curves.easeOutCubic,
///   child: Scaffold(
///     body: showGrid
///       ? GridView(children: [
///           for (final item in items)
///             MotionLayoutId(id: 'item-${item.id}', child: ItemCard(item)),
///         ])
///       : ListView(children: [
///           for (final item in items)
///             MotionLayoutId(id: 'item-${item.id}', child: ItemTile(item)),
///         ]),
///   ),
/// )
/// ```
/// {@end-tool}
class MotionLayoutScope extends StatefulWidget {
  const MotionLayoutScope({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.spring,
    this.transition,
    this.graveyardTimeout = const Duration(milliseconds: 100),
  });

  /// The subtree within which shared layout animations are coordinated.
  final Widget child;

  /// Duration of the shared element transition animation.
  final Duration duration;

  /// Curve applied to the shared element transition.
  final Curve curve;

  /// Optional spring physics. When set, overrides [curve] for the transition.
  final MotionSpring? spring;

  /// Optional transition applied to the content cross-fade.
  /// If null, a simple opacity cross-fade is used.
  final MotionTransition? transition;

  /// How long a graveyard entry persists before expiring.
  /// Increase if route transitions are slow.
  final Duration graveyardTimeout;

  /// Returns the nearest [MotionLayoutScopeState].
  /// Throws if no [MotionLayoutScope] ancestor exists.
  static MotionLayoutScopeState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No MotionLayoutScope found in widget tree');
    return state!;
  }

  /// Returns the nearest [MotionLayoutScopeState], or null.
  static MotionLayoutScopeState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MotionLayoutScopeState>();
  }

  @override
  State<MotionLayoutScope> createState() => MotionLayoutScopeState();
}

/// State for [MotionLayoutScope]. Manages the registry and graveyard.
class MotionLayoutScopeState extends State<MotionLayoutScope>
    with TickerProviderStateMixin {
  /// Active registrations: (namespace, id) -> registration.
  final Map<(Object?, Object), _LayoutIdRegistration> _registry = {};

  /// Graveyard: (namespace, id) -> snapshot from recently unmounted widget.
  final Map<(Object?, Object), _LayoutIdSnapshot> _graveyard = {};

  /// Active overlay animations.
  final List<_SharedAnimation> _activeAnimations = [];

  /// Hidden keys — widgets hidden while their overlay proxy animates.
  final Set<(Object?, Object)> _hiddenIds = {};

  /// Whether a given id is currently hidden (overlay animation in progress).
  bool isHidden(Object? namespace, Object id) =>
      _hiddenIds.contains((namespace, id));

  /// Register a [MotionLayoutId] widget.
  void register(Object? namespace, Object id, GlobalKey key, Widget child) {
    final compositeKey = (namespace, id);
    _registry[compositeKey] = _LayoutIdRegistration(
      globalKey: key,
      child: child,
    );
  }

  /// Unregister a [MotionLayoutId] widget and store its snapshot in the
  /// graveyard for potential matching.
  void unregister(Object? namespace, Object id, GlobalKey key) {
    final compositeKey = (namespace, id);
    final registration = _registry.remove(compositeKey);
    if (registration == null || registration.globalKey != key) return;

    // Capture global position
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final globalOffset = renderObject.localToGlobal(Offset.zero);
    final rect = globalOffset & renderObject.size;

    // Store in graveyard with expiration timer
    _graveyard[compositeKey]?.timer.cancel();
    _graveyard[compositeKey] = _LayoutIdSnapshot(
      rect: rect,
      child: registration.child,
      timer: Timer(widget.graveyardTimeout, () {
        _graveyard.remove(compositeKey);
      }),
    );
  }

  /// Called after the first layout of a newly mounted [MotionLayoutId].
  /// Checks the graveyard for a match and starts the overlay animation.
  void onFirstLayout(Object? namespace, Object id, GlobalKey key) {
    final compositeKey = (namespace, id);
    final snapshot = _graveyard.remove(compositeKey);
    if (snapshot == null) return;

    snapshot.timer.cancel();

    // Capture the new widget's global position
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final toGlobalOffset = renderObject.localToGlobal(Offset.zero);
    final toRect = toGlobalOffset & renderObject.size;
    final fromRect = snapshot.rect;

    // Skip if rects are identical (no visible movement)
    if ((fromRect.left - toRect.left).abs() < 0.5 &&
        (fromRect.top - toRect.top).abs() < 0.5 &&
        (fromRect.width - toRect.width).abs() < 0.5 &&
        (fromRect.height - toRect.height).abs() < 0.5) {
      return;
    }

    // Get the current registration for the new child widget
    final registration = _registry[compositeKey];
    if (registration == null) return;

    // Hide the real widget while the overlay animates
    _hiddenIds.add(compositeKey);

    // Create animation controller
    final controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // If spring is set, use spring simulation
    if (widget.spring != null) {
      final spring = widget.spring!;
      final simulation = SpringSimulation(
        spring.toSpringDescription(),
        0.0,
        1.0,
        0.0,
      );
      controller.animateWith(simulation);
    }

    // Create overlay entry
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) {
      _hiddenIds.remove(compositeKey);
      controller.dispose();
      return;
    }

    final overlayEntry = SharedAnimationOverlay.create(
      fromRect: fromRect,
      toRect: toRect,
      fromChild: snapshot.child,
      toChild: registration.child,
      controller: controller,
      curve: widget.curve,
      transition: widget.transition,
    );

    overlayState.insert(overlayEntry);

    final animation = _SharedAnimation(
      controller: controller,
      entry: overlayEntry,
      targetKey: compositeKey,
    );
    _activeAnimations.add(animation);

    // Trigger rebuild to hide the real widget
    if (mounted) setState(() {});

    // Start animation (if not already started by spring)
    if (widget.spring == null) {
      controller.forward();
    }

    // Clean up when animation completes
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        overlayEntry.remove();
        _activeAnimations.remove(animation);
        _hiddenIds.remove(compositeKey);
        controller.dispose();
        if (mounted) setState(() {});
      }
    });
  }

  /// Cancel any active animation for the given id.
  void cancelAnimation(Object? namespace, Object id) {
    final compositeKey = (namespace, id);
    _activeAnimations.removeWhere((anim) {
      if (anim.targetKey == compositeKey) {
        anim.entry.remove();
        anim.controller.dispose();
        _hiddenIds.remove(compositeKey);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    // Clean up all graveyard timers
    for (final entry in _graveyard.values) {
      entry.timer.cancel();
    }
    _graveyard.clear();

    // Clean up all active animations
    for (final animation in _activeAnimations) {
      animation.entry.remove();
      animation.controller.dispose();
    }
    _activeAnimations.clear();
    _hiddenIds.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
