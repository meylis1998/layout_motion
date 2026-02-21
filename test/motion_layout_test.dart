import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('MotionLayout', () {
    testWidgets('renders children in a Column', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(key: ValueKey('b'), height: 50),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('renders children in a Row', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Row(
              children: [
                SizedBox(key: ValueKey('x'), width: 50),
                SizedBox(key: ValueKey('y'), width: 50),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('x')), findsOneWidget);
      expect(find.byKey(const ValueKey('y')), findsOneWidget);
    });

    testWidgets('renders children in a Wrap', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Wrap(
              children: [
                SizedBox(key: ValueKey('1'), width: 50, height: 50),
                SizedBox(key: ValueKey('2'), width: 50, height: 50),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('1')), findsOneWidget);
      expect(find.byKey(const ValueKey('2')), findsOneWidget);
    });

    testWidgets('renders children in a Stack', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Stack(
              children: [
                SizedBox(key: ValueKey('s1'), width: 50, height: 50),
                SizedBox(key: ValueKey('s2'), width: 50, height: 50),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('s1')), findsOneWidget);
      expect(find.byKey(const ValueKey('s2')), findsOneWidget);
    });

    testWidgets('adding a child triggers enter animation', (tester) async {
      final items = <String>['a', 'b'];

      await tester.pumpWidget(_TestApp(items: List.of(items)));

      // Add a new item.
      items.add('c');
      await tester.pumpWidget(_TestApp(items: List.of(items)));

      // The new child should be present.
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      // Pump to advance animation.
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      // Complete animation.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('removing a child triggers exit animation', (tester) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));

      // Remove 'b'.
      await tester.pumpWidget(const _TestApp(items: ['a', 'c']));

      // 'b' should still be visible during exit animation.
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      // After animation completes, 'b' should be gone.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('reordering children animates positions', (tester) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));

      // Reorder.
      await tester.pumpWidget(const _TestApp(items: ['c', 'a', 'b']));

      // All children should still be present.
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      // Let animations complete.
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('uses custom enter and exit transitions', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            enterTransition: SlideIn(offset: Offset(1, 0)),
            exitTransition: ScaleOut(scale: 0.5),
            child: Column(children: [SizedBox(key: ValueKey('a'), height: 50)]),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('default transitions are FadeIn and FadeOut', (tester) async {
      const motionLayout = MotionLayout(child: Column(children: []));

      expect(motionLayout.effectiveEnterTransition, isA<FadeIn>());
      expect(motionLayout.effectiveExitTransition, isA<FadeOut>());
    });
  });
}

/// Test helper widget that wraps a list of string IDs in a MotionLayout Column.
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
              SizedBox(key: ValueKey(item), height: 50, width: 100),
          ],
        ),
      ),
    );
  }
}
