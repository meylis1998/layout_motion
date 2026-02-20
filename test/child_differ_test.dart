import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layout_motion/src/internals/child_differ.dart';

/// Helper to create a [ValueKey<String>] from a short label.
Key _k(String label) => ValueKey<String>(label);

/// Helper to create a list of [ValueKey<String>]s from labels.
List<Key> _keys(List<String> labels) => labels.map(_k).toList();

void main() {
  group('ChildDiffer.diff', () {
    test('empty old list, non-empty new → all added', () {
      final DiffResult result = ChildDiffer.diff(
        <Key>[],
        _keys(<String>['a', 'b', 'c']),
      );

      expect(result.added, equals(<Key>{_k('a'), _k('b'), _k('c')}));
      expect(result.removed, isEmpty);
      expect(result.moved, isEmpty);
      expect(result.stable, isEmpty);
    });

    test('non-empty old, empty new → all removed', () {
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c']),
        <Key>[],
      );

      expect(result.added, isEmpty);
      expect(result.removed, equals(<Key>{_k('a'), _k('b'), _k('c')}));
      expect(result.moved, isEmpty);
      expect(result.stable, isEmpty);
    });

    test('both empty → everything empty', () {
      final DiffResult result = ChildDiffer.diff(<Key>[], <Key>[]);

      expect(result.added, isEmpty);
      expect(result.removed, isEmpty);
      expect(result.moved, isEmpty);
      expect(result.stable, isEmpty);
    });

    test('same lists → all stable, nothing else', () {
      final List<Key> keys = _keys(<String>['a', 'b', 'c', 'd']);
      final DiffResult result = ChildDiffer.diff(keys, List<Key>.from(keys));

      expect(result.added, isEmpty);
      expect(result.removed, isEmpty);
      expect(result.moved, isEmpty);
      expect(result.stable, equals(<Key>{_k('a'), _k('b'), _k('c'), _k('d')}));
    });

    test('complete replacement → all old removed, all new added', () {
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c']),
        _keys(<String>['x', 'y', 'z']),
      );

      expect(result.added, equals(<Key>{_k('x'), _k('y'), _k('z')}));
      expect(result.removed, equals(<Key>{_k('a'), _k('b'), _k('c')}));
      expect(result.moved, isEmpty);
      expect(result.stable, isEmpty);
    });

    test('reorder (reverse) → LIS determines minimal moves', () {
      // Old: a b c d   (indices 0 1 2 3)
      // New: d c b a
      //
      // Shared keys in new order: d c b a → old indices: 3 2 1 0
      // LIS of [3, 2, 1, 0] has length 1 (any single element).
      // So 1 key is stable, 3 are moved.
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c', 'd']),
        _keys(<String>['d', 'c', 'b', 'a']),
      );

      expect(result.added, isEmpty);
      expect(result.removed, isEmpty);
      expect(result.stable.length, equals(1));
      expect(result.moved.length, equals(3));
      // The union of stable + moved must be the full set.
      expect(
        result.stable.union(result.moved),
        equals(<Key>{_k('a'), _k('b'), _k('c'), _k('d')}),
      );
    });

    test('add items to middle → existing stay stable, new are added', () {
      // Old: a b c
      // New: a x b y c
      //
      // Shared: a b c → old indices in new order: 0 1 2
      // LIS of [0, 1, 2] = all → all stable.
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c']),
        _keys(<String>['a', 'x', 'b', 'y', 'c']),
      );

      expect(result.added, equals(<Key>{_k('x'), _k('y')}));
      expect(result.removed, isEmpty);
      expect(result.moved, isEmpty);
      expect(result.stable, equals(<Key>{_k('a'), _k('b'), _k('c')}));
    });

    test('remove items → removed reported, rest stable', () {
      // Old: a b c d e
      // New: a c e
      //
      // Shared: a c e → old indices: 0 2 4
      // LIS of [0, 2, 4] = all → all stable.
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c', 'd', 'e']),
        _keys(<String>['a', 'c', 'e']),
      );

      expect(result.added, isEmpty);
      expect(result.removed, equals(<Key>{_k('b'), _k('d')}));
      expect(result.moved, isEmpty);
      expect(result.stable, equals(<Key>{_k('a'), _k('c'), _k('e')}));
    });

    test('complex mix of add, remove, and move', () {
      // Old: a b c d e   (indices 0 1 2 3 4)
      // New: f c a d g
      //
      // Removed (only in old): b, e
      // Added   (only in new): f, g
      // Shared  (in new order): c a d → old indices: 2 0 3
      //
      // LIS of [2, 0, 3]:
      //   - 2 → tails=[2]
      //   - 0 → tails=[0] (replaces 2)
      //   - 3 → tails=[0, 3]
      //   LIS length 2. One valid LIS is indices 1,2 in the shared list → (a, d)
      //   or indices 0,2 → (c, d). The algorithm picks (a, d) because:
      //     After processing: tailIndices point to a=1, d=2.
      //     Back-track: result = [1, 2] → keys a, d.
      //   So stable = {a, d}, moved = {c}.
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c', 'd', 'e']),
        _keys(<String>['f', 'c', 'a', 'd', 'g']),
      );

      expect(result.added, equals(<Key>{_k('f'), _k('g')}));
      expect(result.removed, equals(<Key>{_k('b'), _k('e')}));
      expect(result.stable.length, equals(2));
      expect(result.moved.length, equals(1));
      expect(
        result.stable.union(result.moved),
        equals(<Key>{_k('a'), _k('c'), _k('d')}),
      );
      // The LIS picks old-indices subsequence [0, 3] → keys a, d.
      expect(result.stable, equals(<Key>{_k('a'), _k('d')}));
      expect(result.moved, equals(<Key>{_k('c')}));
    });

    test('single element lists', () {
      // Same single element.
      DiffResult result = ChildDiffer.diff(
        _keys(<String>['a']),
        _keys(<String>['a']),
      );
      expect(result.stable, equals(<Key>{_k('a')}));
      expect(result.added, isEmpty);
      expect(result.removed, isEmpty);
      expect(result.moved, isEmpty);

      // Different single elements.
      result = ChildDiffer.diff(_keys(<String>['a']), _keys(<String>['b']));
      expect(result.removed, equals(<Key>{_k('a')}));
      expect(result.added, equals(<Key>{_k('b')}));
      expect(result.stable, isEmpty);
      expect(result.moved, isEmpty);
    });

    test('move one element to the front', () {
      // Old: a b c d e   (indices 0 1 2 3 4)
      // New: e a b c d
      //
      // Shared: e a b c d → old indices: 4 0 1 2 3
      // LIS of [4, 0, 1, 2, 3] → [0, 1, 2, 3] (length 4) → keys a b c d.
      // So e is moved, a b c d are stable.
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c', 'd', 'e']),
        _keys(<String>['e', 'a', 'b', 'c', 'd']),
      );

      expect(result.added, isEmpty);
      expect(result.removed, isEmpty);
      expect(result.stable, equals(<Key>{_k('a'), _k('b'), _k('c'), _k('d')}));
      expect(result.moved, equals(<Key>{_k('e')}));
    });

    test('swap two elements', () {
      // Old: a b c   (indices 0 1 2)
      // New: c b a
      //
      // Shared: c b a → old indices: 2 1 0
      // LIS of [2, 1, 0] → length 1, one element stable, two moved.
      final DiffResult result = ChildDiffer.diff(
        _keys(<String>['a', 'b', 'c']),
        _keys(<String>['c', 'b', 'a']),
      );

      expect(result.added, isEmpty);
      expect(result.removed, isEmpty);
      expect(result.stable.length, equals(1));
      expect(result.moved.length, equals(2));
    });

    test('all sets are mutually exclusive and cover all keys', () {
      final List<Key> oldKeys = _keys(<String>['a', 'b', 'c', 'd', 'e']);
      final List<Key> newKeys = _keys(<String>['b', 'f', 'd', 'a', 'g']);

      final DiffResult result = ChildDiffer.diff(oldKeys, newKeys);

      // All old keys should be in removed or stable or moved.
      final Set<Key> oldSet = oldKeys.toSet();
      final Set<Key> newSet = newKeys.toSet();

      expect(
        result.removed.union(result.stable).union(result.moved),
        equals(oldSet),
      );
      // All new keys should be in added or stable or moved.
      expect(
        result.added.union(result.stable).union(result.moved),
        equals(newSet),
      );
      // No overlaps between the four sets.
      expect(result.added.intersection(result.removed), isEmpty);
      expect(result.added.intersection(result.moved), isEmpty);
      expect(result.added.intersection(result.stable), isEmpty);
      expect(result.removed.intersection(result.moved), isEmpty);
      expect(result.removed.intersection(result.stable), isEmpty);
      expect(result.moved.intersection(result.stable), isEmpty);
    });
  });
}
