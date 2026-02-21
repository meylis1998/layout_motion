import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';
import 'package:layout_motion/src/internals/layout_cloner.dart';

import 'helpers/test_apps.dart';

void main() {
  group('Column/Row spacing property', () {
    test('LayoutCloner preserves Column spacing', () {
      const original = Column(
        spacing: 12.0,
        children: [SizedBox(key: ValueKey('a'))],
      );

      final cloned = LayoutCloner.cloneWithChildren(original, const [
        SizedBox(key: ValueKey('b')),
      ]);

      expect(cloned, isA<Column>());
      expect((cloned as Column).spacing, 12.0);
    });

    test('LayoutCloner preserves Row spacing', () {
      const original = Row(
        spacing: 8.0,
        children: [SizedBox(key: ValueKey('a'))],
      );

      final cloned = LayoutCloner.cloneWithChildren(original, const [
        SizedBox(key: ValueKey('b')),
      ]);

      expect(cloned, isA<Row>());
      expect((cloned as Row).spacing, 8.0);
    });

    testWidgets('Column spacing is preserved during animation', (tester) async {
      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b', 'c'], spacing: 10),
      );
      await tester.pumpAndSettle();

      final aPos = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final bPos = tester.getTopLeft(find.byKey(const ValueKey('b')));

      // With height=50 and spacing=10, b should be at a.dy + 60.
      expect(bPos.dy - aPos.dy, 60.0);

      // Reorder and verify spacing is maintained after animation.
      await tester.pumpWidget(
        const TestColumnApp(items: ['c', 'b', 'a'], spacing: 10),
      );
      await tester.pumpAndSettle();

      final cPos = tester.getTopLeft(find.byKey(const ValueKey('c')));
      final bPos2 = tester.getTopLeft(find.byKey(const ValueKey('b')));
      expect(bPos2.dy - cPos.dy, 60.0);
    });

    testWidgets('Row spacing is preserved during animation', (tester) async {
      await tester.pumpWidget(
        const TestRowApp(items: ['a', 'b', 'c'], spacing: 10),
      );
      await tester.pumpAndSettle();

      final aPos = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final bPos = tester.getTopLeft(find.byKey(const ValueKey('b')));

      // With width=100 and spacing=10, b should be at a.dx + 110.
      expect(bPos.dx - aPos.dx, 110.0);
    });
  });

  group('Duplicate key validation', () {
    testWidgets('throws ArgumentError for duplicate keys on first build', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(key: ValueKey('a'), height: 50),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('throws ArgumentError for duplicate keys on update', (
      tester,
    ) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a', 'b']));

      // Rebuild with duplicate keys.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(key: ValueKey('a'), height: 50),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });
  });

  group('Accessibility', () {
    testWidgets('exiting children are wrapped in ExcludeSemantics', (
      tester,
    ) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Remove 'b'.
      await tester.pumpWidget(const TestColumnApp(items: ['a', 'c']));
      await tester.pump(const Duration(milliseconds: 50));

      // 'b' should still be visible during exit animation.
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      // There should be an ExcludeSemantics wrapping the exiting child.
      expect(find.byType(ExcludeSemantics), findsOneWidget);

      // After animation, ExcludeSemantics is gone along with the child.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
      expect(find.byType(ExcludeSemantics), findsNothing);
    });

    testWidgets('exiting children are wrapped in IgnorePointer', (
      tester,
    ) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Remove 'b'.
      await tester.pumpWidget(const TestColumnApp(items: ['a', 'c']));
      await tester.pump(const Duration(milliseconds: 50));

      // IgnorePointer should be present for the exiting child.
      expect(find.byType(IgnorePointer), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(IgnorePointer), findsNothing);
    });
  });

  group('clipBehavior', () {
    testWidgets('clipBehavior is forwarded to ClipRect', (tester) async {
      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b'], clipBehavior: Clip.antiAlias),
      );

      final clipRect = tester.widget<ClipRect>(find.byType(ClipRect));
      expect(clipRect.clipBehavior, Clip.antiAlias);
    });

    testWidgets('default clipBehavior is Clip.hardEdge', (tester) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a', 'b']));

      final clipRect = tester.widget<ClipRect>(find.byType(ClipRect));
      expect(clipRect.clipBehavior, Clip.hardEdge);
    });
  });

  group('Toggling enabled', () {
    testWidgets(
      'switching enabled from true to false mid-animation cleans up',
      (tester) async {
        await tester.pumpWidget(const TestColumnApp(items: ['a', 'b', 'c']));
        await tester.pumpAndSettle();

        // Start a reorder animation.
        await tester.pumpWidget(const TestColumnApp(items: ['c', 'b', 'a']));
        await tester.pump(const Duration(milliseconds: 50));

        // Disable mid-animation.
        await tester.pumpWidget(
          const TestColumnApp(items: ['c', 'b', 'a'], enabled: false),
        );
        await tester.pump();

        // Should settle immediately, no lingering animations.
        await tester.pumpAndSettle(const Duration(milliseconds: 1));

        expect(find.byKey(const ValueKey('a')), findsOneWidget);
        expect(find.byKey(const ValueKey('b')), findsOneWidget);
        expect(find.byKey(const ValueKey('c')), findsOneWidget);
      },
    );
  });
}
