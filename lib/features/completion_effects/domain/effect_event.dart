/// What the grid announces when something completes.
///
/// **This is a seam, not a feature.** The effects in this change consume it,
/// and so will `add-character-system` — Biscuit stamps on the third step of a
/// **cascade** and walks in when the board is finished — and so will a sound
/// layer, once one exists and a package has been chosen for it. Each of those
/// subscribes rather than being threaded back through the controller, so
/// adding one does not re-cut what is already here.
///
/// Deliberately says nothing about audio. Naming a cue on these events before
/// anything can play one would be a guess baked into a type.
library;

import 'completion_schedule.dart';

/// Something on the board completed.
sealed class EffectEvent {
  const EffectEvent();

  /// The cell the placement landed in.
  int get origin;
}

/// One placement completed one or more **unit**s.
final class UnitsCompleted extends EffectEvent {
  const UnitsCompleted({required this.origin, required this.steps});

  @override
  final int origin;

  /// The effects to run, chained and timed (D-47). More than one step is a
  /// **cascade**.
  final List<ScheduledEffect> steps;

  bool get isCascade => steps.length > 1;

  Duration get duration => CompletionSchedule.totalOf(steps);
}

/// The board is finished: every cell holds a value and no **unit** repeats a
/// digit.
///
/// Fired for the board being *complete*, which is a structural fact. Whether
/// the puzzle also agrees with the solution is the controller's business and
/// not this event's — for a puzzle with one solution the two coincide, and
/// nothing downstream of here is allowed to tell the player which it checked.
final class BoardCompleted extends EffectEvent {
  const BoardCompleted({required this.origin});

  @override
  final int origin;
}
