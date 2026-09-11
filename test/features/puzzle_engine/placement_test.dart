import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/placement.dart';

import 'support/positions.dart';

void main() {
  final clues = gridOf(referenceClues);
  final solution = gridOf(referenceSolution);

  group('conflict with a peer', () {
    test(
      'a digit repeating in a unit is reported with the cells that conflict',
      () {
        // Cell 2 sits in row 0 with the 5 at cell 0 and the 3 at cell 1, and in
        // block 0 with the 6 at cell 9.
        expect(conflictingPeers(clues, cell: 2, digit: 5), <int>[0]);
        expect(conflictingPeers(clues, cell: 2, digit: 3), <int>[1]);
        expect(conflictingPeers(clues, cell: 2, digit: 6), <int>[9]);
      },
    );

    test(
      'each conflicting cell is listed once, however many units it shares',
      () {
        // 8 sits at cell 20 (block 0 and column 2) and at cell 27 (column 0).
        final conflicts = conflictingPeers(clues, cell: 2, digit: 8);
        expect(conflicts, contains(20));
        expect(conflicts, hasLength(1));

        final many = conflictingPeers(clues, cell: 11, digit: 9);
        expect(many.length, greaterThan(1));
        expect(many, equals(many.toSet().toList()..sort()));
      },
    );

    test('a digit that breaks no unit conflicts with nothing', () {
      expect(conflictingPeers(clues, cell: 2, digit: 4), isEmpty);
      expect(conflictingPeers(clues, cell: 2, digit: 1), isEmpty);
    });

    test('a cell never conflicts with itself', () {
      expect(conflictingPeers(clues, cell: 0, digit: 5), isEmpty);
    });
  });

  group('disagreement with the solution', () {
    // A digit can break no unit and still be wrong. `add-mistake-model` has to
    // tell those apart, so the engine reports them apart.
    test(
      'a legal digit that is not the solution is reported as disagreeing',
      () {
        final report = inspectPlacement(
          grid: clues,
          solution: solution,
          cell: 2,
          digit: 1,
        );

        expect(report.conflictingCells, isEmpty);
        expect(report.agreesWithSolution, isFalse);
        expect(report.digit, 1);
        expect(report.cell, 2);
      },
    );

    test('the solution digit agrees, and conflicts with nothing', () {
      final report = inspectPlacement(
        grid: clues,
        solution: solution,
        cell: 2,
        digit: 4,
      );

      expect(report.conflictingCells, isEmpty);
      expect(report.agreesWithSolution, isTrue);
    });

    test('conflicting and disagreeing are separate answers', () {
      final conflicting = inspectPlacement(
        grid: clues,
        solution: solution,
        cell: 2,
        digit: 5,
      );

      expect(conflicting.conflictingCells, isNotEmpty);
      expect(conflicting.agreesWithSolution, isFalse);
      expect(conflicting.conflicts, isTrue);
    });

    test('every cell of the solution agrees with itself', () {
      for (var cell = 0; cell < 81; cell++) {
        final report = inspectPlacement(
          grid: clues,
          solution: solution,
          cell: cell,
          digit: solution.digitAt(cell),
        );
        expect(report.agreesWithSolution, isTrue, reason: 'cell $cell');
      }
    });
  });

  // D-05: overwriting a correct cell is never a mistake, in any mode. The
  // engine reports the fact and stops there — deciding what it costs belongs to
  // `add-mistake-model`, and this layer must not pre-empt it.
  group('overwriting', () {
    test('a value replacing a correct one is reported for what it is', () {
      final partial = clues.withDigit(2, 4); // 4 is the solution at cell 2.
      final report = inspectPlacement(
        grid: partial,
        solution: solution,
        cell: 2,
        digit: 1,
      );

      expect(report.overwritesCorrectValue, isTrue);
      expect(report.agreesWithSolution, isFalse);
      expect(report.conflictingCells, isEmpty);
    });

    test('replacing a wrong value is not an overwrite of a correct one', () {
      final partial = clues.withDigit(2, 1);
      final report = inspectPlacement(
        grid: partial,
        solution: solution,
        cell: 2,
        digit: 2,
      );

      expect(report.overwritesCorrectValue, isFalse);
    });

    test('filling an empty cell overwrites nothing', () {
      final report = inspectPlacement(
        grid: clues,
        solution: solution,
        cell: 2,
        digit: 4,
      );
      expect(report.overwritesCorrectValue, isFalse);
    });

    test('the report offers no verdict beyond the facts', () {
      final report = inspectPlacement(
        grid: clues.withDigit(2, 4),
        solution: solution,
        cell: 2,
        digit: 1,
      );
      // Three separate facts, and no fourth field folding them into a judgement.
      expect(report.conflicts, isFalse);
      expect(report.agreesWithSolution, isFalse);
      expect(report.overwritesCorrectValue, isTrue);
    });
  });

  group('completion', () {
    test('a finished grid is complete', () {
      expect(isComplete(solution), isTrue);
    });

    test('an unfinished grid is not', () {
      expect(isComplete(clues), isFalse);
      expect(isComplete(solution.cleared(0)), isFalse);
    });

    test('a full grid that repeats a digit in a unit is not complete', () {
      expect(isComplete(solution.withDigit(1, 5)), isFalse);
    });

    test('the empty grid is not complete', () {
      expect(isComplete(Grid.empty), isFalse);
    });
  });
}
