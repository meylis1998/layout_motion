import 'package:flutter/widgets.dart';

import 'child_differ.dart';

/// State of an item in the animated display list.
enum DisplayItemState {
  /// Item is playing its enter animation.
  entering,

  /// Item is fully visible and idle.
  idle,

  /// Item is playing its exit animation.
  exiting,
}

/// A tracked item in the animated display list.
///
/// Used by [SliverChildTracker] to manage the mapping between user data
/// and the display list (which includes exiting items during their animations).
class DisplayItem {
  DisplayItem({required this.key, required this.dataIndex});

  /// The user-provided key for this item.
  final Key key;

  /// Index in the user's data. Set to -1 for exiting items.
  int dataIndex;

  /// Current animation state.
  DisplayItemState state = DisplayItemState.idle;

  /// The last built widget, used for exit animation rendering.
  Widget? lastWidget;
}

/// Manages the display list for animated scrollable layouts.
///
/// Handles the mapping between the user's data (by key) and the
/// display list (which includes items animating out).
class SliverChildTracker {
  /// The current ordered display list.
  final List<DisplayItem> displayItems = [];

  final Map<Key, DisplayItem> _itemMap = {};

  /// Keys that have already played their enter animation.
  final Set<Key> seenKeys = {};

  /// Current data keys in order.
  List<Key> dataKeys = [];

  /// Initializes the tracker with initial data keys.
  void initialize(List<Key> keys) {
    dataKeys = List.of(keys);
    displayItems.clear();
    _itemMap.clear();

    for (int i = 0; i < keys.length; i++) {
      final item = DisplayItem(key: keys[i], dataIndex: i);
      displayItems.add(item);
      _itemMap[keys[i]] = item;
    }
  }

  /// Updates the tracker with new data keys and returns the [DiffResult].
  DiffResult update(List<Key> newKeys) {
    final diff = ChildDiffer.diff(dataKeys, newKeys);

    // Mark removed items as exiting.
    for (final key in diff.removed) {
      final item = _itemMap[key];
      if (item != null) {
        item.state = DisplayItemState.exiting;
        item.dataIndex = -1;
      }
    }

    _rebuildDisplayList(newKeys, diff);
    dataKeys = List.of(newKeys);
    return diff;
  }

  void _rebuildDisplayList(List<Key> newKeys, DiffResult diff) {
    final exitingItems = displayItems
        .where((item) => item.state == DisplayItemState.exiting)
        .toList();

    final newDisplay = <DisplayItem>[];

    for (int i = 0; i < newKeys.length; i++) {
      final key = newKeys[i];
      if (diff.added.contains(key)) {
        final item = DisplayItem(key: key, dataIndex: i);
        item.state = DisplayItemState.entering;
        _itemMap[key] = item;
        newDisplay.add(item);
      } else {
        final item = _itemMap[key]!;
        item.dataIndex = i;
        newDisplay.add(item);
      }
    }

    // Insert exiting items at approximate old positions.
    for (final exitItem in exitingItems) {
      final oldIndex = displayItems.indexOf(exitItem);
      int insertPos = newDisplay.length;
      for (int i = oldIndex + 1; i < displayItems.length; i++) {
        final neighbor = displayItems[i];
        if (neighbor.state != DisplayItemState.exiting) {
          final idx = newDisplay.indexOf(neighbor);
          if (idx >= 0) {
            insertPos = idx;
            break;
          }
        }
      }
      newDisplay.insert(insertPos, exitItem);
    }

    displayItems
      ..clear()
      ..addAll(newDisplay);
  }

  /// Removes a completed exit item from the display list.
  void removeExited(Key key) {
    displayItems.removeWhere((item) => item.key == key);
    _itemMap.remove(key);
  }

  /// Gets the display item for a [key].
  DisplayItem? getItem(Key key) => _itemMap[key];

  /// Disposes all tracked state.
  void dispose() {
    displayItems.clear();
    _itemMap.clear();
    seenKeys.clear();
    dataKeys = [];
  }
}
