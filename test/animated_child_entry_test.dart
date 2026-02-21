import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/src/internals/animated_child_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimatedChildEntry.isAnimating', () {
    test('returns false when both controllers are null', () {
      final entry = AnimatedChildEntry(
        key: const ValueKey('a'),
        widget: const SizedBox(),
        globalKey: GlobalKey(),
      );

      expect(entry.isAnimating, isFalse);
    });

    test('returns true when moveController is animating', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      final entry = AnimatedChildEntry(
        key: const ValueKey('a'),
        widget: const SizedBox(),
        globalKey: GlobalKey(),
      )..moveController = controller;

      controller.forward();
      expect(entry.isAnimating, isTrue);

      controller.dispose();
    });

    test('returns true when transitionController is animating', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      final entry = AnimatedChildEntry(
        key: const ValueKey('a'),
        widget: const SizedBox(),
        globalKey: GlobalKey(),
      )..transitionController = controller;

      controller.forward();
      expect(entry.isAnimating, isTrue);

      controller.dispose();
    });

    test('returns false when controllers are stopped', () {
      final moveCtrl = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      final transCtrl = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      final entry =
          AnimatedChildEntry(
              key: const ValueKey('a'),
              widget: const SizedBox(),
              globalKey: GlobalKey(),
            )
            ..moveController = moveCtrl
            ..transitionController = transCtrl;

      // Controllers exist but haven't been started — not animating.
      expect(entry.isAnimating, isFalse);

      moveCtrl.dispose();
      transCtrl.dispose();
    });
  });

  group('AnimatedChildEntry.dispose', () {
    test('disposes null controllers without error', () {
      final entry = AnimatedChildEntry(
        key: const ValueKey('a'),
        widget: const SizedBox(),
        globalKey: GlobalKey(),
      );

      // Should not throw.
      entry.dispose();
    });

    test('disposes active moveController', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      final entry = AnimatedChildEntry(
        key: const ValueKey('a'),
        widget: const SizedBox(),
        globalKey: GlobalKey(),
      )..moveController = controller;

      controller.forward();
      entry.dispose();

      // Verify controller is disposed (accessing value after dispose throws).
      expect(() => controller.forward(), throwsA(isA<AssertionError>()));
    });

    test('disposes active transitionController', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      final entry = AnimatedChildEntry(
        key: const ValueKey('a'),
        widget: const SizedBox(),
        globalKey: GlobalKey(),
      )..transitionController = controller;

      controller.forward();
      entry.dispose();

      expect(() => controller.forward(), throwsA(isA<AssertionError>()));
    });

    test('disposes both controllers', () {
      final moveCtrl = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      final transCtrl = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      final entry =
          AnimatedChildEntry(
              key: const ValueKey('a'),
              widget: const SizedBox(),
              globalKey: GlobalKey(),
            )
            ..moveController = moveCtrl
            ..transitionController = transCtrl;

      moveCtrl.forward();
      transCtrl.forward();
      entry.dispose();

      expect(() => moveCtrl.forward(), throwsA(isA<AssertionError>()));
      expect(() => transCtrl.forward(), throwsA(isA<AssertionError>()));
    });
  });
}
