/// One frame of whatever is currently celebrating.
///
/// A value, not a controller: the painter is handed a snapshot and draws it,
/// which is what lets the frame be built and asserted on without a canvas, and
/// what keeps the effect layer from being able to write anything. Nothing here
/// can reach the board.
library;

import '../../puzzle_engine/domain/grid_geometry.dart';
import 'completion_sequence.dart';
import 'particle_pool.dart';

/// An effect part-way through running.
final class ActiveEffect {
  const ActiveEffect({
    required this.unit,
    required this.origin,
    required this.progress,
  });

  /// The **unit** being celebrated.
  final Unit unit;

  /// The cell the placement landed in. The rope is thrown from here and the
  /// charge goes off here, so the effect reads as caused by what the player
  /// just did.
  final int origin;

  /// 0 at the start of this step, 1 at its end.
  final double progress;

  /// Whether this step is the dynamite rather than the lasso.
  bool get isRadial => unit.kind == UnitKind.block;

  /// How far along the **unit** the rope has run, in cells.
  ///
  /// Staggered so the eye reads direction: a lasso that lit all nine cells at
  /// once would be a flash, and a flash does not point anywhere.
  double get reach => progress * GridGeometry.side;
}

/// The completion sequence, part-way through.
final class SequenceFrame {
  const SequenceFrame({required this.origin, required this.elapsed});

  /// The cell that finished the board. The wave starts here.
  final int origin;

  final Duration elapsed;

  /// The beats running right now. Two of the four draw nothing yet, and they
  /// appear here all the same — the sequence runs through them at the right
  /// speed rather than pausing where a character will eventually be.
  List<CompletionBeat> get running => CompletionSequence.runningAt(elapsed);

  double progressOf(CompletionBeat beat) => beat.progressAt(elapsed);

  bool get isOver => elapsed >= CompletionSequence.duration;

  @override
  bool operator ==(Object other) =>
      other is SequenceFrame &&
      other.origin == origin &&
      other.elapsed == elapsed;

  @override
  int get hashCode => Object.hash(origin, elapsed);
}

/// Everything the effect layer draws this frame.
final class EffectFrame {
  const EffectFrame({
    required this.effects,
    required this.particles,
    this.sequence,
  });

  static const EffectFrame empty = EffectFrame(
    effects: <ActiveEffect>[],
    particles: <Particle>[],
  );

  final List<ActiveEffect> effects;
  final List<Particle> particles;

  /// The puzzle-completion sequence, if one is running.
  final SequenceFrame? sequence;

  bool get isEmpty => effects.isEmpty && particles.isEmpty && sequence == null;

  bool get isNotEmpty => !isEmpty;

  /// The cells this frame is celebrating, so the grid can hold them at the
  /// fresh colour while it runs.
  Set<int> get litCells => <int>{
    for (final effect in effects) ...effect.unit.cells,
  };

  @override
  bool operator ==(Object other) =>
      other is EffectFrame &&
      other.effects.length == effects.length &&
      other.particles.length == particles.length &&
      other.sequence == sequence &&
      _sameEffects(other.effects);

  bool _sameEffects(List<ActiveEffect> other) {
    for (var i = 0; i < effects.length; i++) {
      if (other[i].unit != effects[i].unit) return false;
      if (other[i].progress != effects[i].progress) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    effects.length,
    particles.length,
    sequence,
    Object.hashAll(effects.map((e) => Object.hash(e.unit, e.progress))),
  );
}
