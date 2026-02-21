# layout_motion

[![pub package](https://img.shields.io/pub/v/layout_motion.svg)](https://pub.dev/packages/layout_motion)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Automatic FLIP layout animations for Flutter. Wrap any `Column`, `Row`, `Wrap`, or `Stack` to animate child additions, removals, and reorders with zero configuration.

## Features

- **Zero-config** — wrap your layout widget with `MotionLayout` and you're done
- **FLIP technique** — GPU-accelerated `Transform` animations (paint phase only, no relayout per frame)
- **Add / Remove / Reorder** — all detected automatically via key-based diffing
- **Customizable transitions** — built-in `FadeIn`/`FadeOut`, `SlideIn`/`SlideOut`, `ScaleIn`/`ScaleOut`
- **Interruption-safe** — mid-animation changes produce smooth redirects
- **Accessible** — exiting children are excluded from the semantic tree and pointer events
- **Zero dependencies** — only depends on the Flutter SDK

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  layout_motion: ^0.3.2
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

### Row

```dart
MotionLayout(
  enterTransition: const SlideIn(offset: Offset(0.15, 0)),
  exitTransition: const FadeOut(),
  child: Row(
    children: [
      for (final tag in tags)
        Chip(key: ValueKey(tag), label: Text(tag)),
    ],
  ),
)
```

### Stack

```dart
MotionLayout(
  child: Stack(
    children: [
      for (final item in items)
        Positioned(
          key: ValueKey(item.id),
          left: item.x,
          top: item.y,
          child: Text(item.name),
        ),
    ],
  ),
)
```

### Supported Layouts

- `Column`
- `Row`
- `Wrap`
- `Stack`

## Migrating from v0.1.0

v0.2.0 renamed the scale transition parameters for consistency:

- `ScaleIn.beginScale` → `ScaleIn.scale`
- `ScaleOut.endScale` → `ScaleOut.scale`

## API Reference

### MotionLayout

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | A `Column`, `Row`, `Wrap`, or `Stack` |
| `duration` | `Duration` | 300ms | Move animation duration (fallback for enter/exit transitions) |
| `curve` | `Curve` | `Curves.easeInOut` | Animation curve |
| `enterTransition` | `MotionTransition?` | `FadeIn()` | Transition for entering children |
| `exitTransition` | `MotionTransition?` | `FadeOut()` | Transition for exiting children |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | How to clip during animation |
| `enabled` | `bool` | `true` | Set to `false` to disable all animations |
| `moveThreshold` | `double` | `0.5` | Minimum position delta (logical pixels) to trigger a move animation |
| `transitionDuration` | `Duration?` | `null` | Duration for enter/exit transitions (falls back to `duration`) |

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

## Troubleshooting

### Animations not working

Ensure all children have unique `Key`s. Without keys, Flutter cannot track which children were added, removed, or reordered.

### Unsupported layout type

`MotionLayout` only supports `Column`, `Row`, `Wrap`, and `Stack` as the direct child. Other layout widgets are not supported.

### Children overlap during animation

Adjust the `clipBehavior` parameter. The default `Clip.hardEdge` clips overflowing children. Use `Clip.none` to allow children to paint outside the layout bounds during animation.

### Performance with many items

For large lists where you temporarily need to disable animations (e.g. during bulk updates), set `enabled: false` to skip animation processing entirely.

## Accessibility

### Reduced Motion

Respect user preferences for reduced motion by integrating with `MediaQuery.disableAnimations`:

```dart
MotionLayout(
  enabled: !MediaQuery.of(context).disableAnimations,
  child: Column(children: [...]),
)
```

This disables all animations when the user has enabled "Reduce motion" in their system accessibility settings.

### Screen Readers

Exiting children are automatically wrapped in `ExcludeSemantics` and `IgnorePointer`, so screen readers skip disappearing elements and users cannot interact with them during exit animations.

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
