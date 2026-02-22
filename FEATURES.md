# layout_motion — New Features Roadmap

> Comprehensive feature specifications for layout_motion v0.4+.
> Each feature includes API design, implementation notes, and usage examples.

---

## Table of Contents

1. [Staggered Animations](#1-staggered-animations)
2. [Animation Lifecycle Callbacks](#2-animation-lifecycle-callbacks)
3. [Transition Composition](#3-transition-composition)
4. [Auto-Detect Reduced Motion](#4-auto-detect-reduced-motion)
5. [Spring Physics](#5-spring-physics)
6. [New Transition Presets](#6-new-transition-presets)
7. [Per-Child Curve Control](#7-per-child-curve-control)

---

## 1. Staggered Animations

**Priority:** Tier 1 — Highest Impact
**Inspiration:** Framer Motion `stagger()`, react-flip-toolkit `stagger`, flutter_staggered_animations
**Files:** `motion_layout.dart`, `motion_layout_state.dart`

### Problem

All children animate simultaneously on enter, exit, and move. Staggered (cascading)
animations — where each child starts its animation slightly after the previous one — are
the single most visually impactful upgrade and the most requested feature across
animation libraries.

### API Design

```dart
MotionLayout(
  // Delay between each child's animation start.
  // Applied to enter, exit, and move animations.
  // Default: Duration.zero (no stagger — current behavior).
  staggerDuration: const Duration(milliseconds: 50),

  // Direction of the stagger cascade.
  // Default: StaggerFrom.first.
  staggerFrom: StaggerFrom.first,

  child: Column(children: items),
)
```

```dart
/// Direction from which the stagger delay cascades.
enum StaggerFrom {
  /// First child animates first, last child animates last.
  first,

  /// Last child animates first, first child animates first.
  last,

  /// Center child(ren) animate first, edges animate last.
  center,
}
```

### Implementation Notes

- In `_handleAnimatedUpdate`, compute each child's stagger index based on
  its position in `newKeys` and the `staggerFrom` direction.
- For `StaggerFrom.first`: `delay = index * staggerDuration`.
- For `StaggerFrom.last`: `delay = (count - 1 - index) * staggerDuration`.
- For `StaggerFrom.center`: `delay = (index - center).abs() * staggerDuration`.
- Pass the computed delay to `_startEnter`, `_startMove`, and `_startExit`.
- In each `_start*` method, use `Future.delayed(delay, () => controller.forward())`
  instead of calling `controller.forward()` immediately. Guard with `if (mounted)`.
- Store the pending `Future` or `Timer` in `AnimatedChildEntry` so it can be
  cancelled on interruption or disposal.

### Usage Example

```dart
MotionLayout(
  duration: const Duration(milliseconds: 400),
  staggerDuration: const Duration(milliseconds: 50),
  staggerFrom: StaggerFrom.first,
  enterTransition: const SlideIn(offset: Offset(0, 0.15)),
  exitTransition: const FadeOut(),
  child: Column(
    children: [
      for (final item in items)
        ListTile(key: ValueKey(item.id), title: Text(item.name)),
    ],
  ),
)
```

---

## 2. Animation Lifecycle Callbacks

**Priority:** Tier 1 — High Impact
**Inspiration:** Framer Motion `onLayoutAnimationStart`/`onLayoutAnimationComplete`, react-flip-toolkit `onComplete`/`onStart`
**Files:** `motion_layout.dart`, `motion_layout_state.dart`

### Problem

Users cannot react to animation lifecycle events. Production apps need this for:
- Disabling UI during animations
- Triggering side effects after animations complete
- Analytics/telemetry
- Sound effects or haptic feedback
- Coordinating with other widgets

### API Design

```dart
MotionLayout(
  // Called when any animation starts (at least one child begins animating).
  onAnimationStart: () => print('Animations started'),

  // Called when all animations complete (no children animating).
  onAnimationComplete: () => print('All animations done'),

  // Called when a specific child begins its enter animation.
  onChildEnter: (Key key) => print('Child $key entering'),

  // Called when a specific child begins its exit animation.
  onChildExit: (Key key) => print('Child $key exiting'),

  child: Column(children: items),
)
```

### Implementation Notes

- Track `_activeAnimationCount` in `MotionLayoutState`.
- Increment on `_startEnter`, `_startExit`, `_startMove`; decrement on completion.
- When count transitions from 0 → >0, fire `onAnimationStart`.
- When count transitions from >0 → 0, fire `onAnimationComplete`.
- Fire `onChildEnter` at the top of `_startEnter`.
- Fire `onChildExit` at the top of `_startExit`.
- All callbacks are optional (`VoidCallback?` / `ValueChanged<Key>?`).

### Usage Example

```dart
MotionLayout(
  onAnimationComplete: () {
    setState(() => _canInteract = true);
  },
  onChildExit: (key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item removed')),
    );
  },
  child: Column(children: items),
)
```

---

## 3. Transition Composition

**Priority:** Tier 1 — High Impact
**Inspiration:** flutter_staggered_animations (nested FadeIn + SlideAnimation + ScaleAnimation), flutter_animate chain API
**Files:** `motion_transition.dart`, new `composed_transition.dart`

### Problem

Users can only apply one enter transition and one exit transition. Combining effects
(e.g., fade + slide + scale simultaneously) requires writing a custom `MotionTransition`
subclass. This should be effortless.

### API Design

```dart
// Using the + operator:
MotionLayout(
  enterTransition: const FadeIn() + const SlideIn() + const ScaleIn(),
  exitTransition: const FadeOut() + const ScaleOut(),
  child: Column(children: items),
)

// Using the constructor directly:
MotionLayout(
  enterTransition: const ComposedTransition([FadeIn(), SlideIn(), ScaleIn()]),
  child: Column(children: items),
)
```

### Implementation Notes

- Add `operator+` to `MotionTransition` base class:
  ```dart
  ComposedTransition operator +(MotionTransition other) {
    if (this is ComposedTransition) {
      return ComposedTransition([...(this as ComposedTransition).transitions, other]);
    }
    return ComposedTransition([this, other]);
  }
  ```
- Create `ComposedTransition` class that nests `build()` outputs:
  ```dart
  class ComposedTransition extends MotionTransition {
    const ComposedTransition(this.transitions);
    final List<MotionTransition> transitions;

    @override
    Widget build(BuildContext context, Animation<double> animation, Widget child) {
      Widget result = child;
      // Apply in reverse order so the first transition is outermost.
      for (int i = transitions.length - 1; i >= 0; i--) {
        result = transitions[i].build(context, animation, result);
      }
      return result;
    }
  }
  ```
- Export `ComposedTransition` from `layout_motion.dart`.

### Usage Example

```dart
// Fade + slide from bottom:
enterTransition: const FadeIn() + const SlideIn(offset: Offset(0, 0.3)),

// Fade + scale down on exit:
exitTransition: const FadeOut() + const ScaleOut(scale: 0.5),

// Triple combination:
enterTransition: const FadeIn() + const SlideIn() + const ScaleIn(scale: 0.9),
```

---

## 4. Auto-Detect Reduced Motion

**Priority:** Tier 1 — Accessibility
**Inspiration:** SwiftUI automatic reduced motion, CSS `prefers-reduced-motion`
**Files:** `motion_layout.dart`, `motion_layout_state.dart`

### Problem

Users must manually wire `MediaQuery.disableAnimations` to the `enabled` parameter.
This creates friction and risks accessibility non-compliance when developers forget.

### API Design

```dart
MotionLayout(
  // Change `enabled` from bool to bool? (nullable).
  // null (default) = auto-detect from MediaQuery.disableAnimations
  // true = always animate (override system setting)
  // false = never animate
  enabled: null, // auto-detect (new default)

  child: Column(children: items),
)
```

### Implementation Notes

- Change `this.enabled = true` to `this.enabled` (nullable `bool?`).
- In `MotionLayoutState.build()` and `didUpdateWidget()`, resolve the effective value:
  ```dart
  bool get _effectiveEnabled {
    if (widget.enabled != null) return widget.enabled!;
    return !MediaQuery.of(context).disableAnimations;
  }
  ```
- Use `_effectiveEnabled` everywhere that currently reads `widget.enabled`.
- **Breaking change consideration:** Making `enabled` nullable changes the default
  behavior. Document in CHANGELOG and migration guide. Users who had `enabled: true`
  explicitly won't be affected. Users relying on the default `true` will now get
  automatic reduced-motion support.

### Usage Example

```dart
// Auto-detect (recommended — new default):
MotionLayout(child: Column(children: items))

// Force animations on (overrides system setting):
MotionLayout(enabled: true, child: Column(children: items))

// Force animations off:
MotionLayout(enabled: false, child: Column(children: items))
```

---

## 5. Spring Physics

**Priority:** Tier 2 — High Impact
**Inspiration:** Framer Motion `type: "spring"`, SwiftUI `.spring()`, animated_to
**Files:** `motion_layout.dart`, `motion_layout_state.dart`, new `motion_spring.dart`

### Problem

Curve-based animations (easeIn, easeOut, etc.) feel mechanical compared to
physics-based spring animations. Flutter has `SpringSimulation` built-in
but MotionLayout doesn't expose it.

### API Design

```dart
MotionLayout(
  // Optional spring configuration. When set, overrides `curve` for move
  // animations. Enter/exit transitions still use `curve`.
  spring: MotionSpring.bouncy,

  child: Column(children: items),
)
```

```dart
/// Spring configuration for physics-based move animations.
///
/// Provides named presets and custom configuration.
class MotionSpring {
  const MotionSpring({
    this.stiffness = 200.0,
    this.damping = 20.0,
    this.mass = 1.0,
  }) : assert(stiffness > 0, 'stiffness must be positive'),
       assert(damping > 0, 'damping must be positive'),
       assert(mass > 0, 'mass must be positive');

  final double stiffness;
  final double damping;
  final double mass;

  /// Gentle spring with minimal bounce.
  static const gentle = MotionSpring(stiffness: 120, damping: 20, mass: 1);

  /// Standard spring with natural feel.
  static const smooth = MotionSpring(stiffness: 200, damping: 22, mass: 1);

  /// Bouncy spring with visible overshoot.
  static const bouncy = MotionSpring(stiffness: 300, damping: 15, mass: 1);

  /// Stiff spring that settles quickly.
  static const stiff = MotionSpring(stiffness: 400, damping: 30, mass: 1);

  /// Converts to a [SpringDescription] for use with Flutter's physics engine.
  SpringDescription toSpringDescription() =>
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping);
}
```

### Implementation Notes

- Add `this.spring` (nullable `MotionSpring?`) to `MotionLayout` constructor.
- In `_startMove`, when `widget.spring != null`:
  ```dart
  final springDesc = widget.spring!.toSpringDescription();
  final simulation = SpringSimulation(springDesc, 0.0, 1.0, 0.0);
  controller.animateWith(simulation);
  ```
  instead of `controller.forward()`.
- The `CurvedAnimation` wrapping is skipped when using spring (spring provides
  its own easing). Use the raw controller value in the listener.
- `duration` becomes the upper bound for spring animations. The controller still
  has a duration for `upperBound` purposes, but the spring simulation determines
  actual timing.
- Import `package:flutter/physics.dart` for `SpringSimulation` and `SpringDescription`.
- Export `MotionSpring` from `layout_motion.dart`.

### Usage Example

```dart
// Bouncy spring:
MotionLayout(
  spring: MotionSpring.bouncy,
  child: Column(children: items),
)

// Custom spring:
MotionLayout(
  spring: const MotionSpring(stiffness: 250, damping: 18, mass: 1.2),
  child: Column(children: items),
)
```

---

## 6. New Transition Presets

**Priority:** Tier 2 — Medium Impact
**Inspiration:** animated_reorderable_list (16 presets), flutter_animate (shimmer, blur)
**Files:** New files in `lib/src/transitions/`, barrel export update

### Problem

Only 3 transition pairs exist (Fade, Slide, Scale). Common visual patterns like
fade+slide combined, size grow/shrink, and 3D flips require custom subclasses.

### New Transitions

#### 6a. FadeSlideIn / FadeSlideOut

Combined fade and slide — the most commonly used animation pattern in production apps.

```dart
class FadeSlideIn extends MotionTransition {
  const FadeSlideIn({this.offset = const Offset(0, 0.15)});
  final Offset offset;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}

class FadeSlideOut extends MotionTransition {
  const FadeSlideOut({this.offset = const Offset(0, 0.15)});
  final Offset offset;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}
```

#### 6b. FadeScaleIn / FadeScaleOut

Combined fade and scale — popular for dialog/modal-like appearances.

```dart
class FadeScaleIn extends MotionTransition {
  const FadeScaleIn({this.scale = 0.8});
  final double scale;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: scale, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }
}

class FadeScaleOut extends MotionTransition {
  const FadeScaleOut({this.scale = 0.8});
  final double scale;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: scale, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }
}
```

#### 6c. SizeIn / SizeOut

Animate height/width from zero (accordion/expand-collapse effect).

```dart
class SizeIn extends MotionTransition {
  const SizeIn({this.axis = Axis.vertical, this.axisAlignment = 0.0});
  final Axis axis;
  final double axisAlignment;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return SizeTransition(
      sizeFactor: animation,
      axis: axis,
      axisAlignment: axisAlignment,
      child: child,
    );
  }
}

class SizeOut extends MotionTransition {
  const SizeOut({this.axis = Axis.vertical, this.axisAlignment = 0.0});
  final Axis axis;
  final double axisAlignment;

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return SizeTransition(
      sizeFactor: animation,
      axis: axis,
      axisAlignment: axisAlignment,
      child: child,
    );
  }
}
```

### Export Updates

Add to `lib/layout_motion.dart`:
```dart
export 'src/transitions/fade_slide_transition.dart';
export 'src/transitions/fade_scale_transition.dart';
export 'src/transitions/size_transition.dart';
export 'src/transitions/composed_transition.dart';
```

---

## 7. Per-Child Curve Control

**Priority:** Tier 2 — Medium Impact
**Inspiration:** react-flip-toolkit per-element spring override
**Files:** `motion_layout.dart`, `motion_layout_state.dart`

### Problem

A single `curve` parameter applies to all animation types (move, enter, exit).
Users often want different easing per animation type — for example, a fast ease-out
for enters but a slow ease-in for exits.

### API Design

```dart
MotionLayout(
  // Global curve (existing parameter, becomes fallback).
  curve: Curves.easeInOut,

  // Optional per-animation-type curve overrides.
  moveCurve: Curves.easeOutCubic,   // Move animations only
  enterCurve: Curves.easeOut,       // Enter transitions only
  exitCurve: Curves.easeIn,         // Exit transitions only

  child: Column(children: items),
)
```

### Implementation Notes

- Add `this.moveCurve`, `this.enterCurve`, `this.exitCurve` (all nullable `Curve?`).
- Add computed properties:
  ```dart
  Curve get effectiveMoveCurve => moveCurve ?? curve;
  Curve get effectiveEnterCurve => enterCurve ?? curve;
  Curve get effectiveExitCurve => exitCurve ?? curve;
  ```
- In `_startMove`: use `widget.effectiveMoveCurve` instead of `widget.curve`.
- In `_startEnter`: use `widget.effectiveEnterCurve` instead of `widget.curve`.
- In `_startExit`: use `widget.effectiveExitCurve` instead of `widget.curve`.
- Fully backward-compatible: existing `curve` parameter still works as the global
  default. Per-type curves only override when explicitly set.

### Usage Example

```dart
MotionLayout(
  duration: const Duration(milliseconds: 400),
  moveCurve: Curves.easeOutCubic,
  enterCurve: Curves.easeOut,
  exitCurve: Curves.easeIn,
  enterTransition: const FadeSlideIn(),
  exitTransition: const FadeOut(),
  child: Column(
    children: [
      for (final item in items)
        Card(key: ValueKey(item.id), child: Text(item.name)),
    ],
  ),
)
```

---

## Summary

| # | Feature                    | Priority | Effort  | Breaking? |
|---|----------------------------|----------|---------|-----------|
| 1 | Staggered Animations       | Tier 1   | Medium  | No        |
| 2 | Animation Lifecycle Callbacks | Tier 1 | Low     | No        |
| 3 | Transition Composition     | Tier 1   | Low     | No        |
| 4 | Auto-Detect Reduced Motion | Tier 1   | Low     | Minor*    |
| 5 | Spring Physics             | Tier 2   | Medium  | No        |
| 6 | New Transition Presets      | Tier 2   | Low     | No        |
| 7 | Per-Child Curve Control    | Tier 2   | Low     | No        |

\* Feature 4 changes `enabled` from `bool` to `bool?` with a different default.

---

## Files Changed

### Modified
- `lib/src/motion_layout.dart` — New parameters (#1, #2, #4, #5, #7)
- `lib/src/motion_layout_state.dart` — Core engine changes (#1, #2, #4, #5, #7)
- `lib/src/transitions/motion_transition.dart` — `operator+` (#3)
- `lib/src/internals/animated_child_entry.dart` — Stagger timer field (#1)
- `lib/layout_motion.dart` — New exports (#3, #5, #6)

### New Files
- `lib/src/transitions/composed_transition.dart` (#3)
- `lib/src/transitions/fade_slide_transition.dart` (#6)
- `lib/src/transitions/fade_scale_transition.dart` (#6)
- `lib/src/transitions/size_transition.dart` (#6)
- `lib/src/motion_spring.dart` (#5)
- `lib/src/stagger.dart` (#1 — StaggerFrom enum)
