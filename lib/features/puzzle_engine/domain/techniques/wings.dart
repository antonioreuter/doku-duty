import '../deduction.dart';
import '../grid_geometry.dart';
import '../solver_state.dart';
import '../technique.dart';
import 'solving_technique.dart';

/// A pivot holding exactly two candidates, and two pincers that each share one
/// of them plus a third digit. Whichever way the pivot falls, one pincer takes
/// the third digit — so no cell seeing both pincers can.
final class XyWing extends SolvingTechnique {
  const XyWing();

  @override
  Technique get technique => Technique.xyWing;

  @override
  Deduction? deduce(SolverState state) {
    for (var pivot = 0; pivot < GridGeometry.cellCount; pivot++) {
      if (!state.isEmptyAt(pivot)) continue;
      final pivotMask = state.candidateMask(pivot);
      if (bitCount(pivotMask) != 2) continue;

      final pincers = <int>[
        for (final peer in GridGeometry.peersOf(pivot))
          if (state.isEmptyAt(peer) && bitCount(state.candidateMask(peer)) == 2)
            peer,
      ]..sort();

      for (final pair in combinations(pincers, 2)) {
        final firstMask = state.candidateMask(pair[0]);
        final secondMask = state.candidateMask(pair[1]);

        final firstShared = firstMask & pivotMask;
        final secondShared = secondMask & pivotMask;
        if (bitCount(firstShared) != 1 || bitCount(secondShared) != 1) continue;
        if (firstShared == secondShared) continue;

        final third = firstMask & secondMask;
        if (bitCount(third) != 1 || third & pivotMask != 0) continue;
        final digit = digitsOf(third).single;

        final seesBoth = GridGeometry.peersOf(pair[0]).toSet().intersection(
          GridGeometry.peersOf(pair[1]).toSet(),
        )..remove(pivot);
        final eliminations = <CellDigit>[
          for (final cell in seesBoth.toList()..sort())
            if (state.isEmptyAt(cell) && state.hasCandidate(cell, digit))
              CellDigit(cell, digit),
        ];
        if (eliminations.isEmpty) continue;

        return Deduction(
          technique: technique,
          eliminations: eliminations,
          witnesses: <int>[pivot, pair[0], pair[1]]..sort(),
        );
      }
    }
    return null;
  }
}
