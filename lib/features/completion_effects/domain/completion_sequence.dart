/// The four beats the board plays when it is finished.
///
/// **An ordered list of named beats, not one 1400ms animation.** Two of the
/// four are characters — Biscuit walks in and stamps a hoof, and Ace turns up
/// disappointed — and characters are `add-character-system`, which depends on
/// this change. Naming the beats now means that change fills two slots rather
/// than re-cutting the sequence, and that the timing it lands into is the
/// timing already shipped.
///
/// Pure Dart with no Flutter import: which beat runs when is a decision from
/// `docs/DESIGN.md` §6, and a test should be able to read it back in
/// milliseconds.
library;

import '../../design_system/domain/motion.dart';

/// One beat of the completion sequence.
enum CompletionBeat {
  /// A wave crossing the grid from the final cell.
  wave(starts: Duration.zero, ends: Duration(milliseconds: 300), isDrawn: true),

  /// Biscuit walks in and stamps a hoof on the board.
  ///
  /// **Empty until `add-character-system`.** The beat holds its place in the
  /// timeline and draws nothing, so the sequence runs through it at the right
  /// speed rather than pausing where a burro will eventually be.
  hoof(
    starts: Duration(milliseconds: 300),
    ends: Duration(milliseconds: 700),
    isDrawn: false,
  ),

  /// Wanted-poster scraps burst from the stamp point and drift.
  scraps(
    starts: Duration(milliseconds: 700),
    ends: Duration(milliseconds: 1200),
    isDrawn: true,
  ),

  /// The digits take a small bow; Ace appears, disappointed.
  ///
  /// **Empty until `add-character-system`**, like [hoof].
  bow(
    starts: Duration(milliseconds: 1200),
    ends: Duration(milliseconds: 1400),
    isDrawn: false,
  );

  const CompletionBeat({
    required this.starts,
    required this.ends,
    required this.isDrawn,
  });

  final Duration starts;
  final Duration ends;

  /// Whether anything draws this beat yet.
  ///
  /// False is not a defect. It is the seam, and it is readable: a later change
  /// flips one flag and adds the drawing, and every timing test here keeps
  /// passing unchanged.
  final bool isDrawn;

  Duration get duration => ends - starts;

  /// How far into this beat [elapsed] is, 0 before it and 1 after.
  double progressAt(Duration elapsed) {
    if (elapsed <= starts) return 0;
    if (elapsed >= ends) return 1;
    return (elapsed - starts).inMicroseconds / duration.inMicroseconds;
  }

  bool isRunningAt(Duration elapsed) => elapsed >= starts && elapsed < ends;
}

abstract final class CompletionSequence {
  /// The whole sequence, in order.
  static const List<CompletionBeat> beats = CompletionBeat.values;

  /// 1400ms — the second of the two recorded exceptions to the 400ms ceiling.
  ///
  /// It fires once per puzzle, after the last cell, when there is no next tap
  /// to block. Nothing waits on it either way: the puzzle is recorded as solved
  /// whether the player watches it or taps straight through.
  static Duration get duration => DokuMotion.puzzleComplete.duration;

  /// The beats running at [elapsed]. Empty once the sequence is over.
  static List<CompletionBeat> runningAt(Duration elapsed) => <CompletionBeat>[
    for (final beat in beats)
      if (beat.isRunningAt(elapsed)) beat,
  ];

  /// The beats that draw something today.
  static List<CompletionBeat> get drawn =>
      beats.where((beat) => beat.isDrawn).toList(growable: false);

  /// The beats waiting for `add-character-system`.
  static List<CompletionBeat> get empty =>
      beats.where((beat) => !beat.isDrawn).toList(growable: false);
}
