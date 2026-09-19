import 'package:test/test.dart';

import 'package:doku_duty/features/completion_effects/domain/particle_pool.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

String _withHoles(Iterable<int> cells) {
  final digits = _solution.split('');
  for (final cell in cells) {
    digits[cell] = '.';
  }
  return digits.join();
}

Particle _at(int cell) => const Particle(
  cell: 0,
  offset: (0.5, 0.5),
  age: Duration.zero,
  lifetime: Duration(milliseconds: 260),
).copyAt(cell);

extension on Particle {
  Particle copyAt(int cell) =>
      Particle(cell: cell, offset: offset, age: age, lifetime: lifetime);
}

void main() {
  group('the pool is fixed and reused', () {
    test('it never allocates past the on-screen cap', () {
      final pool = ParticlePool();

      for (var i = 0; i < 500; i++) {
        pool.emit(_at(i % 81), cellIsFilled: (_) => true);
      }

      expect(pool.allocated, ParticleBudget.onScreen);
      expect(pool.aliveCount, lessThanOrEqualTo(ParticleBudget.onScreen));
    });

    test('a three-step cascade draws from the same pool as one effect', () {
      final oneEffect = ParticlePool();
      for (var i = 0; i < ParticleBudget.perUnit; i++) {
        oneEffect.emit(_at(i), cellIsFilled: (_) => true);
      }

      final cascade = ParticlePool();
      for (final kind in <UnitKind>[
        UnitKind.row,
        UnitKind.column,
        UnitKind.block,
      ]) {
        for (var i = 0; i < ParticlePool.budgetFor(kind); i++) {
          cascade.emit(_at(i), cellIsFilled: (_) => true);
        }
      }

      expect(
        cascade.allocated,
        oneEffect.allocated,
        reason: 'a cascade reuses the pool rather than tripling it',
      );
      expect(
        cascade.aliveCount,
        lessThanOrEqualTo(ParticleBudget.onScreen),
        reason: '8 + 8 + 12 is within sixty, and could not exceed it anyway',
      );
    });

    test('the per-unit budgets are the documented ones', () {
      expect(ParticlePool.budgetFor(UnitKind.row), 8);
      expect(ParticlePool.budgetFor(UnitKind.column), 8);
      expect(ParticlePool.budgetFor(UnitKind.block), 12);
      expect(ParticleBudget.atPuzzleCompletion, 40);
      expect(ParticleBudget.onScreen, 60);
    });

    test('spent particles leave', () {
      final pool = ParticlePool();
      pool.emit(_at(0), cellIsFilled: (_) => true);
      expect(pool.aliveCount, 1);

      pool.advance(const Duration(milliseconds: 300));
      expect(pool.aliveCount, 0, reason: 'its lifetime was 260ms');
    });

    test('clearing drops everything at once', () {
      final pool = ParticlePool();
      for (var i = 0; i < 20; i++) {
        pool.emit(_at(i), cellIsFilled: (_) => true);
      }

      pool.clear();
      expect(pool.aliveCount, 0);
    });
  });

  group('a particle never covers unsolved ground', () {
    // Cells 4 and 40 are empty; everything else holds a value.
    final board = Board.forPuzzle(givens: _grid(_withHoles(<int>[4, 40])));
    bool filled(int cell) => !board.isEmptyAt(cell);

    test('one over an empty cell is culled', () {
      final pool = ParticlePool();

      expect(pool.emit(_at(4), cellIsFilled: filled), isFalse);
      expect(pool.emit(_at(40), cellIsFilled: filled), isFalse);
      expect(pool.aliveCount, 0);
    });

    test('one over a filled cell is kept', () {
      final pool = ParticlePool();

      expect(pool.emit(_at(0), cellIsFilled: filled), isTrue);
      expect(pool.aliveCount, 1);
    });

    test('an effect emitting across a holed unit keeps only what it may', () {
      final pool = ParticlePool();
      var kept = 0;

      // The lasso runs the length of row 0, which holds the empty cell 4.
      for (final cell in GridGeometry.unitsOfKind(UnitKind.row)[0].cells) {
        if (pool.emit(_at(cell), cellIsFilled: filled)) kept++;
      }

      expect(kept, 8, reason: 'nine cells, one of them still to be solved');
      expect(
        pool.alive.map((p) => p.cell),
        isNot(contains(4)),
        reason: 'a puff on ground the player has to read is culled, not dimmed',
      );
    });
  });
}
