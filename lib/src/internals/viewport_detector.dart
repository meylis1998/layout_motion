import 'package:flutter/widgets.dart';

import 'layout_snapshot.dart';

/// Detects which children are visible within a scroll viewport.
///
/// Used by [ScrollAwareMotionLayout] to trigger enter animations
/// when children first scroll into view.
class ViewportDetector {
  const ViewportDetector._();

  /// Returns the keys of children whose snapshots overlap the visible
  /// viewport rectangle.
  ///
  /// The viewport is defined by [scrollOffset] (start of visible area)
  /// and [viewportExtent] (size of visible area) along the [scrollDirection].
  ///
  /// A child is considered visible when at least [visibilityThreshold]
  /// fraction of its extent along the scroll axis is within the viewport.
  /// - 0.0 = any pixel visible
  /// - 1.0 = fully visible
  static Set<Key> visibleChildren({
    required Map<Key, ChildSnapshot> snapshots,
    required double scrollOffset,
    required double viewportExtent,
    required Axis scrollDirection,
    required double visibilityThreshold,
  }) {
    final result = <Key>{};
    final viewportStart = scrollOffset;
    final viewportEnd = scrollOffset + viewportExtent;

    for (final entry in snapshots.entries) {
      final snap = entry.value;
      final double childStart;
      final double childEnd;

      if (scrollDirection == Axis.vertical) {
        childStart = snap.offset.dy;
        childEnd = snap.offset.dy + snap.size.height;
      } else {
        childStart = snap.offset.dx;
        childEnd = snap.offset.dx + snap.size.width;
      }

      final childExtent = childEnd - childStart;
      if (childExtent <= 0) continue;

      // Compute visible fraction.
      final visibleStart = childStart.clamp(viewportStart, viewportEnd);
      final visibleEnd = childEnd.clamp(viewportStart, viewportEnd);
      final visibleExtent = visibleEnd - visibleStart;
      final fraction = visibleExtent / childExtent;

      if (fraction >= visibilityThreshold) {
        result.add(entry.key);
      }
    }

    return result;
  }
}
