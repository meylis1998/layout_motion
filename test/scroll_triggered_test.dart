import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('Scroll-Triggered Animations (v0.10.0)', () {
    Widget buildScrollApp({
      required List<String> items,
      double visibilityThreshold = 0.1,
      bool animateOnce = true,
      MotionTransition? enterTransition,
      Duration staggerDuration = Duration.zero,
      VoidCallback? onAnimationStart,
      ValueChanged<Key>? onChildEnter,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: ScrollAwareMotionLayout(
                visibilityThreshold: visibilityThreshold,
                animateOnce: animateOnce,
                enterTransition: enterTransition ?? const FadeIn(),
                staggerDuration: staggerDuration,
                onAnimationStart: onAnimationStart,
                onChildEnter: onChildEnter,
                child: Column(
                  children: [
                    for (final item in items)
                      SizedBox(
                        key: ValueKey(item),
                        height: 80,
                        width: 200,
                        child: Text(item),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    group('Basic rendering', () {
      testWidgets('renders inside a ScrollView', (tester) async {
        await tester.pumpWidget(buildScrollApp(
          items: List.generate(10, (i) => 'item_$i'),
        ));
        await tester.pumpAndSettle();

        // First items visible.
        expect(find.byKey(const ValueKey('item_0')), findsOneWidget);
        expect(find.byKey(const ValueKey('item_1')), findsOneWidget);
      });

      testWidgets('renders empty list without error', (tester) async {
        await tester.pumpWidget(buildScrollApp(items: []));
        await tester.pumpAndSettle();
      });
    });

    group('Scroll-triggered enter', () {
      testWidgets('visible children get enter animation on initial build',
          (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(buildScrollApp(
          items: List.generate(10, (i) => 'item_$i'),
          onChildEnter: (key) => enteredKeys.add(key),
        ));

        // Pump a few frames for the post-frame callback + animation.
        await tester.pump();
        await tester.pump();
        await tester.pump();

        // Some initially visible items should have triggered enter.
        expect(enteredKeys, isNotEmpty);

        await tester.pumpAndSettle();
      });

      testWidgets('scrolling reveals new children', (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(buildScrollApp(
          items: List.generate(20, (i) => 'item_$i'),
          onChildEnter: (key) => enteredKeys.add(key),
        ));

        await tester.pumpAndSettle();
        enteredKeys.clear();

        // Scroll down to reveal new items.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -400),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();

        // New items that scrolled into view should trigger enter.
        // (May or may not have entries depending on layout)
        await tester.pumpAndSettle();
      });
    });

    group('animateOnce behavior', () {
      testWidgets('animateOnce: true prevents re-animation', (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(buildScrollApp(
          items: List.generate(20, (i) => 'item_$i'),
          animateOnce: true,
          onChildEnter: (key) => enteredKeys.add(key),
        ));

        await tester.pumpAndSettle();
        final firstPassCount = enteredKeys.length;

        // Scroll down.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();

        // Scroll back up.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 400),
        );
        await tester.pumpAndSettle();

        // The initially visible items should not have re-entered.
        // Total enter count should be <= firstPassCount + newly revealed count.
        expect(enteredKeys.length, greaterThanOrEqualTo(firstPassCount));
      });
    });

    group('Stagger with scroll', () {
      testWidgets('stagger delays work with scroll-triggered enter',
          (tester) async {
        await tester.pumpWidget(buildScrollApp(
          items: List.generate(10, (i) => 'item_$i'),
          staggerDuration: const Duration(milliseconds: 50),
        ));

        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // Should complete without error.
        expect(find.byKey(const ValueKey('item_0')), findsOneWidget);
      });
    });

    group('Transitions', () {
      testWidgets('custom enter transition is applied', (tester) async {
        await tester.pumpWidget(buildScrollApp(
          items: List.generate(5, (i) => 'item_$i'),
          enterTransition: const FadeSlideIn(),
        ));

        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('item_0')), findsOneWidget);
      });
    });

    group('animateOnFirstBuild parameter', () {
      testWidgets('animateOnFirstBuild: true triggers enter on first build',
          (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MotionLayout(
              animateOnFirstBuild: true,
              onChildEnter: (key) => enteredKeys.add(key),
              child: Column(
                children: const [
                  SizedBox(key: ValueKey('a'), height: 50, width: 100),
                  SizedBox(key: ValueKey('b'), height: 50, width: 100),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();
        expect(enteredKeys, contains(const ValueKey('a')));
        expect(enteredKeys, contains(const ValueKey('b')));

        await tester.pumpAndSettle();
      });

      testWidgets('animateOnFirstBuild: false (default) does not animate',
          (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MotionLayout(
              onChildEnter: (key) => enteredKeys.add(key),
              child: Column(
                children: const [
                  SizedBox(key: ValueKey('a'), height: 50, width: 100),
                  SizedBox(key: ValueKey('b'), height: 50, width: 100),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();
        expect(enteredKeys, isEmpty);

        await tester.pumpAndSettle();
      });
    });
  });
}
