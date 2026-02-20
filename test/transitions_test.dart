import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

/// Helper that builds a MotionTransition inside a real widget tree so that
/// a valid BuildContext is available.
class _TransitionHarness extends StatelessWidget {
  const _TransitionHarness({
    required this.transition,
    required this.animation,
  });

  final MotionTransition transition;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return transition.build(
      context,
      animation,
      const SizedBox(key: ValueKey('child')),
    );
  }
}

void main() {
  group('FadeIn', () {
    testWidgets('wraps child in FadeTransition with given animation', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeIn(),
            animation: controller,
          ),
        ),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 0.0);

      controller.value = 0.5;
      await tester.pump();
      expect(fadeTransition.opacity.value, 0.5);

      controller.value = 1.0;
      await tester.pump();
      expect(fadeTransition.opacity.value, 1.0);

      controller.dispose();
    });
  });

  group('FadeOut', () {
    testWidgets('uses same FadeTransition (direction handled by framework)', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeOut(),
            animation: controller,
          ),
        ),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 1.0);

      // Simulate exit: animation goes from 1→0.
      controller.value = 0.5;
      await tester.pump();
      expect(fadeTransition.opacity.value, 0.5);

      controller.value = 0.0;
      await tester.pump();
      expect(fadeTransition.opacity.value, 0.0);

      controller.dispose();
    });
  });

  group('SlideIn', () {
    testWidgets('slides from offset to zero as animation goes 0→1', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SlideIn(offset: Offset(0, 0.2)),
            animation: controller,
          ),
        ),
      );

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );

      // At 0: should be at the offset position.
      expect(slideTransition.position.value, const Offset(0, 0.2));

      controller.value = 0.5;
      await tester.pump();
      expect(slideTransition.position.value, const Offset(0, 0.1));

      // At 1: should be at zero (fully in place).
      controller.value = 1.0;
      await tester.pump();
      expect(slideTransition.position.value, Offset.zero);

      controller.dispose();
    });

    testWidgets('uses default offset of (0, 0.15)', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SlideIn(),
            animation: controller,
          ),
        ),
      );

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value, const Offset(0, 0.15));

      controller.dispose();
    });

    testWidgets('supports horizontal slide', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SlideIn(offset: Offset(1.0, 0)),
            animation: controller,
          ),
        ),
      );

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value, const Offset(1.0, 0));

      controller.value = 1.0;
      await tester.pump();
      expect(slideTransition.position.value, Offset.zero);

      controller.dispose();
    });
  });

  group('SlideOut', () {
    testWidgets('works correctly with reversed animation (1→0)', (
      tester,
    ) async {
      // Simulate how the framework uses SlideOut: controller goes 0→1,
      // then ReverseAnimation makes it 1→0 for the transition.
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );
      final reversed = ReverseAnimation(controller);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SlideOut(offset: Offset(0, 0.2)),
            animation: reversed,
          ),
        ),
      );

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );

      // At controller=0 → reversed=1 → lerp(offset, zero, 1.0) = zero (visible).
      expect(slideTransition.position.value, Offset.zero);

      // At controller=1 → reversed=0 → lerp(offset, zero, 0.0) = offset (slid out).
      controller.value = 1.0;
      await tester.pump();
      expect(slideTransition.position.value, const Offset(0, 0.2));

      controller.dispose();
    });
  });

  group('ScaleIn', () {
    testWidgets('scales from scale to 1.0 as animation goes 0→1', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const ScaleIn(scale: 0.5),
            animation: controller,
          ),
        ),
      );

      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );

      // At 0: at beginScale.
      expect(scaleTransition.scale.value, 0.5);

      controller.value = 0.5;
      await tester.pump();
      expect(scaleTransition.scale.value, 0.75);

      // At 1: fully visible (1.0).
      controller.value = 1.0;
      await tester.pump();
      expect(scaleTransition.scale.value, 1.0);

      controller.dispose();
    });

    testWidgets('uses default scale of 0.8', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const ScaleIn(),
            animation: controller,
          ),
        ),
      );

      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      expect(scaleTransition.scale.value, 0.8);

      controller.dispose();
    });
  });

  group('ScaleOut', () {
    testWidgets('works correctly with reversed animation (1→0)', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );
      final reversed = ReverseAnimation(controller);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const ScaleOut(scale: 0.5),
            animation: reversed,
          ),
        ),
      );

      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );

      // At controller=0 → reversed=1 → lerp(0.5, 1.0, 1.0) = 1.0 (visible).
      expect(scaleTransition.scale.value, 1.0);

      // At controller=1 → reversed=0 → lerp(0.5, 1.0, 0.0) = 0.5 (scaled out).
      controller.value = 1.0;
      await tester.pump();
      expect(scaleTransition.scale.value, 0.5);

      controller.dispose();
    });

    testWidgets('uses default scale of 0.8', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const ScaleOut(),
            animation: controller,
          ),
        ),
      );

      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      // At 0: lerp(0.8, 1.0, 0.0) = 0.8.
      expect(scaleTransition.scale.value, 0.8);

      controller.dispose();
    });
  });

  group('Custom MotionTransition', () {
    testWidgets('can be extended for custom effects', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const _RotateTransition(),
            animation: controller,
          ),
        ),
      );

      expect(find.byType(RotationTransition), findsOneWidget);

      final rotation = tester.widget<RotationTransition>(
        find.byType(RotationTransition),
      );
      expect(rotation.turns.value, 0.0);

      controller.value = 0.5;
      await tester.pump();
      expect(rotation.turns.value, 0.5);

      controller.dispose();
    });
  });
}

class _RotateTransition extends MotionTransition {
  const _RotateTransition();

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return RotationTransition(turns: animation, child: child);
  }
}
