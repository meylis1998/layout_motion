import 'package:flutter/widgets.dart';
import 'package:layout_motion/layout_motion.dart';

/// Shared test helper: wraps string items in a MotionLayout Column.
class TestColumnApp extends StatelessWidget {
  const TestColumnApp({
    super.key,
    required this.items,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 300),
    this.itemHeight = 50,
    this.itemWidth = 100,
    this.enabled,
    this.enterTransition,
    this.exitTransition,
    this.clipBehavior = Clip.hardEdge,
    this.moveThreshold = 0.5,
    this.spacing = 0,
  });

  final List<String> items;
  final Curve curve;
  final Duration duration;
  final double itemHeight;
  final double itemWidth;
  final bool? enabled;
  final MotionTransition? enterTransition;
  final MotionTransition? exitTransition;
  final Clip clipBehavior;
  final double moveThreshold;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        duration: duration,
        curve: curve,
        enabled: enabled,
        enterTransition: enterTransition,
        exitTransition: exitTransition,
        clipBehavior: clipBehavior,
        moveThreshold: moveThreshold,
        child: Column(
          spacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                key: ValueKey(item),
                height: itemHeight,
                width: itemWidth,
              ),
          ],
        ),
      ),
    );
  }
}

/// Shared test helper: wraps string items in a MotionLayout Row.
class TestRowApp extends StatelessWidget {
  const TestRowApp({
    super.key,
    required this.items,
    this.duration = const Duration(milliseconds: 300),
    this.itemHeight = 50,
    this.itemWidth = 100,
    this.spacing = 0,
  });

  final List<String> items;
  final Duration duration;
  final double itemHeight;
  final double itemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        duration: duration,
        child: Row(
          spacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                key: ValueKey(item),
                height: itemHeight,
                width: itemWidth,
              ),
          ],
        ),
      ),
    );
  }
}
