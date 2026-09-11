import 'grid.dart';
import 'grid_geometry.dart';

/// What the engine can say about putting a digit in a cell.
///
/// Three separate facts and no fourth folding them into a verdict. Whether any
/// of this counts as a mistake is `add-mistake-model`'s decision — D-05 says
/// overwriting a correct cell never does, and the engine must not be the layer
/// that quietly decides otherwise.
final class PlacementReport {
  const PlacementReport({
    required this.cell,
    required this.digit,
    required this.conflictingCells,
    required this.agreesWithSolution,
    required this.overwritesCorrectValue,
  });

  final int cell;
  final int digit;

  /// The peers already holding [digit], ascending. Empty when there are none.
  final List<int> conflictingCells;

  /// Whether [digit] is what the solution has in [cell].
  final bool agreesWithSolution;

  /// Whether [cell] already held the solution's digit. A fact, not a fault.
  final bool overwritesCorrectValue;

  bool get conflicts => conflictingCells.isNotEmpty;
}

/// The peers of [cell] already holding [digit], ascending.
///
/// A digit repeating in a **unit** is reported with the cells it repeats
/// against, because a caller that wants to point at the clash needs to know
/// where it is.
List<int> conflictingPeers(
  Grid grid, {
  required int cell,
  required int digit,
}) => <int>[
  for (final peer in GridGeometry.peersOf(cell))
    if (grid.digitAt(peer) == digit) peer,
];

/// Everything the engine knows about placing [digit] in [cell].
///
/// Conflict and disagreement are answered separately on purpose: a digit can
/// break no **unit** and still be wrong, and telling those apart is what lets
/// the mistake model treat them differently.
PlacementReport inspectPlacement({
  required Grid grid,
  required Grid solution,
  required int cell,
  required int digit,
}) {
  final existing = grid.digitAt(cell);
  return PlacementReport(
    cell: cell,
    digit: digit,
    conflictingCells: conflictingPeers(grid, cell: cell, digit: digit),
    agreesWithSolution: solution.digitAt(cell) == digit,
    overwritesCorrectValue:
        existing != Grid.blank && existing == solution.digitAt(cell),
  );
}

/// Every cell holds a digit and no **unit** repeats one.
bool isComplete(Grid grid) => grid.isComplete;
