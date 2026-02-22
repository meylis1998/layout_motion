import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

import 'helpers/test_apps.dart';

/// Helper that builds a MotionTransition inside a real widget tree so that
/// a valid BuildContext is available.
class _TransitionHarness extends StatelessWidget {
  const _TransitionHarness({required this.transition, required this.animation});

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
  group('ComposedTransition', () {
    testWidgets('applies all transitions (verify widget tree nesting)', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      final composed = const FadeIn() + const SlideIn() + const ScaleIn();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: composed,
            animation: controller,
          ),
        ),
      );

      // All three transition widgets should be present in the tree.
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);

      // FadeTransition should be outermost (first in list).
      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 0.0);

      controller.value = 1.0;
      await tester.pump();
      expect(fadeTransition.opacity.value, 1.0);

      controller.dispose();
    });

    testWidgets('applies transitions in order (first is outermost)', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.5,
      );

      final composed = const FadeIn() + const ScaleIn(scale: 0.5);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: composed,
            animation: controller,
          ),
        ),
      );

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );

      expect(fadeTransition.opacity.value, 0.5);
      expect(scaleTransition.scale.value, 0.75); // lerp(0.5, 1.0, 0.5)

      controller.dispose();
    });
  });

  group('operator+', () {
    test('creates ComposedTransition from two transitions', () {
      final composed = const FadeIn() + const SlideIn();
      expect(composed, isA<ComposedTransition>());
      expect(composed.transitions.length, 2);
      expect(composed.transitions[0], isA<FadeIn>());
      expect(composed.transitions[1], isA<SlideIn>());
    });

    test('chains three transitions', () {
      final composed = const FadeIn() + const SlideIn() + const ScaleIn();
      expect(composed, isA<ComposedTransition>());
      expect(composed.transitions.length, 3);
      expect(composed.transitions[0], isA<FadeIn>());
      expect(composed.transitions[1], isA<SlideIn>());
      expect(composed.transitions[2], isA<ScaleIn>());
    });

    test('ComposedTransition + another transition flattens', () {
      final composed = const FadeIn() + const SlideIn();
      // Adding another single transition to a ComposedTransition
      // flattens the left side.
      final extended = composed + const ScaleIn();
      expect(extended, isA<ComposedTransition>());
      expect(extended.transitions.length, 3);
      expect(extended.transitions[0], isA<FadeIn>());
      expect(extended.transitions[1], isA<SlideIn>());
      expect(extended.transitions[2], isA<ScaleIn>());
    });
  });

  group('ComposedTransition in MotionLayout', () {
    testWidgets('works as enterTransition', (tester) async {
      // Start with one item.
      await tester.pumpWidget(const TestColumnApp(items: ['a']));
      await tester.pumpAndSettle();

      // Add a second item with a composed enter transition.
      await tester.pumpWidget(
        TestColumnApp(
          items: const ['a', 'b'],
          enterTransition: const FadeIn() + const SlideIn(),
        ),
      );

      // Mid-animation: both FadeTransition and SlideTransition should be present.
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // After animation completes.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('works as exitTransition', (tester) async {
      // Start with two items.
      await tester.pumpWidget(
        TestColumnApp(
          items: const ['a', 'b'],
          exitTransition: const FadeOut() + const SlideOut(),
        ),
      );
      await tester.pumpAndSettle();

      // Remove 'b'.
      await tester.pumpWidget(
        TestColumnApp(
          items: const ['a'],
          exitTransition: const FadeOut() + const SlideOut(),
        ),
      );

      // Mid-animation: exit transition should be active.
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // After animation completes, 'b' should be gone.
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });
  });
}
