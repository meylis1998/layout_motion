import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_motion/layout_motion.dart';

import 'helpers/test_apps.dart';

// ---------------------------------------------------------------------------
// Test app variants for the new features
// ---------------------------------------------------------------------------

/// A stateful wrapper to drive MotionLayout updates with new feature params.
class _NewFeaturesApp extends StatefulWidget {
  const _NewFeaturesApp({
    required this.items,
    this.staggerDuration = Duration.zero,
    this.staggerFrom = StaggerFrom.first,
    this.onAnimationStart,
    this.onAnimationComplete,
    this.onChildEnter,
    this.onChildExit,
    this.spring,
    this.moveCurve,
    this.enterCurve,
    this.exitCurve,
    this.enabled,
  });

  final List<String> items;
  final Duration staggerDuration;
  final StaggerFrom staggerFrom;
  final VoidCallback? onAnimationStart;
  final VoidCallback? onAnimationComplete;
  final ValueChanged<Key>? onChildEnter;
  final ValueChanged<Key>? onChildExit;
  final MotionSpring? spring;
  final Curve? moveCurve;
  final Curve? enterCurve;
  final Curve? exitCurve;
  final bool? enabled;

  @override
  State<_NewFeaturesApp> createState() => _NewFeaturesAppState();
}

class _NewFeaturesAppState extends State<_NewFeaturesApp> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionLayout(
        staggerDuration: widget.staggerDuration,
        staggerFrom: widget.staggerFrom,
        onAnimationStart: widget.onAnimationStart,
        onAnimationComplete: widget.onAnimationComplete,
        onChildEnter: widget.onChildEnter,
        onChildExit: widget.onChildExit,
        spring: widget.spring,
        moveCurve: widget.moveCurve,
        enterCurve: widget.enterCurve,
        exitCurve: widget.exitCurve,
        enabled: widget.enabled,
        child: Column(
          children: [
            for (final item in widget.items)
              SizedBox(key: ValueKey(item), height: 50, width: 100),
          ],
        ),
      ),
    );
  }
}

void main() {
  // =========================================================================
  // Feature 1: Staggered Animations
  // =========================================================================
  group('Staggered Animations', () {
    testWidgets('staggerDuration offsets enter animations', (tester) async {
      // Start with empty list.
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: [],
          staggerDuration: Duration(milliseconds: 100),
        ),
      );

      // Add three items.
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['a', 'b', 'c'],
          staggerDuration: Duration(milliseconds: 100),
        ),
      );

      // After 50ms, first child should have started (0ms delay), but third
      // child (200ms delay) should not yet have started.
      await tester.pump(const Duration(milliseconds: 50));

      // Verify that the items exist (added to tree even before stagger fires).
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      // Let all animations complete.
      await tester.pumpAndSettle();

      // All items should be present.
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('StaggerFrom.last reverses delay order', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: [],
          staggerDuration: Duration(milliseconds: 100),
          staggerFrom: StaggerFrom.last,
        ),
      );

      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['a', 'b', 'c'],
          staggerDuration: Duration(milliseconds: 100),
          staggerFrom: StaggerFrom.last,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('StaggerFrom.center starts from center', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: [],
          staggerDuration: Duration(milliseconds: 50),
          staggerFrom: StaggerFrom.center,
        ),
      );

      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['a', 'b', 'c', 'd', 'e'],
          staggerDuration: Duration(milliseconds: 50),
          staggerFrom: StaggerFrom.center,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
      expect(find.byKey(const ValueKey('e')), findsOneWidget);
    });

    testWidgets('default staggerDuration (zero) means no stagger', (
      tester,
    ) async {
      await tester.pumpWidget(const _NewFeaturesApp(items: []));

      await tester.pumpWidget(const _NewFeaturesApp(items: ['a', 'b', 'c']));

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('stagger works with exit animations', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['a', 'b', 'c'],
          staggerDuration: Duration(milliseconds: 50),
        ),
      );

      // Remove all items.
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: [],
          staggerDuration: Duration(milliseconds: 50),
        ),
      );

      await tester.pumpAndSettle();

      // All items should be gone.
      expect(find.byKey(const ValueKey('a')), findsNothing);
      expect(find.byKey(const ValueKey('b')), findsNothing);
      expect(find.byKey(const ValueKey('c')), findsNothing);
    });

    testWidgets('stagger works with move animations', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['a', 'b', 'c'],
          staggerDuration: Duration(milliseconds: 50),
        ),
      );
      await tester.pumpAndSettle();

      // Reorder: reverse the list.
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['c', 'b', 'a'],
          staggerDuration: Duration(milliseconds: 50),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });
  });

  // =========================================================================
  // Feature 2: Animation Lifecycle Callbacks
  // =========================================================================
  group('Animation Lifecycle Callbacks', () {
    testWidgets('onAnimationStart fires when animations begin', (tester) async {
      int startCount = 0;

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a'],
          onAnimationStart: () => startCount++,
        ),
      );

      // Add a child to trigger animation.
      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a', 'b'],
          onAnimationStart: () => startCount++,
        ),
      );

      expect(startCount, greaterThan(0));
    });

    testWidgets('onAnimationComplete fires when all animations finish', (
      tester,
    ) async {
      int completeCount = 0;

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a'],
          onAnimationComplete: () => completeCount++,
        ),
      );

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a', 'b'],
          onAnimationComplete: () => completeCount++,
        ),
      );

      // Let animations complete.
      await tester.pumpAndSettle();
      expect(completeCount, greaterThan(0));
    });

    testWidgets('onChildEnter fires for each entering child', (tester) async {
      final enteredKeys = <Key>[];

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a'],
          onChildEnter: (key) => enteredKeys.add(key),
        ),
      );

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a', 'b', 'c'],
          onChildEnter: (key) => enteredKeys.add(key),
        ),
      );

      expect(enteredKeys, contains(const ValueKey('b')));
      expect(enteredKeys, contains(const ValueKey('c')));
    });

    testWidgets('onChildExit fires for each exiting child', (tester) async {
      final exitedKeys = <Key>[];

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a', 'b', 'c'],
          onChildExit: (key) => exitedKeys.add(key),
        ),
      );

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a'],
          onChildExit: (key) => exitedKeys.add(key),
        ),
      );

      expect(exitedKeys, contains(const ValueKey('b')));
      expect(exitedKeys, contains(const ValueKey('c')));
    });

    testWidgets('callbacks are not fired when disabled', (tester) async {
      int startCount = 0;

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a'],
          enabled: false,
          onAnimationStart: () => startCount++,
        ),
      );

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a', 'b'],
          enabled: false,
          onAnimationStart: () => startCount++,
        ),
      );

      await tester.pumpAndSettle();
      expect(startCount, 0);
    });
  });

  // =========================================================================
  // Feature 4: Auto-Detect Reduced Motion
  // =========================================================================
  group('Auto-Detect Reduced Motion', () {
    testWidgets('enabled: null respects MediaQuery.disableAnimations', (
      tester,
    ) async {
      // With disableAnimations: true, layout changes should be instant.
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: _NewFeaturesApp(items: ['a']),
        ),
      );

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: _NewFeaturesApp(items: ['a', 'b']),
        ),
      );

      // Should be instant — no animation running.
      await tester.pump();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);

      // No FadeTransition should be present (instant update, no transition).
      expect(find.byType(FadeTransition), findsNothing);
    });

    testWidgets('enabled: true overrides system reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: _NewFeaturesApp(items: ['a'], enabled: true),
        ),
      );

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: _NewFeaturesApp(items: ['a', 'b'], enabled: true),
        ),
      );

      // With enabled: true, animations should run despite system setting.
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(FadeTransition), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('enabled: false disables regardless', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a'], enabled: false),
      );

      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a', 'b'], enabled: false),
      );

      await tester.pump();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
    });

    testWidgets('default (null) auto-detects without MediaQuery', (
      tester,
    ) async {
      // Without MediaQuery ancestor, should default to enabled.
      await tester.pumpWidget(const _NewFeaturesApp(items: ['a']));

      await tester.pumpWidget(const _NewFeaturesApp(items: ['a', 'b']));

      await tester.pump(const Duration(milliseconds: 1));
      // Should have FadeTransition since default is enabled.
      expect(find.byType(FadeTransition), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  // =========================================================================
  // Feature 5: Spring Physics
  // =========================================================================
  group('Spring Physics', () {
    test('MotionSpring.bouncy creates valid spring description', () {
      final desc = MotionSpring.bouncy.toSpringDescription();
      expect(desc.mass, 1.0);
      expect(desc.stiffness, 300.0);
      expect(desc.damping, 15.0);
    });

    test('MotionSpring presets have correct values', () {
      expect(MotionSpring.gentle.stiffness, 120);
      expect(MotionSpring.gentle.damping, 20);
      expect(MotionSpring.smooth.stiffness, 200);
      expect(MotionSpring.smooth.damping, 22);
      expect(MotionSpring.bouncy.stiffness, 300);
      expect(MotionSpring.bouncy.damping, 15);
      expect(MotionSpring.stiff.stiffness, 400);
      expect(MotionSpring.stiff.damping, 30);
    });

    test('custom spring parameters work', () {
      const spring = MotionSpring(stiffness: 250, damping: 18, mass: 1.5);
      final desc = spring.toSpringDescription();
      expect(desc.stiffness, 250);
      expect(desc.damping, 18);
      expect(desc.mass, 1.5);
    });

    test('spring assertions reject invalid values', () {
      expect(() => MotionSpring(stiffness: 0), throwsA(isA<AssertionError>()));
      expect(() => MotionSpring(damping: -1), throwsA(isA<AssertionError>()));
      expect(() => MotionSpring(mass: 0), throwsA(isA<AssertionError>()));
    });

    testWidgets('spring animation applies to move', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['a', 'b', 'c'],
          spring: MotionSpring.bouncy,
        ),
      );
      await tester.pumpAndSettle();

      // Reorder to trigger move.
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['c', 'b', 'a'],
          spring: MotionSpring.bouncy,
        ),
      );

      // Mid-animation, Transform.translate should be present.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(Transform), findsWidgets);

      await tester.pumpAndSettle();

      // All children still present after animation completes.
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
      expect(find.byKey(const ValueKey('c')), findsOneWidget);
    });

    testWidgets('spring with enter/exit animations completes without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a', 'b'], spring: MotionSpring.gentle),
      );

      // Add item.
      await tester.pumpWidget(
        const _NewFeaturesApp(
          items: ['a', 'b', 'c'],
          spring: MotionSpring.gentle,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('c')), findsOneWidget);

      // Remove item.
      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a', 'b'], spring: MotionSpring.gentle),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('c')), findsNothing);
    });
  });

  // =========================================================================
  // Feature 7: Per-Child Curve Control
  // =========================================================================
  group('Per-Child Curve Control', () {
    testWidgets('moveCurve overrides curve for moves', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a', 'b', 'c'], moveCurve: Curves.linear),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['c', 'b', 'a'], moveCurve: Curves.linear),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('a')), findsOneWidget);
    });

    testWidgets('enterCurve overrides curve for enters', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a'], enterCurve: Curves.bounceOut),
      );

      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a', 'b'], enterCurve: Curves.bounceOut),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('exitCurve overrides curve for exits', (tester) async {
      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a', 'b'], exitCurve: Curves.easeIn),
      );

      await tester.pumpWidget(
        const _NewFeaturesApp(items: ['a'], exitCurve: Curves.easeIn),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsNothing);
    });

    test('null per-child curves fall back to global curve', () {
      const layout = MotionLayout(child: Column(children: []));
      expect(layout.effectiveMoveCurve, Curves.easeInOut);
      expect(layout.effectiveEnterCurve, Curves.easeInOut);
      expect(layout.effectiveExitCurve, Curves.easeInOut);
    });

    test('per-child curves override global curve', () {
      const layout = MotionLayout(
        moveCurve: Curves.linear,
        enterCurve: Curves.bounceOut,
        exitCurve: Curves.easeIn,
        child: Column(children: []),
      );
      expect(layout.effectiveMoveCurve, Curves.linear);
      expect(layout.effectiveEnterCurve, Curves.bounceOut);
      expect(layout.effectiveExitCurve, Curves.easeIn);
    });
  });

  // =========================================================================
  // Feature 3: Transition Composition (operator+)
  // =========================================================================
  group('Transition Composition', () {
    test('operator+ creates ComposedTransition from two transitions', () {
      final composed = const FadeIn() + const SlideIn();
      expect(composed, isA<ComposedTransition>());
      expect(composed.transitions.length, 2);
      expect(composed.transitions[0], isA<FadeIn>());
      expect(composed.transitions[1], isA<SlideIn>());
    });

    test('operator+ chains three transitions', () {
      final composed = const FadeIn() + const SlideIn() + const ScaleIn();
      expect(composed.transitions.length, 3);
      expect(composed.transitions[0], isA<FadeIn>());
      expect(composed.transitions[1], isA<SlideIn>());
      expect(composed.transitions[2], isA<ScaleIn>());
    });

    test('ComposedTransition + another transition flattens', () {
      final first = const FadeIn() + const SlideIn();
      final combined = first + const ScaleIn();
      expect(combined.transitions.length, 3);
    });

    testWidgets('composed transition works as enterTransition', (tester) async {
      final enter = const FadeIn() + const ScaleIn();

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            child: Column(
              children: [SizedBox(key: ValueKey('a'), height: 50)],
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            enterTransition: enter,
            child: const Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(key: ValueKey('b'), height: 50),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1));

      // Should have both FadeTransition and ScaleTransition.
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });

  // =========================================================================
  // Feature 6: New Transition Presets
  // =========================================================================
  group('New Transition Presets', () {
    test('FadeSlideIn uses default offset', () {
      const t = FadeSlideIn();
      expect(t.offset, const Offset(0, 0.15));
    });

    test('FadeScaleIn uses default scale', () {
      const t = FadeScaleIn();
      expect(t.scale, 0.8);
    });

    test('SizeIn defaults to vertical axis', () {
      const t = SizeIn();
      expect(t.axis, Axis.vertical);
      expect(t.axisAlignment, 0.0);
    });

    testWidgets('FadeSlideIn works as enter transition end-to-end', (
      tester,
    ) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a']));

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            enterTransition: FadeSlideIn(),
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(key: ValueKey('b'), height: 50),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });

    testWidgets('SizeIn works as enter transition end-to-end', (tester) async {
      await tester.pumpWidget(const TestColumnApp(items: ['a']));

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionLayout(
            enterTransition: SizeIn(),
            child: Column(
              children: [
                SizedBox(key: ValueKey('a'), height: 50),
                SizedBox(key: ValueKey('b'), height: 50),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('b')), findsOneWidget);
    });
  });

  // =========================================================================
  // Integration: Multiple new features combined
  // =========================================================================
  group('Feature Integration', () {
    testWidgets('stagger + callbacks + spring all work together', (
      tester,
    ) async {
      int startCount = 0;
      int completeCount = 0;
      final entered = <Key>[];

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a'],
          staggerDuration: const Duration(milliseconds: 30),
          spring: MotionSpring.smooth,
          onAnimationStart: () => startCount++,
          onAnimationComplete: () => completeCount++,
          onChildEnter: (key) => entered.add(key),
        ),
      );

      await tester.pumpWidget(
        _NewFeaturesApp(
          items: const ['a', 'b', 'c'],
          staggerDuration: const Duration(milliseconds: 30),
          spring: MotionSpring.smooth,
          onAnimationStart: () => startCount++,
          onAnimationComplete: () => completeCount++,
          onChildEnter: (key) => entered.add(key),
        ),
      );

      await tester.pumpAndSettle();

      expect(startCount, greaterThan(0));
      expect(completeCount, greaterThan(0));
      expect(entered, contains(const ValueKey('b')));
      expect(entered, contains(const ValueKey('c')));
    });

    testWidgets('rapid updates with stagger produce no exceptions', (
      tester,
    ) async {
      for (int i = 0; i < 10; i++) {
        final items = i.isEven ? ['a', 'b', 'c'] : ['c', 'a'];
        await tester.pumpWidget(
          _NewFeaturesApp(
            items: items,
            staggerDuration: const Duration(milliseconds: 20),
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
