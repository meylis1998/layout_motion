import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../transitions/motion_transition.dart';

/// A per-item animation wrapper for [MotionListView] and [MotionGridView]
/// builder mode.
///
/// Manages enter and exit transitions for individual items. Enter animation
/// starts in [initState] when [shouldEnter] is true. Exit animation starts
/// when [isExiting] becomes true via [didUpdateWidget].
class MotionItemWrapper extends StatefulWidget {
  const MotionItemWrapper({
    required super.key,
    required this.child,
    required this.enterTransition,
    required this.exitTransition,
    required this.duration,
    required this.enterCurve,
    required this.exitCurve,
    this.shouldEnter = false,
    this.isExiting = false,
    this.onExitComplete,
    this.onEntered,
  });

  /// The child widget to animate.
  final Widget child;

  /// Transition for entering items.
  final MotionTransition enterTransition;

  /// Transition for exiting items.
  final MotionTransition exitTransition;

  /// Duration of the animation.
  final Duration duration;

  /// Curve for enter animation.
  final Curve enterCurve;

  /// Curve for exit animation.
  final Curve exitCurve;

  /// Whether this item should play an enter animation.
  ///
  /// Only read in [initState]. Subsequent changes are ignored so that
  /// an in-progress animation is not interrupted by parent rebuilds.
  final bool shouldEnter;

  /// Whether this item is currently exiting.
  final bool isExiting;

  /// Called when exit animation completes.
  final VoidCallback? onExitComplete;

  /// Called when enter animation actually starts (from [initState]).
  final VoidCallback? onEntered;

  @override
  State<MotionItemWrapper> createState() => _MotionItemWrapperState();
}

class _MotionItemWrapperState extends State<MotionItemWrapper>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  CurvedAnimation? _curved;
  bool _isExiting = false;
  bool _isEntering = false;

  @override
  void initState() {
    super.initState();
    _isExiting = widget.isExiting;

    if (_isExiting) {
      _startExit();
    } else if (widget.shouldEnter) {
      _startEnter();
      if (widget.onEntered != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onEntered!();
        });
      }
    }
  }

  void _startEnter() {
    _isEntering = true;
    _disposeAnimation();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _curved = CurvedAnimation(parent: _controller!, curve: widget.enterCurve);
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isEntering = false;
        if (mounted) setState(() {});
      }
    });
    _controller!.forward();
  }

  void _startExit() {
    _isExiting = true;
    _isEntering = false;
    _disposeAnimation();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _curved = CurvedAnimation(parent: _controller!, curve: widget.exitCurve);
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onExitComplete?.call();
      }
    });
    _controller!.forward();
  }

  void _disposeAnimation() {
    _curved?.dispose();
    _curved = null;
    _controller?.dispose();
    _controller = null;
  }

  @override
  void didUpdateWidget(covariant MotionItemWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExiting && !_isExiting) {
      _startExit();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _disposeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isExiting && _curved != null) {
      final reversed = ReverseAnimation(_curved!);
      return ExcludeSemantics(
        child: IgnorePointer(
          child: widget.exitTransition.build(context, reversed, widget.child),
        ),
      );
    }

    if (_isEntering && _curved != null) {
      return widget.enterTransition.build(context, _curved!, widget.child);
    }

    return widget.child;
  }
}
