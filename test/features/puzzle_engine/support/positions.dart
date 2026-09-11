import 'package:doku_duty/features/puzzle_engine/domain/candidates.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';

/// The flat index of a cell, from its row and column, both zero-based.
int at(int row, int column) => GridGeometry.cellAt(row: row, column: column);

/// A state holding no digits and only the candidates named.
///
/// A technique can then only fire on what the test put in front of it, which is
/// the point: the half of each technique's suite that matters is the half that
/// asserts it says *nothing*, and that assertion is worthless if the position
/// carries patterns the test did not intend.
SolverState position(Map<int, List<int>> candidates) =>
    SolverState.fromCandidates(
      digits: List<int>.filled(GridGeometry.cellCount, Grid.blank),
      candidates: <Candidates>[
        for (var cell = 0; cell < GridGeometry.cellCount; cell++)
          Candidates.of(candidates[cell] ?? const <int>[]),
      ],
    );

Grid gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

SolverState stateOf(String source) => SolverState.fromGrid(gridOf(source));

/// The classic grid used across the suite. Unique, and graded by the engine
/// rather than asserted here.
const String referenceClues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String referenceSolution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
