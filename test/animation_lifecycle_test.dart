import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_apps.dart';

void main() {
  group('Animation lifecycle stress tests', () {
    group('Controller disposal under rapid updates', () {
      testWidgets('100+ rapid add/remove cycles produce no exceptions', (
        tester,
      ) async {
        // Start with a baseline set of items.
        // Use small itemHeight (8) so many items fit without overflow.
        var items = List.generate(10, (i) => 'item-$i');
        await tester.pumpWidget(TestColumnApp(items: items, itemHeight: 8));
        await tester.pumpAndSettle();

        // Perform 100+ rapid updates alternating between add and remove.
        // Use small itemHeight (8) so many items fit without overflow.
        for (var cycle = 0; cycle < 110; cycle++) {
          if (cycle.isEven) {
            // Add items.
            items = List.generate(15 + (cycle % 5), (i) => 'item-$i');
          } else {
            // Remove items.
            items = List.generate(5 + (cycle % 3), (i) => 'item-$i');
          }
          await tester.pumpWidget(
            TestColumnApp(items: items, itemHeight: 8),
          );
          // Advance just one frame — no settling.
          await tester.pump(const Duration(milliseconds: 1));
        }

        // Verify no exceptions were thrown during rapid updates.
        expect(tester.takeException(), isNull);

        // Let everything settle.
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Dispose the widget cleanly.
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('Interrupting move with exit', () {
      testWidgets('removing a moving item mid-animation causes no crash', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd', 'e']),
        );
        await tester.pumpAndSettle();

        // Trigger a reorder so 'c' moves.
        await tester.pumpWidget(
          const TestColumnApp(items: ['e', 'd', 'c', 'b', 'a']),
        );
        // Advance partway — move animations are running.
        await tester.pump(const Duration(milliseconds: 80));

        // Now remove 'c' while it is mid-move.
        await tester.pumpWidget(
          const TestColumnApp(items: ['e', 'd', 'b', 'a']),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);

        // Let the exit animation finish.
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('c')), findsNothing);
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('e')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Interrupting exit with re-add', () {
      testWidgets('re-adding a key during exit recovers smoothly', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pumpAndSettle();

        // Remove 'b' — starts exit animation.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'c']),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // 'b' should still be visible (exit in progress).
        expect(find.byKey(const ValueKey('b')), findsOneWidget);

        // Re-add 'b' before exit completes.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);

        // Settle fully.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('rapid exit-then-re-add cycles on the same key', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pumpAndSettle();

        // Cycle 'b' in and out rapidly 10 times.
        for (var i = 0; i < 10; i++) {
          // Remove 'b'.
          await tester.pumpWidget(
            const TestColumnApp(items: ['a', 'c']),
          );
          await tester.pump(const Duration(milliseconds: 30));

          // Re-add 'b'.
          await tester.pumpWidget(
            const TestColumnApp(items: ['a', 'b', 'c']),
          );
          await tester.pump(const Duration(milliseconds: 30));
        }

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Rapid reorder cycles', () {
      testWidgets('10+ shuffles with 50ms gaps produce no crash', (
        tester,
      ) async {
        final base = ['a', 'b', 'c', 'd', 'e', 'f'];
        await tester.pumpWidget(TestColumnApp(items: base));
        await tester.pumpAndSettle();

        // Define distinct reorder permutations.
        final permutations = <List<String>>[
          ['f', 'e', 'd', 'c', 'b', 'a'],
          ['c', 'a', 'f', 'b', 'e', 'd'],
          ['b', 'd', 'f', 'a', 'c', 'e'],
          ['e', 'c', 'a', 'f', 'd', 'b'],
          ['d', 'f', 'b', 'e', 'a', 'c'],
          ['a', 'b', 'c', 'd', 'e', 'f'],
          ['f', 'd', 'b', 'a', 'c', 'e'],
          ['c', 'e', 'a', 'd', 'f', 'b'],
          ['b', 'a', 'e', 'f', 'c', 'd'],
          ['d', 'c', 'f', 'b', 'a', 'e'],
          ['e', 'f', 'd', 'c', 'a', 'b'],
          ['a', 'c', 'e', 'b', 'd', 'f'],
        ];

        for (final perm in permutations) {
          await tester.pumpWidget(TestColumnApp(items: perm));
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        // All items still present.
        for (final item in base) {
          expect(find.byKey(ValueKey(item)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    });

    group('Dispose during active animations', () {
      testWidgets('disposing widget with enter, exit, and move in flight', (
        tester,
      ) async {
        // Start with items and settle.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd']),
        );
        await tester.pumpAndSettle();

        // Trigger a mix of enter, exit, and reorder.
        await tester.pumpWidget(
          const TestColumnApp(items: ['d', 'new1', 'b', 'new2']),
        );
        // Advance partway — all animation types should be active.
        await tester.pump(const Duration(milliseconds: 80));

        // Now rip the MotionLayout out of the tree mid-animation.
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(),
          ),
        );

        // Should not throw during disposal.
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('dispose immediately after triggering animations (no pump)',
          (tester) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pumpAndSettle();

        // Trigger animation.
        await tester.pumpWidget(
          const TestColumnApp(items: ['c', 'b', 'a', 'd']),
        );
        // Do NOT pump — dispose immediately.
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(),
          ),
        );

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('Enter interrupted by new enter', () {
      testWidgets('replacing all items before enter completes', (
        tester,
      ) async {
        // Start empty.
        await tester.pumpWidget(const TestColumnApp(items: []));
        await tester.pumpAndSettle();

        // Add items — triggers enter animations.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Items are still entering — now replace all of them.
        await tester.pumpWidget(
          const TestColumnApp(items: ['x', 'y', 'z']),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);

        // New items should be present.
        expect(find.byKey(const ValueKey('x')), findsOneWidget);
        expect(find.byKey(const ValueKey('y')), findsOneWidget);
        expect(find.byKey(const ValueKey('z')), findsOneWidget);

        // Old items should be exiting.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);

        await tester.pumpAndSettle();

        // After settle, old items are gone.
        expect(find.byKey(const ValueKey('a')), findsNothing);
        expect(find.byKey(const ValueKey('b')), findsNothing);
        expect(find.byKey(const ValueKey('c')), findsNothing);

        // New items remain.
        expect(find.byKey(const ValueKey('x')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('adding item then immediately adding more before settle', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a']),
        );
        await tester.pumpAndSettle();

        // Add 'b' — enter starts.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b']),
        );
        await tester.pump(const Duration(milliseconds: 30));

        // Add 'c' and 'd' before 'b' finishes entering.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd']),
        );
        await tester.pump(const Duration(milliseconds: 30));

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
        expect(find.byKey(const ValueKey('d')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('All animation types simultaneously', () {
      testWidgets('enter, exit, and move all at once', (tester) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd', 'e']),
        );
        await tester.pumpAndSettle();

        // 'a' stays, 'b' removed (exit), 'c' moves, 'd' removed (exit),
        // 'e' moves, 'new1' and 'new2' enter.
        await tester.pumpWidget(
          const TestColumnApp(items: ['e', 'new1', 'a', 'new2', 'c']),
        );
        await tester.pump(const Duration(milliseconds: 80));

        expect(tester.takeException(), isNull);

        // All new items present.
        expect(find.byKey(const ValueKey('new1')), findsOneWidget);
        expect(find.byKey(const ValueKey('new2')), findsOneWidget);

        // Exiting items still visible mid-animation.
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('d')), findsOneWidget);

        await tester.pumpAndSettle();

        // Exiting items gone.
        expect(find.byKey(const ValueKey('b')), findsNothing);
        expect(find.byKey(const ValueKey('d')), findsNothing);

        // Remaining items present.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
        expect(find.byKey(const ValueKey('e')), findsOneWidget);
        expect(find.byKey(const ValueKey('new1')), findsOneWidget);
        expect(find.byKey(const ValueKey('new2')), findsOneWidget);

        expect(tester.takeException(), isNull);
      });

      testWidgets('multiple waves of mixed operations', (tester) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd']),
        );
        await tester.pumpAndSettle();

        // Wave 1: remove + add + reorder.
        await tester.pumpWidget(
          const TestColumnApp(items: ['d', 'x', 'a']),
        );
        await tester.pump(const Duration(milliseconds: 60));

        // Wave 2: another mixed update before wave 1 settles.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'y', 'd', 'z']),
        );
        await tester.pump(const Duration(milliseconds: 60));

        // Wave 3: yet another.
        await tester.pumpWidget(
          const TestColumnApp(items: ['z', 'a', 'w', 'd', 'y']),
        );
        await tester.pump(const Duration(milliseconds: 60));

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();

        for (final key in ['z', 'a', 'w', 'd', 'y']) {
          expect(find.byKey(ValueKey(key)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    });

    group('Duration zero with active animations', () {
      testWidgets('switching to duration=0 while animations are running', (
        tester,
      ) async {
        // Start with a normal duration.
        await tester.pumpWidget(
          const TestColumnApp(
            items: ['a', 'b', 'c'],
            duration: Duration(milliseconds: 300),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger animation (reorder + add).
        await tester.pumpWidget(
          const TestColumnApp(
            items: ['c', 'b', 'a', 'd'],
            duration: Duration(milliseconds: 300),
          ),
        );
        await tester.pump(const Duration(milliseconds: 80));

        // Now switch to zero duration mid-animation.
        await tester.pumpWidget(
          const TestColumnApp(
            items: ['c', 'b', 'a', 'd'],
            duration: Duration.zero,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
        expect(find.byKey(const ValueKey('d')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('switching from duration=0 back to normal', (
        tester,
      ) async {
        // Start with zero duration.
        await tester.pumpWidget(
          const TestColumnApp(
            items: ['a', 'b'],
            duration: Duration.zero,
          ),
        );
        await tester.pump();

        // Switch to normal duration and trigger changes.
        await tester.pumpWidget(
          const TestColumnApp(
            items: ['b', 'a', 'c'],
            duration: Duration(milliseconds: 300),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Enabled toggle during animations', () {
      testWidgets('disabling mid-animation cleans up instantly', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd']),
        );
        await tester.pumpAndSettle();

        // Trigger animations (reorder + exit + enter).
        await tester.pumpWidget(
          const TestColumnApp(items: ['d', 'new1', 'b']),
        );
        await tester.pump(const Duration(milliseconds: 80));

        // Verify animations are in progress — exiting items still visible.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);

        // Disable animations.
        await tester.pumpWidget(
          const TestColumnApp(items: ['d', 'new1', 'b'], enabled: false),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        // Exiting items should now be gone since enabled=false means instant.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('a')), findsNothing);
        expect(find.byKey(const ValueKey('c')), findsNothing);

        // Current items present.
        expect(find.byKey(const ValueKey('d')), findsOneWidget);
        expect(find.byKey(const ValueKey('new1')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('re-enabling after disable works correctly', (
        tester,
      ) async {
        // Start disabled.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b'], enabled: false),
        );
        await tester.pump();

        // Enable and make changes.
        await tester.pumpWidget(
          const TestColumnApp(items: ['b', 'a', 'c'], enabled: true),
        );
        await tester.pump(const Duration(milliseconds: 80));

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('toggling enabled rapidly does not crash', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pumpAndSettle();

        // Rapidly toggle enabled on/off with layout changes.
        for (var i = 0; i < 20; i++) {
          final enabled = i.isEven;
          final items =
              i % 3 == 0 ? ['a', 'b', 'c'] : ['c', 'b', 'a', 'item-$i'];
          await tester.pumpWidget(
            TestColumnApp(items: items, enabled: enabled),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('Pending disposal queue stress', () {
      testWidgets('many interrupted animations stress _pendingDisposal', (
        tester,
      ) async {
        // Start with items.
        await tester.pumpWidget(
          const TestColumnApp(
            items: ['a', 'b', 'c', 'd', 'e'],
            duration: Duration(milliseconds: 300),
          ),
        );
        await tester.pumpAndSettle();

        // Rapidly reorder 30 times, each interrupting the previous animation.
        // This creates many pending disposals from interrupted move controllers.
        final permutations = <List<String>>[
          ['e', 'd', 'c', 'b', 'a'],
          ['a', 'c', 'e', 'b', 'd'],
          ['d', 'b', 'e', 'c', 'a'],
          ['c', 'a', 'd', 'e', 'b'],
          ['b', 'e', 'a', 'd', 'c'],
        ];

        for (var round = 0; round < 6; round++) {
          for (final perm in permutations) {
            await tester.pumpWidget(
              TestColumnApp(
                items: perm,
                duration: const Duration(milliseconds: 300),
              ),
            );
            // Only pump 10ms — far less than the 300ms duration, so every
            // update interrupts the previous animation mid-flight.
            await tester.pump(const Duration(milliseconds: 10));
          }
        }

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        // All items still present.
        for (final item in ['a', 'b', 'c', 'd', 'e']) {
          expect(find.byKey(ValueKey(item)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('enter/exit interruptions stress disposal queue', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pumpAndSettle();

        // Rapidly cycle through different item sets to create many
        // interrupted enter and exit animations.
        final sets = <List<String>>[
          ['a', 'x'],
          ['x', 'y', 'z'],
          ['a', 'b'],
          ['b', 'c', 'd'],
          ['a'],
          ['a', 'b', 'c', 'd', 'e'],
          ['e'],
          ['a', 'b', 'c'],
          ['c', 'b'],
          ['b', 'a', 'c', 'x', 'y'],
        ];

        for (var round = 0; round < 3; round++) {
          for (final itemSet in sets) {
            await tester.pumpWidget(
              TestColumnApp(items: itemSet),
            );
            await tester.pump(const Duration(milliseconds: 15));
          }
        }

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('Additional stress scenarios', () {
      testWidgets('single item add/remove/add cycle', (tester) async {
        // Edge case: single item being added, removed, re-added rapidly.
        await tester.pumpWidget(const TestColumnApp(items: []));
        await tester.pumpAndSettle();

        await tester.pumpWidget(const TestColumnApp(items: ['solo']));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpWidget(const TestColumnApp(items: []));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpWidget(const TestColumnApp(items: ['solo']));
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('solo')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('complete list reversal during active exit', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd', 'e']),
        );
        await tester.pumpAndSettle();

        // Remove some items to trigger exits.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'c', 'e']),
        );
        await tester.pump(const Duration(milliseconds: 60));

        // While 'b' and 'd' are exiting, reverse the remaining list.
        await tester.pumpWidget(
          const TestColumnApp(items: ['e', 'c', 'a']),
        );
        await tester.pump(const Duration(milliseconds: 60));

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('e')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsNothing);
        expect(find.byKey(const ValueKey('d')), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('grow from zero to many to zero rapidly', (tester) async {
        // Use small itemHeight (8) so many items fit without overflow.
        await tester.pumpWidget(
          const TestColumnApp(items: [], itemHeight: 8),
        );
        await tester.pumpAndSettle();

        // Grow rapidly.
        for (var count = 1; count <= 20; count++) {
          final items = List.generate(count, (i) => 'item-$i');
          await tester.pumpWidget(
            TestColumnApp(items: items, itemHeight: 8),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Shrink rapidly.
        for (var count = 19; count >= 0; count--) {
          final items = List.generate(count, (i) => 'item-$i');
          await tester.pumpWidget(
            TestColumnApp(items: items, itemHeight: 8),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('interleaved adds and removes on overlapping keys', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd', 'e', 'f']),
        );
        await tester.pumpAndSettle();

        // Remove odd-indexed, add new ones.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'x', 'c', 'y', 'e', 'z']),
        );
        await tester.pump(const Duration(milliseconds: 40));

        // Remove what we just added, bring back the old ones.
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c', 'd', 'e', 'f']),
        );
        await tester.pump(const Duration(milliseconds: 40));

        // One more swap.
        await tester.pumpWidget(
          const TestColumnApp(items: ['f', 'e', 'd', 'c', 'b', 'a']),
        );
        await tester.pump(const Duration(milliseconds: 40));

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();

        for (final item in ['a', 'b', 'c', 'd', 'e', 'f']) {
          expect(find.byKey(ValueKey(item)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('dispose with only exiting children (no current children)', (
        tester,
      ) async {
        await tester.pumpWidget(
          const TestColumnApp(items: ['a', 'b', 'c']),
        );
        await tester.pumpAndSettle();

        // Remove all items — they are now exiting.
        await tester.pumpWidget(const TestColumnApp(items: []));
        await tester.pump(const Duration(milliseconds: 50));

        // Exiting items should still be visible.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);

        // Dispose the entire widget while only exiting children remain.
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(),
          ),
        );

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  });
}
