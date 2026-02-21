import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/src/internals/layout_snapshot.dart';

void main() {
  group('ChildSnapshot', () {
    test('equality', () {
      const a = ChildSnapshot(offset: Offset(10, 20), size: Size(100, 50));
      const b = ChildSnapshot(offset: Offset(10, 20), size: Size(100, 50));
      const c = ChildSnapshot(offset: Offset(30, 40), size: Size(100, 50));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('hashCode differs for different snapshots', () {
      const a = ChildSnapshot(offset: Offset(10, 20), size: Size(100, 50));
      const b = ChildSnapshot(offset: Offset(30, 40), size: Size(100, 50));
      const c = ChildSnapshot(offset: Offset(10, 20), size: Size(200, 60));

      expect(a.hashCode, isNot(equals(b.hashCode)));
      expect(a.hashCode, isNot(equals(c.hashCode)));
    });

    test('toString', () {
      const snapshot = ChildSnapshot(
        offset: Offset(10, 20),
        size: Size(100, 50),
      );
      expect(
        snapshot.toString(),
        'ChildSnapshot(offset: Offset(10.0, 20.0), size: Size(100.0, 50.0))',
      );
    });
  });

  group('LayoutSnapshotManager', () {
    test('capture returns empty map for empty keyMap', () {
      // We need a RenderBox ancestor for the call - use a widget test
    });

    testWidgets('capture returns empty map for empty input', (tester) async {
      final parentKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: parentKey, width: 200, height: 200),
        ),
      );

      final parentBox =
          parentKey.currentContext!.findRenderObject() as RenderBox;
      final result = LayoutSnapshotManager.capture(
        keyMap: {},
        ancestor: parentBox,
      );
      expect(result, isEmpty);
    });

    testWidgets('capture skips keys with null context', (tester) async {
      final parentKey = GlobalKey();
      final orphanKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: parentKey, width: 200, height: 200),
        ),
      );

      final parentBox =
          parentKey.currentContext!.findRenderObject() as RenderBox;
      final result = LayoutSnapshotManager.capture(
        keyMap: {const ValueKey('orphan'): orphanKey},
        ancestor: parentBox,
      );
      expect(result, isEmpty);
    });

    testWidgets('capture records correct positions', (tester) async {
      final parentKey = GlobalKey();
      final childKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            key: parentKey,
            width: 300,
            height: 300,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(key: childKey, width: 100, height: 50),
            ),
          ),
        ),
      );

      final parentBox =
          parentKey.currentContext!.findRenderObject() as RenderBox;
      final result = LayoutSnapshotManager.capture(
        keyMap: {const ValueKey('child'): childKey},
        ancestor: parentBox,
      );

      expect(result, hasLength(1));
      final snapshot = result[const ValueKey('child')]!;
      expect(snapshot.size, const Size(100, 50));
      expect(snapshot.offset, const Offset(0, 0));
    });
  });
}
