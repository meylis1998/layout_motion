import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('MotionGridView (v1.0.0)', () {
    group('Children mode', () {
      testWidgets('renders children in a scrollable grid', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                width: 400,
                child: MotionGridView(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  children: [
                    for (int i = 0; i < 10; i++)
                      SizedBox(
                        key: ValueKey('item_$i'),
                        child: Text('Item $i'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('item_0')), findsOneWidget);
        expect(find.byKey(const ValueKey('item_1')), findsOneWidget);
      });

      testWidgets('renders empty grid without error', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                width: 400,
                child: MotionGridView(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  children: const [],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      testWidgets('item add triggers enter animation', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                width: 400,
                child: MotionGridView(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  children: [
                    for (int i = 0; i < 4; i++)
                      SizedBox(
                        key: ValueKey('item_$i'),
                        child: Text('Item $i'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Add item_4.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                width: 400,
                child: MotionGridView(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  children: [
                    for (int i = 0; i < 5; i++)
                      SizedBox(
                        key: ValueKey('item_$i'),
                        child: Text('Item $i'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const ValueKey('item_4')), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('item remove triggers exit animation', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                width: 400,
                child: MotionGridView(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  children: [
                    for (int i = 0; i < 4; i++)
                      SizedBox(
                        key: ValueKey('item_$i'),
                        height: 50,
                        child: Text('Item $i'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Remove item_1.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                width: 400,
                child: MotionGridView(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  children: [
                    for (int i = 0; i < 4; i++)
                      if (i != 1)
                        SizedBox(
                          key: ValueKey('item_$i'),
                          height: 50,
                          child: Text('Item $i'),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('item_1')), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('item_1')), findsNothing);
      });
    });

    group('Builder mode', () {
      testWidgets('renders items from builder', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                width: 400,
                child: MotionGridView.builder(
                  itemCount: 8,
                  keyBuilder: (i) => ValueKey('item_$i'),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index) => SizedBox(
                    key: ValueKey('item_$index'),
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 1'), findsOneWidget);
      });

      testWidgets('removing items triggers exit animation', (tester) async {
        final items = List.generate(4, (i) => 'item_$i');
        late StateSetter setOuterState;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: StatefulBuilder(
                builder: (context, setState) {
                  setOuterState = setState;
                  return SizedBox(
                    height: 400,
                    width: 400,
                    child: MotionGridView.builder(
                      itemCount: items.length,
                      keyBuilder: (i) => ValueKey(items[i]),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      itemBuilder: (context, index) => SizedBox(
                        key: ValueKey(items[index]),
                        child: Text(items[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('item_2'), findsOneWidget);

        // Remove item_2.
        setOuterState(() {
          items.removeAt(2);
        });

        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('item_2'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('item_2'), findsNothing);
      });

      testWidgets('initial items do not animate', (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                width: 400,
                child: MotionGridView.builder(
                  itemCount: 4,
                  keyBuilder: (i) => ValueKey('item_$i'),
                  onChildEnter: (key) => enteredKeys.add(key),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index) => SizedBox(
                    key: ValueKey('item_$index'),
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(enteredKeys, isEmpty);
      });

      testWidgets('renders empty builder without error', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                width: 400,
                child: MotionGridView.builder(
                  itemCount: 0,
                  keyBuilder: (i) => ValueKey('item_$i'),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index) => SizedBox(
                    key: ValueKey('item_$index'),
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      testWidgets('adding items triggers enter animation', (tester) async {
        final items = List.generate(2, (i) => 'item_$i');
        late StateSetter setOuterState;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: StatefulBuilder(
                builder: (context, setState) {
                  setOuterState = setState;
                  return SizedBox(
                    height: 400,
                    width: 400,
                    child: MotionGridView.builder(
                      itemCount: items.length,
                      keyBuilder: (i) => ValueKey(items[i]),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      itemBuilder: (context, index) => SizedBox(
                        key: ValueKey(items[index]),
                        child: Text(items[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Add item_2.
        setOuterState(() {
          items.add('item_2');
        });

        await tester.pump();
        await tester.pump();
        expect(find.text('item_2'), findsOneWidget);
        await tester.pumpAndSettle();
      });
    });
  });
}
