import '../cage.dart';
import '../deduction.dart';
import '../grid.dart';
import '../grid_geometry.dart';
import '../solver_state.dart';
import '../technique.dart';
import 'solving_technique.dart';

/// Only some sets of digits add up to a **cage sum**: whatever no such set can
/// seat in the **cage**'s open cells goes (D-128).
///
/// A two-cell **cage** of 3 is {1,2}. "Can seat" matters: a set whose digits
/// the open cells' candidates cannot place one per cell is no combination at
/// all, and counting it would leave digits standing that nothing can use.
final class CageCombination extends SolvingTechnique {
  const CageCombination();

  @override
  Technique get technique => Technique.cageCombination;

  @override
  Deduction? deduce(SolverState state) {
    final cages = state.cages;
    if (cages == null) return null;
    for (final cage in cages.cages) {
      final open = <int>[];
      var used = 0;
      var remaining = cage.sum;
      for (final cell in cage.cells) {
        final digit = state.digitAt(cell);
        if (digit == Grid.blank) {
          open.add(cell);
        } else {
          used |= 1 << (digit - 1);
          remaining -= digit;
        }
      }
      if (open.isEmpty) continue;

      final masks = <int>[for (final cell in open) state.candidateMask(cell)];
      var usable = 0;
      for (final set in Cage.combinations(open.length, remaining)) {
        if (set & used != 0) continue;
        if (!_canSeat(set, masks, 0)) continue;
        usable |= set;
      }
      // Nothing seats: a broken position, and a broken position deduces nothing.
      if (usable == 0) continue;

      final eliminations = <CellDigit>[
        for (var i = 0; i < open.length; i++)
          for (final digit in digitsOf(masks[i] & ~usable))
            CellDigit(open[i], digit),
      ];
      if (eliminations.isEmpty) continue;
      return Deduction(
        technique: technique,
        eliminations: eliminations,
        witnesses: cage.cells,
      );
    }
    return null;
  }

  /// Whether [set]'s digits can go one to each of the cells from [index] on.
  /// At most nine cells, so a plain search is cheap.
  static bool _canSeat(int set, List<int> masks, int index) {
    if (index == masks.length) return set == 0;
    for (final digit in digitsOf(set & masks[index])) {
      if (_canSeat(set & ~(1 << (digit - 1)), masks, index + 1)) return true;
    }
    return false;
  }
}

/// Every **unit** holds 1 to 9, which sum to 45. Take the **cage**s lying
/// wholly inside a **unit**: if they leave one cell of it uncovered, that cell
/// is 45 less their sums — a single innie. Take the **cage**s touching it: if
/// they reach one cell outside it, that cell is their sums less 45 — a single
/// outie (D-128).
///
/// A cell already holding its digit still counts toward the total, so a
/// **unit** whose uncovered cells are all filled but one gives that one too.
final class FortyFiveRule extends SolvingTechnique {
  const FortyFiveRule();

  static const int _unitTotal = 45;

  @override
  Technique get technique => Technique.fortyFiveRule;

  @override
  Deduction? deduce(SolverState state) {
    final cages = state.cages;
    if (cages == null) return null;
    for (final unit in GridGeometry.allUnits) {
      final members = unit.cells.toSet();
      final touching = <Cage>{
        for (final cell in unit.cells) cages.cageOf(cell),
      };
      final inside = <Cage>[
        for (final cage in touching)
          if (cage.cells.every(members.contains)) cage,
      ];

      final covered = <int>{for (final cage in inside) ...cage.cells};
      final innie = _single(
        state,
        cells: unit.cells.where((cell) => !covered.contains(cell)),
        total: _unitTotal - _sumOf(inside),
        witnesses: <int>{...unit.cells, ...covered},
      );
      if (innie != null) return innie;

      final outside = <int>[
        for (final cage in touching)
          for (final cell in cage.cells)
            if (!members.contains(cell)) cell,
      ];
      final outie = _single(
        state,
        cells: outside,
        total: _sumOf(touching) - _unitTotal,
        witnesses: <int>{
          ...unit.cells,
          for (final cage in touching) ...cage.cells,
        },
      );
      if (outie != null) return outie;
    }
    return null;
  }

  /// The placement when exactly one of [cells] is open and the rest are filled:
  /// the open one is [total] less the filled ones. Null otherwise, and null
  /// when the digit that leaves is not one the cell can take.
  Deduction? _single(
    SolverState state, {
    required Iterable<int> cells,
    required int total,
    required Set<int> witnesses,
  }) {
    var open = -1;
    var remaining = total;
    for (final cell in cells) {
      final digit = state.digitAt(cell);
      if (digit != Grid.blank) {
        remaining -= digit;
      } else if (open != -1) {
        return null;
      } else {
        open = cell;
      }
    }
    if (open == -1) return null;
    if (remaining < 1 || remaining > 9) return null;
    if (!state.hasCandidate(open, remaining)) return null;
    return Deduction(
      technique: technique,
      placements: <CellDigit>[CellDigit(open, remaining)],
      witnesses: (witnesses..remove(open)).toList()..sort(),
    );
  }

  static int _sumOf(Iterable<Cage> cages) =>
      cages.fold(0, (total, cage) => total + cage.sum);
}
