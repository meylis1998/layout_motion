import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('Edge cases', () {
    testWidgets('disabled MotionLayout shows changes instantly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            enabled: false,
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

      // Remove 'b' — should disappear instantly.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            enabled: false,
            child: Column(children: [SizedBox(key: ValueKey('a'), height: 50)]),
          ),
        ),
      );

      // Single pump, no settling needed.
      await tester.pump();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('zero duration acts as instant', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            duration: Duration.zero,
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(key: ValueKey('b'), height: 50),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            duration: Duration.zero,
            child: Column(children: [SizedBox(key: ValueKey('a'), height: 50)]),
          ),
        ),
      );

      await tester.pump();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('identical rebuild does not create animations', (tester) async {
      const items = ['a', 'b', 'c'];

      await tester.pumpWidget(const _TestApp(items: items));

      // Rebuild with identical items.
      await tester.pumpWidget(const _TestApp(items: items));

      // Should settle immediately since nothing changed.
      await tester.pumpAndSettle(const Duration(milliseconds: 1));

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('complete replacement of all children', (tester) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b']));

      // Replace all children.
      await tester.pumpWidget(const _TestApp(items: ['x', 'y', 'z']));

      // New children should be present.
      expect(find.byKey(const ValueKey('x')), findsOneWidget);
      expect(find.byKey(const ValueKey('y')), findsOneWidget);
      expect(find.byKey(const ValueKey('z')), findsOneWidget);

      // Old children should still be exiting.
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      // After animation, old children are gone.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('a')), findsNothing);
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('re-adding a child during exit cancels exit', (tester) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));

      // Remove 'b'.
      await tester.pumpWidget(const _TestApp(items: ['a', 'c']));

      // Mid-animation, re-add 'b'.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));

      // 'b' should still be present.
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('disposes cleanly with active animations', (tester) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b']));

      // Trigger an animation.
      await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));

      await tester.pump(const Duration(milliseconds: 50));

      // Remove the widget entirely mid-animation.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      // Should not throw.
      await tester.pumpAndSettle();
    });

    testWidgets('single child works', (tester) async {
      await tester.pumpWidget(const _TestApp(items: ['only']));

      expect(find.byKey(const ValueKey('only')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('throws ArgumentError for child without key on first build', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(height: 50), // no key
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('throws ArgumentError for child without key on update', (
      tester,
    ) async {
      await tester.pumpWidget(const _TestApp(items: ['a', 'b']));

      // Rebuild with a child missing a key.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(height: 50), // no key
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('empty children list works', (tester) async {
      await tester.pumpWidget(const _TestApp(items: []));

      await tester.pumpAndSettle();

      // Add items after starting empty.
      await tester.pumpWidget(const _TestApp(items: ['first']));

      expect(find.byKey(const ValueKey('first')), findsOneWidget);
      await tester.pumpAndSettle();
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
              SizedBox(key: ValueKey(item), height: 50, width: 100),
          ],
        ),
      ),
    );
  }
}
