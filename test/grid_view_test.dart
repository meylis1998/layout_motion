import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';
import 'package:layout_motion/src/internals/layout_cloner.dart';

import 'helpers/test_apps.dart';

void main() {
  group('GridView support (v0.8.0)', () {
    group('Basic rendering', () {
      testWidgets('renders GridView inside MotionLayout', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c', 'd', 'e', 'f']),
        );

        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
        expect(find.byKey(const ValueKey('d')), findsOneWidget);
        expect(find.byKey(const ValueKey('e')), findsOneWidget);
        expect(find.byKey(const ValueKey('f')), findsOneWidget);
      });

      testWidgets('renders empty GridView without error', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: []),
        );

        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('renders single item GridView', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: ['a']),
        );

        expect(find.byKey(const ValueKey('a')), findsOneWidget);
      });
    });

    group('Add/remove FLIP animations', () {
      testWidgets('adding items triggers enter animation', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c']),
        );

        // Add items.
        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c', 'd', 'e']),
        );

        // Mid-animation: new items should exist.
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('d')), findsOneWidget);
        expect(find.byKey(const ValueKey('e')), findsOneWidget);

        // Complete animation.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('d')), findsOneWidget);
        expect(find.byKey(const ValueKey('e')), findsOneWidget);
      });

      testWidgets('removing items triggers exit animation', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c', 'd', 'e', 'f']),
        );

        // Remove items.
        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c']),
        );

        // Mid-animation: exiting items still visible.
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('d')), findsOneWidget);

        // Complete animation: exiting items gone.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('d')), findsNothing);
        expect(find.byKey(const ValueKey('e')), findsNothing);
        expect(find.byKey(const ValueKey('f')), findsNothing);
      });

      testWidgets('reorder triggers FLIP move animation', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c', 'd', 'e', 'f']),
        );

        // Reorder: move 'f' to front.
        await tester.pumpWidget(
          const TestGridApp(items: ['f', 'a', 'b', 'c', 'd', 'e']),
        );

        // Mid-animation.
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('f')), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('f')), findsOneWidget);
      });
    });

    group('Dual-axis stagger', () {
      testWidgets('stagger from first cascades diagonally', (tester) async {
        int startCount = 0;
        await tester.pumpWidget(
          TestGridApp(
            items: const [],
            staggerDuration: const Duration(milliseconds: 50),
            staggerFrom: StaggerFrom.first,
            onAnimationStart: () => startCount++,
          ),
        );

        // Add a 3x2 grid (6 items).
        await tester.pumpWidget(
          TestGridApp(
            items: const ['a', 'b', 'c', 'd', 'e', 'f'],
            staggerDuration: const Duration(milliseconds: 50),
            staggerFrom: StaggerFrom.first,
            onAnimationStart: () => startCount++,
          ),
        );

        // Animation should start.
        await tester.pump(const Duration(milliseconds: 10));
        expect(startCount, greaterThan(0));

        await tester.pumpAndSettle();
      });

      testWidgets('stagger from last cascades from bottom-right',
          (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: []),
        );

        await tester.pumpWidget(
          const TestGridApp(
            items: ['a', 'b', 'c', 'd', 'e', 'f'],
            staggerDuration: Duration(milliseconds: 50),
            staggerFrom: StaggerFrom.last,
          ),
        );

        await tester.pumpAndSettle();
        // Verify all items rendered.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('f')), findsOneWidget);
      });

      testWidgets('stagger from center cascades from center outward',
          (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: []),
        );

        await tester.pumpWidget(
          const TestGridApp(
            items: ['a', 'b', 'c', 'd', 'e', 'f'],
            staggerDuration: Duration(milliseconds: 50),
            staggerFrom: StaggerFrom.center,
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('f')), findsOneWidget);
      });
    });

    group('GridView.builder throws', () {
      testWidgets('throws UnsupportedError for GridView.builder',
          (tester) async {
        expect(
          () => LayoutCloner.getChildren(
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 5,
              itemBuilder: (context, index) =>
                  SizedBox(key: ValueKey(index)),
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('Layout cloner', () {
      testWidgets('clones GridView.count preserving crossAxisCount',
          (tester) async {
        final original = GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(key: ValueKey('a')),
          ],
        );

        final cloned = LayoutCloner.cloneWithChildren(original, [
          const SizedBox(key: ValueKey('b')),
          const SizedBox(key: ValueKey('c')),
        ]);

        expect(cloned, isA<GridView>());
        final gridCloned = cloned as GridView;
        expect(gridCloned.gridDelegate,
            isA<SliverGridDelegateWithFixedCrossAxisCount>());
        final delegate = gridCloned.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, 4);
      });

      testWidgets('clones GridView.extent preserving maxCrossAxisExtent',
          (tester) async {
        final original = GridView.extent(
          maxCrossAxisExtent: 150,
          children: [
            const SizedBox(key: ValueKey('a')),
          ],
        );

        final cloned = LayoutCloner.cloneWithChildren(original, [
          const SizedBox(key: ValueKey('b')),
        ]);

        expect(cloned, isA<GridView>());
        final gridCloned = cloned as GridView;
        expect(gridCloned.gridDelegate,
            isA<SliverGridDelegateWithMaxCrossAxisExtent>());
        final delegate = gridCloned.gridDelegate
            as SliverGridDelegateWithMaxCrossAxisExtent;
        expect(delegate.maxCrossAxisExtent, 150);
      });

      testWidgets('getChildren extracts children from GridView',
          (tester) async {
        final grid = GridView.count(
          crossAxisCount: 2,
          children: const [
            SizedBox(key: ValueKey('a')),
            SizedBox(key: ValueKey('b')),
            SizedBox(key: ValueKey('c')),
          ],
        );

        final children = LayoutCloner.getChildren(grid);
        expect(children.length, 3);
        expect(children[0].key, const ValueKey('a'));
        expect(children[1].key, const ValueKey('b'));
        expect(children[2].key, const ValueKey('c'));
      });
    });

    group('Drag-to-reorder in grid', () {
      testWidgets('onReorder callback is supported with GridView',
          (tester) async {
        // Verify that MotionLayout with GridView and onReorder doesn't crash.
        // The drag handler is instantiated and the layout renders correctly.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MotionLayout(
              duration: const Duration(milliseconds: 300),
              onReorder: (o, n) {},
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final item in ['a', 'b', 'c', 'd', 'e', 'f'])
                    SizedBox(
                      key: ValueKey(item),
                      height: 50,
                      width: 50,
                    ),
                ],
              ),
            ),
          ),
        );

        // All items should render.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('f')), findsOneWidget);

        // Each item should be wrapped in a GestureDetector for long-press.
        expect(find.byType(GestureDetector), findsNWidgets(6));
      });
    });

    group('Spring physics with GridView', () {
      testWidgets('spring move animations work in grid', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(
            items: ['a', 'b', 'c', 'd', 'e', 'f'],
            spring: MotionSpring.bouncy,
          ),
        );

        // Reorder items.
        await tester.pumpWidget(
          const TestGridApp(
            items: ['f', 'e', 'd', 'c', 'b', 'a'],
            spring: MotionSpring.bouncy,
          ),
        );

        await tester.pump(const Duration(milliseconds: 150));
        // Items should be animating.
        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('f')), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('Transitions with GridView', () {
      testWidgets('custom enter/exit transitions work', (tester) async {
        await tester.pumpWidget(
          const TestGridApp(
            items: ['a', 'b', 'c'],
            enterTransition: FadeScaleIn(),
            exitTransition: FadeScaleOut(),
          ),
        );

        await tester.pumpWidget(
          const TestGridApp(
            items: ['a', 'b', 'c', 'd', 'e'],
            enterTransition: FadeScaleIn(),
            exitTransition: FadeScaleOut(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('d')), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('Performance', () {
      testWidgets('30-cell grid with rapid mutations', (tester) async {
        final items = List.generate(30, (i) => 'item_$i');
        await tester.pumpWidget(TestGridApp(items: items));

        // Rapidly add/remove/reorder.
        for (int cycle = 0; cycle < 10; cycle++) {
          final modified = List<String>.from(items);
          if (cycle.isEven) {
            modified.removeAt(0);
            modified.add('new_$cycle');
          } else {
            modified.insert(0, modified.removeLast());
          }
          await tester.pumpWidget(TestGridApp(items: modified));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        // Should complete without error.
      });
    });

    group('Disabled state', () {
      testWidgets('disabled GridView applies changes instantly',
          (tester) async {
        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c'], enabled: false),
        );

        await tester.pumpWidget(
          const TestGridApp(items: ['a', 'b', 'c', 'd'], enabled: false),
        );

        // No animation needed.
        expect(find.byKey(const ValueKey('d')), findsOneWidget);
      });
    });
  });
}
