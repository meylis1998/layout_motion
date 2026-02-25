import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'motion_layout_group.dart';
import 'motion_layout_scope.dart';

/// Marks a widget for shared layout animations within a [MotionLayoutScope].
///
/// When a [MotionLayoutId] with a given [id] unmounts and another with the
/// same [id] mounts (under the same scope and namespace), an overlay animation
/// smoothly transitions from the old position/size to the new one.
///
/// Must be a descendant of [MotionLayoutScope]. Without a scope ancestor,
/// degrades gracefully to a no-op.
///
/// {@tool snippet}
/// ```dart
/// MotionLayoutScope(
///   child: showDetail
///     ? DetailPage(
///         hero: MotionLayoutId(
///           id: 'avatar-${user.id}',
///           child: CircleAvatar(radius: 60, backgroundImage: user.photo),
///         ),
///       )
///     : ListTile(
///         leading: MotionLayoutId(
///           id: 'avatar-${user.id}',
///           child: CircleAvatar(radius: 20, backgroundImage: user.photo),
///         ),
///         title: Text(user.name),
///       ),
/// )
/// ```
/// {@end-tool}
class MotionLayoutId extends StatefulWidget {
  const MotionLayoutId({
    super.key,
    required this.id,
    required this.child,
  });

  /// The shared identity for this widget. Two [MotionLayoutId] widgets with
  /// the same [id] (and same namespace via [MotionLayoutGroup]) will animate
  /// between each other when one unmounts and the other mounts.
  final Object id;

  /// The widget to display and animate.
  final Widget child;

  @override
  State<MotionLayoutId> createState() => _MotionLayoutIdState();
}

class _MotionLayoutIdState extends State<MotionLayoutId> {
  final GlobalKey _globalKey = GlobalKey();
  MotionLayoutScopeState? _scope;
  Object? _namespace;

  @override
  void initState() {
    super.initState();
    _registerAndSchedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-register if scope or namespace changed
    final newScope = MotionLayoutScope.maybeOf(context);
    final newNamespace = MotionLayoutGroup.maybeNamespaceOf(context);
    if (newScope != _scope || newNamespace != _namespace) {
      _unregister();
      _scope = newScope;
      _namespace = newNamespace;
      _register();
    }
  }

  @override
  void didUpdateWidget(MotionLayoutId oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.child != widget.child) {
      // Unregister old, register new
      if (oldWidget.id != widget.id) {
        _scope?.unregister(_namespace, oldWidget.id, _globalKey);
      }
      _register();
    }
  }

  void _registerAndSchedule() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scope = MotionLayoutScope.maybeOf(context);
      _namespace = MotionLayoutGroup.maybeNamespaceOf(context);
      _register();
      _scope?.onFirstLayout(_namespace, widget.id, _globalKey);
    });
  }

  void _register() {
    _scope?.register(_namespace, widget.id, _globalKey, widget.child);
  }

  void _unregister() {
    _scope?.unregister(_namespace, widget.id, _globalKey);
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHidden = _scope?.isHidden(_namespace, widget.id) ?? false;

    return KeyedSubtree(
      key: _globalKey,
      child: Visibility(
        visible: !isHidden,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: widget.child,
      ),
    );
  }
}
