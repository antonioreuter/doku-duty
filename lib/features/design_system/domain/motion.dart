/// Motion durations from `docs/DESIGN.md` §5.
///
/// The 400ms ceiling in constraint 2 is a product requirement, not a target, so
/// it is expressed as a test over these tokens rather than as a note in a
/// document. Two events exceed it and both are recorded decisions; a third would
/// have to declare itself, which is the point.
library;

import 'haptics.dart';

enum DokuMotion {
  /// Cell scale 1.04 → 1.0.
  valuePlaced(Duration(milliseconds: 90), haptic: DokuHaptic.selectionTick),

  /// Squash to 0.94 vertical, rebound.
  keyPressed(Duration(milliseconds: 90), haptic: DokuHaptic.selectionTick),

  /// Instant, no transition. Notes trigger nothing — no particle, no sound, no
  /// haptic (D-52). A player marking a dense board makes forty entries a
  /// minute, and any celebration attached to that is noise within seconds.
  noteAdded(Duration.zero),

  /// Row or column complete — the lasso cinch.
  unitComplete(Duration(milliseconds: 260), haptic: DokuHaptic.lightImpact),

  /// Block complete — the dynamite detonation.
  blockComplete(Duration(milliseconds: 340), haptic: DokuHaptic.mediumImpact),

  /// Both digits notice each other, in horror. This replaces the conventional
  /// red flash (D-42).
  duplicatePlaced(
    Duration(milliseconds: 400),
    haptic: DokuHaptic.lightDoubleTap,
  ),

  /// Chained row, then column, then block (D-47).
  ///
  /// A deliberate exception to the 400ms rule: cascades are rare, they are the
  /// best moment in ordinary play, and collapsing them into one flash wastes
  /// three rewards.
  cascade(
    Duration(milliseconds: 520),
    isRecordedException: true,
    haptic: DokuHaptic.lightImpact,
  ),

  /// Four beats: wave, Biscuit's hoof, poster scraps, the digits' bow.
  ///
  /// The second recorded exception. It fires once per puzzle, after the last
  /// cell, when there is no next tap to block.
  puzzleComplete(
    Duration(milliseconds: 1400),
    isRecordedException: true,
    haptic: DokuHaptic.success,
  ),

  /// The character strip slides up with overshoot.
  characterEnters(Duration(milliseconds: 220)),

  /// `goldPale` settling to `greenPale`.
  ///
  /// Not in-puzzle motion in the sense the ceiling means: it is a hold on a
  /// colour that is already correct, and it blocks nothing.
  completionTintHold(Duration(milliseconds: 2000), isInPuzzle: false);

  const DokuMotion(
    this.duration, {
    this.isRecordedException = false,
    this.isInPuzzle = true,
    this.haptic,
  });

  final Duration duration;

  /// The haptic this event fires, or null where it fires none.
  ///
  /// Null is the interesting case: [noteAdded] has no haptic and no way to
  /// acquire one without editing this table, which is how D-52 is kept.
  final DokuHaptic? haptic;

  /// Whether this motion is subject to the 400ms in-puzzle ceiling.
  final bool isInPuzzle;

  /// Whether exceeding the ceiling is a recorded decision rather than a drift.
  final bool isRecordedException;

  /// Chained completions fire this far apart, in the order row, column, block —
  /// never simultaneous (D-47).
  static const Duration cascadeStepOffset = Duration(milliseconds: 90);

  /// This motion's duration under the current motion settings.
  ///
  /// Reduced motion resolves everything to its end state instantly. Instant
  /// states are unaffected because they were already instant.
  Duration resolve({required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : duration;
}
