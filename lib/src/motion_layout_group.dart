import 'package:flutter/widgets.dart';

/// Namespaces [MotionLayoutId] widgets into independent animation contexts.
///
/// Two [MotionLayoutId] widgets with the same `id` will only animate between
/// each other if they share the same namespace (or both have no namespace).
///
/// {@tool snippet}
/// ```dart
/// MotionLayoutScope(
///   child: Column(children: [
///     MotionLayoutGroup(
///       namespace: 'favorites',
///       child: Row(children: [
///         for (final fav in favorites)
///           MotionLayoutId(id: fav.id, child: FavChip(fav)),
///       ]),
///     ),
///     MotionLayoutGroup(
///       namespace: 'all',
///       child: ListView(children: [
///         for (final item in all)
///           MotionLayoutId(id: item.id, child: ItemTile(item)),
///       ]),
///     ),
///   ]),
/// )
/// ```
/// {@end-tool}
class MotionLayoutGroup extends InheritedWidget {
  const MotionLayoutGroup({
    super.key,
    required this.namespace,
    required super.child,
  });

  /// The namespace for this group. Only [MotionLayoutId] widgets within
  /// the same namespace will animate between each other.
  final Object namespace;

  /// Returns the namespace of the nearest [MotionLayoutGroup], or null.
  static Object? maybeNamespaceOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MotionLayoutGroup>()
        ?.namespace;
  }

  @override
  bool updateShouldNotify(MotionLayoutGroup oldWidget) =>
      namespace != oldWidget.namespace;
}
