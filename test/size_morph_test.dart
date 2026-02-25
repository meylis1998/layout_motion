import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('Size Morphing (v0.9.0)', () {
    Widget buildApp({
      required List<String> items,
      required Map<String, bool> expanded,
      bool animateSizeChanges = true,
      double sizeChangeThreshold = 1.0,
      ValueChanged<Key>? onChildSizeChange,
      VoidCallback? onAnimationStart,
      VoidCallback? onAnimationComplete,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MotionLayout(
          duration: const Duration(milliseconds: 300),
          animateSizeChanges: animateSizeChanges,
          sizeChangeThreshold: sizeChangeThreshold,
          onChildSizeChange: onChildSizeChange,
          onAnimationStart: onAnimationStart,
          onAnimationComplete: onAnimationComplete,
          child: Column(
            children: [
              for (final item in items)
                SizedBox(
                  key: ValueKey(item),
                  height: (expanded[item] ?? false) ? 100 : 50,
                  width: 200,
                  child: Text(item),
                ),
            ],
          ),
        ),
      );
    }

    group('Size change detection', () {
      testWidgets('size increase triggers morph animation', (tester) async {
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {},
        ));

        // Expand item 'b'.
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {'b': true},
        ));

        // Mid-animation: item should be morphing.
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('b')), findsOneWidget);

        // Complete animation.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
      });

      testWidgets('size decrease triggers morph animation', (tester) async {
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {'b': true},
        ));

        // Collapse item 'b'.
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {},
        ));

        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('b')), findsOneWidget);

        await tester.pumpAndSettle();
      });

      testWidgets('below-threshold size change is not animated',
          (tester) async {
        int morphCount = 0;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MotionLayout(
              duration: const Duration(milliseconds: 300),
              animateSizeChanges: true,
              sizeChangeThreshold: 10.0,
              onChildSizeChange: (_) => morphCount++,
              child: Column(
                children: [
                  SizedBox(key: const ValueKey('a'), height: 50, width: 200),
                ],
              ),
            ),
          ),
        );

        // Change size by only 5px (below 10px threshold).
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MotionLayout(
              duration: const Duration(milliseconds: 300),
              animateSizeChanges: true,
              sizeChangeThreshold: 10.0,
              onChildSizeChange: (_) => morphCount++,
              child: Column(
                children: [
                  SizedBox(key: const ValueKey('a'), height: 55, width: 200),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(morphCount, 0);
      });
    });

    group('Callbacks', () {
      testWidgets('onChildSizeChange fires on morph', (tester) async {
        Key? morphedKey;

        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {},
          onChildSizeChange: (key) => morphedKey = key,
        ));

        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {'b': true},
          onChildSizeChange: (key) => morphedKey = key,
        ));

        await tester.pump();
        await tester.pump();
        expect(morphedKey, const ValueKey('b'));

        await tester.pumpAndSettle();
      });

      testWidgets('onAnimationStart/Complete fire for morph', (tester) async {
        int startCount = 0;
        int completeCount = 0;

        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {},
          onAnimationStart: () => startCount++,
          onAnimationComplete: () => completeCount++,
        ));

        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {'a': true},
          onAnimationStart: () => startCount++,
          onAnimationComplete: () => completeCount++,
        ));

        await tester.pump();
        await tester.pump();
        expect(startCount, greaterThan(0));

        await tester.pumpAndSettle();
        expect(completeCount, greaterThan(0));
      });
    });

    group('animateSizeChanges: false (default)', () {
      testWidgets('does not morph when disabled', (tester) async {
        int morphCount = 0;

        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {},
          animateSizeChanges: false,
          onChildSizeChange: (_) => morphCount++,
        ));

        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {'a': true},
          animateSizeChanges: false,
          onChildSizeChange: (_) => morphCount++,
        ));

        await tester.pumpAndSettle();
        expect(morphCount, 0);
      });
    });

    group('Morph + other animations', () {
      testWidgets('morph + enter simultaneously', (tester) async {
        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {},
        ));

        // Expand 'a' AND add 'c' at the same time.
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {'a': true},
        ));

        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('c')), findsOneWidget);

        await tester.pumpAndSettle();
      });

      testWidgets('morph + exit simultaneously', (tester) async {
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {},
        ));

        // Expand 'a' AND remove 'c' at the same time.
        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {'a': true},
        ));

        await tester.pump(const Duration(milliseconds: 150));
        // 'c' should still be visible (exit animation).
        expect(find.byKey(const ValueKey('c')), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('c')), findsNothing);
      });

      testWidgets('multiple items morph simultaneously', (tester) async {
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {},
        ));

        // Expand all items.
        await tester.pumpWidget(buildApp(
          items: ['a', 'b', 'c'],
          expanded: {'a': true, 'b': true, 'c': true},
        ));

        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('Morph interruption', () {
      testWidgets('re-size mid-morph starts new animation', (tester) async {
        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {},
        ));

        // Start expanding 'a'.
        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {'a': true},
        ));
        await tester.pump(const Duration(milliseconds: 100));

        // Collapse 'a' mid-morph.
        await tester.pumpWidget(buildApp(
          items: ['a', 'b'],
          expanded: {},
        ));

        await tester.pumpAndSettle();
        // Should complete without error.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
      });
    });

    group('Works with different layouts', () {
      testWidgets('morph works with Row', (tester) async {
        Widget buildRowApp({required double width}) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MotionLayout(
              duration: const Duration(milliseconds: 300),
              animateSizeChanges: true,
              child: Row(
                children: [
                  SizedBox(key: const ValueKey('a'), width: width, height: 50),
                  const SizedBox(
                      key: ValueKey('b'), width: 50, height: 50),
                ],
              ),
            ),
          );
        }

        await tester.pumpWidget(buildRowApp(width: 50));
        await tester.pumpWidget(buildRowApp(width: 100));

        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('a')), findsOneWidget);

        await tester.pumpAndSettle();
      });

      testWidgets('morph works with Wrap', (tester) async {
        Widget buildWrapApp({required double height}) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MotionLayout(
              duration: const Duration(milliseconds: 300),
              animateSizeChanges: true,
              child: Wrap(
                children: [
                  SizedBox(
                      key: const ValueKey('a'), width: 50, height: height),
                  const SizedBox(
                      key: ValueKey('b'), width: 50, height: 50),
                ],
              ),
            ),
          );
        }

        await tester.pumpWidget(buildWrapApp(height: 50));
        await tester.pumpWidget(buildWrapApp(height: 100));

        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
      });
    });
  });
}
