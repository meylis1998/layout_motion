import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('Move animation', () {
    testWidgets('reordered children apply Transform.translate mid-animation', (
      tester,
    ) async {
      // Initial layout: a, b, c stacked vertically.
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Capture initial positions.
      final aPosBefore = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final cPosBefore = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // Reorder: c, b, a (swap a and c).
      await tester.pumpWidget(const _TestApp(items: ['c', 'b', 'a']));

      // Advance partway through animation.
      await tester.pump(const Duration(milliseconds: 50));

      // Children should have Transform.translate applied during animation.
      expect(find.byType(Transform), findsWidgets);

      // After animation, children are at their final positions.
      await tester.pumpAndSettle();

      final aPosAfter = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final cPosAfter = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // a moved down (was first, now last).
      expect(aPosAfter.dy, greaterThan(aPosBefore.dy));
      // c moved up (was last, now first).
      expect(cPosAfter.dy, lessThan(cPosBefore.dy));
    });

    testWidgets('move animation completes and removes Transform', (
      tester,
    ) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Reorder.
      await tester.pumpWidget(const _TestApp(items: ['c', 'a', 'b']));

      // Mid-animation: Transform should be present.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(Transform), findsWidgets);

      // After settle: Transforms should be gone (offset is Offset.zero).
      await tester.pumpAndSettle();

      // Verify all children still present.
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('sub-pixel moves do not trigger animation', (tester) async {
      // Identical rebuild should not produce Transform.translate animations.
      await tester.pumpWidget(const _TestApp(items: ['a', 'b']));
      await tester.pumpAndSettle();

      // Rebuild with the same items — no actual position change.
      await tester.pumpWidget(const _TestApp(items: ['a', 'b']));
      await tester.pump(const Duration(milliseconds: 50));

      // Should settle immediately without transform.
      await tester.pumpAndSettle(const Duration(milliseconds: 1));
    });

    testWidgets('move animation interrupted by new reorder', (tester) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // First reorder.
      await tester.pumpWidget(const _TestApp(items: ['c', 'b', 'a']));
      await tester.pump(const Duration(milliseconds: 50));

      // Second reorder mid-animation — interrupts first.
      await tester.pumpWidget(const _TestApp(items: ['b', 'a', 'c']));
      await tester.pump(const Duration(milliseconds: 50));

      // All children still present (no crash).
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      // Completes without error.
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('move and enter work together for added items', (
      tester,
    ) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'c']));
      await tester.pumpAndSettle();

      final cPosBefore = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // Insert 'b' between 'a' and 'c' — 'c' should move down.
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));

      // New item is present.
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();

      final cPosAfter = tester.getTopLeft(find.byKey(const ValueKey('c')));
      // 'c' moved down because 'b' was inserted above it.
      expect(cPosAfter.dy, greaterThan(cPosBefore.dy));
    });

    testWidgets('move and exit work together for removed items', (
      tester,
    ) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      final cPosBefore = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // Remove 'b' — 'c' should move up.
      await tester.pumpWidget(const _TestApp(items: ['a', 'c']));

      await tester.pumpAndSettle();

      final cPosAfter = tester.getTopLeft(find.byKey(const ValueKey('c')));
      expect(cPosAfter.dy, lessThan(cPosBefore.dy));
    });

    testWidgets('rapid successive reorders complete without error', (
      tester,
    ) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c', 'd']));
      await tester.pumpAndSettle();

      // Rapid fire reorders.
      await tester.pumpWidget(const _TestApp(items: ['d', 'c', 'b', 'a']));
      await tester.pump(const Duration(milliseconds: 20));

      await tester.pumpWidget(const _TestApp(items: ['b', 'a', 'd', 'c']));
      await tester.pump(const Duration(milliseconds: 20));

      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c', 'd']));
      await tester.pump(const Duration(milliseconds: 20));

      // All should settle without error.
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
      expect(find.byKey(const ValueKey('d')), findsOneWidget);
    });

    testWidgets('Row reorder animates horizontally', (tester) async {
      await tester.pumpWidget(const _RowTestApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      final aPosBefore = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final cPosBefore = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // Swap a and c.
      await tester.pumpWidget(const _RowTestApp(items: ['c', 'b', 'a']));
      await tester.pumpAndSettle();

      final aPosAfter = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final cPosAfter = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // a moved right, c moved left.
      expect(aPosAfter.dx, greaterThan(aPosBefore.dx));
      expect(cPosAfter.dx, lessThan(cPosBefore.dx));
    });

    testWidgets('custom curve is applied to move animation', (tester) async {
      await tester.pumpWidget(
        const _TestApp(
          items: ['a', 'b', 'c'],
          curve: Curves.linear,
          duration: Duration(milliseconds: 400),
        ),
      );
      await tester.pumpAndSettle();

      final cPosBefore = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // Reorder: c, a, b.
      await tester.pumpWidget(
        const _TestApp(
          items: ['c', 'a', 'b'],
          curve: Curves.linear,
          duration: Duration(milliseconds: 400),
        ),
      );

      // At exactly halfway through a linear animation, the position should be
      // roughly halfway between before and after.
      await tester.pump(const Duration(milliseconds: 200));

      // All children present.
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      await tester.pumpAndSettle();

      final cPosAfter = tester.getTopLeft(find.byKey(const ValueKey('c')));
      // c moved up (was at index 2, now at index 0).
      expect(cPosAfter.dy, lessThan(cPosBefore.dy));
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.items,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 300),
  });

  final List<String> items;
  final Curve curve;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        duration: duration,
        curve: curve,
        child: Column(
          children: [
            for (final item in items)
              SizedBox(key: ValueKey(item), height: 50, width: 100),
          ],
        ),
      ),
    );
  }
}

class _RowTestApp extends StatelessWidget {
  const _RowTestApp({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        duration: const Duration(milliseconds: 300),
        child: Row(
          children: [
            for (final item in items)
              SizedBox(key: ValueKey(item), height: 50, width: 100),
          ],
        ),
      ),
    );
  }
}
