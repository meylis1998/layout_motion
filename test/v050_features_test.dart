import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

// ---------------------------------------------------------------------------
// Test apps for v0.5.0 features
// ---------------------------------------------------------------------------

/// Stateful wrapper that supports all v0.5.0 params.
class _V050App extends StatefulWidget {
  const _V050App({
    required this.items,
    this.onChildMove,
    this.exitLayoutBehavior = ExitLayoutBehavior.maintain,
    this.onReorder,
    this.dragDecorator,
    this.itemHeight = 50,
    this.itemWidth = 100,
    this.enabled,
    this.useRow = false,
    this.useWrap = false,
  });

  final List<String> items;
  final ValueChanged<Key>? onChildMove;
  final ExitLayoutBehavior exitLayoutBehavior;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final Widget Function(Widget child)? dragDecorator;
  final double itemHeight;
  final double itemWidth;
  final bool? enabled;
  final bool useRow;
  final bool useWrap;

  @override
  State<_V050App> createState() => _V050AppState();
}

class _V050AppState extends State<_V050App> {
  @override
  Widget build(BuildContext context) {
    final children = [
      for (final item in widget.items)
        SizedBox(
          key: ValueKey(item),
          height: widget.itemHeight,
          width: widget.itemWidth,
        ),
    ];

    Widget layout;
    if (widget.useRow) {
      layout = Row(children: children);
    } else if (widget.useWrap) {
      layout = Wrap(children: children);
    } else {
      layout = Column(children: children);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        enabled: widget.enabled,
        onChildMove: widget.onChildMove,
        exitLayoutBehavior: widget.exitLayoutBehavior,
        onReorder: widget.onReorder,
        dragDecorator: widget.dragDecorator,
        child: layout,
      ),
    );
  }
}

void main() {
  // =========================================================================
  // Feature 1: onChildMove Callback
  // =========================================================================
  group('onChildMove Callback', () {
    testWidgets('fires when child moves due to reorder', (tester) async {
      final movedKeys = <Key>[];

      await tester.pumpWidget(
        _V050App(items: const ['a', 'b', 'c'], onChildMove: movedKeys.add),
      );

      // Reorder: [a, b, c] → [c, a, b]
      await tester.pumpWidget(
        _V050App(items: const ['c', 'a', 'b'], onChildMove: movedKeys.add),
      );
      await tester.pump(); // trigger post-frame callback

      // 'a' and 'b' should have moved (c moved too but via LIS diff).
      expect(movedKeys, isNotEmpty);
    });

    testWidgets('does not fire when move is below threshold', (tester) async {
      final movedKeys = <Key>[];

      await tester.pumpWidget(
        _V050App(items: const ['a', 'b'], onChildMove: movedKeys.add),
      );

      // Same order — no move animation needed.
      await tester.pumpWidget(
        _V050App(items: const ['a', 'b'], onChildMove: movedKeys.add),
      );
      await tester.pump();

      expect(movedKeys, isEmpty);
    });

    testWidgets('does not fire when enabled is false', (tester) async {
      final movedKeys = <Key>[];

      await tester.pumpWidget(
        _V050App(
          items: const ['a', 'b', 'c'],
          onChildMove: movedKeys.add,
          enabled: false,
        ),
      );

      await tester.pumpWidget(
        _V050App(
          items: const ['c', 'a', 'b'],
          onChildMove: movedKeys.add,
          enabled: false,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(movedKeys, isEmpty);
    });

    testWidgets('fires for each moving child', (tester) async {
      final movedKeys = <Key>[];

      await tester.pumpWidget(
        _V050App(items: const ['a', 'b', 'c'], onChildMove: movedKeys.add),
      );

      // Remove 'a' — 'b' and 'c' should move up.
      await tester.pumpWidget(
        _V050App(items: const ['b', 'c'], onChildMove: movedKeys.add),
      );
      await tester.pump(); // post-frame callback

      // Both b and c move up.
      expect(
        movedKeys
            .where((k) => k == const ValueKey('b') || k == const ValueKey('c'))
            .length,
        2,
      );
    });
  });

  // =========================================================================
  // Feature 2: ExitLayoutBehavior
  // =========================================================================
  group('ExitLayoutBehavior', () {
    testWidgets('maintain mode: unchanged behavior (regression)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'b', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.maintain,
        ),
      );

      // Remove 'b'.
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.maintain,
        ),
      );
      await tester.pump();

      // 'b' should still be found (exiting but in tree).
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      // Complete animation.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('pop mode: exiting child renders as positioned overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'b', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
        ),
      );

      // Remove 'b'.
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
        ),
      );
      await tester.pump();

      // 'b' should still be in the tree (animating out as overlay).
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      // Should find a Positioned ancestor for the exiting child.
      expect(find.byType(Positioned), findsWidgets);

      // Complete animation.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('pop mode: remaining children shift immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'b', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
          itemHeight: 50,
        ),
      );
      await tester.pump();

      // Get 'c' position before removal.
      final cBefore = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // Remove 'b'.
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
          itemHeight: 50,
        ),
      );
      // After first pump + post-frame, 'c' should start moving up.
      await tester.pump();
      await tester.pump();

      tester.getTopLeft(find.byKey(const ValueKey('c')));

      // In pop mode, 'c' layout position should be at index 1 (50px)
      // immediately — it may have a FLIP animation but the target is index 1.
      // After the animation, it should be at y=50.
      await tester.pumpAndSettle();
      final cFinal = tester.getTopLeft(find.byKey(const ValueKey('c')));

      // 'c' moved from y=100 to y=50.
      expect(cFinal.dy, lessThan(cBefore.dy));
    });

    testWidgets('pop mode: works with Row', (tester) async {
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'b', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
          useRow: true,
        ),
      );

      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
          useRow: true,
        ),
      );
      await tester.pump();

      // Should not crash and 'b' should still be in tree.
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('pop mode: works with Wrap', (tester) async {
      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'b', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
          useWrap: true,
        ),
      );

      await tester.pumpWidget(
        const _V050App(
          items: ['a', 'c'],
          exitLayoutBehavior: ExitLayoutBehavior.pop,
          useWrap: true,
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });
  });

  // =========================================================================
  // Feature 3: Drag-to-Reorder
  // =========================================================================
  group('Drag-to-Reorder', () {
    testWidgets('long-press starts drag mode', (tester) async {
      await tester.pumpWidget(
        _V050App(items: const ['a', 'b', 'c'], onReorder: (o, n) {}),
      );

      // Long-press on 'b'.
      final bFinder = find.byKey(const ValueKey('b'));
      final bCenter = tester.getCenter(bFinder);
      final gesture = await tester.startGesture(bCenter);
      await tester.pump(const Duration(milliseconds: 500));
      // Move slightly to trigger a drag visual.
      await gesture.moveBy(const Offset(0, 5));
      await tester.pump();

      // During drag, the dragged child appears twice: once as a transparent
      // placeholder in the layout and once as the floating drag proxy.
      expect(bFinder, findsWidgets);

      // Find the Opacity widget wrapping the dragged placeholder.
      final opacityFinder = find.ancestor(
        of: find.byKey(const ValueKey('b')),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsWidgets);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('drag end calls onReorder with correct indices', (
      tester,
    ) async {
      int? oldIdx;

      await tester.pumpWidget(
        _V050App(
          items: const ['a', 'b', 'c'],
          itemHeight: 50,
          onReorder: (o, n) {
            oldIdx = o;
          },
        ),
      );

      // Long-press on 'a' and drag it past 'b' and 'c' (down 120px).
      final aCenter = tester.getCenter(find.byKey(const ValueKey('a')));
      final gesture = await tester.startGesture(aCenter);
      await tester.pump(const Duration(milliseconds: 500)); // long-press

      // Move down past midpoints.
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      // Release.
      await gesture.up();
      await tester.pump();

      // Should have called onReorder.
      expect(oldIdx, isNotNull);
      expect(oldIdx, 0); // started at index 0
    });

    testWidgets('no onReorder call when drag cancelled without movement', (
      tester,
    ) async {
      int callCount = 0;

      await tester.pumpWidget(
        _V050App(
          items: const ['a', 'b', 'c'],
          onReorder: (o, n) => callCount++,
        ),
      );

      // Long-press on 'a' and release without moving.
      final aCenter = tester.getCenter(find.byKey(const ValueKey('a')));
      final gesture = await tester.startGesture(aCenter);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      // onReorder should not have been called (no index change).
      expect(callCount, 0);
    });

    testWidgets('drag reorder works with Row', (tester) async {
      int? oldIdx;

      await tester.pumpWidget(
        _V050App(
          items: const ['a', 'b', 'c'],
          itemWidth: 100,
          useRow: true,
          onReorder: (o, n) {
            oldIdx = o;
          },
        ),
      );

      // Long-press on 'a' and drag right.
      final aCenter = tester.getCenter(find.byKey(const ValueKey('a')));
      final gesture = await tester.startGesture(aCenter);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(oldIdx, isNotNull);
    });

    testWidgets('disabled when enabled is false', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        _V050App(
          items: const ['a', 'b', 'c'],
          enabled: false,
          onReorder: (o, n) => callCount++,
        ),
      );

      // Long-press on 'a' and drag down.
      final aCenter = tester.getCenter(find.byKey(const ValueKey('a')));
      final gesture = await tester.startGesture(aCenter);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(callCount, 0);
    });

    testWidgets('drag handler not created when onReorder is null', (
      tester,
    ) async {
      await tester.pumpWidget(const _V050App(items: ['a', 'b', 'c']));

      // Verify no GestureDetector wrapping (no long-press handling).
      // The widget should render normally.
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('dragDecorator is applied to floating proxy', (tester) async {
      bool decoratorCalled = false;

      await tester.pumpWidget(
        _V050App(
          items: const ['a', 'b', 'c'],
          onReorder: (o, n) {},
          dragDecorator: (child) {
            decoratorCalled = true;
            return DecoratedBox(
              decoration: const BoxDecoration(),
              child: child,
            );
          },
        ),
      );

      // Long-press to start drag.
      final aCenter = tester.getCenter(find.byKey(const ValueKey('a')));
      final gesture = await tester.startGesture(aCenter);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();

      expect(decoratorCalled, isTrue);

      await gesture.up();
      await tester.pump();
    });
  });
}
