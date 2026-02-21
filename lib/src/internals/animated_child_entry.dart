import 'package:flutter/widgets.dart';
import 'layout_snapshot.dart';

/// The animation state of a child within [MotionLayout].
enum ChildAnimationState {
  /// The child is entering the layout (playing enter transition).
  entering,

  /// The child is present and idle (no active animation).
  idle,

  /// The child is exiting the layout (playing exit transition).
  exiting,

  /// The child is being removed after exit animation completes.
  removed,
}

/// Holds per-child state for the FLIP animation engine.
///
/// Each child tracked by [MotionLayout] has an associated entry that
/// manages its animation controllers, global key for position tracking,
/// and current animation state.
class AnimatedChildEntry {
  AnimatedChildEntry({
    required this.key,
    required this.widget,
    required this.globalKey,
  });

  /// The user-provided key identifying this child.
  final Key key;

  /// The current widget for this child.
  Widget widget;

  /// A [GlobalKey] used internally to find this child's [RenderBox]
  /// for position capture.
  final GlobalKey globalKey;

  /// Controller for the move (FLIP translate) animation.
  AnimationController? moveController;

  /// Controller for the enter/exit transition animation.
  AnimationController? transitionController;

  /// The [CurvedAnimation] wrapping [moveController].
  /// Stored so it can be disposed before its parent controller.
  CurvedAnimation? moveCurvedAnimation;

  /// The [CurvedAnimation] wrapping [transitionController].
  /// Stored so it can be disposed before its parent controller.
  CurvedAnimation? transitionCurvedAnimation;

  /// The snapshot captured before a layout change ("First" in FLIP).
  ChildSnapshot? beforeSnapshot;

  /// The current animation state of this child.
  ChildAnimationState state = ChildAnimationState.entering;

  /// The current translation offset applied by the move animation.
  /// Used for interruption handling — when a new layout change happens
  /// mid-animation, this represents the current visual offset that must
  /// be accounted for in the new "before" position.
  Offset currentTranslationOffset = Offset.zero;

  /// Whether this child is currently animating (moving or transitioning).
  bool get isAnimating =>
      (moveController?.isAnimating ?? false) ||
      (transitionController?.isAnimating ?? false);

  /// Disposes all animation controllers owned by this entry.
  /// Curved animations are disposed before their parent controllers
  /// to detach listeners before the parent is torn down.
  void dispose() {
    moveCurvedAnimation?.dispose();
    transitionCurvedAnimation?.dispose();
    moveController?.dispose();
    transitionController?.dispose();
  }

  /// Creates an idle entry with a fresh [GlobalKey].
  factory AnimatedChildEntry.idle({required Key key, required Widget widget}) {
    return AnimatedChildEntry(key: key, widget: widget, globalKey: GlobalKey())
      ..state = ChildAnimationState.idle;
  }
}
