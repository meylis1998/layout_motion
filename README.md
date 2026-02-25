# layout_motion

[![pub package](https://img.shields.io/pub/v/layout_motion.svg)](https://pub.dev/packages/layout_motion)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Automatic FLIP layout animations for Flutter. Wrap any `Column`, `Row`, `Wrap`, `Stack`, or `GridView` to animate child additions, removals, and reorders with zero configuration. Plus scrollable animated lists, shared element transitions, size morphing, and scroll-triggered animations.

## Features

### Core
- **Zero-config** — wrap your layout widget with `MotionLayout` and you're done
- **FLIP technique** — GPU-accelerated `Transform` animations (paint phase only, no relayout per frame)
- **Add / Remove / Reorder** — all detected automatically via key-based diffing
- **Column, Row, Wrap, Stack, GridView** — all supported layout types
- **Staggered animations** — cascading delays with configurable direction (dual-axis for grids)
- **Spring physics** — physics-based move animations with named presets
- **Transition composition** — combine transitions with `+` operator: `FadeIn() + SlideIn()`
- **Drag-to-reorder** — long-press and drag to reorder with smooth FLIP animations
- **Size morphing** — animate size changes of existing children with `animateSizeChanges: true`

### Scrollable Lists & Grids
- **`MotionListView`** — animated scrollable list with `children` and `.builder` constructors
- **`MotionGridView`** — animated scrollable grid with `children` and `.builder` constructors
- **Lazy building** — `.builder` mode only builds visible items via slivers

### Shared Element Transitions
- **`MotionLayoutScope`** — coordinates cross-tree FLIP animations via a registry/graveyard pattern
- **`MotionLayoutId`** — marks a widget for shared element animations (same-page Hero alternative)
- **`MotionLayoutGroup`** — namespace isolation for independent animation contexts

### Scroll-Triggered Animations
- **`ScrollAwareMotionLayout`** — animates children as they first scroll into the viewport

### General
- **Auto reduced motion** — respects system accessibility settings by default
- **Interruption-safe** — mid-animation changes produce smooth redirects
- **Accessible** — exiting children are excluded from the semantic tree
- **Zero dependencies** — only depends on the Flutter SDK

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  layout_motion: ^1.1.0
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

### Staggered Animations

```dart
MotionLayout(
  duration: const Duration(milliseconds: 400),
  staggerDuration: const Duration(milliseconds: 50),
  staggerFrom: StaggerFrom.first, // or .last, .center
  enterTransition: const FadeSlideIn(),
  exitTransition: const FadeOut(),
  child: Column(children: [...]),
)
```

### Spring Physics

```dart
MotionLayout(
  spring: MotionSpring.bouncy, // or .gentle, .smooth, .stiff
  child: Column(children: [...]),
)

// Custom spring:
MotionLayout(
  spring: const MotionSpring(stiffness: 250, damping: 18, mass: 1.2),
  child: Column(children: [...]),
)
```

### Transition Composition

Combine multiple transitions with the `+` operator:

```dart
MotionLayout(
  enterTransition: const FadeIn() + const SlideIn() + const ScaleIn(scale: 0.9),
  exitTransition: const FadeOut() + const ScaleOut(scale: 0.5),
  child: Column(children: [...]),
)
```

### Per-Child Curve Control

```dart
MotionLayout(
  moveCurve: Curves.easeOutCubic,
  enterCurve: Curves.easeOut,
  exitCurve: Curves.easeIn,
  child: Column(children: [...]),
)
```

### Lifecycle Callbacks

```dart
MotionLayout(
  onAnimationStart: () => print('Animations started'),
  onAnimationComplete: () => print('All done'),
  onChildEnter: (key) => print('$key entering'),
  onChildExit: (key) => print('$key exiting'),
  child: Column(children: [...]),
)
```

### Drag-to-Reorder

```dart
MotionLayout(
  onReorder: (int oldIndex, int newIndex) {
    setState(() {
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });
  },
  dragDecorator: (Widget child) {
    return Material(elevation: 8, borderRadius: BorderRadius.circular(12), child: child);
  },
  child: Column(children: [...]),
)
```

When `onReorder` is non-null, children become reorderable via long-press drag. Non-dragged children animate smoothly via FLIP as the insertion point changes.

### Pop Exit Mode

```dart
MotionLayout(
  exitLayoutBehavior: ExitLayoutBehavior.pop,
  child: Column(children: [...]),
)
```

In `pop` mode, exiting children are immediately removed from the layout flow and animate out at their last known position as an overlay. Remaining children slide into the freed space instantly.

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

### GridView

```dart
MotionLayout(
  enterTransition: const FadeScaleIn(),
  spring: MotionSpring.smooth,
  staggerDuration: const Duration(milliseconds: 30),
  child: GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    children: [
      for (final item in items)
        Card(key: ValueKey(item.id), child: Text(item.name)),
    ],
  ),
)
```

### Size Morphing

```dart
MotionLayout(
  animateSizeChanges: true,
  child: Column(
    children: [
      for (final item in items)
        ExpandableCard(
          key: ValueKey(item.id),
          expanded: item.isExpanded,
          child: Text(item.content),
        ),
    ],
  ),
)
```

### Scroll-Triggered Animations

```dart
SingleChildScrollView(
  child: ScrollAwareMotionLayout(
    visibilityThreshold: 0.1,
    animateOnce: true,
    enterTransition: const FadeSlideIn(),
    staggerDuration: const Duration(milliseconds: 80),
    child: Column(
      children: [
        for (final item in items)
          ListTile(key: ValueKey(item.id), title: Text(item.name)),
      ],
    ),
  ),
)
```

### MotionListView

```dart
// Children mode (small lists — wraps MotionLayout in a scroll view)
MotionListView(
  enterTransition: const FadeSlideIn(),
  exitTransition: const FadeOut(),
  children: [
    for (final item in items)
      ListTile(key: ValueKey(item.id), title: Text(item.name)),
  ],
)

// Builder mode (large lists — lazy sliver-based rendering)
MotionListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ListTile(
    key: ValueKey(items[index].id),
    title: Text(items[index].name),
  ),
  keyBuilder: (index) => ValueKey(items[index].id),
  enterTransition: const FadeSlideIn(),
)
```

### MotionGridView

```dart
MotionGridView(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
  enterTransition: const FadeScaleIn(),
  children: [
    for (final item in items)
      Card(key: ValueKey(item.id), child: Text(item.name)),
  ],
)
```

### Shared Element Transitions

```dart
MotionLayoutScope(
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOutCubic,
  child: Scaffold(
    body: showGrid
      ? GridView(children: [
          for (final item in items)
            MotionLayoutId(id: 'item-${item.id}', child: ItemCard(item)),
        ])
      : ListView(children: [
          for (final item in items)
            MotionLayoutId(id: 'item-${item.id}', child: ItemTile(item)),
        ]),
  ),
)
```

With namespace isolation:

```dart
MotionLayoutScope(
  child: Column(children: [
    MotionLayoutGroup(
      namespace: 'favorites',
      child: Row(children: [
        for (final fav in favorites)
          MotionLayoutId(id: fav.id, child: FavChip(fav)),
      ]),
    ),
    MotionLayoutGroup(
      namespace: 'all',
      child: ListView(children: [
        for (final item in all)
          MotionLayoutId(id: item.id, child: ItemTile(item)),
      ]),
    ),
  ]),
)
```

### Supported Layouts

- `Column`
- `Row`
- `Wrap`
- `Stack`
- `GridView`

## Migrating from v0.3.x

v0.4.0 changes the `enabled` parameter from `bool` (default `true`) to `bool?` (default `null`):

- **`null` (new default)** — auto-detects reduced motion from `MediaQuery.disableAnimations`
- **`true`** — always animate (previous default behavior)
- **`false`** — never animate

If you relied on the default `enabled: true` and don't want auto reduced-motion, pass `enabled: true` explicitly.

## Migrating from v0.1.0

v0.2.0 renamed the scale transition parameters for consistency:

- `ScaleIn.beginScale` → `ScaleIn.scale`
- `ScaleOut.endScale` → `ScaleOut.scale`

## API Reference

### MotionLayout

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | A `Column`, `Row`, `Wrap`, `Stack`, or `GridView` |
| `duration` | `Duration` | 300ms | Move animation duration (fallback for enter/exit transitions) |
| `curve` | `Curve` | `Curves.easeInOut` | Animation curve (fallback for per-type curves) |
| `enterTransition` | `MotionTransition?` | `FadeIn()` | Transition for entering children |
| `exitTransition` | `MotionTransition?` | `FadeOut()` | Transition for exiting children |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | How to clip during animation |
| `enabled` | `bool?` | `null` | `null` = auto-detect reduced motion, `true` = always animate, `false` = disable |
| `moveThreshold` | `double` | `0.5` | Minimum position delta (logical pixels) to trigger a move animation |
| `transitionDuration` | `Duration?` | `null` | Duration for enter/exit transitions (falls back to `duration`) |
| `staggerDuration` | `Duration` | `Duration.zero` | Delay between each child's animation start |
| `staggerFrom` | `StaggerFrom` | `.first` | Direction of stagger cascade (`.first`, `.last`, `.center`) |
| `spring` | `MotionSpring?` | `null` | Spring physics for move animations (overrides `curve`/`moveCurve`) |
| `moveCurve` | `Curve?` | `null` | Curve override for move animations (falls back to `curve`) |
| `enterCurve` | `Curve?` | `null` | Curve override for enter transitions (falls back to `curve`) |
| `exitCurve` | `Curve?` | `null` | Curve override for exit transitions (falls back to `curve`) |
| `onAnimationStart` | `VoidCallback?` | `null` | Called when any animation starts |
| `onAnimationComplete` | `VoidCallback?` | `null` | Called when all animations complete |
| `onChildEnter` | `ValueChanged<Key>?` | `null` | Called when a child begins entering |
| `onChildExit` | `ValueChanged<Key>?` | `null` | Called when a child begins exiting |
| `onChildMove` | `ValueChanged<Key>?` | `null` | Called when a child begins moving |
| `exitLayoutBehavior` | `ExitLayoutBehavior` | `.maintain` | How exiting children affect layout (`.maintain` or `.pop`) |
| `onReorder` | `void Function(int, int)?` | `null` | Called on drag-reorder with old and new indices. Enables drag when non-null. |
| `dragDecorator` | `Widget Function(Widget)?` | `null` | Decorates the floating drag proxy during reorder |
| `animateSizeChanges` | `bool` | `false` | Animate size changes of existing children |
| `sizeChangeThreshold` | `double` | `2.0` | Minimum size delta to trigger morph animation |
| `onChildSizeChange` | `ValueChanged<Key>?` | `null` | Called when a child begins a size morph |
| `animateOnFirstBuild` | `bool` | `false` | Whether children animate on initial build |

### MotionSpring

| Preset | Stiffness | Damping | Mass | Character |
|---|---|---|---|---|
| `MotionSpring.gentle` | 120 | 20 | 1 | Soft, minimal bounce |
| `MotionSpring.smooth` | 200 | 22 | 1 | Natural feel |
| `MotionSpring.bouncy` | 300 | 15 | 1 | Visible overshoot |
| `MotionSpring.stiff` | 400 | 30 | 1 | Settles quickly |

### Built-in Transitions

| Class | Description |
|---|---|
| `FadeIn` / `FadeOut` | Opacity fade |
| `SlideIn` / `SlideOut` | Fractional slide (default offset: `Offset(0, 0.15)`) |
| `ScaleIn` / `ScaleOut` | Scale (default scale: `0.8`) |
| `FadeSlideIn` / `FadeSlideOut` | Combined fade + slide |
| `FadeScaleIn` / `FadeScaleOut` | Combined fade + scale |
| `SizeIn` / `SizeOut` | Accordion/expand-collapse size transition |

### Transition Composition

Use the `+` operator to combine any transitions:

```dart
const FadeIn() + const SlideIn()                    // fade + slide
const FadeOut() + const ScaleOut(scale: 0.5)         // fade + scale
const FadeIn() + const SlideIn() + const ScaleIn()   // triple combo
```

Or use the constructor directly:

```dart
const ComposedTransition([FadeIn(), SlideIn(), ScaleIn()])
```

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

`MotionLayout` only supports `Column`, `Row`, `Wrap`, `Stack`, and `GridView` as the direct child. For scrollable lists, use `MotionListView` or `MotionGridView` instead.

### Children overlap during animation

Adjust the `clipBehavior` parameter. The default `Clip.hardEdge` clips overflowing children. Use `Clip.none` to allow children to paint outside the layout bounds during animation.

### Performance with many items

For large lists, use `MotionListView.builder` or `MotionGridView.builder` which only build visible items. For `MotionLayout`, set `enabled: false` during bulk updates to skip animation processing entirely.

## Accessibility

### Reduced Motion

Animations are automatically disabled when the user has enabled "Reduce motion" in their system accessibility settings. `MotionLayout` reads `MediaQuery.disableAnimations` by default (when `enabled` is `null`).

To override the system setting:

```dart
// Always animate (ignore system preference):
MotionLayout(enabled: true, child: Column(children: [...]))

// Always disable (force instant layout):
MotionLayout(enabled: false, child: Column(children: [...]))
```

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
