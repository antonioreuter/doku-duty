/// When each completion effect starts, how long it runs, and what it feels
/// like.
///
/// Pure Dart with no Flutter import. The timing of a **cascade** is a decision
/// (D-47), not a rendering detail, so it is decided here where a test can read
/// it back in milliseconds rather than inferred from whatever an animation
/// controller happened to do.
library;

import '../../design_system/domain/haptics.dart';
import '../../design_system/domain/motion.dart';
import '../../puzzle_engine/domain/grid_geometry.dart';
import 'unit_completion.dart';

/// One completion effect, placed on the timeline.
final class ScheduledEffect {
  const ScheduledEffect({
    required this.unit,
    required this.origin,
    required this.startsAt,
    required this.motion,
  });

  /// The **unit** that completed.
  final Unit unit;

  /// The cell the placement landed in — where the rope is thrown from and
  /// where the charge goes off. An effect that started from the middle of the
  /// **unit** every time would not read as caused by anything.
  final int origin;

  /// How far into the **cascade** this step begins. Zero for the first.
  final Duration startsAt;

  /// The motion token this step runs, which carries its duration and its
  /// haptic.
  final DokuMotion motion;

  Duration get duration => motion.duration;

  Duration get endsAt => startsAt + duration;

  DokuHaptic? get haptic => motion.haptic;

  @override
  String toString() =>
      '$unit from $origin at ${startsAt.inMilliseconds}ms for '
      '${duration.inMilliseconds}ms';
}

abstract final class CompletionSchedule {
  /// The effects [change] fires, in order, timed.
  ///
  /// **Chained, never simultaneous** (D-47). The **unit**s arrive already in
  /// the row, column, block order [UnitCompletion.forChange] fixes, and each
  /// step starts [DokuMotion.cascadeStepOffset] after the one before it. Firing
  /// them together would collapse three rewards into one indistinct flash,
  /// which is the whole of what this decision is about.
  ///
  /// The offsets are consecutive among the **unit**s that actually completed,
  /// not reserved per kind. A placement that completes a row and a block chains
  /// at one 90ms offset rather than leaving a silent 90ms where the column
  /// would have been — an empty slot in the middle of a celebration reads as a
  /// stutter, and the order is what D-47 fixes, not the calendar.
  static List<ScheduledEffect> forChange(
    CompletionChange change, {
    required int origin,
  }) {
    if (change.completed.isEmpty) return const <ScheduledEffect>[];

    final steps = <ScheduledEffect>[];
    for (var index = 0; index < change.completed.length; index++) {
      final unit = change.completed[index];
      steps.add(
        ScheduledEffect(
          unit: unit,
          origin: origin,
          startsAt: DokuMotion.cascadeStepOffset * index,
          motion: unit.kind == UnitKind.block
              // The dynamite, radial from the placed cell, so a block never
              // reads as a row.
              ? DokuMotion.blockComplete
              // The lasso, running the length of the unit.
              : DokuMotion.unitComplete,
        ),
      );
    }
    return List<ScheduledEffect>.unmodifiable(steps);
  }

  /// How long [steps] take from the first start to the last end.
  ///
  /// For a full three-step **cascade** this is 520ms — the deliberate exception
  /// D-46's ceiling records rather than a drift past it. A test asserts the
  /// number so a changed offset or duration cannot quietly move it.
  static Duration totalOf(List<ScheduledEffect> steps) {
    var end = Duration.zero;
    for (final step in steps) {
      if (step.endsAt > end) end = step.endsAt;
    }
    return end;
  }
}
