import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/src/internals/layout_cloner.dart';

void main() {
  group('LayoutCloner.cloneWithChildren', () {
    test('clones Column preserving all properties', () {
      const original = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        verticalDirection: VerticalDirection.up,
        children: [SizedBox(key: ValueKey('a'))],
      );

      final cloned = LayoutCloner.cloneWithChildren(
        original,
        const [SizedBox(key: ValueKey('b')), SizedBox(key: ValueKey('c'))],
      );

      expect(cloned, isA<Column>());
      final col = cloned as Column;
      expect(col.mainAxisAlignment, MainAxisAlignment.center);
      expect(col.mainAxisSize, MainAxisSize.min);
      expect(col.crossAxisAlignment, CrossAxisAlignment.end);
      expect(col.verticalDirection, VerticalDirection.up);
      expect(col.children, hasLength(2));
    });

    test('clones Row preserving all properties', () {
      const original = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SizedBox(key: ValueKey('a'))],
      );

      final cloned = LayoutCloner.cloneWithChildren(
        original,
        const [SizedBox(key: ValueKey('x'))],
      );

      expect(cloned, isA<Row>());
      final row = cloned as Row;
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(row.crossAxisAlignment, CrossAxisAlignment.stretch);
      expect(row.children, hasLength(1));
    });

    test('clones Wrap preserving all properties', () {
      const original = Wrap(
        direction: Axis.vertical,
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 12.0,
        runAlignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        clipBehavior: Clip.antiAlias,
        children: [SizedBox(key: ValueKey('a'))],
      );

      final cloned = LayoutCloner.cloneWithChildren(
        original,
        const [SizedBox(key: ValueKey('y'))],
      );

      expect(cloned, isA<Wrap>());
      final wrap = cloned as Wrap;
      expect(wrap.direction, Axis.vertical);
      expect(wrap.alignment, WrapAlignment.center);
      expect(wrap.spacing, 8.0);
      expect(wrap.runSpacing, 12.0);
      expect(wrap.runAlignment, WrapAlignment.end);
      expect(wrap.crossAxisAlignment, WrapCrossAlignment.center);
      expect(wrap.clipBehavior, Clip.antiAlias);
      expect(wrap.children, hasLength(1));
    });

    test('throws UnsupportedError for unsupported widget', () {
      const stack = Stack(children: []);
      expect(
        () => LayoutCloner.cloneWithChildren(stack, []),
        throwsUnsupportedError,
      );
    });
  });

  group('LayoutCloner.getChildren', () {
    test('extracts children from Column', () {
      const col = Column(children: [SizedBox(), Text('hi', textDirection: TextDirection.ltr)]);
      final children = LayoutCloner.getChildren(col);
      expect(children, hasLength(2));
    });

    test('extracts children from Row', () {
      const row = Row(children: [SizedBox()]);
      final children = LayoutCloner.getChildren(row);
      expect(children, hasLength(1));
    });

    test('extracts children from Wrap', () {
      const wrap = Wrap(children: [SizedBox(), SizedBox()]);
      final children = LayoutCloner.getChildren(wrap);
      expect(children, hasLength(2));
    });

    test('throws for unsupported widget', () {
      const stack = Stack(children: []);
      expect(() => LayoutCloner.getChildren(stack), throwsUnsupportedError);
    });
  });
}
