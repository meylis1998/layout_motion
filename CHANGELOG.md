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
