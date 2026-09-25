import 'cage.dart';
import 'candidates.dart';
import 'deduction.dart';
import 'grid.dart';
import 'grid_geometry.dart';
import 'peers.dart';

/// A grid together with the candidates still standing in it.
///
/// Mutable, and deliberately so: the solver applies one deduction after another
/// and eliminations have to persist between steps. A technique that ran on a
/// freshly derived candidate set would keep rediscovering the same eliminations
/// and never reach the ones that depend on them.
///
/// Candidates are nine-bit masks, so an elimination is one bitwise operation
/// against no allocation.
final class SolverState {
  SolverState._(this._digits, this._candidates, this.cages)
    : peers = Peers.of(cages);

  /// Derive the candidates from the grid: every digit not placed in a peer.
  ///
  /// [cages] makes it a **killer** state: **cage** mates become peers, and the
  /// **killer** techniques have something to reason about.
  factory SolverState.fromGrid(Grid grid, {CageSet? cages}) {
    final peers = Peers.of(cages);
    final digits = <int>[
      for (var cell = 0; cell < GridGeometry.cellCount; cell++)
        grid.digitAt(cell),
    ];
    final candidates = <int>[
      for (var cell = 0; cell < GridGeometry.cellCount; cell++)
        grid.candidatesAt(cell, peers: peers).mask,
    ];
    return SolverState._(digits, candidates, cages);
  }

  /// Build from explicit candidates.
  ///
  /// The candidates are taken as given rather than re-derived, which is what
  /// lets a single technique be exercised against exactly the position a test
  /// means to put in front of it.
  factory SolverState.fromCandidates({
    required List<int> digits,
    required List<Candidates> candidates,
    CageSet? cages,
  }) {
    assert(digits.length == GridGeometry.cellCount);
    assert(candidates.length == GridGeometry.cellCount);
    return SolverState._(List<int>.of(digits), <int>[
      for (final candidate in candidates) candidate.mask,
    ], cages);
  }

  final List<int> _digits;
  final List<int> _candidates;

  /// The **cage**s of a **killer** puzzle, or null for a classic one.
  final CageSet? cages;

  /// The cells each cell may not share a digit with, **cage** mates included.
  final Peers peers;

  int digitAt(int cell) => _digits[cell];

  bool isEmptyAt(int cell) => _digits[cell] == Grid.blank;

  Candidates candidatesAt(int cell) => Candidates(_candidates[cell]);

  /// The raw mask, for techniques that live in their inner loop.
  int candidateMask(int cell) => _candidates[cell];

  bool hasCandidate(int cell, int digit) =>
      _candidates[cell] & (1 << (digit - 1)) != 0;

  /// The empty cells of [cells] that still admit [digit], ascending.
  List<int> cellsAdmitting(int digit, Iterable<int> cells) {
    final bit = 1 << (digit - 1);
    return <int>[
      for (final cell in cells)
        if (_digits[cell] == Grid.blank && _candidates[cell] & bit != 0) cell,
    ];
  }

  bool unitHolds(Unit unit, int digit) {
    for (final cell in unit.cells) {
      if (_digits[cell] == digit) return true;
    }
    return false;
  }

  bool get isSolved => !_digits.contains(Grid.blank);

  Iterable<int> get emptyCells sync* {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (_digits[cell] == Grid.blank) yield cell;
    }
  }

  /// Apply a deduction: settle its placements, strike out its eliminations.
  void apply(Deduction deduction) {
    for (final placement in deduction.placements) {
      place(placement.cell, placement.digit);
    }
    for (final elimination in deduction.eliminations) {
      eliminate(elimination.cell, elimination.digit);
    }
  }

  void place(int cell, int digit) {
    _digits[cell] = digit;
    _candidates[cell] = 0;
    final removed = ~(1 << (digit - 1));
    for (final peer in peers.of(cell)) {
      _candidates[peer] &= removed;
    }
  }

  void eliminate(int cell, int digit) {
    _candidates[cell] &= ~(1 << (digit - 1));
  }

  Grid toGrid() => Grid.fromDigits(_digits);

  SolverState copy() =>
      SolverState._(List<int>.of(_digits), List<int>.of(_candidates), cages);
}
