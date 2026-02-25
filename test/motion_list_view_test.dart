import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('MotionListView (v1.0.0)', () {
    group('Children mode', () {
      testWidgets('renders children inside a scrollable list', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                child: MotionListView(
                  children: [
                    for (int i = 0; i < 10; i++)
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

        expect(find.byKey(const ValueKey('item_0')), findsOneWidget);
        expect(find.byKey(const ValueKey('item_1')), findsOneWidget);
      });

      testWidgets('scrolling reveals items with enter animation',
          (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                child: MotionListView(
                  onChildEnter: (key) => enteredKeys.add(key),
                  children: [
                    for (int i = 0; i < 20; i++)
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
        enteredKeys.clear();

        // Scroll down to reveal new items.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();
      });

      testWidgets('renders empty list without error', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                child: MotionListView(children: const []),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      testWidgets('horizontal scroll direction uses Row', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                width: 200,
                height: 100,
                child: MotionListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < 10; i++)
                      SizedBox(
                        key: ValueKey('item_$i'),
                        width: 50,
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
        expect(find.byType(Row), findsOneWidget);
      });

      testWidgets('item add triggers enter animation', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                child: MotionListView(
                  children: [
                    for (int i = 0; i < 5; i++)
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

        // Add item_5.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                child: MotionListView(
                  children: [
                    for (int i = 0; i < 6; i++)
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
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const ValueKey('item_5')), findsOneWidget);
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
                child: MotionListView(
                  children: [
                    for (int i = 0; i < 5; i++)
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

        // Remove item_2.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 400,
                child: MotionListView(
                  children: [
                    for (int i = 0; i < 5; i++)
                      if (i != 2)
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
        // Mid-animation: item_2 should still be visible (exit animation).
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byKey(const ValueKey('item_2')), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('item_2')), findsNothing);
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
                height: 200,
                child: MotionListView.builder(
                  itemCount: 10,
                  keyBuilder: (i) => ValueKey('item_$i'),
                  itemBuilder: (context, index) => SizedBox(
                    key: ValueKey('item_$index'),
                    height: 50,
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

      testWidgets('scrolling triggers enter animation for new items',
          (tester) async {
        final enteredKeys = <Key>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                child: MotionListView.builder(
                  itemCount: 50,
                  keyBuilder: (i) => ValueKey('item_$i'),
                  onChildEnter: (key) => enteredKeys.add(key),
                  itemBuilder: (context, index) => SizedBox(
                    key: ValueKey('item_$index'),
                    height: 50,
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Initially visible items should not trigger enter.
        expect(enteredKeys, isEmpty);

        // Scroll down to reveal new items.
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        // New items should have triggered enter.
        expect(enteredKeys, isNotEmpty);
      });

      testWidgets('removing items triggers exit animation', (tester) async {
        final items = List.generate(5, (i) => 'item_$i');
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
                    child: MotionListView.builder(
                      itemCount: items.length,
                      keyBuilder: (i) => ValueKey(items[i]),
                      itemBuilder: (context, index) => SizedBox(
                        key: ValueKey(items[index]),
                        height: 50,
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

        // Mid-animation: item_2 should still be visible (exit animation).
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
                height: 200,
                child: MotionListView.builder(
                  itemCount: 5,
                  keyBuilder: (i) => ValueKey('item_$i'),
                  onChildEnter: (key) => enteredKeys.add(key),
                  itemBuilder: (context, index) => SizedBox(
                    key: ValueKey('item_$index'),
                    height: 50,
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

      testWidgets('adding items triggers enter animation', (tester) async {
        final items = List.generate(3, (i) => 'item_$i');
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
                    child: MotionListView.builder(
                      itemCount: items.length,
                      keyBuilder: (i) => ValueKey(items[i]),
                      itemBuilder: (context, index) => SizedBox(
                        key: ValueKey(items[index]),
                        height: 50,
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

        // Add item_3.
        setOuterState(() {
          items.add('item_3');
        });

        await tester.pump();
        await tester.pump();

        expect(find.text('item_3'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('renders empty builder without error', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox(
                height: 200,
                child: MotionListView.builder(
                  itemCount: 0,
                  keyBuilder: (i) => ValueKey('item_$i'),
                  itemBuilder: (context, index) => SizedBox(
                    key: ValueKey('item_$index'),
                    height: 50,
                    child: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      testWidgets('onChildExit callback fires on removal', (tester) async {
        final exitedKeys = <Key>[];
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
                    child: MotionListView.builder(
                      itemCount: items.length,
                      keyBuilder: (i) => ValueKey(items[i]),
                      onChildExit: (key) => exitedKeys.add(key),
                      itemBuilder: (context, index) => SizedBox(
                        key: ValueKey(items[index]),
                        height: 50,
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

        setOuterState(() {
          items.removeAt(1); // Remove item_1
        });

        await tester.pumpAndSettle();
        expect(exitedKeys, contains(const ValueKey('item_1')));
      });
    });
  });
}
