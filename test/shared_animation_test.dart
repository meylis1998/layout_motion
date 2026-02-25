import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('Shared Element Transitions (v1.1.0)', () {
    group('MotionLayoutScope', () {
      testWidgets('provides scope to descendants', (tester) async {
        late MotionLayoutScopeState scopeState;
        await tester.pumpWidget(
          MaterialApp(
            home: MotionLayoutScope(
              child: Builder(
                builder: (context) {
                  scopeState = MotionLayoutScope.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        expect(scopeState, isNotNull);
      });

      testWidgets('maybeOf returns null when no scope', (tester) async {
        MotionLayoutScopeState? scopeState;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                scopeState = MotionLayoutScope.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(scopeState, isNull);
      });

      testWidgets('disposes cleanly without active animations', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MotionLayoutScope(
              child: MotionLayoutId(
                id: 'test',
                child: Container(width: 50, height: 50, color: Colors.red),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Remove the scope — should not throw
        await tester.pumpWidget(
          const MaterialApp(home: SizedBox()),
        );
        await tester.pumpAndSettle();
      });
    });

    group('MotionLayoutId', () {
      testWidgets('renders child normally without animation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MotionLayoutScope(
              child: Center(
                child: MotionLayoutId(
                  id: 'item-1',
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('degrades gracefully without scope', (tester) async {
        // MotionLayoutId without MotionLayoutScope should not crash
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: MotionLayoutId(
                id: 'orphan',
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('unmount + remount with same id triggers overlay animation',
          (tester) async {
        bool showFirst = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState2(() => showFirst = !showFirst),
                        child: const Text('Toggle'),
                      ),
                      if (showFirst)
                        Align(
                          alignment: Alignment.topLeft,
                          child: MotionLayoutId(
                            id: 'shared',
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Colors.red,
                            ),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.bottomRight,
                          child: MotionLayoutId(
                            id: 'shared',
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger switch
        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // During animation, there should be an overlay entry (Positioned widget)
        // The real widget should be hidden (Visibility maintainSize)
        final visibilityFinder = find.byType(Visibility);
        expect(visibilityFinder, findsWidgets);

        // Let animation complete
        await tester.pumpAndSettle();

        // After animation, widget should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('no match in graveyard — widget appears normally',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MotionLayoutScope(
              child: Center(
                child: MotionLayoutId(
                  id: 'new-item',
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No overlay animation — widget is just there
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('graveyard entry expires after timeout', (tester) async {
        bool show = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  graveyardTimeout: const Duration(milliseconds: 50),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState2(() => show = !show),
                        child: const Text('Toggle'),
                      ),
                      if (show)
                        MotionLayoutId(
                          id: 'expiring',
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Remove the widget
        await tester.tap(find.text('Toggle'));
        await tester.pumpAndSettle();

        // Wait longer than graveyard timeout
        await tester.pump(const Duration(milliseconds: 200));

        // Re-add the widget — should NOT trigger animation (graveyard expired)
        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Widget should be immediately visible (no overlay hiding it)
        final visibility = tester.widgetList<Visibility>(
          find.byType(Visibility),
        );
        // All Visibility widgets should be visible
        for (final v in visibility) {
          if (v.maintainSize) {
            expect(v.visible, isTrue);
          }
        }

        await tester.pumpAndSettle();
      });

      testWidgets('multiple IDs animate simultaneously', (tester) async {
        bool showFirst = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState2(() => showFirst = !showFirst),
                        child: const Text('Toggle'),
                      ),
                      if (showFirst) ...[
                        Align(
                          alignment: Alignment.topLeft,
                          child: MotionLayoutId(
                            id: 'item-a',
                            child: Container(
                              width: 40,
                              height: 40,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: MotionLayoutId(
                            id: 'item-b',
                            child: Container(
                              width: 40,
                              height: 40,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.bottomRight,
                          child: MotionLayoutId(
                            id: 'item-a',
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: MotionLayoutId(
                            id: 'item-b',
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle
        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Both should be animating — we should see Positioned overlay entries
        // Just verify no crash and eventually settles
        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    group('MotionLayoutGroup', () {
      testWidgets('namespace isolation — same id, different groups, no animation',
          (tester) async {
        bool showInGroupA = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            setState2(() => showInGroupA = !showInGroupA),
                        child: const Text('Toggle'),
                      ),
                      MotionLayoutGroup(
                        namespace: 'group-a',
                        child: showInGroupA
                            ? MotionLayoutId(
                                id: 'shared',
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.red,
                                ),
                              )
                            : const SizedBox(),
                      ),
                      MotionLayoutGroup(
                        namespace: 'group-b',
                        child: !showInGroupA
                            ? MotionLayoutId(
                                id: 'shared',
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.blue,
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle — removes from group-a, adds to group-b
        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Different namespaces → no overlay animation
        // Widget in group-b should be immediately visible
        final visibilities = tester.widgetList<Visibility>(
          find.byType(Visibility),
        );
        for (final v in visibilities) {
          if (v.maintainSize) {
            expect(v.visible, isTrue);
          }
        }

        await tester.pumpAndSettle();
      });

      testWidgets('same namespace — same id animates', (tester) async {
        bool showFirst = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  duration: const Duration(milliseconds: 300),
                  child: MotionLayoutGroup(
                    namespace: 'shared-ns',
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              setState2(() => showFirst = !showFirst),
                          child: const Text('Toggle'),
                        ),
                        if (showFirst)
                          Align(
                            alignment: Alignment.topLeft,
                            child: MotionLayoutId(
                              id: 'item',
                              child: Container(
                                width: 50,
                                height: 50,
                                color: Colors.red,
                              ),
                            ),
                          )
                        else
                          Align(
                            alignment: Alignment.bottomRight,
                            child: MotionLayoutId(
                              id: 'item',
                              child: Container(
                                width: 100,
                                height: 100,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Should animate (same namespace) — settles without error
        await tester.pumpAndSettle();
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('maybeNamespaceOf returns null without group', (tester) async {
        Object? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = MotionLayoutGroup.maybeNamespaceOf(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, isNull);
      });

      testWidgets('maybeNamespaceOf returns namespace', (tester) async {
        Object? result;
        await tester.pumpWidget(
          MaterialApp(
            home: MotionLayoutGroup(
              namespace: 'my-ns',
              child: Builder(
                builder: (context) {
                  result = MotionLayoutGroup.maybeNamespaceOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        expect(result, equals('my-ns'));
      });
    });

    group('Spring physics', () {
      testWidgets('shared animation with spring', (tester) async {
        bool showFirst = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  duration: const Duration(milliseconds: 500),
                  spring: MotionSpring.bouncy,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState2(() => showFirst = !showFirst),
                        child: const Text('Toggle'),
                      ),
                      if (showFirst)
                        Align(
                          alignment: Alignment.topLeft,
                          child: MotionLayoutId(
                            id: 'spring-item',
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Colors.red,
                            ),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.bottomRight,
                          child: MotionLayoutId(
                            id: 'spring-item',
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Spring animation should eventually settle
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Edge cases', () {
      testWidgets('rapid toggle does not crash', (tester) async {
        bool showFirst = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState2(() => showFirst = !showFirst),
                        child: const Text('Toggle'),
                      ),
                      if (showFirst)
                        MotionLayoutId(
                          id: 'rapid',
                          child: Container(
                            width: 50,
                            height: 50,
                            color: Colors.red,
                          ),
                        )
                      else
                        MotionLayoutId(
                          id: 'rapid',
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rapidly toggle multiple times
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Toggle'));
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Should settle without crash
        await tester.pumpAndSettle();
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('scope disposal during active animation', (tester) async {
        bool showScope = true;
        bool showFirst = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                if (!showScope) return const SizedBox();
                return MotionLayoutScope(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      ElevatedButton(
                        key: const ValueKey('toggle'),
                        onPressed: () =>
                            setState2(() => showFirst = !showFirst),
                        child: const Text('Toggle'),
                      ),
                      ElevatedButton(
                        key: const ValueKey('remove'),
                        onPressed: () =>
                            setState2(() => showScope = false),
                        child: const Text('Remove'),
                      ),
                      if (showFirst)
                        Align(
                          alignment: Alignment.topLeft,
                          child: MotionLayoutId(
                            id: 'dispose-test',
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Colors.red,
                            ),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.bottomRight,
                          child: MotionLayoutId(
                            id: 'dispose-test',
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start animation
        await tester.tap(find.byKey(const ValueKey('toggle')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Remove scope mid-animation
        await tester.tap(find.byKey(const ValueKey('remove')));
        await tester.pumpAndSettle();

        // Should not throw
        expect(find.byType(MotionLayoutScope), findsNothing);
      });

      testWidgets('id change on MotionLayoutId', (tester) async {
        String currentId = 'id-a';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState2) {
                return MotionLayoutScope(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            setState2(() => currentId = 'id-b'),
                        child: const Text('Change ID'),
                      ),
                      MotionLayoutId(
                        id: currentId,
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Change ID'));
        await tester.pumpAndSettle();

        // Should not crash — id changed in-place
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('Works alongside MotionLayout', () {
      testWidgets('MotionLayoutId coexists with MotionLayout in same tree',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MotionLayoutScope(
              child: Column(
                children: [
                  // MotionLayoutId managed by scope
                  MotionLayoutId(
                    id: 'shared-item',
                    child: Container(
                      width: 80,
                      height: 40,
                      color: Colors.amber,
                    ),
                  ),
                  // MotionLayout managed separately
                  MotionLayout(
                    child: Column(
                      children: [
                        Container(
                          key: const ValueKey('a'),
                          width: 80,
                          height: 40,
                          color: Colors.cyan,
                        ),
                        Container(
                          key: const ValueKey('b'),
                          width: 80,
                          height: 40,
                          color: Colors.pink,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All three containers should render
        expect(find.byType(Container), findsNWidgets(3));
      });
    });
  });
}
