## 1.1.0

- **NEW:** Shared element transitions — `MotionLayoutScope`, `MotionLayoutId`, and `MotionLayoutGroup` enable cross-tree FLIP animations. Two widgets with the same `id` automatically animate between positions when one unmounts and the other mounts. Supports namespace isolation, spring physics, content cross-fade, and graveyard timeout.
- Add Shared Element demo to example app

## 1.0.0

- **NEW:** `MotionListView` — animated scrollable list with `children` and `.builder` constructors. Children mode wraps `SingleChildScrollView` + FLIP engine; builder mode uses `CustomScrollView` + `SliverList` with per-item enter/exit animations.
- **NEW:** `MotionGridView` — animated scrollable grid with `children` and `.builder` constructors. Same two-tier architecture with `gridDelegate` support.
- Add MotionListView demo to example app

## 0.10.0

- **NEW:** Scroll-triggered animations — `ScrollAwareMotionLayout` animates children as they scroll into the viewport. Supports `visibilityThreshold`, `animateOnce`, and stagger integration.
- **NEW:** `animateOnFirstBuild` parameter on `MotionLayout` — controls whether children animate on initial build (default `false` for backward compatibility).
- Add Scroll-Triggered demo to example app

## 0.9.0

- **NEW:** Size morphing — `animateSizeChanges: true` on `MotionLayout` detects when an existing child changes size and smoothly interpolates using ClipRect + SizedOverflowBox. Siblings FLIP to new positions during the morph.
- **NEW:** `sizeChangeThreshold` parameter — minimum size delta to trigger morph animation (default 2.0 pixels).
- **NEW:** `onChildSizeChange` callback — fires when a child begins a size morph animation.
- Add Size Morphing demo to example app

## 0.8.0

- **NEW:** GridView support — `MotionLayout` now accepts `GridView` as a child layout type with full FLIP, dual-axis stagger, and drag-to-reorder support.
- Add GridView demo to example app

## 0.5.0

- **NEW:** Drag-to-Reorder — long-press and drag children to reorder with smooth FLIP animations for siblings. Set `onReorder` to enable. Customize the dragged child appearance with `dragDecorator`.
- **NEW:** `ExitLayoutBehavior.pop` — exiting children are immediately removed from layout flow and animate out as positioned overlays. Remaining children slide into freed space instantly. Set `exitLayoutBehavior: ExitLayoutBehavior.pop` to enable.
- **NEW:** `onChildMove` callback — fires when a child begins its move animation, completing the lifecycle callback set alongside `onChildEnter` and `onChildExit`.
- Add Drag-to-Reorder and Pop Exit Mode demos to example app

## 0.4.0

- **NEW:** Staggered animations — cascading delays with `staggerDuration` and `staggerFrom` (`first`, `last`, `center`)
- **NEW:** Animation lifecycle callbacks — `onAnimationStart`, `onAnimationComplete`, `onChildEnter`, `onChildExit`
- **NEW:** Auto-detect reduced motion — `enabled` is now `bool?` (nullable); `null` (default) auto-reads `MediaQuery.disableAnimations`
- **NEW:** Spring physics — `MotionSpring` class with presets (`gentle`, `smooth`, `bouncy`, `stiff`) for physics-based move animations
- **NEW:** Per-child curve control — `moveCurve`, `enterCurve`, `exitCurve` override the global `curve` per animation type
- **NEW:** Transition composition — use `operator+` to combine transitions: `const FadeIn() + const SlideIn()`
- **NEW:** `FadeSlideIn`/`FadeSlideOut` — combined fade + slide preset
- **NEW:** `FadeScaleIn`/`FadeScaleOut` — combined fade + scale preset
- **NEW:** `SizeIn`/`SizeOut` — accordion/expand-collapse size transition
- **BREAKING:** `enabled` parameter changed from `bool` (default `true`) to `bool?` (default `null`). Pass `enabled: true` to restore the previous behavior.

## 0.3.3

- **FIX:** Snap exiting children to their pre-removal visual position so they don't jump during exit transitions
- **FIX:** Stop in-progress move animations when exit starts to prevent offset override
- **FIX:** Include exiting children in snapshot capture for correct position tracking
- Add constructor assertion validating child is Column, Row, Wrap, or Stack
- Add Stack layout demo and Advanced Options demo to example app
- Add animation lifecycle stress tests (23 tests covering rapid updates, interruption, disposal)
- Fix example widget test (was broken boilerplate referencing wrong class)
- Add `flutter_test` and `flutter_lints` to example dev_dependencies
- Exclude `example/` from root analyzer to prevent cross-package analysis errors
- Add GitHub Sponsors funding link to pubspec

## 0.3.2

- **FIX:** Preserve `spacing` property when cloning `Column` and `Row` (Flutter 3.27+)
- **FIX:** Detect duplicate keys and throw `ArgumentError` instead of silently corrupting state
- Wrap exiting children in `ExcludeSemantics` so screen readers skip disappearing elements
- Add shared test helpers (`TestColumnApp`, `TestRowApp`) and new tests for spacing, duplicate keys, semantics, clipBehavior, and enabled toggling
- Add `.claude/` and `coverage/` to `.gitignore`; add `.claude/` and `.github/` to `.pubignore`

## 0.3.1

- **FIX:** Dispose `CurvedAnimation` objects before their parent controllers to prevent listener leaks
- **FIX:** Defer `_entries.remove()` in exit status listener to avoid map mutation during iteration
- **FIX:** Replace per-frame `setState` in move animations with scoped `AnimatedBuilder` rebuilds
- Guard status listeners against double-disposal when animations race
- Extract `AnimatedChildEntry.idle()` factory to deduplicate entry creation
- Update README: add `Stack` references, `moveThreshold`/`transitionDuration` to API table, bump version

## 0.3.0

- **FIX:** Key validation now throws `ArgumentError` in release builds (was assert-only)
- Add configurable `moveThreshold` parameter to control sub-pixel move filtering
- Add `transitionDuration` parameter for independent enter/exit animation timing
- Add `Stack` layout support
- Improve `AnimatedChildEntry` test coverage (`isAnimating`, `dispose()`)
- Add `DiffResult.toString()` and `ChildSnapshot.hashCode` coverage tests

## 0.2.1

- Add scale parameter assertions to `ScaleIn`/`ScaleOut` constructors
- Add clarifying code comments for reversed animation and listener patterns
- Add README badges, migration guide, troubleshooting, and accessibility docs
- Add Row usage example to README
- Add Row layout demo to example app
- Add GitHub Actions CI and docs workflows
- Add RTL (right-to-left) tests
- Add performance tests with large child counts

## 0.2.0

- **BREAKING:** Rename `ScaleIn.beginScale` → `ScaleIn.scale` and `ScaleOut.endScale` → `ScaleOut.scale` for consistent parameter naming
- Extract move-animation threshold to named constant `_moveThreshold` with documentation
- Add comprehensive transition tests (FadeIn/Out, SlideIn/Out, ScaleIn/Out, custom transitions)
- Add move animation tests (reorder, interruption, sub-pixel threshold, Row support, combined add/remove+move)

## 0.1.0

- Initial release
- `MotionLayout` widget with FLIP animation engine
- Supports `Column`, `Row`, and `Wrap` layouts
- Key-based diffing with LIS for optimal move detection
- Built-in transitions: `FadeIn`/`FadeOut`, `SlideIn`/`SlideOut`, `ScaleIn`/`ScaleOut`
- Custom transitions via `MotionTransition` base class
- Interruption-safe animations with smooth redirects
- `enabled` flag and `Duration.zero` for instant mode
