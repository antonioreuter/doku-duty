import 'package:doku_duty/features/puzzle_engine/domain/cage.dart';
import 'package:doku_duty/features/puzzle_engine/domain/candidates.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';

/// Cages drawn as 81 characters, one per cell, where cells sharing a character
/// share a **cage**, summed from [solution].
///
/// Every **cage** needs its own character, so a shape reads like the board it
/// describes. That caps a shape at the 62 letters and digits, which is more
/// cages than any test here needs.
CageSet cagesFromShape(String shape, String solution) {
  assert(shape.length == GridGeometry.cellCount);
  final cells = <String, List<int>>{};
  for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
    cells.putIfAbsent(shape[cell], () => <int>[]).add(cell);
  }
  final result = CageSet.build(<Cage>[
    for (final group in cells.values)
      Cage(
        cells: group,
        sum: group.fold(0, (sum, cell) => sum + int.parse(solution[cell])),
      ),
  ]);
  return switch (result) {
    ValidCageSet(:final cages) => cages,
    InvalidCageSet(:final description) => throw ArgumentError(description),
  };
}

/// Every row cut into four horizontal pairs and a single last cell, summed
/// from [solution].
CageSet dominoCages(String solution) => cagesFromShape(dominoShape, solution);

const String dominoShape =
    'aabbccdde'
    'ffgghhiij'
    'kkllmmnno'
    'ppqqrrsst'
    'uuvvwwxxy'
    'zzAABBCCD'
    'EEFFGGHHI'
    'JJKKLLMMN'
    'OOPPQQRRS';

/// A **killer** board over [solution] that is unique with no givens at all —
/// the sums alone pin it. For the reference solution only: found by searching
/// seeded partitions, and checked by the uniqueness suite rather than trusted.
CageSet referenceKillerCages(String solution) =>
    cagesFromShape(referenceKillerShape, solution);

const String referenceKillerShape =
    'aaabcddde'
    'ffgbccdhe'
    'figjckhhe'
    'iijjlkmhn'
    'iojplmmqn'
    'rooplsmnn'
    'rotpussvv'
    'rwtpuuxxy'
    'zwAAuBxxy';

/// [given] plus a cage for every horizontal run of cells it leaves, so the set
/// covers the grid. The fillers' sums are the least their size allows and mean
/// nothing: they exist to make a valid set around the cages under test.
CageSet cagesAround(List<Cage> given) {
  final taken = <int>{for (final cage in given) ...cage.cells};
  final fillers = <Cage>[];
  for (var row = 0; row < GridGeometry.side; row++) {
    var run = <int>[];
    void close() {
      if (run.isEmpty) return;
      fillers.add(Cage(cells: run, sum: Cage.leastSum(run.length)));
      run = <int>[];
    }

    for (var column = 0; column < GridGeometry.side; column++) {
      final cell = GridGeometry.cellAt(row: row, column: column);
      if (taken.contains(cell)) {
        close();
      } else {
        run.add(cell);
      }
    }
    close();
  }
  final result = CageSet.build(<Cage>[...given, ...fillers]);
  return switch (result) {
    ValidCageSet(:final cages) => cages,
    InvalidCageSet(:final description) => throw ArgumentError(description),
  };
}

/// A **killer** state holding only the digits and candidates named, so a
/// technique can only fire on what the test put in front of it — the same
/// discipline as `position` in positions.dart.
SolverState killerPosition(
  CageSet cages, {
  Map<int, int> digits = const <int, int>{},
  Map<int, List<int>> candidates = const <int, List<int>>{},
}) => SolverState.fromCandidates(
  digits: <int>[
    for (var cell = 0; cell < GridGeometry.cellCount; cell++)
      digits[cell] ?? Grid.blank,
  ],
  candidates: <Candidates>[
    for (var cell = 0; cell < GridGeometry.cellCount; cell++)
      Candidates.of(candidates[cell] ?? const <int>[]),
  ],
  cages: cages,
);
