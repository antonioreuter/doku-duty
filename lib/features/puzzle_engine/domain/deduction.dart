import 'grid_geometry.dart';
import 'technique.dart';

/// A digit in a cell — either placed there or ruled out of it.
final class CellDigit {
  const CellDigit(this.cell, this.digit);

  final int cell;
  final int digit;

  @override
  bool operator ==(Object other) =>
      other is CellDigit && other.cell == cell && other.digit == digit;

  @override
  int get hashCode => Object.hash(cell, digit);

  @override
  String toString() =>
      'r${GridGeometry.rowOf(cell) + 1}c${GridGeometry.columnOf(cell) + 1}=$digit';
}

/// One step of reasoning: what a named technique concluded, and from what.
///
/// The engine reports rather than merely solving. A hint (change 19) needs the
/// technique's name, the cells it changed, and the cells that justify it; the
/// grader needs only the name. Both read this.
final class Deduction {
  const Deduction({
    required this.technique,
    this.placements = const <CellDigit>[],
    this.eliminations = const <CellDigit>[],
    this.witnesses = const <int>[],
  });

  final Technique technique;

  /// Digits this step settles.
  final List<CellDigit> placements;

  /// Digits this step rules out of a cell.
  final List<CellDigit> eliminations;

  /// The cells that justify the step — the pair, the wing, the chain. Empty
  /// where the pattern is the changed cell itself, as with a naked single.
  final List<int> witnesses;

  /// Every cell this step changed, ascending.
  List<int> get affectedCells => <int>{
    for (final placement in placements) placement.cell,
    for (final elimination in eliminations) elimination.cell,
  }.toList()..sort();

  /// A step that changes nothing is not a deduction. Techniques return null
  /// rather than one of these, and this is the assertion that says so.
  bool get changesNothing => placements.isEmpty && eliminations.isEmpty;

  @override
  String toString() =>
      '${technique.name}(placed: $placements, eliminated: $eliminations)';
}
