import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('Performance', () {
    testWidgets('handles 50+ children without errors', (tester) async {
      final items = List.generate(60, (i) => 'item-$i');

      await tester.pumpWidget(_TestApp(items: items));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-59')), findsOneWidget);
    });

    testWidgets('adding many items at once completes without error', (
      tester,
    ) async {
      // Start with 10 items.
      final items = List.generate(10, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pumpAndSettle();

      // Add 40 more items at once.
      final manyItems = List.generate(50, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: manyItems));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-49')), findsOneWidget);
    });

    testWidgets('removing many items at once completes without error', (
      tester,
    ) async {
      final items = List.generate(50, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pumpAndSettle();

      // Remove all but 5 items.
      final fewItems = List.generate(5, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: fewItems));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-4')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-5')), findsNothing);
    });

    testWidgets('rapid add/remove cycles complete without error', (
      tester,
    ) async {
      var items = List.generate(20, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pumpAndSettle();

      // Cycle 1: remove half.
      items = List.generate(10, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pump(const Duration(milliseconds: 50));

      // Cycle 2: add them back plus more (interrupt exit animations).
      items = List.generate(25, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pump(const Duration(milliseconds: 50));

      // Cycle 3: remove some again mid-animation.
      items = List.generate(15, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pump(const Duration(milliseconds: 50));

      // Let everything settle.
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-14')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-15')), findsNothing);
    });

    testWidgets('large reorder settles correctly', (tester) async {
      final items = List.generate(30, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pumpAndSettle();

      // Reverse the entire list.
      final reversed = items.reversed.toList();
      await tester.pumpWidget(_TestApp(items: reversed));
      await tester.pumpAndSettle();

      // All items still present.
      for (var i = 0; i < 30; i++) {
        expect(find.byKey(ValueKey('item-$i')), findsOneWidget);
      }

      // First item (item-0) should now be at the bottom.
      final firstPos = tester.getTopLeft(find.byKey(const ValueKey('item-0')));
      final lastPos = tester.getTopLeft(find.byKey(const ValueKey('item-29')));
      expect(firstPos.dy, greaterThan(lastPos.dy));
    });

    testWidgets('simultaneous add, remove, and reorder with many items', (
      tester,
    ) async {
      final items = List.generate(20, (i) => 'item-$i');
      await tester.pumpWidget(_TestApp(items: items));
      await tester.pumpAndSettle();

      // Remove some, add new ones, reorder remaining.
      final mixed = [
        'item-19',
        'item-15',
        'new-0',
        'item-2',
        'new-1',
        'item-10',
        'item-5',
        'new-2',
        'item-0',
      ];
      await tester.pumpWidget(_TestApp(items: mixed));
      await tester.pumpAndSettle();

      // All new items present.
      expect(find.byKey(const ValueKey('new-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('new-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('new-2')), findsOneWidget);

      // Removed items gone.
      expect(find.byKey(const ValueKey('item-1')), findsNothing);
      expect(find.byKey(const ValueKey('item-3')), findsNothing);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            for (final item in items)
              SizedBox(key: ValueKey(item), height: 8, width: 100),
          ],
        ),
      ),
    );
  }
}
