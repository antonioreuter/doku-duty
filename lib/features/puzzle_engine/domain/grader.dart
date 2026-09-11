import 'grid.dart';
import 'rank.dart';
import 'solver.dart';
import 'technique.dart';

/// What a puzzle's **rank** is, or why it has none.
///
/// Two answers, and the second is not a failure: a puzzle the ladder cannot
/// finish is a puzzle nobody should be handed, and saying so is the point.
sealed class GradeResult {
  const GradeResult();
}

/// The puzzle is solvable by the ladder, at the **rank** its hardest technique
/// implies (D-07, D-57).
final class Graded extends GradeResult {
  const Graded({
    required this.hardest,
    required this.rank,
    required this.techniquesUsed,
  });

  /// The hardest technique the solve actually needed, or null for a grid that
  /// was already finished and needed none.
  final Technique? hardest;

  /// The **rank** [hardest] belongs to. Greenhorn when nothing was needed.
  final Rank rank;

  /// Everything the solve used, for a per-technique statistic.
  final Set<Technique> techniquesUsed;
}

/// No implemented technique can finish the puzzle.
///
/// Reported rather than filed under the top **rank**. Calling this Legend is
/// what would put a guess-and-check puzzle in front of a player, and constraint
/// 8 forbids that.
final class Ungradable extends GradeResult {
  const Ungradable({required this.stalledAt, required this.techniquesUsed});

  /// As far as the ladder got.
  final Grid stalledAt;

  /// What it managed before stalling. Useful for saying how far short it fell.
  final Set<Technique> techniquesUsed;

  int get cellsRemaining => 81 - stalledAt.filledCount;
}

/// Grade [grid] by the hardest technique it requires.
///
/// Never by clue count (D-07). Nothing here counts givens, times a solve, or
/// consults anything but the ladder — a rank means "this is the hardest thing
/// you will have to see", and it can only mean that if it is measured that way.
GradeResult grade(Grid grid) {
  final outcome = const Solver().solve(grid);
  if (!outcome.solved) {
    return Ungradable(
      stalledAt: outcome.grid,
      techniquesUsed: outcome.techniquesUsed,
    );
  }
  final hardest = outcome.hardestTechnique;
  return Graded(
    hardest: hardest,
    rank: hardest?.introducedAt ?? Rank.greenhorn,
    techniquesUsed: outcome.techniquesUsed,
  );
}
