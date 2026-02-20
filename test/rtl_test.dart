import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('RTL support', () {
    testWidgets('Column renders correctly in RTL', (tester) async {
      await tester.pumpWidget(const _RtlTestApp(items: ['a', 'b', 'c']));

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('Row renders correctly in RTL', (tester) async {
      await tester.pumpWidget(const _RtlRowTestApp(items: ['a', 'b', 'c']));

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      // In RTL, 'a' (first child) should be on the right side.
      final aPos = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final cPos = tester.getTopLeft(find.byKey(const ValueKey('c')));
      expect(aPos.dx, greaterThan(cPos.dx));
    });

    testWidgets('Row reorder animates correctly in RTL', (tester) async {
      await tester.pumpWidget(const _RtlRowTestApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      final aPosBefore = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final cPosBefore = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // Swap a and c.
      await tester.pumpWidget(const _RtlRowTestApp(items: ['c', 'b', 'a']));
      await tester.pumpAndSettle();

      final aPosAfter = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final cPosAfter = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // In RTL: 'a' was first (rightmost), now last (leftmost) → moved left.
      expect(aPosAfter.dx, lessThan(aPosBefore.dx));
      // 'c' was last (leftmost), now first (rightmost) → moved right.
      expect(cPosAfter.dx, greaterThan(cPosBefore.dx));
    });

    testWidgets('enter transition works in RTL', (tester) async {
      await tester.pumpWidget(const _RtlTestApp(items: ['a', 'b']));
      await tester.pumpAndSettle();

      // Add item.
      await tester.pumpWidget(const _RtlTestApp(items: ['a', 'b', 'c']));

      expect(find.byKey(const ValueKey('c')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('exit transition works in RTL', (tester) async {
      await tester.pumpWidget(const _RtlTestApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Remove item.
      await tester.pumpWidget(const _RtlTestApp(items: ['a', 'c']));

      // Still visible during exit animation.
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('Wrap reflow works in RTL', (tester) async {
      await tester.pumpWidget(
        const _RtlWrapTestApp(items: ['a', 'b', 'c', 'd']),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('d')), findsOneWidget);

      // Remove an item to trigger reflow.
      await tester.pumpWidget(const _RtlWrapTestApp(items: ['a', 'c', 'd']));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
      expect(find.byKey(const ValueKey('d')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });
  });
}

class _RtlTestApp extends StatelessWidget {
  const _RtlTestApp({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MotionLayout(
        duration: const Duration(milliseconds: 300),
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

class _RtlRowTestApp extends StatelessWidget {
  const _RtlRowTestApp({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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

class _RtlWrapTestApp extends StatelessWidget {
  const _RtlWrapTestApp({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MotionLayout(
        duration: const Duration(milliseconds: 300),
        child: Wrap(
          children: [
            for (final item in items)
              SizedBox(key: ValueKey(item), height: 50, width: 100),
          ],
        ),
      ),
    );
  }
}
