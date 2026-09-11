import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/puzzle_engine/domain/techniques/ladder.dart';

import 'support/corpus.dart';
import 'support/positions.dart';

/// Four cells locking 5 into a rectangle, all carrying a second candidate so
/// that no cell is a naked single. Row 7 then holds the digit in one place
/// only, which is a hidden single — and the X-wing is still there to be found.
SolverState get bothApply => position(<int, List<int>>{
  at(0, 1): <int>[5, 9],
  at(0, 5): <int>[5, 9],
  at(3, 1): <int>[5, 9],
  at(3, 5): <int>[5, 9],
  at(6, 1): <int>[5, 9],
});

void main() {
  const solver = Solver();

  group('a single step', () {
    test('reports one deduction, naming its technique and what it changed', () {
      final step = solver.step(gridOf(referenceClues));

      expect(step, isA<DeducedStep>());
      final deduction = (step as DeducedStep).deduction;
      expect(Technique.values, contains(deduction.technique));
      expect(deduction.changesNothing, isFalse);
      expect(deduction.affectedCells, isNotEmpty);
    });

    test('does not solve the rest of the puzzle on the way past', () {
      final step = solver.step(gridOf(referenceClues)) as DeducedStep;
      expect(step.deduction.placements.length, lessThanOrEqualTo(1));
      expect(step.grid.filledCount, lessThan(81));
    });
  });

  // A puzzle graded by a technique it never needed is a puzzle that lies about
  // its rank. The solver must reach for the easiest thing that works.
  test('the easiest applicable technique wins', () {
    final state = bothApply;
    expect(
      techniqueFor(Technique.hiddenSingle).deduce(state.copy()),
      isNotNull,
    );
    expect(techniqueFor(Technique.xWing).deduce(state.copy()), isNotNull);

    final step = solver.stepFrom(state) as DeducedStep;
    expect(step.deduction.technique, Technique.hiddenSingle);
  });

  test('the reported technique is always the earliest one that applies', () {
    var state = SolverState.fromGrid(gridOf(referenceClues));
    for (var i = 0; i < 12; i++) {
      final applicable = <Technique>[
        for (final entry in techniqueLadder)
          if (entry.deduce(state.copy()) != null) entry.technique,
      ];
      final step = solver.stepFrom(state.copy());
      if (applicable.isEmpty) {
        expect(step, isA<NoProgress>());
        break;
      }
      expect((step as DeducedStep).deduction.technique, applicable.first);
      state.apply(step.deduction);
    }
  });

  group('nothing to do', () {
    test('a grid no technique can touch reports no progress, unchanged', () {
      final step = solver.step(Grid.empty);

      expect(step, isA<NoProgress>());
      expect((step as NoProgress).grid, Grid.empty);
    });

    test('a completed grid reports solved and invents no deduction', () {
      final step = solver.step(gridOf(referenceSolution));

      expect(step, isA<Solved>());
      expect((step as Solved).grid, gridOf(referenceSolution));
    });

    test('no progress and solved are different answers', () {
      expect(
        solver.step(Grid.empty).runtimeType,
        isNot(solver.step(gridOf(referenceSolution)).runtimeType),
      );
    });
  });

  group('solving to completion', () {
    test('the reference puzzle solves, and to the one right answer', () {
      final outcome = solver.solve(gridOf(referenceClues));

      expect(outcome.solved, isTrue);
      expect(outcome.grid, gridOf(referenceSolution));
      expect(outcome.deductions, isNotEmpty);
      expect(outcome.techniquesUsed, isNotEmpty);
      expect(outcome.hardestTechnique, isNotNull);
    });

    test('every deduction it reports is one it actually applied', () {
      final outcome = solver.solve(gridOf(referenceClues));
      final replayed = SolverState.fromGrid(gridOf(referenceClues));
      for (final deduction in outcome.deductions) {
        replayed.apply(deduction);
      }
      expect(replayed.toGrid(), outcome.grid);
    });

    test('a puzzle it cannot finish comes back unsolved, not thrown', () {
      final outcome = solver.solve(Grid.empty);

      expect(outcome.solved, isFalse);
      expect(outcome.deductions, isEmpty);
      expect(outcome.grid, Grid.empty);
      expect(outcome.hardestTechnique, isNull);
    });

    test('restricting the ladder restricts what it can reach', () {
      const singlesOnly = Solver(
        allowed: <Technique>{Technique.fullHouse, Technique.nakedSingle},
      );
      final outcome = singlesOnly.solve(gridOf(referenceClues));
      expect(
        outcome.techniquesUsed.difference(<Technique>{
          Technique.fullHouse,
          Technique.nakedSingle,
        }),
        isEmpty,
      );
    });
  });

  // Grading depends on it, and so will a hint that must not change its mind
  // between taps.
  test('solving is deterministic', () {
    List<String> trace() => <String>[
      for (final deduction in solver.solve(gridOf(referenceClues)).deductions)
        '${deduction.technique.name}'
            '|${deduction.placements}'
            '|${deduction.eliminations}',
    ];

    final first = trace();
    expect(first, isNotEmpty);
    for (var run = 0; run < 4; run++) {
      expect(trace(), first);
    }
  });

  test('a step taken twice from the same grid is the same step', () {
    final grid = gridOf(referenceClues);
    final first = solver.step(grid) as DeducedStep;
    final second = solver.step(grid) as DeducedStep;
    expect(first.deduction.technique, second.deduction.technique);
    expect(first.deduction.placements, second.deduction.placements);
    expect(first.deduction.eliminations, second.deduction.eliminations);
  });

  test('it solves a puzzle at every rank by repeated stepping', () {
    for (final entry in corpus) {
      final outcome = solver.solve(entry.grid);
      expect(outcome.solved, isTrue, reason: entry.rank.name);
      expect(outcome.grid, entry.solutionGrid, reason: entry.rank.name);

      // The same answer one step at a time, which is what a hint will do.
      final state = SolverState.fromGrid(entry.grid);
      var steps = 0;
      while (steps++ < 200) {
        final step = solver.stepFrom(state);
        if (step is! DeducedStep) break;
        state.apply(step.deduction);
      }
      expect(solver.stepFrom(state), isA<Solved>(), reason: entry.rank.name);
      expect(state.toGrid(), entry.solutionGrid, reason: entry.rank.name);
    }
  });
}
