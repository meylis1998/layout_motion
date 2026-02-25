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

/// Shared test helper: wraps string items in a MotionLayout GridView.
class TestGridApp extends StatelessWidget {
  const TestGridApp({
    super.key,
    required this.items,
    this.crossAxisCount = 3,
    this.duration = const Duration(milliseconds: 300),
    this.itemHeight = 50,
    this.itemWidth = 50,
    this.enabled,
    this.enterTransition,
    this.exitTransition,
    this.staggerDuration = Duration.zero,
    this.staggerFrom = StaggerFrom.first,
    this.onReorder,
    this.spring,
    this.onAnimationStart,
    this.onAnimationComplete,
  });

  final List<String> items;
  final int crossAxisCount;
  final Duration duration;
  final double itemHeight;
  final double itemWidth;
  final bool? enabled;
  final MotionTransition? enterTransition;
  final MotionTransition? exitTransition;
  final Duration staggerDuration;
  final StaggerFrom staggerFrom;
  final void Function(int, int)? onReorder;
  final MotionSpring? spring;
  final VoidCallback? onAnimationStart;
  final VoidCallback? onAnimationComplete;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        duration: duration,
        enabled: enabled,
        enterTransition: enterTransition,
        exitTransition: exitTransition,
        staggerDuration: staggerDuration,
        staggerFrom: staggerFrom,
        onReorder: onReorder,
        spring: spring,
        onAnimationStart: onAnimationStart,
        onAnimationComplete: onAnimationComplete,
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
