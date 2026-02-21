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
