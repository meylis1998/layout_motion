# layout_motion

Automatic FLIP layout animations for Flutter. Wrap any `Column`, `Row`, or `Wrap` to animate child additions, removals, and reorders with zero configuration.

## Features

- **Zero-config** — wrap your layout widget with `MotionLayout` and you're done
- **FLIP technique** — GPU-accelerated `Transform` animations (paint phase only, no relayout per frame)
- **Add / Remove / Reorder** — all detected automatically via key-based diffing
- **Customizable transitions** — built-in `FadeIn`/`FadeOut`, `SlideIn`/`SlideOut`, `ScaleIn`/`ScaleOut`
- **Interruption-safe** — mid-animation changes produce smooth redirects
- **Zero dependencies** — only depends on the Flutter SDK

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  layout_motion: ^0.1.0
```

## Usage

### Basic

```dart
MotionLayout(
  child: Column(
    children: [
      for (final item in items)
        ListTile(key: ValueKey(item.id), title: Text(item.name)),
    ],
  ),
)
```

**Important:** All children must have unique `Key`s.

### Configurable

```dart
MotionLayout(
  duration: const Duration(milliseconds: 500),
  curve: Curves.easeOutCubic,
  enterTransition: const SlideIn(offset: Offset(0, 0.15)),
  exitTransition: const FadeOut(),
  clipBehavior: Clip.hardEdge,
  child: Wrap(children: [...]),
)
```

### Supported Layouts

- `Column`
- `Row`
- `Wrap`

## API Reference

### MotionLayout

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | A `Column`, `Row`, or `Wrap` |
| `duration` | `Duration` | 300ms | Animation duration |
| `curve` | `Curve` | `Curves.easeInOut` | Animation curve |
| `enterTransition` | `MotionTransition?` | `FadeIn()` | Transition for entering children |
| `exitTransition` | `MotionTransition?` | `FadeOut()` | Transition for exiting children |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | How to clip during animation |
| `enabled` | `bool` | `true` | Set to `false` to disable all animations |

### Built-in Transitions

| Class | Description |
|---|---|
| `FadeIn` / `FadeOut` | Opacity fade |
| `SlideIn` / `SlideOut` | Fractional slide (default offset: `Offset(0, 0.15)`) |
| `ScaleIn` / `ScaleOut` | Scale (default scale: `0.8`) |

### Custom Transitions

Extend `MotionTransition`:

```dart
class MyTransition extends MotionTransition {
  const MyTransition();

  @override
  Widget build(BuildContext context, Animation<double> animation, Widget child) {
    return RotationTransition(turns: animation, child: child);
  }
}
```

## How It Works

**FLIP** = First, Last, Invert, Play

1. **First** — Before layout changes, capture child positions
2. **Diff** — Key-based diffing with LIS (Longest Increasing Subsequence) for minimal move detection
3. **Last** — After Flutter lays out the new state, capture new positions
4. **Invert** — Apply a `Transform.translate` equal to (old position - new position)
5. **Play** — Animate the transform to zero, children visually glide to their new spots

Exit animations keep removed children in the tree until the animation completes. Enter animations fade/slide/scale new children in.

## License

MIT
