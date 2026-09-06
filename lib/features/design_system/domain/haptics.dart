/// The haptic vocabulary from `docs/DESIGN.md` §5.
///
/// A fixed named set, not a wrapper that passes anything through. The point of
/// naming them is that a new one has to be added here, where it is visible,
/// rather than appearing as a raw platform call somewhere in a widget.
enum DokuHaptic {
  /// A value placed, a key pressed.
  selectionTick,

  /// A row or column completed.
  lightImpact,

  /// A block completed.
  mediumImpact,

  /// A duplicate placed — both digits notice each other.
  lightDoubleTap,

  /// The puzzle solved.
  success,
}
