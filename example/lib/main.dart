import 'dart:math';
import 'package:flutter/material.dart';
import 'package:layout_motion/layout_motion.dart';

void main() => runApp(const LayoutMotionExampleApp());

class LayoutMotionExampleApp extends StatelessWidget {
  const LayoutMotionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'layout_motion Demo',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const DemoSelector(),
    );
  }
}

class DemoSelector extends StatelessWidget {
  const DemoSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('layout_motion Demos')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Basic List (Add / Remove)'),
            subtitle: const Text('Column with animated insert and delete'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasicListDemo()),
            ),
          ),
          ListTile(
            title: const Text('Reorder'),
            subtitle: const Text('Shuffle items and watch them animate'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReorderDemo()),
            ),
          ),
          ListTile(
            title: const Text('Wrap Reflow'),
            subtitle: const Text('Responsive Wrap with animated reflow'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WrapReflowDemo()),
            ),
          ),
          ListTile(
            title: const Text('Row Layout'),
            subtitle: const Text('Horizontal row with animated add/remove'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RowDemo()),
            ),
          ),
          ListTile(
            title: const Text('Stack Layout'),
            subtitle: const Text('Positioned boxes with animated shuffling'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StackDemo()),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Stagger + Spring'),
            subtitle: const Text('Cascading spring-based animations'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaggerSpringDemo()),
            ),
          ),
          ListTile(
            title: const Text('Transition Composition'),
            subtitle: const Text('Combine fade + slide + scale with operator+'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompositionDemo()),
            ),
          ),
          ListTile(
            title: const Text('Lifecycle Callbacks'),
            subtitle: const Text('React to animation start/complete events'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CallbacksDemo()),
            ),
          ),
          ListTile(
            title: const Text('Advanced Options'),
            subtitle: const Text('Toggle enabled, clip, threshold, timing'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdvancedOptionsDemo()),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Drag-to-Reorder'),
            subtitle: const Text('Long-press and drag to reorder with FLIP'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DragReorderDemo()),
            ),
          ),
          ListTile(
            title: const Text('Pop Exit Mode'),
            subtitle: const Text(
              'Exiting children leave layout flow instantly',
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PopExitDemo()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'v0.8.0 \u2013 v1.1.0',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            title: const Text('GridView'),
            subtitle: const Text('Animated grid with 2D FLIP and stagger'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GridViewDemo()),
            ),
          ),
          ListTile(
            title: const Text('Size Morphing'),
            subtitle: const Text('Expandable cards with smooth size animation'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SizeMorphDemo()),
            ),
          ),
          ListTile(
            title: const Text('Scroll-Triggered'),
            subtitle: const Text('Children animate as they scroll into view'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScrollTriggeredDemo()),
            ),
          ),
          ListTile(
            title: const Text('MotionListView'),
            subtitle: const Text('Animated scrollable list with add/remove'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MotionListViewDemo()),
            ),
          ),
          ListTile(
            title: const Text('Shared Element'),
            subtitle: const Text('Cross-tree FLIP between grid and detail'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SharedElementDemo()),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 1: Basic List — Add/Remove items from a Column
// ---------------------------------------------------------------------------
class BasicListDemo extends StatefulWidget {
  const BasicListDemo({super.key});

  @override
  State<BasicListDemo> createState() => _BasicListDemoState();
}

class _BasicListDemoState extends State<BasicListDemo> {
  final _items = <int>[1, 2, 3];
  int _nextId = 4;

  void _addItem() {
    setState(() {
      _items.add(_nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic List')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MotionLayout(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          enterTransition: const SlideIn(offset: Offset(0, 0.15)),
          exitTransition: const FadeOut(),
          child: Column(
            children: [
              for (final id in _items)
                Card(
                  key: ValueKey(id),
                  child: ListTile(
                    title: Text('Item $id'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeItem(id),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 2: Reorder — Shuffle items, watch them animate to new positions
// ---------------------------------------------------------------------------
class ReorderDemo extends StatefulWidget {
  const ReorderDemo({super.key});

  @override
  State<ReorderDemo> createState() => _ReorderDemoState();
}

class _ReorderDemoState extends State<ReorderDemo> {
  var _items = List.generate(8, (i) => i + 1);

  void _shuffle() {
    setState(() {
      _items = List.of(_items)..shuffle(Random());
    });
  }

  void _sort() {
    setState(() {
      _items.sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _sort,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: _shuffle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MotionLayout(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          child: Column(
            children: [
              for (final id in _items)
                Card(
                  key: ValueKey(id),
                  color: Colors.primaries[id % Colors.primaries.length]
                      .withValues(alpha: 0.3),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('$id')),
                    title: Text('Item $id'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 3: Wrap Reflow — Responsive Wrap that animates when items reflow
// ---------------------------------------------------------------------------
class WrapReflowDemo extends StatefulWidget {
  const WrapReflowDemo({super.key});

  @override
  State<WrapReflowDemo> createState() => _WrapReflowDemoState();
}

class _WrapReflowDemoState extends State<WrapReflowDemo> {
  var _tags = <String>[
    'Flutter',
    'Dart',
    'Animation',
    'FLIP',
    'Layout',
    'Motion',
    'Widget',
    'Package',
  ];
  int _nextId = 0;

  void _addTag() {
    setState(() {
      _tags.add('Tag ${_nextId++}');
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _shuffle() {
    setState(() {
      _tags = List.of(_tags)..shuffle(Random());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrap Reflow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: _shuffle,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Tag',
            onPressed: _addTag,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MotionLayout(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          enterTransition: const ScaleIn(scale: 0.5),
          exitTransition: const ScaleOut(scale: 0.5),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                Chip(
                  key: ValueKey(tag),
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 4: Row Layout — Horizontal row with add/remove/shuffle
// ---------------------------------------------------------------------------
class RowDemo extends StatefulWidget {
  const RowDemo({super.key});

  @override
  State<RowDemo> createState() => _RowDemoState();
}

class _RowDemoState extends State<RowDemo> {
  var _items = <int>[1, 2, 3, 4, 5];
  int _nextId = 6;

  void _addItem() {
    setState(() {
      _items.add(_nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.remove(id);
    });
  }

  void _shuffle() {
    setState(() {
      _items = List.of(_items)..shuffle(Random());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Row Layout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: _shuffle,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _addItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: MotionLayout(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          enterTransition: const SlideIn(offset: Offset(0.15, 0)),
          exitTransition: const ScaleOut(),
          child: Row(
            children: [
              for (final id in _items)
                Padding(
                  key: ValueKey(id),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    avatar: CircleAvatar(
                      radius: 12,
                      child: Text('$id', style: const TextStyle(fontSize: 11)),
                    ),
                    label: Text('Item $id'),
                    onPressed: () => _removeItem(id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 5: Stack Layout — Positioned boxes that animate within a Stack
// ---------------------------------------------------------------------------
class StackDemo extends StatefulWidget {
  const StackDemo({super.key});

  @override
  State<StackDemo> createState() => _StackDemoState();
}

class _StackDemoState extends State<StackDemo> {
  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  static const _boxSize = 80.0;
  static const _stackWidth = 320.0;
  static const _stackHeight = 400.0;

  final _rng = Random();
  int _nextId = 5;

  /// Each box stores its id, position, and color index.
  var _boxes = <_StackBox>[
    const _StackBox(id: 1, left: 20, top: 20, colorIndex: 0),
    const _StackBox(id: 2, left: 160, top: 40, colorIndex: 1),
    const _StackBox(id: 3, left: 60, top: 180, colorIndex: 2),
    const _StackBox(id: 4, left: 200, top: 260, colorIndex: 3),
  ];

  /// Randomise positions for every box within the stack bounds.
  void _shufflePositions() {
    setState(() {
      _boxes = [
        for (final box in _boxes)
          box.copyWith(
            left: _rng.nextDouble() * (_stackWidth - _boxSize),
            top: _rng.nextDouble() * (_stackHeight - _boxSize),
          ),
      ];
    });
  }

  void _addBox() {
    final id = _nextId++;
    setState(() {
      _boxes.add(
        _StackBox(
          id: id,
          left: _rng.nextDouble() * (_stackWidth - _boxSize),
          top: _rng.nextDouble() * (_stackHeight - _boxSize),
          colorIndex: id % _colors.length,
        ),
      );
    });
  }

  void _removeBox(int id) {
    setState(() {
      _boxes = _boxes.where((b) => b.id != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stack Layout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle Positions',
            onPressed: _shufflePositions,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove Last',
            onPressed: _boxes.isNotEmpty
                ? () => _removeBox(_boxes.last.id)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Box',
            onPressed: _addBox,
          ),
        ],
      ),
      body: Center(
        child: MotionLayout(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          enterTransition: const ScaleIn(scale: 0.3),
          exitTransition: const ScaleOut(scale: 0.3),
          child: Stack(
            children: [
              // Invisible sizing widget to keep the Stack at a fixed size.
              const SizedBox(
                key: ValueKey('__stack_sizer__'),
                width: _stackWidth,
                height: _stackHeight,
              ),
              for (final box in _boxes)
                Positioned(
                  key: ValueKey(box.id),
                  left: box.left,
                  top: box.top,
                  width: _boxSize,
                  height: _boxSize,
                  child: GestureDetector(
                    onTap: () => _removeBox(box.id),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _colors[box.colorIndex].withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${box.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple data class for a box in the [StackDemo].
class _StackBox {
  const _StackBox({
    required this.id,
    required this.left,
    required this.top,
    required this.colorIndex,
  });

  final int id;
  final double left;
  final double top;
  final int colorIndex;

  _StackBox copyWith({double? left, double? top}) {
    return _StackBox(
      id: id,
      left: left ?? this.left,
      top: top ?? this.top,
      colorIndex: colorIndex,
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 6: Stagger + Spring — Cascading spring-based animations
// ---------------------------------------------------------------------------
class StaggerSpringDemo extends StatefulWidget {
  const StaggerSpringDemo({super.key});

  @override
  State<StaggerSpringDemo> createState() => _StaggerSpringDemoState();
}

class _StaggerSpringDemoState extends State<StaggerSpringDemo> {
  var _items = List.generate(6, (i) => i + 1);
  int _nextId = 7;
  MotionSpring _spring = MotionSpring.bouncy;
  StaggerFrom _staggerFrom = StaggerFrom.first;
  int _staggerMs = 50;

  void _addItem() {
    setState(() {
      _items.add(_nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.remove(id);
    });
  }

  void _shuffle() {
    setState(() {
      _items = List.of(_items)..shuffle(Random());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stagger + Spring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: _shuffle,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove Last',
            onPressed: _items.isNotEmpty
                ? () => _removeItem(_items.last)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Spring preset selector.
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8),
                          child: Text('Spring Preset'),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'gentle', label: Text('Gentle')),
                              ButtonSegment(value: 'smooth', label: Text('Smooth')),
                              ButtonSegment(value: 'bouncy', label: Text('Bouncy')),
                              ButtonSegment(value: 'stiff', label: Text('Stiff')),
                            ],
                            selected: {
                              _spring == MotionSpring.gentle
                                  ? 'gentle'
                                  : _spring == MotionSpring.smooth
                                  ? 'smooth'
                                  : _spring == MotionSpring.bouncy
                                  ? 'bouncy'
                                  : 'stiff',
                            },
                            onSelectionChanged: (v) {
                              setState(() {
                                _spring = switch (v.first) {
                                  'gentle' => MotionSpring.gentle,
                                  'smooth' => MotionSpring.smooth,
                                  'bouncy' => MotionSpring.bouncy,
                                  _ => MotionSpring.stiff,
                                };
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Stagger direction selector.
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8),
                          child: Text('Stagger From'),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<StaggerFrom>(
                            segments: const [
                              ButtonSegment(
                                value: StaggerFrom.first,
                                label: Text('First'),
                              ),
                              ButtonSegment(
                                value: StaggerFrom.last,
                                label: Text('Last'),
                              ),
                              ButtonSegment(
                                value: StaggerFrom.center,
                                label: Text('Center'),
                              ),
                            ],
                            selected: {_staggerFrom},
                            onSelectionChanged: (v) {
                              setState(() => _staggerFrom = v.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Stagger delay slider.
                  ListTile(
                    title: Text('Stagger Delay: ${_staggerMs}ms'),
                    subtitle: Slider(
                      min: 0,
                      max: 200,
                      divisions: 20,
                      value: _staggerMs.toDouble(),
                      label: '${_staggerMs}ms',
                      onChanged: (v) => setState(() => _staggerMs = v.round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MotionLayout(
                duration: const Duration(milliseconds: 600),
                spring: _spring,
                staggerDuration: Duration(milliseconds: _staggerMs),
                staggerFrom: _staggerFrom,
                enterTransition: const FadeSlideIn(),
                exitTransition: const FadeOut(),
                child: Column(
                  children: [
                    for (final id in _items)
                      Card(
                        key: ValueKey(id),
                        color: Colors.primaries[id % Colors.primaries.length]
                            .withValues(alpha: 0.25),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('$id')),
                          title: Text('Item $id'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeItem(id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 7: Transition Composition — Combine transitions with operator+
// ---------------------------------------------------------------------------
class CompositionDemo extends StatefulWidget {
  const CompositionDemo({super.key});

  @override
  State<CompositionDemo> createState() => _CompositionDemoState();
}

class _CompositionDemoState extends State<CompositionDemo> {
  final _items = <int>[1, 2, 3, 4, 5];
  int _nextId = 6;
  String _enterPreset = 'fadeSlide';
  String _exitPreset = 'fadeScale';

  MotionTransition get _enterTransition => switch (_enterPreset) {
    'fade' => const FadeIn(),
    'slide' => const SlideIn(),
    'scale' => const ScaleIn(),
    'fadeSlide' => const FadeSlideIn(),
    'fadeScale' => const FadeScaleIn(),
    'size' => const SizeIn(),
    'fadeSlideScale' =>
      const FadeIn() + const SlideIn() + const ScaleIn(scale: 0.9),
    _ => const FadeIn(),
  };

  MotionTransition get _exitTransition => switch (_exitPreset) {
    'fade' => const FadeOut(),
    'slide' => const SlideOut(),
    'scale' => const ScaleOut(),
    'fadeSlide' => const FadeSlideOut(),
    'fadeScale' => const FadeScaleOut(),
    'size' => const SizeOut(),
    'fadeSlideScale' =>
      const FadeOut() + const SlideOut() + const ScaleOut(scale: 0.9),
    _ => const FadeOut(),
  };

  void _addItem() {
    setState(() => _items.add(_nextId++));
  }

  void _removeItem(int id) {
    setState(() => _items.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transition Composition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove Last',
            onPressed: _items.isNotEmpty
                ? () => _removeItem(_items.last)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Enter Transition'),
                    trailing: DropdownButton<String>(
                      value: _enterPreset,
                      onChanged: (v) => setState(() => _enterPreset = v!),
                      items: const [
                        DropdownMenuItem(value: 'fade', child: Text('Fade')),
                        DropdownMenuItem(value: 'slide', child: Text('Slide')),
                        DropdownMenuItem(value: 'scale', child: Text('Scale')),
                        DropdownMenuItem(
                          value: 'fadeSlide',
                          child: Text('Fade + Slide'),
                        ),
                        DropdownMenuItem(
                          value: 'fadeScale',
                          child: Text('Fade + Scale'),
                        ),
                        DropdownMenuItem(value: 'size', child: Text('Size')),
                        DropdownMenuItem(
                          value: 'fadeSlideScale',
                          child: Text('Fade + Slide + Scale'),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Exit Transition'),
                    trailing: DropdownButton<String>(
                      value: _exitPreset,
                      onChanged: (v) => setState(() => _exitPreset = v!),
                      items: const [
                        DropdownMenuItem(value: 'fade', child: Text('Fade')),
                        DropdownMenuItem(value: 'slide', child: Text('Slide')),
                        DropdownMenuItem(value: 'scale', child: Text('Scale')),
                        DropdownMenuItem(
                          value: 'fadeSlide',
                          child: Text('Fade + Slide'),
                        ),
                        DropdownMenuItem(
                          value: 'fadeScale',
                          child: Text('Fade + Scale'),
                        ),
                        DropdownMenuItem(value: 'size', child: Text('Size')),
                        DropdownMenuItem(
                          value: 'fadeSlideScale',
                          child: Text('Fade + Slide + Scale'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MotionLayout(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                enterTransition: _enterTransition,
                exitTransition: _exitTransition,
                child: Column(
                  children: [
                    for (final id in _items)
                      Card(
                        key: ValueKey(id),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('$id')),
                          title: Text('Item $id'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeItem(id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 8: Lifecycle Callbacks — React to animation events
// ---------------------------------------------------------------------------
class CallbacksDemo extends StatefulWidget {
  const CallbacksDemo({super.key});

  @override
  State<CallbacksDemo> createState() => _CallbacksDemoState();
}

class _CallbacksDemoState extends State<CallbacksDemo> {
  final _items = <int>[1, 2, 3];
  int _nextId = 4;
  bool _isAnimating = false;
  final _log = <String>[];

  void _addItem() {
    setState(() => _items.add(_nextId++));
  }

  void _removeItem(int id) {
    setState(() => _items.remove(id));
  }

  void _addLog(String msg) {
    setState(() {
      _log.insert(0, msg);
      if (_log.length > 20) _log.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Callbacks'),
            if (_isAnimating) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Log',
            onPressed: () => setState(() => _log.clear()),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove Last',
            onPressed: _items.isNotEmpty
                ? () => _removeItem(_items.last)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MotionLayout(
                duration: const Duration(milliseconds: 400),
                staggerDuration: const Duration(milliseconds: 40),
                enterTransition: const FadeSlideIn(),
                exitTransition: const FadeOut(),
                onAnimationStart: () {
                  _addLog('onAnimationStart');
                  setState(() => _isAnimating = true);
                },
                onAnimationComplete: () {
                  _addLog('onAnimationComplete');
                  setState(() => _isAnimating = false);
                },
                onChildEnter: (key) => _addLog('onChildEnter: $key'),
                onChildExit: (key) => _addLog('onChildExit: $key'),
                child: Column(
                  children: [
                    for (final id in _items)
                      Card(
                        key: ValueKey(id),
                        child: ListTile(
                          title: Text('Item $id'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeItem(id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Log',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _log.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _log[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 9: Advanced Options — Explore MotionLayout parameters interactively
// ---------------------------------------------------------------------------
class AdvancedOptionsDemo extends StatefulWidget {
  const AdvancedOptionsDemo({super.key});

  @override
  State<AdvancedOptionsDemo> createState() => _AdvancedOptionsDemoState();
}

class _AdvancedOptionsDemoState extends State<AdvancedOptionsDemo> {
  var _items = <int>[1, 2, 3, 4, 5];
  int _nextId = 6;

  // --- Configurable parameters ---
  bool _enabled = true;
  bool _clipHardEdge = true;
  double _moveThreshold = 0.5;
  int _transitionMs = 400;

  // Move duration is fixed to make the contrast visible.
  static const _moveDuration = Duration(milliseconds: 600);

  void _addItem() {
    setState(() {
      _items.add(_nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.remove(id);
    });
  }

  void _shuffle() {
    setState(() {
      _items = List.of(_items)..shuffle(Random());
    });
  }

  @override
  Widget build(BuildContext context) {
    final transitionDuration = Duration(milliseconds: _transitionMs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Options'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: _shuffle,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove Last',
            onPressed: _items.isNotEmpty
                ? () => _removeItem(_items.last)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------------------------------------------------------------
          // Controls panel
          // ---------------------------------------------------------------
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // --- enabled toggle ---
                  SwitchListTile(
                    title: const Text('enabled'),
                    subtitle: Text(
                      _enabled
                          ? 'Animations are active'
                          : 'Animations disabled (instant layout)',
                    ),
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                  const Divider(height: 1),

                  // --- clipBehavior toggle ---
                  SwitchListTile(
                    title: const Text('clipBehavior'),
                    subtitle: Text(
                      _clipHardEdge
                          ? 'Clip.hardEdge (clips overflow)'
                          : 'Clip.none (overflow visible)',
                    ),
                    value: _clipHardEdge,
                    onChanged: (v) => setState(() => _clipHardEdge = v),
                  ),
                  const Divider(height: 1),

                  // --- moveThreshold slider ---
                  ListTile(
                    title: Text(
                      'moveThreshold: ${_moveThreshold.toStringAsFixed(1)} px',
                    ),
                    subtitle: Slider(
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      value: _moveThreshold,
                      label: _moveThreshold.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _moveThreshold = v),
                    ),
                  ),
                  const Divider(height: 1),

                  // --- transitionDuration slider ---
                  ListTile(
                    title: Text(
                      'transitionDuration: ${_transitionMs}ms  '
                      '(move: ${_moveDuration.inMilliseconds}ms)',
                    ),
                    subtitle: Slider(
                      min: 100,
                      max: 1500,
                      divisions: 14,
                      value: _transitionMs.toDouble(),
                      label: '${_transitionMs}ms',
                      onChanged: (v) =>
                          setState(() => _transitionMs = v.round()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // Animated list area
          // ---------------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MotionLayout(
                duration: _moveDuration,
                curve: Curves.easeOutCubic,
                enabled: _enabled,
                clipBehavior: _clipHardEdge ? Clip.hardEdge : Clip.none,
                moveThreshold: _moveThreshold,
                transitionDuration: transitionDuration,
                enterTransition: const SlideIn(offset: Offset(0, 0.15)),
                exitTransition: const FadeOut(),
                child: Column(
                  children: [
                    for (final id in _items)
                      Card(
                        key: ValueKey(id),
                        color: Colors.primaries[id % Colors.primaries.length]
                            .withValues(alpha: 0.25),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('$id')),
                          title: Text('Item $id'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeItem(id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 10: Drag-to-Reorder — Long-press and drag to reorder items with FLIP
// ---------------------------------------------------------------------------
class DragReorderDemo extends StatefulWidget {
  const DragReorderDemo({super.key});

  @override
  State<DragReorderDemo> createState() => _DragReorderDemoState();
}

class _DragReorderDemoState extends State<DragReorderDemo> {
  final _items = List.generate(6, (i) => i + 1);
  int _nextId = 7;

  void _addItem() {
    setState(() {
      _items.add(_nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drag-to-Reorder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove Last',
            onPressed: _items.isNotEmpty
                ? () => _removeItem(_items.last)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _addItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MotionLayout(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          enterTransition: const FadeSlideIn(),
          exitTransition: const FadeOut(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
          },
          dragDecorator: (child) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          child: Column(
            children: [
              for (final id in _items)
                Card(
                  key: ValueKey(id),
                  color: Colors.primaries[id % Colors.primaries.length]
                      .withValues(alpha: 0.25),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('$id')),
                    title: Text('Item $id'),
                    subtitle: const Text('Long-press to drag'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeItem(id),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 11: Pop Exit Mode — Exiting children leave layout flow instantly
// ---------------------------------------------------------------------------
class PopExitDemo extends StatefulWidget {
  const PopExitDemo({super.key});

  @override
  State<PopExitDemo> createState() => _PopExitDemoState();
}

class _PopExitDemoState extends State<PopExitDemo> {
  final _items = <int>[1, 2, 3, 4, 5];
  int _nextId = 6;
  ExitLayoutBehavior _behavior = ExitLayoutBehavior.pop;

  void _addItem() {
    setState(() {
      _items.add(_nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() {
      _items.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pop Exit Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Remove Last',
            onPressed: _items.isNotEmpty
                ? () => _removeItem(_items.last)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: const Text('Exit Layout Behavior'),
                trailing: SegmentedButton<ExitLayoutBehavior>(
                  segments: const [
                    ButtonSegment(
                      value: ExitLayoutBehavior.maintain,
                      label: Text('Maintain'),
                    ),
                    ButtonSegment(
                      value: ExitLayoutBehavior.pop,
                      label: Text('Pop'),
                    ),
                  ],
                  selected: {_behavior},
                  onSelectionChanged: (v) {
                    setState(() => _behavior = v.first);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MotionLayout(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                enterTransition: const FadeSlideIn(),
                exitTransition: const FadeOut(),
                exitLayoutBehavior: _behavior,
                child: Column(
                  children: [
                    for (final id in _items)
                      Card(
                        key: ValueKey(id),
                        color: Colors.primaries[id % Colors.primaries.length]
                            .withValues(alpha: 0.25),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('$id')),
                          title: Text('Item $id'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeItem(id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo: GridView — Animated grid with 2D FLIP (v0.8.0)
// ---------------------------------------------------------------------------
class GridViewDemo extends StatefulWidget {
  const GridViewDemo({super.key});

  @override
  State<GridViewDemo> createState() => _GridViewDemoState();
}

class _GridViewDemoState extends State<GridViewDemo> {
  var _items = List.generate(12, (i) => i + 1);
  int _nextId = 13;

  void _addItem() {
    setState(() {
      final index = _items.isEmpty ? 0 : Random().nextInt(_items.length);
      _items.insert(index, _nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() => _items.remove(id));
  }

  void _shuffle() {
    setState(() => _items = List.of(_items)..shuffle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GridView')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'shuffle',
            onPressed: _shuffle,
            child: const Icon(Icons.shuffle),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addItem,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MotionLayout(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          enterTransition: const FadeScaleIn(),
          exitTransition: const FadeOut(),
          spring: MotionSpring.smooth,
          staggerDuration: const Duration(milliseconds: 30),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final id in _items)
                GestureDetector(
                  key: ValueKey(id),
                  onTap: () => _removeItem(id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.primaries[id % Colors.primaries.length]
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$id',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo: Size Morphing — Expandable cards (v0.9.0)
// ---------------------------------------------------------------------------
class SizeMorphDemo extends StatefulWidget {
  const SizeMorphDemo({super.key});

  @override
  State<SizeMorphDemo> createState() => _SizeMorphDemoState();
}

class _SizeMorphDemoState extends State<SizeMorphDemo> {
  final _expanded = <int>{};
  final _items = List.generate(5, (i) => i + 1);

  void _toggle(int id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Size Morphing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MotionLayout(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          animateSizeChanges: true,
          child: Column(
            children: [
              for (final id in _items)
                Card(
                  key: ValueKey(id),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _toggle(id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(child: Text('$id')),
                          title: Text('Card $id'),
                          trailing: Icon(
                            _expanded.contains(id)
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ),
                        if (_expanded.contains(id))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              'This is the expanded content for card $id. '
                              'The card smoothly morphs its size while siblings '
                              'FLIP to their new positions.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo: Scroll-Triggered — Animate on viewport entry (v0.10.0)
// ---------------------------------------------------------------------------
class ScrollTriggeredDemo extends StatelessWidget {
  const ScrollTriggeredDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scroll-Triggered')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ScrollAwareMotionLayout(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          enterTransition: const FadeSlideIn(offset: Offset(0, 0.2)),
          staggerDuration: const Duration(milliseconds: 60),
          visibilityThreshold: 0.1,
          child: Column(
            children: [
              for (int i = 1; i <= 30; i++)
                Card(
                  key: ValueKey(i),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.primaries[i % Colors.primaries.length],
                      child: Text(
                        '$i',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('Item $i'),
                    subtitle: const Text('Scroll down to reveal more items'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo: MotionListView — Animated scrollable list (v1.0.0)
// ---------------------------------------------------------------------------
class MotionListViewDemo extends StatefulWidget {
  const MotionListViewDemo({super.key});

  @override
  State<MotionListViewDemo> createState() => _MotionListViewDemoState();
}

class _MotionListViewDemoState extends State<MotionListViewDemo> {
  final _items = List.generate(20, (i) => i + 1);
  int _nextId = 21;

  void _addItem() {
    setState(() {
      final index = _items.isEmpty ? 0 : Random().nextInt(_items.length);
      _items.insert(index, _nextId++);
    });
  }

  void _removeItem(int id) {
    setState(() => _items.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MotionListView')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: MotionListView(
        padding: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        enterTransition: const FadeSlideIn(),
        exitTransition: const FadeOut(),
        staggerDuration: const Duration(milliseconds: 40),
        children: [
          for (final id in _items)
            Card(
              key: ValueKey(id),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.primaries[id % Colors.primaries.length],
                  child: Text(
                    '$id',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('Item $id'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeItem(id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo: Shared Element — Cross-tree FLIP animation (v1.1.0)
// ---------------------------------------------------------------------------
class SharedElementDemo extends StatefulWidget {
  const SharedElementDemo({super.key});

  @override
  State<SharedElementDemo> createState() => _SharedElementDemoState();
}

class _SharedElementDemoState extends State<SharedElementDemo> {
  bool _showGrid = true;

  final _items = List.generate(
    9,
    (i) => (
      id: i + 1,
      color: Colors.primaries[i % Colors.primaries.length],
      label: 'Item ${i + 1}',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Element'),
        actions: [
          IconButton(
            icon: Icon(_showGrid ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
        ],
      ),
      body: MotionLayoutScope(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _showGrid ? _buildGrid() : _buildList(),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.count(
      key: const ValueKey('grid'),
      crossAxisCount: 3,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final item in _items)
          MotionLayoutId(
            id: 'shared-${item.id}',
            child: Container(
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: item.color),
                  const SizedBox(height: 4),
                  Text(item.label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: item.color)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildList() {
    return ListView(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MotionLayoutId(
              id: 'shared-${item.id}',
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.star, color: item.color),
                    const SizedBox(width: 12),
                    Text(item.label,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: item.color)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
