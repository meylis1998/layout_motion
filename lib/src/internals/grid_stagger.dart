import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../stagger.dart';

/// Computes dual-axis stagger delays for grid layouts.
///
/// In a grid, the stagger delay is based on the Manhattan distance from the
/// stagger origin to each child's (row, column) position. This produces a
/// natural diagonal cascade effect instead of the linear cascade used for
/// single-axis layouts.
class GridStagger {
  const GridStagger._();

  /// Computes the stagger delay for a child at [index] in a grid with
  /// [crossAxisCount] columns and [total] items.
  ///
  /// The delay is proportional to the Manhattan distance from the stagger
  /// origin (determined by [staggerFrom]) to the child's grid position.
  static Duration compute({
    required int index,
    required int total,
    required int crossAxisCount,
    required Duration staggerDuration,
    required StaggerFrom staggerFrom,
  }) {
    if (staggerDuration == Duration.zero || total <= 1 || crossAxisCount <= 0) {
      return Duration.zero;
    }

    final row = index ~/ crossAxisCount;
    final col = index % crossAxisCount;
    final rowCount = (total + crossAxisCount - 1) ~/ crossAxisCount;

    final int distance;
    switch (staggerFrom) {
      case StaggerFrom.first:
        // Top-left origin: Manhattan distance from (0, 0).
        distance = row + col;
      case StaggerFrom.last:
        // Bottom-right origin: Manhattan distance from (lastRow, lastCol).
        final lastRow = rowCount - 1;
        final lastCol = crossAxisCount - 1;
        distance = (lastRow - row) + (lastCol - col);
      case StaggerFrom.center:
        // Center origin: Manhattan distance from center cell.
        final centerRow = (rowCount - 1) / 2;
        final centerCol = (crossAxisCount - 1) / 2;
        distance = ((row - centerRow).abs() + (col - centerCol).abs()).round();
    }

    return staggerDuration * math.max(0, distance);
  }

  /// Extracts the cross-axis count from a [SliverGridDelegate].
  ///
  /// Returns the count directly for [SliverGridDelegateWithFixedCrossAxisCount].
  /// For [SliverGridDelegateWithMaxCrossAxisExtent], computes from [parentWidth].
  /// Returns null if the delegate type is not recognized or parentWidth is needed
  /// but not provided.
  static int? extractCrossAxisCount(
    SliverGridDelegate gridDelegate, {
    double? parentWidth,
  }) {
    if (gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
      return gridDelegate.crossAxisCount;
    }
    if (gridDelegate is SliverGridDelegateWithMaxCrossAxisExtent &&
        parentWidth != null &&
        parentWidth > 0) {
      final maxExtent = gridDelegate.maxCrossAxisExtent;
      if (maxExtent > 0) {
        return (parentWidth / maxExtent).ceil();
      }
    }
    return null;
  }
}
