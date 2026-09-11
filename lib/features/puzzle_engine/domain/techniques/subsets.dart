import '../deduction.dart';
import '../grid_geometry.dart';
import '../solver_state.dart';
import '../technique.dart';
import 'solving_technique.dart';

/// Two cells in a **unit** carrying the same two candidates: no other cell in
/// that **unit** can hold either digit.
final class NakedPair extends SolvingTechnique {
  const NakedPair();

  @override
  Technique get technique => Technique.nakedPair;

  @override
  Deduction? deduce(SolverState state) => _nakedSubset(state, technique, 2);
}

/// Three cells in a **unit** sharing three candidates between them, however
/// they are distributed: no other cell in that **unit** can hold any of them.
final class NakedTriple extends SolvingTechnique {
  const NakedTriple();

  @override
  Technique get technique => Technique.nakedTriple;

  @override
  Deduction? deduce(SolverState state) => _nakedSubset(state, technique, 3);
}

Deduction? _nakedSubset(SolverState state, Technique technique, int size) {
  for (final unit in GridGeometry.allUnits) {
    final candidateCells = <int>[
      for (final cell in unit.cells)
        if (state.isEmptyAt(cell) &&
            bitCount(state.candidateMask(cell)) >= 2 &&
            bitCount(state.candidateMask(cell)) <= size)
          cell,
    ];
    if (candidateCells.length < size) continue;

    for (final subset in combinations(candidateCells, size)) {
      var union = 0;
      for (final cell in subset) {
        union |= state.candidateMask(cell);
      }
      if (bitCount(union) != size) continue;

      final digits = digitsOf(union);
      final eliminations = <CellDigit>[
        for (final cell in unit.cells)
          if (state.isEmptyAt(cell) && !subset.contains(cell))
            for (final digit in digits)
              if (state.hasCandidate(cell, digit)) CellDigit(cell, digit),
      ];
      if (eliminations.isEmpty) continue;

      return Deduction(
        technique: technique,
        eliminations: eliminations,
        witnesses: subset,
      );
    }
  }
  return null;
}

/// Two digits confined to the same two cells of a **unit**: those two cells hold
/// nothing else, whatever else they still look like they could hold.
final class HiddenPair extends SolvingTechnique {
  const HiddenPair();

  @override
  Technique get technique => Technique.hiddenPair;

  @override
  Deduction? deduce(SolverState state) {
    for (final unit in GridGeometry.allUnits) {
      final places = <int, List<int>>{};
      for (var digit = 1; digit <= 9; digit++) {
        if (state.unitHolds(unit, digit)) continue;
        final cells = state.cellsAdmitting(digit, unit.cells);
        if (cells.length == 2) places[digit] = cells;
      }
      if (places.length < 2) continue;

      final digits = places.keys.toList();
      for (final pair in combinations(digits, 2)) {
        final first = places[pair[0]]!;
        final second = places[pair[1]]!;
        if (first[0] != second[0] || first[1] != second[1]) continue;

        final keep = (1 << (pair[0] - 1)) | (1 << (pair[1] - 1));
        final eliminations = <CellDigit>[
          for (final cell in first)
            for (final digit in digitsOf(state.candidateMask(cell) & ~keep))
              CellDigit(cell, digit),
        ];
        if (eliminations.isEmpty) continue;

        return Deduction(
          technique: technique,
          eliminations: eliminations,
          witnesses: first,
        );
      }
    }
    return null;
  }
}
