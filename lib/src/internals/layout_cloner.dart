import 'package:flutter/widgets.dart';

/// Clones a layout widget (Column, Row, or Wrap) replacing its children
/// with a new set of children while preserving all layout properties.
///
/// This is used by [MotionLayout] to inject exiting children (kept alive
/// during their exit animation) alongside the current children.
class LayoutCloner {
  const LayoutCloner._();

  /// Returns a new widget of the same type as [original] but with
  /// [newChildren] instead of the original children.
  ///
  /// Supports [Column], [Row], and [Wrap]. Throws [UnsupportedError]
  /// for other widget types.
  static Widget cloneWithChildren(Widget original, List<Widget> newChildren) {
    if (original is Column) {
      return Column(
        key: original.key,
        mainAxisAlignment: original.mainAxisAlignment,
        mainAxisSize: original.mainAxisSize,
        crossAxisAlignment: original.crossAxisAlignment,
        textDirection: original.textDirection,
        verticalDirection: original.verticalDirection,
        textBaseline: original.textBaseline,
        children: newChildren,
      );
    }

    if (original is Row) {
      return Row(
        key: original.key,
        mainAxisAlignment: original.mainAxisAlignment,
        mainAxisSize: original.mainAxisSize,
        crossAxisAlignment: original.crossAxisAlignment,
        textDirection: original.textDirection,
        verticalDirection: original.verticalDirection,
        textBaseline: original.textBaseline,
        children: newChildren,
      );
    }

    if (original is Wrap) {
      return Wrap(
        key: original.key,
        direction: original.direction,
        alignment: original.alignment,
        spacing: original.spacing,
        runAlignment: original.runAlignment,
        runSpacing: original.runSpacing,
        crossAxisAlignment: original.crossAxisAlignment,
        textDirection: original.textDirection,
        verticalDirection: original.verticalDirection,
        clipBehavior: original.clipBehavior,
        children: newChildren,
      );
    }

    throw UnsupportedError(
      'MotionLayout does not support ${original.runtimeType}. '
      'Supported types: Column, Row, Wrap.',
    );
  }

  /// Extracts the children list from a supported layout widget.
  ///
  /// Returns the children of [Column], [Row], or [Wrap].
  /// Throws [UnsupportedError] for other widget types.
  static List<Widget> getChildren(Widget widget) {
    if (widget is Flex) {
      return widget.children;
    }
    if (widget is Wrap) {
      return widget.children;
    }
    throw UnsupportedError(
      'MotionLayout does not support ${widget.runtimeType}. '
      'Supported types: Column, Row, Wrap.',
    );
  }
}
