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
          ListTile(
            title: const Text('Advanced Options'),
            subtitle: const Text('Toggle enabled, clip, threshold, timing'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdvancedOptionsDemo()),
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
                    avatar: CircleAvatar(child: Text('$id')),
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
      _boxes.add(_StackBox(
        id: id,
        left: _rng.nextDouble() * (_stackWidth - _boxSize),
        top: _rng.nextDouble() * (_stackHeight - _boxSize),
        colorIndex: id % _colors.length,
      ));
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
// Demo 6: Advanced Options — Explore MotionLayout parameters interactively
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
                    subtitle: Text(_enabled
                        ? 'Animations are active'
                        : 'Animations disabled (instant layout)'),
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                  const Divider(height: 1),

                  // --- clipBehavior toggle ---
                  SwitchListTile(
                    title: const Text('clipBehavior'),
                    subtitle: Text(_clipHardEdge
                        ? 'Clip.hardEdge (clips overflow)'
                        : 'Clip.none (overflow visible)'),
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
                clipBehavior:
                    _clipHardEdge ? Clip.hardEdge : Clip.none,
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
