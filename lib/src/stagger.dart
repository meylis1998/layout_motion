/// Direction from which the stagger delay cascades.
enum StaggerFrom {
  /// First child animates first, last child animates last.
  first,

  /// Last child animates first, first child animates last.
  last,

  /// Center child(ren) animate first, edges animate last.
  center,
}
