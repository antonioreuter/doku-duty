import 'cage.dart';
import 'deduction.dart';
import 'grid.dart';
import 'solver_state.dart';
import 'technique.dart';
import 'techniques/ladder.dart';
import 'techniques/solving_technique.dart';

/// What one step of solving found.
///
/// Three answers, none of them an error: a puzzle nothing can be done with is a
/// thing puzzles are, not a fault to throw at whoever asked.
sealed class SolverStep {
  const SolverStep();

  /// The grid as it stands after the step. Unchanged unless something was
  /// deduced.
  Grid get grid;
}

/// One technique made one deduction.
final class DeducedStep extends SolverStep {
  const DeducedStep({required this.deduction, required this.grid});

  final Deduction deduction;

  @override
  final Grid grid;
}

/// Every cell holds a digit; there is nothing left to deduce.
final class Solved extends SolverStep {
  const Solved(this.grid);

  @override
  final Grid grid;
}

/// No implemented technique can make progress. The grid comes back untouched.
final class NoProgress extends SolverStep {
  const NoProgress(this.grid);

  @override
  final Grid grid;
}

/// The end of a full solve.
final class SolveOutcome {
  const SolveOutcome({
    required this.grid,
    required this.deductions,
    required this.solved,
  });

  /// The grid as far as the solver got.
  final Grid grid;

  /// Every deduction made, in the order they were made.
  final List<Deduction> deductions;

  /// Whether the grid was finished. False is an answer, not a failure.
  final bool solved;

  Set<Technique> get techniquesUsed => <Technique>{
    for (final deduction in deductions) deduction.technique,
  };

  /// The hardest technique the solve actually needed, or null when it needed
  /// none. This is what a grade is made of.
  Technique? get hardestTechnique {
    Technique? hardest;
    for (final deduction in deductions) {
      if (hardest == null || deduction.technique.index > hardest.index) {
        hardest = deduction.technique;
      }
    }
    return hardest;
  }
}

/// Solves by applying named techniques, easiest first, and says what it did.
///
/// [allowed] restricts the ladder, which is how a puzzle's grade is checked at
/// its boundary: a puzzle that needs a naked pair must solve with the Sheriff
/// ladder and must stall with everything below it.
final class Solver {
  const Solver({this.allowed});

  /// The techniques this solver may use, or null for the whole ladder.
  final Set<Technique>? allowed;

  Iterable<SolvingTechnique> get _ladder => allowed == null
      ? techniqueLadder
      : techniqueLadder.where((entry) => allowed!.contains(entry.technique));

  /// The next deduction for [grid], without solving the rest of it. [cages]
  /// makes it a **killer** grid.
  SolverStep step(Grid grid, {CageSet? cages}) =>
      stepFrom(SolverState.fromGrid(grid, cages: cages));

  /// The next deduction for a state that already carries its eliminations.
  ///
  /// The state is not modified; apply the deduction to advance it.
  SolverStep stepFrom(SolverState state) {
    if (state.isSolved) return Solved(state.toGrid());
    for (final entry in _ladder) {
      final deduction = entry.deduce(state);
      if (deduction == null) continue;
      final next = state.copy()..apply(deduction);
      return DeducedStep(deduction: deduction, grid: next.toGrid());
    }
    return NoProgress(state.toGrid());
  }

  /// Step until the grid is finished or nothing applies. [cages] makes it a
  /// **killer** grid.
  SolveOutcome solve(Grid grid, {CageSet? cages}) {
    final state = SolverState.fromGrid(grid, cages: cages);
    final deductions = <Deduction>[];
    while (true) {
      if (state.isSolved) {
        return SolveOutcome(
          grid: state.toGrid(),
          deductions: deductions,
          solved: true,
        );
      }
      Deduction? found;
      for (final entry in _ladder) {
        found = entry.deduce(state);
        if (found != null) break;
      }
      if (found == null) {
        return SolveOutcome(
          grid: state.toGrid(),
          deductions: deductions,
          solved: false,
        );
      }
      deductions.add(found);
      state.apply(found);
    }
  }
}
