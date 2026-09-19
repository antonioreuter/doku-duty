/// The particles an effect draws, and the ceiling they never go over.
///
/// Pure Dart with no Flutter import: where a puff is and whether it is allowed
/// to be there is arithmetic, and the budget in `docs/DESIGN.md` §6 is a number
/// a test can read rather than a frame rate someone hopes holds.
///
/// **Sixty on screen, and a fixed pool.** Sixty is what holds 60fps on a
/// mid-tier Android phone, which is the device the number was chosen for. The
/// pool is allocated once and reused, so a **cascade** running three effects
/// draws from the same sixty rather than asking for a hundred and eighty — the
/// one moment in ordinary play most likely to stutter is the one where three
/// effects overlap, and tripling the allocation there is how it would.
library;

import '../../puzzle_engine/domain/grid_geometry.dart';

/// The caps from `docs/DESIGN.md` §6.
abstract final class ParticleBudget {
  /// Dust puffs behind the lasso, per row or column.
  static const int perUnit = 8;

  /// Sparks and debris from the dynamite, per block.
  static const int perBlock = 12;

  /// Wanted-poster scraps at puzzle completion.
  static const int atPuzzleCompletion = 40;

  /// Never more than this on screen at once, whatever is running.
  static const int onScreen = 60;
}

/// One particle, as the painter needs it.
final class Particle {
  const Particle({
    required this.cell,
    required this.offset,
    required this.age,
    required this.lifetime,
  });

  /// The cell the particle is over. What makes culling a lookup rather than a
  /// hit test.
  final int cell;

  /// Where in the cell it sits, each component in 0..1.
  final (double, double) offset;

  final Duration age;
  final Duration lifetime;

  /// 0 at birth, 1 at the end of its life.
  double get progress => lifetime == Duration.zero
      ? 1
      : (age.inMicroseconds / lifetime.inMicroseconds).clamp(0.0, 1.0);

  bool get isSpent => progress >= 1;
}

/// A fixed-size ring of particles, reused rather than reallocated.
///
/// Emitting past [capacity] overwrites the oldest particle instead of growing.
/// That is the intended behaviour and not a loss: sixty is already more than
/// reads as distinct on a grid this size, and a pool that grew under load would
/// drop frames exactly when the most is happening on screen.
final class ParticlePool {
  ParticlePool({this.capacity = ParticleBudget.onScreen})
    : _slots = List<Particle?>.filled(capacity, null);

  final int capacity;
  final List<Particle?> _slots;
  int _next = 0;

  /// The particles currently alive, oldest first.
  Iterable<Particle> get alive =>
      _slots.whereType<Particle>().where((p) => !p.isSpent);

  int get aliveCount => alive.length;

  /// How many slots the pool has ever held. Never more than [capacity],
  /// whatever a **cascade** asked for.
  int get allocated => _slots.length;

  /// Add [particle], unless it would land somewhere it must not be drawn.
  ///
  /// **A particle over a cell the player still has to solve is culled** — not
  /// dimmed, not drawn behind, culled. Effects are decoration on work already
  /// done; a puff drifting across an empty cell obscures the thing the player
  /// is in the middle of reading, and it does so at the exact moment they are
  /// most likely to be looking at it.
  ///
  /// Returns whether it was kept, so a test can count what the rule threw away.
  bool emit(
    Particle particle, {
    required bool Function(int cell) cellIsFilled,
  }) {
    if (!cellIsFilled(particle.cell)) return false;
    _slots[_next] = particle;
    _next = (_next + 1) % capacity;
    return true;
  }

  /// Move every particle on by [elapsed], dropping the spent ones.
  void advance(Duration elapsed) {
    for (var i = 0; i < _slots.length; i++) {
      final particle = _slots[i];
      if (particle == null) continue;
      final aged = Particle(
        cell: particle.cell,
        offset: particle.offset,
        age: particle.age + elapsed,
        lifetime: particle.lifetime,
      );
      _slots[i] = aged.isSpent ? null : aged;
    }
  }

  /// Drop everything at once. What a tap that skips an effect does.
  void clear() {
    _slots.fillRange(0, _slots.length, null);
    _next = 0;
  }

  /// How many particles [kind] of **unit** is allowed to emit.
  static int budgetFor(UnitKind kind) =>
      kind == UnitKind.block ? ParticleBudget.perBlock : ParticleBudget.perUnit;
}
