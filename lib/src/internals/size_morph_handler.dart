import 'package:flutter/widgets.dart';

import 'layout_snapshot.dart';

/// Describes a detected size change for a stable child.
class SizeMorphEntry {
  const SizeMorphEntry({
    required this.key,
    required this.beforeSize,
    required this.afterSize,
  });

  /// The user-provided key of the child that changed size.
  final Key key;

  /// The size before the layout change.
  final Size beforeSize;

  /// The size after the layout change.
  final Size afterSize;
}

/// Detects size changes for stable children (same key, different size).
///
/// Used by [MotionLayoutState] to trigger size morph animations when
/// [MotionLayout.animateSizeChanges] is true.
class SizeMorphHandler {
  const SizeMorphHandler._();

  /// Compares before and after snapshots for [stableKeys] and returns
  /// entries where the size changed beyond [sizeThreshold].
  static List<SizeMorphEntry> detectSizeChanges({
    required Map<Key, ChildSnapshot> beforeSnapshots,
    required Map<Key, ChildSnapshot> afterSnapshots,
    required Set<Key> stableKeys,
    required double sizeThreshold,
  }) {
    final results = <SizeMorphEntry>[];

    for (final key in stableKeys) {
      final before = beforeSnapshots[key];
      final after = afterSnapshots[key];
      if (before == null || after == null) continue;

      final dw = (after.size.width - before.size.width).abs();
      final dh = (after.size.height - before.size.height).abs();

      if (dw >= sizeThreshold || dh >= sizeThreshold) {
        results.add(SizeMorphEntry(
          key: key,
          beforeSize: before.size,
          afterSize: after.size,
        ));
      }
    }

    return results;
  }
}
