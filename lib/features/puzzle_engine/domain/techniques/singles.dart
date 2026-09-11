import '../deduction.dart';
import '../grid.dart';
import '../grid_geometry.dart';
import '../solver_state.dart';
import '../technique.dart';
import 'solving_technique.dart';

/// A **unit** with one empty cell left: the missing digit goes there.
final class FullHouse extends SolvingTechnique {
  const FullHouse();

  @override
  Technique get technique => Technique.fullHouse;

  @override
  Deduction? deduce(SolverState state) {
    for (final unit in GridGeometry.allUnits) {
      var empty = -1;
      var placed = 0;
      var emptyCount = 0;
      for (final cell in unit.cells) {
        final digit = state.digitAt(cell);
        if (digit == Grid.blank) {
          empty = cell;
          emptyCount++;
          if (emptyCount > 1) break;
        } else {
          placed |= 1 << (digit - 1);
        }
      }
      if (emptyCount != 1) continue;
      final missing = digitsOf(0x1FF & ~placed);
      if (missing.length != 1) continue; // A broken unit deduces nothing.
      return Deduction(
        technique: technique,
        placements: <CellDigit>[CellDigit(empty, missing.single)],
        witnesses: <int>[
          for (final cell in unit.cells)
            if (cell != empty) cell,
        ],
      );
    }
    return null;
  }
}

/// A cell with one candidate left: that digit goes there.
final class NakedSingle extends SolvingTechnique {
  const NakedSingle();

  @override
  Technique get technique => Technique.nakedSingle;

  @override
  Deduction? deduce(SolverState state) {
    for (final cell in state.emptyCells) {
      final digit = state.candidatesAt(cell).single;
      if (digit == null) continue;
      return Deduction(
        technique: technique,
        placements: <CellDigit>[CellDigit(cell, digit)],
      );
    }
    return null;
  }
}

/// A digit with one place left in a **unit**: it goes there, however many other
/// candidates that cell still carries.
final class HiddenSingle extends SolvingTechnique {
  const HiddenSingle();

  @override
  Technique get technique => Technique.hiddenSingle;

  @override
  Deduction? deduce(SolverState state) {
    for (final unit in GridGeometry.allUnits) {
      for (var digit = 1; digit <= 9; digit++) {
        if (state.unitHolds(unit, digit)) continue;
        final places = state.cellsAdmitting(digit, unit.cells);
        if (places.length != 1) continue;
        return Deduction(
          technique: technique,
          placements: <CellDigit>[CellDigit(places.single, digit)],
          witnesses: <int>[
            for (final cell in unit.cells)
              if (cell != places.single) cell,
          ],
        );
      }
    }
    return null;
  }
}
