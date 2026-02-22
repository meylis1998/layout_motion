/// How exiting children affect the layout during their exit animation.
enum ExitLayoutBehavior {
  /// Exiting children remain in the layout flow (default, current behavior).
  ///
  /// The exiting child continues to occupy space in the Column/Row/Wrap
  /// while its exit transition plays. Remaining children only shift after
  /// the exit animation completes.
  maintain,

  /// Exiting children are removed from layout flow immediately.
  ///
  /// They animate out at their last known absolute position using a
  /// positioned overlay, while remaining children immediately slide
  /// into the freed space via FLIP animations.
  pop,
}
