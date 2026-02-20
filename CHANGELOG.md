## 0.1.0

- Initial release
- `MotionLayout` widget with FLIP animation engine
- Supports `Column`, `Row`, and `Wrap` layouts
- Key-based diffing with LIS for optimal move detection
- Built-in transitions: `FadeIn`/`FadeOut`, `SlideIn`/`SlideOut`, `ScaleIn`/`ScaleOut`
- Custom transitions via `MotionTransition` base class
- Interruption-safe animations with smooth redirects
- `enabled` flag and `Duration.zero` for instant mode
