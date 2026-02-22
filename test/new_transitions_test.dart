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
  group('FadeSlideIn', () {
    testWidgets('builds FadeTransition + SlideTransition', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeSlideIn(),
            animation: controller,
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      controller.dispose();
    });

    testWidgets('uses default offset (0, 0.15)', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeSlideIn(),
            animation: controller,
          ),
        ),
      );

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value, const Offset(0, 0.15));

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 0.0);

      controller.value = 1.0;
      await tester.pump();
      expect(slideTransition.position.value, Offset.zero);
      expect(fadeTransition.opacity.value, 1.0);

      controller.dispose();
    });

    testWidgets('uses custom offset', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeSlideIn(offset: Offset(1.0, 0)),
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

  group('FadeSlideOut', () {
    testWidgets('builds FadeTransition + SlideTransition', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeSlideOut(),
            animation: controller,
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 1.0);

      final slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value, Offset.zero);

      controller.value = 0.0;
      await tester.pump();
      expect(fadeTransition.opacity.value, 0.0);
      expect(slideTransition.position.value, const Offset(0, 0.15));

      controller.dispose();
    });
  });

  group('FadeScaleIn', () {
    testWidgets('builds FadeTransition + ScaleTransition', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeScaleIn(),
            animation: controller,
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);

      controller.dispose();
    });

    testWidgets('uses default scale 0.8', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeScaleIn(),
            animation: controller,
          ),
        ),
      );

      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      expect(scaleTransition.scale.value, 0.8);

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 0.0);

      controller.value = 1.0;
      await tester.pump();
      expect(scaleTransition.scale.value, 1.0);
      expect(fadeTransition.opacity.value, 1.0);

      controller.dispose();
    });

    testWidgets('custom scale', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeScaleIn(scale: 0.5),
            animation: controller,
          ),
        ),
      );

      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      expect(scaleTransition.scale.value, 0.5);

      controller.value = 0.5;
      await tester.pump();
      expect(scaleTransition.scale.value, 0.75); // lerp(0.5, 1.0, 0.5)

      controller.dispose();
    });

    test('assertion: scale must be positive', () {
      expect(() => FadeScaleIn(scale: 0), throwsA(isA<AssertionError>()));
      expect(() => FadeScaleIn(scale: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('FadeScaleOut', () {
    testWidgets('builds FadeTransition + ScaleTransition', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const FadeScaleOut(),
            animation: controller,
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);

      final fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, 1.0);

      final scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      expect(scaleTransition.scale.value, 1.0);

      controller.value = 0.0;
      await tester.pump();
      expect(fadeTransition.opacity.value, 0.0);
      expect(scaleTransition.scale.value, 0.8);

      controller.dispose();
    });

    test('assertion: scale must be positive', () {
      expect(() => FadeScaleOut(scale: 0), throwsA(isA<AssertionError>()));
      expect(() => FadeScaleOut(scale: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('SizeIn', () {
    testWidgets('builds SizeTransition with vertical axis', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SizeIn(),
            animation: controller,
          ),
        ),
      );

      expect(find.byType(SizeTransition), findsOneWidget);

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.axis, Axis.vertical);
      expect(sizeTransition.sizeFactor.value, 0.0);

      controller.value = 1.0;
      await tester.pump();
      expect(sizeTransition.sizeFactor.value, 1.0);

      controller.dispose();
    });

    testWidgets('with horizontal axis', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SizeIn(axis: Axis.horizontal),
            animation: controller,
          ),
        ),
      );

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.axis, Axis.horizontal);

      controller.dispose();
    });

    testWidgets('with custom axisAlignment', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 0.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SizeIn(axisAlignment: -1.0),
            animation: controller,
          ),
        ),
      );

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.axisAlignment, -1.0);

      controller.dispose();
    });
  });

  group('SizeOut', () {
    testWidgets('builds SizeTransition with vertical axis', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TransitionHarness(
            transition: const SizeOut(),
            animation: controller,
          ),
        ),
      );

      expect(find.byType(SizeTransition), findsOneWidget);

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.axis, Axis.vertical);
      expect(sizeTransition.sizeFactor.value, 1.0);

      controller.value = 0.0;
      await tester.pump();
      expect(sizeTransition.sizeFactor.value, 0.0);

      controller.dispose();
    });
  });

  group('New transitions end-to-end with MotionLayout', () {
    testWidgets('FadeSlideIn works as enterTransition', (tester) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a']));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b'], enterTransition: FadeSlideIn()),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('FadeScaleIn works as enterTransition', (tester) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a']));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b'], enterTransition: FadeScaleIn()),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('SizeIn works as enterTransition', (tester) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a']));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b'], enterTransition: SizeIn()),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(SizeTransition), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('FadeSlideOut works as exitTransition', (tester) async {
      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b'], exitTransition: FadeSlideOut()),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const TestColumnApp(items: ['a'], exitTransition: FadeSlideOut()),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('FadeScaleOut works as exitTransition', (tester) async {
      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b'], exitTransition: FadeScaleOut()),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const TestColumnApp(items: ['a'], exitTransition: FadeScaleOut()),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    testWidgets('SizeOut works as exitTransition', (tester) async {
      await tester.pumpWidget(
        const TestColumnApp(items: ['a', 'b'], exitTransition: SizeOut()),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const TestColumnApp(items: ['a'], exitTransition: SizeOut()),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });
  });
}
