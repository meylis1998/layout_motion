import 'dart:collection';

import 'package:flutter/foundation.dart';

/// The result of diffing two ordered key lists.
///
/// Each key from the union of old and new lists is classified into exactly
/// one of the four sets: [added], [removed], [moved], or [stable].
class DiffResult {
  const DiffResult({
    required this.added,
    required this.removed,
    required this.moved,
    required this.stable,
  });

  /// Keys present in the new list but not in the old list.
  final Set<Key> added;

  /// Keys present in the old list but not in the new list.
  final Set<Key> removed;

  /// Keys present in both lists whose relative order changed (not part of the
  /// longest increasing subsequence of old indices).
  final Set<Key> moved;

  /// Keys present in both lists whose relative order is preserved (part of the
  /// longest increasing subsequence of old indices).
  final Set<Key> stable;

  @override
  String toString() =>
      'DiffResult(added: $added, removed: $removed, moved: $moved, stable: $stable)';
}

/// A stateless utility that computes a key-based set diff between two ordered
/// lists of [Key]s, using a Longest Increasing Subsequence (LIS) to minimize
/// the number of keys classified as "moved".
class ChildDiffer {
  const ChildDiffer._();

  /// Computes the [DiffResult] between [oldKeys] and [newKeys].
  ///
  /// The algorithm:
  /// 1. Build a map from old keys to their indices in the old list.
  /// 2. Identify shared keys (present in both lists).
  /// 3. Collect the old-list indices of shared keys, ordered by their
  ///    appearance in [newKeys].
  /// 4. Run LIS on those old indices. Keys whose old indices are part of
  ///    the LIS are "stable"; the remaining shared keys are "moved".
  /// 5. Keys only in [newKeys] are "added".
  /// 6. Keys only in [oldKeys] are "removed".
  static DiffResult diff(List<Key> oldKeys, List<Key> newKeys) {
    // Step 1 – Map each old key to its index.
    final LinkedHashMap<Key, int> oldKeyIndex = LinkedHashMap<Key, int>();
    for (int i = 0; i < oldKeys.length; i++) {
      oldKeyIndex[oldKeys[i]] = i;
    }

    // Build a set of new keys for O(1) lookup.
    final Set<Key> newKeySet = LinkedHashSet<Key>.from(newKeys);

    // Step 6 – Keys only in old.
    final Set<Key> removed = <Key>{};
    for (final Key key in oldKeys) {
      if (!newKeySet.contains(key)) {
        removed.add(key);
      }
    }

    // Steps 2–3 – Walk the new list; separate added keys from shared keys,
    // and collect the old indices of shared keys in new-list order.
    final Set<Key> added = <Key>{};
    final List<Key> sharedKeysInNewOrder = <Key>[];
    final List<int> oldIndicesOfShared = <int>[];

    for (final Key key in newKeys) {
      final int? oldIndex = oldKeyIndex[key];
      if (oldIndex == null) {
        // Step 5 – Key only in new.
        added.add(key);
      } else {
        sharedKeysInNewOrder.add(key);
        oldIndicesOfShared.add(oldIndex);
      }
    }

    // Step 4 – Run LIS on oldIndicesOfShared.
    final List<int> lisPositions =
        _longestIncreasingSubsequence(oldIndicesOfShared);

    // Convert LIS positions to a set for O(1) membership testing.
    final Set<int> lisPositionSet = HashSet<int>.from(lisPositions);

    // Classify shared keys as stable or moved.
    final Set<Key> stable = <Key>{};
    final Set<Key> moved = <Key>{};

    for (int i = 0; i < sharedKeysInNewOrder.length; i++) {
      if (lisPositionSet.contains(i)) {
        stable.add(sharedKeysInNewOrder[i]);
      } else {
        moved.add(sharedKeysInNewOrder[i]);
      }
    }

    return DiffResult(
      added: added,
      removed: removed,
      moved: moved,
      stable: stable,
    );
  }

  /// Returns indices into [values] that form a longest strictly increasing
  /// subsequence.
  ///
  /// Uses the patience-sorting / binary-search approach for O(n log n) time.
  ///
  /// The algorithm maintains:
  /// - `tails`: the smallest tail element of all increasing subsequences of
  ///   each length found so far.
  /// - `predecessors`: for back-tracking the actual subsequence.
  /// - `tailIndices`: the index in [values] of each element stored in `tails`.
  static List<int> _longestIncreasingSubsequence(List<int> values) {
    final int n = values.length;
    if (n == 0) {
      return const <int>[];
    }

    // tails[i] holds the smallest tail value of all increasing subsequences
    // of length i + 1 found so far.
    final List<int> tails = <int>[];

    // tailIndices[i] holds the index in `values` of the element stored in
    // tails[i].
    final List<int> tailIndices = <int>[];

    // predecessors[i] holds the index in `values` of the element that
    // precedes values[i] in the best subsequence ending at values[i].
    final List<int> predecessors = List<int>.filled(n, -1);

    for (int i = 0; i < n; i++) {
      final int value = values[i];

      // Binary search for the left-most position in `tails` where
      // tails[pos] >= value.
      int lo = 0;
      int hi = tails.length;
      while (lo < hi) {
        final int mid = (lo + hi) >>> 1;
        if (tails[mid] < value) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }

      // Extend or replace.
      if (lo == tails.length) {
        tails.add(value);
        tailIndices.add(i);
      } else {
        tails[lo] = value;
        tailIndices[lo] = i;
      }

      // Record predecessor.
      if (lo > 0) {
        predecessors[i] = tailIndices[lo - 1];
      }
    }

    // Back-track to reconstruct the subsequence indices.
    final int lisLength = tails.length;
    final List<int> result = List<int>.filled(lisLength, 0);
    int k = tailIndices[lisLength - 1];
    for (int i = lisLength - 1; i >= 0; i--) {
      result[i] = k;
      k = predecessors[k];
    }

    return result;
  }
}
