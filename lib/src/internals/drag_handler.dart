import 'package:flutter/widgets.dart';

import 'layout_snapshot.dart';

/// Manages drag-to-reorder state and hit-testing logic.
///
/// Extracted from [MotionLayoutState] to keep the state class manageable.
/// This handler tracks the currently dragged child, computes target insertion
/// indices based on pointer position, and provides the drag offset for
/// rendering the floating proxy.
class MotionDragHandler {
  /// The key of the child currently being dragged, or null if not dragging.
  Key? draggedKey;

  /// The global position where the drag started.
  Offset dragStartGlobal = Offset.zero;

  /// The local offset within the dragged child where the pointer initially hit.
  /// Used to keep the child anchored to the pointer at the grab point.
  Offset dragGrabOffset = Offset.zero;

  /// The current global position of the pointer during the drag.
  Offset dragCurrentGlobal = Offset.zero;

  /// The index of the dragged child in the original order when drag started.
  int dragOriginalIndex = -1;

  /// The current insertion index where the dragged child would be placed.
  int dragCurrentIndex = -1;

  /// Whether a drag operation is currently in progress.
  bool get isDragging => draggedKey != null;

  /// The local offset of the dragged child relative to the parent widget,
  /// accounting for the initial grab point within the child.
  Offset dragLocalOffset(RenderBox parentBox) {
    if (!isDragging) return Offset.zero;
    final local = parentBox.globalToLocal(dragCurrentGlobal);
    return local - dragGrabOffset;
  }

  /// Starts a drag operation for the child at [key].
  void start({
    required Key key,
    required int index,
    required Offset globalPosition,
    required Offset childLocalOffset,
  }) {
    draggedKey = key;
    dragOriginalIndex = index;
    dragCurrentIndex = index;
    dragStartGlobal = globalPosition;
    dragCurrentGlobal = globalPosition;
    dragGrabOffset = childLocalOffset;
  }

  /// Updates the drag position.
  void updatePosition(Offset globalPosition) {
    dragCurrentGlobal = globalPosition;
  }

  /// Computes the target insertion index based on the current pointer position.
  ///
  /// For vertical layouts (Column), compares the drag Y to each child's
  /// vertical midpoint. For horizontal layouts (Row), compares drag X.
  /// For Wrap, uses 2D closest-midpoint comparison.
  int computeTargetIndex({
    required Offset localPosition,
    required List<Key> orderedKeys,
    required Map<Key, ChildSnapshot> snapshots,
    required bool isVertical,
    required bool isWrap,
  }) {
    if (orderedKeys.isEmpty) return 0;

    if (isWrap) {
      // For Wrap, find the closest child midpoint in 2D.
      double minDist = double.infinity;
      int closest = 0;
      for (int i = 0; i < orderedKeys.length; i++) {
        final snap = snapshots[orderedKeys[i]];
        if (snap == null) continue;
        final mid =
            snap.offset + Offset(snap.size.width / 2, snap.size.height / 2);
        final dist = (localPosition - mid).distanceSquared;
        if (dist < minDist) {
          minDist = dist;
          closest = i;
        }
      }
      return closest;
    }

    // For Column/Row, compare along the primary axis.
    for (int i = 0; i < orderedKeys.length; i++) {
      final snap = snapshots[orderedKeys[i]];
      if (snap == null) continue;
      final midpoint = isVertical
          ? snap.offset.dy + snap.size.height / 2
          : snap.offset.dx + snap.size.width / 2;
      final dragPos = isVertical ? localPosition.dy : localPosition.dx;
      if (dragPos < midpoint) return i;
    }
    return orderedKeys.length - 1;
  }

  /// Ends the drag and returns the final index, or null if not dragging.
  int? end() {
    if (!isDragging) return null;
    final finalIndex = dragCurrentIndex;
    reset();
    return finalIndex;
  }

  /// Resets all drag state.
  void reset() {
    draggedKey = null;
    dragStartGlobal = Offset.zero;
    dragGrabOffset = Offset.zero;
    dragCurrentGlobal = Offset.zero;
    dragOriginalIndex = -1;
    dragCurrentIndex = -1;
  }
}
