import '../deduction.dart';
import '../grid_geometry.dart';
import '../solver_state.dart';
import '../technique.dart';
import 'solving_technique.dart';

/// A digit confined to one row or column *within a block*: it cannot sit
/// anywhere else along that line.
final class PointingPair extends SolvingTechnique {
  const PointingPair();

  @override
  Technique get technique => Technique.pointingPair;

  @override
  Deduction? deduce(SolverState state) {
    for (final block in GridGeometry.unitsOfKind(UnitKind.block)) {
      for (var digit = 1; digit <= 9; digit++) {
        if (state.unitHolds(block, digit)) continue;
        final cells = state.cellsAdmitting(digit, block.cells);
        if (cells.length < 2) continue;

        for (final kind in const <UnitKind>[UnitKind.row, UnitKind.column]) {
          final line = _sharedLine(cells, kind);
          if (line == null) continue;
          final eliminations = <CellDigit>[
            for (final cell in line.cells)
              if (GridGeometry.blockOf(cell) != block.index &&
                  state.isEmptyAt(cell) &&
                  state.hasCandidate(cell, digit))
                CellDigit(cell, digit),
          ];
          if (eliminations.isEmpty) continue;
          return Deduction(
            technique: technique,
            eliminations: eliminations,
            witnesses: cells,
          );
        }
      }
    }
    return null;
  }
}

/// A digit confined to one block *within a row or column*: it cannot sit
/// anywhere else in that block.
final class BoxLineReduction extends SolvingTechnique {
  const BoxLineReduction();

  @override
  Technique get technique => Technique.boxLineReduction;

  @override
  Deduction? deduce(SolverState state) {
    for (final kind in const <UnitKind>[UnitKind.row, UnitKind.column]) {
      for (final line in GridGeometry.unitsOfKind(kind)) {
        for (var digit = 1; digit <= 9; digit++) {
          if (state.unitHolds(line, digit)) continue;
          final cells = state.cellsAdmitting(digit, line.cells);
          if (cells.length < 2) continue;

          final block = GridGeometry.blockOf(cells.first);
          if (cells.any((cell) => GridGeometry.blockOf(cell) != block)) {
            continue;
          }

          final eliminations = <CellDigit>[
            for (final cell in GridGeometry.unitsOfKind(
              UnitKind.block,
            )[block].cells)
              if (!cells.contains(cell) &&
                  state.isEmptyAt(cell) &&
                  state.hasCandidate(cell, digit))
                CellDigit(cell, digit),
          ];
          if (eliminations.isEmpty) continue;
          return Deduction(
            technique: technique,
            eliminations: eliminations,
            witnesses: cells,
          );
        }
      }
    }
    return null;
  }
}

/// The row or column every one of [cells] lies on, or null when they straddle.
Unit? _sharedLine(List<int> cells, UnitKind kind) {
  final index = kind == UnitKind.row
      ? GridGeometry.rowOf(cells.first)
      : GridGeometry.columnOf(cells.first);
  for (final cell in cells) {
    final other = kind == UnitKind.row
        ? GridGeometry.rowOf(cell)
        : GridGeometry.columnOf(cell);
    if (other != index) return null;
  }
  return GridGeometry.unitsOfKind(kind)[index];
}
