import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

void main() {
  group('Exit position', () {
    testWidgets(
      'removed first item stays at its original position during exit',
      (tester) async {
        // Initial layout: A at top, B below, C at bottom.
        await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));
        await tester.pumpAndSettle();

        // Capture A's position before removal.
        final aBeforeTop = tester.getTopLeft(find.byKey(const ValueKey('a')));

        // Remove A → should animate out at its original position (top).
        await tester.pumpWidget(const _TestApp(items: ['b', 'c']));
        // Pump one frame so the post-frame FLIP callback fires.
        await tester.pump();

        // A should still be present (exit animation in progress).
        expect(find.byKey(const ValueKey('a')), findsOneWidget);

        // A's visual position should be at (or very near) its original spot,
        // NOT at the bottom of the column.
        final aDuringExit = tester.getTopLeft(find.byKey(const ValueKey('a')));
        expect(
          aDuringExit.dy,
          moreOrLessEquals(aBeforeTop.dy, epsilon: 1.0),
          reason: 'Exiting item should stay at its original Y position',
        );

        // After animation completes, A should be gone.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('a')), findsNothing);
      },
    );

    testWidgets(
      'removed middle item stays at its original position during exit',
      (tester) async {
        await tester.pumpWidget(const _TestApp(items: ['a', 'b', 'c']));
        await tester.pumpAndSettle();

        final bBeforeTop = tester.getTopLeft(find.byKey(const ValueKey('b')));

        // Remove B.
        await tester.pumpWidget(const _TestApp(items: ['a', 'c']));
        await tester.pump();

        expect(find.byKey(const ValueKey('b')), findsOneWidget);

        final bDuringExit = tester.getTopLeft(find.byKey(const ValueKey('b')));
        expect(
          bDuringExit.dy,
          moreOrLessEquals(bBeforeTop.dy, epsilon: 1.0),
          reason: 'Exiting middle item should stay at its original Y position',
        );

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('b')), findsNothing);
      },
    );

    testWidgets(
      'removed first item in Wrap stays at its original position',
      (tester) async {
        await tester.pumpWidget(const _WrapTestApp(items: ['a', 'b', 'c']));
        await tester.pumpAndSettle();

        final aBeforePos = tester.getTopLeft(find.byKey(const ValueKey('a')));

        // Remove A.
        await tester.pumpWidget(const _WrapTestApp(items: ['b', 'c']));
        await tester.pump();

        expect(find.byKey(const ValueKey('a')), findsOneWidget);

        final aDuringExit = tester.getTopLeft(find.byKey(const ValueKey('a')));
        expect(
          aDuringExit.dx,
          moreOrLessEquals(aBeforePos.dx, epsilon: 1.0),
          reason: 'Exiting item in Wrap should stay at its original X position',
        );
        expect(
          aDuringExit.dy,
          moreOrLessEquals(aBeforePos.dy, epsilon: 1.0),
          reason: 'Exiting item in Wrap should stay at its original Y position',
        );

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('a')), findsNothing);
      },
    );
  });
}

/// Test helper: Column-based MotionLayout.
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

/// Test helper: Wrap-based MotionLayout.
class _WrapTestApp extends StatelessWidget {
  const _WrapTestApp({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        duration: const Duration(milliseconds: 300),
        child: Wrap(
          children: [
            for (final item in items)
              SizedBox(key: ValueKey(item), width: 80, height: 50),
          ],
        ),
      ),
    );
  }
}
