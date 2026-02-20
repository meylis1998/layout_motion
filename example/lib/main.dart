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
          enterTransition: const ScaleIn(beginScale: 0.5),
          exitTransition: const ScaleOut(endScale: 0.5),
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
