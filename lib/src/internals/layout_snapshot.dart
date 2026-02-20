import 'package:flutter/widgets.dart';

/// A snapshot of a child's position and size relative to its parent.
class ChildSnapshot {
  const ChildSnapshot({
    required this.offset,
    required this.size,
  });

  /// Position relative to the ancestor (MotionLayout's RenderBox).
  final Offset offset;

  /// Size of the child.
  final Size size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildSnapshot &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          size == other.size;

  @override
  int get hashCode => Object.hash(offset, size);

  @override
  String toString() => 'ChildSnapshot(offset: $offset, size: $size)';
}

/// Captures layout snapshots of children identified by their [GlobalKey]s.
class LayoutSnapshotManager {
  const LayoutSnapshotManager._();

  /// Captures the current positions of all children whose [GlobalKey]s
  /// are provided, relative to [ancestor].
  ///
  /// Keys whose current context is null or not yet laid out are skipped.
  static Map<Key, ChildSnapshot> capture({
    required Map<Key, GlobalKey> keyMap,
    required RenderBox ancestor,
  }) {
    final snapshots = <Key, ChildSnapshot>{};
    for (final entry in keyMap.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final childBox = renderObject;
      final offset = childBox.localToGlobal(Offset.zero, ancestor: ancestor);
      snapshots[entry.key] = ChildSnapshot(
        offset: offset,
        size: childBox.size,
      );
    }
    return snapshots;
  }
}
