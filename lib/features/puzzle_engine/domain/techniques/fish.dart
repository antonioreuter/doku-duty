import '../deduction.dart';
import '../grid_geometry.dart';
import '../solver_state.dart';
import '../technique.dart';
import 'solving_technique.dart';

/// Two rows in which a digit sits in the same two columns — or the transpose.
/// The digit is then locked to that rectangle, and leaves those columns alone.
final class XWing extends SolvingTechnique {
  const XWing();

  @override
  Technique get technique => Technique.xWing;

  @override
  Deduction? deduce(SolverState state) => _fish(state, technique, 2);
}

/// The same argument over three lines instead of two.
final class Swordfish extends SolvingTechnique {
  const Swordfish();

  @override
  Technique get technique => Technique.swordfish;

  @override
  Deduction? deduce(SolverState state) => _fish(state, technique, 3);
}

/// A fish of [size] lines: [size] base **units** in which a digit occupies at
/// most [size] positions between them, covering exactly [size] cross **units**.
///
/// Rows are searched before columns, and lower digits before higher ones, so the
/// same grid always yields the same deduction.
Deduction? _fish(SolverState state, Technique technique, int size) {
  for (var digit = 1; digit <= 9; digit++) {
    for (final orientation in const <UnitKind>[UnitKind.row, UnitKind.column]) {
      final cross = orientation == UnitKind.row
          ? UnitKind.column
          : UnitKind.row;
      final bases = <_FishLine>[];
      for (final line in GridGeometry.unitsOfKind(orientation)) {
        if (state.unitHolds(line, digit)) continue;
        final cells = state.cellsAdmitting(digit, line.cells);
        if (cells.length < 2 || cells.length > size) continue;
        bases.add(
          _FishLine(
            line: line,
            cells: cells,
            crossIndices: <int>{
              for (final cell in cells) _indexIn(cross, cell),
            },
          ),
        );
      }
      if (bases.length < size) continue;

      for (final subset in combinations(bases, size)) {
        final covered = <int>{for (final base in subset) ...base.crossIndices};
        if (covered.length != size) continue;

        final witnesses = <int>[for (final base in subset) ...base.cells]
          ..sort();
        final baseIndices = <int>{for (final base in subset) base.line.index};
        final eliminations = <CellDigit>[
          for (final index in covered.toList()..sort())
            for (final cell in GridGeometry.unitsOfKind(cross)[index].cells)
              if (!baseIndices.contains(_indexIn(orientation, cell)) &&
                  state.isEmptyAt(cell) &&
                  state.hasCandidate(cell, digit))
                CellDigit(cell, digit),
        ];
        if (eliminations.isEmpty) continue;

        return Deduction(
          technique: technique,
          eliminations: eliminations,
          witnesses: witnesses,
        );
      }
    }
  }
  return null;
}

int _indexIn(UnitKind kind, int cell) => kind == UnitKind.row
    ? GridGeometry.rowOf(cell)
    : GridGeometry.columnOf(cell);

final class _FishLine {
  const _FishLine({
    required this.line,
    required this.cells,
    required this.crossIndices,
  });

  final Unit line;
  final List<int> cells;
  final Set<int> crossIndices;
}
