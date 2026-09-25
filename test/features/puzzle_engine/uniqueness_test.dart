import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

import 'package:doku_duty/features/puzzle_engine/domain/cage.dart';

import 'support/corpus.dart';
import 'support/killer.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// The solution above with every 8 and every 9 removed.
///
/// Seven distinct digits appear, so the two absent ones can be exchanged
/// wholesale: whatever completes this grid, swapping 8 for 9 completes it too.
/// Ambiguity here is a property of the construction, not a lucky find.
const String _sevenDigits =
    '53467..126721.534.1..342567.5.761423426.537.1713.24.56.615372.42.741.6353452.617.';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

void main() {
  test('a puzzle with one solution is unique, and the solution comes back', () {
    final result = checkUniqueness(_grid(_clues));
    expect(result, isA<UniqueSolution>());
    expect((result as UniqueSolution).solution, _grid(_solution));
  });

  test('a grid that can be completed more than one way is ambiguous', () {
    final result = checkUniqueness(_grid(_sevenDigits));
    expect(result, isA<AmbiguousSolutions>());
    final ambiguous = result as AmbiguousSolutions;
    expect(ambiguous.first, isNot(ambiguous.second));
    for (final solution in <Grid>[ambiguous.first, ambiguous.second]) {
      expect(solution.isComplete, isTrue);
    }
  });

  test('clues that contradict outright report no solution', () {
    // A second 5 in the first row.
    final result = checkUniqueness(_grid(_clues).withDigit(2, 5));
    expect(result, isA<NoSolution>());
  });

  test(
    'clues that break no unit but admit no completion report no solution',
    () {
      // Cell 2 holds 4 in the only solution, and 1 is a legal candidate there —
      // so this grid conflicts with nothing and still cannot be finished. The
      // distinction from ambiguity has to survive that.
      final result = checkUniqueness(_grid(_clues).withDigit(2, 1));
      expect(result, isA<NoSolution>());
    },
  );

  test('the three answers are distinct, not a boolean', () {
    expect(<Type>{
      checkUniqueness(_grid(_clues)).runtimeType,
      checkUniqueness(_grid(_sevenDigits)).runtimeType,
      checkUniqueness(_grid(_clues).withDigit(2, 5)).runtimeType,
    }, hasLength(3));
  });

  test('the empty grid is ambiguous, and the check returns promptly', () {
    final stopwatch = Stopwatch()..start();
    final result = checkUniqueness(Grid.empty);
    stopwatch.stop();
    expect(result, isA<AmbiguousSolutions>());
    expect(result, isNot(isA<NoSolution>()));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('a completed grid is its own unique solution', () {
    final result = checkUniqueness(_grid(_solution));
    expect(result, isA<UniqueSolution>());
    expect((result as UniqueSolution).solution, _grid(_solution));
  });

  test('a completed grid that repeats a digit has no solution', () {
    final result = checkUniqueness(_grid(_solution).withDigit(1, 5));
    expect(result, isA<NoSolution>());
  });

  test('the search stops at the second solution rather than enumerating', () {
    // The empty grid has 6.67e21 solutions. Anything that counted them would
    // not return, so returning at all is the assertion.
    final result = checkUniqueness(Grid.empty);
    expect(result, isA<AmbiguousSolutions>());
  });

  // Constraint 8, and conflating the two questions is the way it breaks. A
  // technique solver that fails to finish tells you it ran out of techniques,
  // not that the puzzle is ambiguous.
  group('independent of the technique solver', () {
    test('a puzzle no technique can finish still reports one solution', () {
      final grid = corpusGrid(puzzleBeyondTheLadder);
      expect(const Solver().solve(grid).solved, isFalse);

      final result = checkUniqueness(grid);
      expect(result, isA<UniqueSolution>());
      expect(
        (result as UniqueSolution).solution,
        corpusGrid(puzzleBeyondTheLadderSolution),
      );
    });

    test('the check does not consult the ladder at all', () {
      final source = File(
        'lib/features/puzzle_engine/domain/uniqueness.dart',
      ).readAsStringSync();
      for (final forbidden in <String>[
        'techniques/',
        'solver.dart',
        'Technique.',
      ]) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: 'uniqueness must not reach for $forbidden',
        );
      }
    });
  });

  // A **killer** search prunes on **cage** repeats and partial sums, and its
  // answer must be the same three answers for the same reasons.
  group('on a killer puzzle', () {
    test('a grid unique only through its sums is reported unique', () {
      final cages = referenceKillerCages(_solution);
      // No givens at all: the grid alone admits every sudoku there is.
      expect(checkUniqueness(Grid.empty), isA<AmbiguousSolutions>());

      final result = checkUniqueness(Grid.empty, cages: cages);
      expect(result, isA<UniqueSolution>());
      final solution = (result as UniqueSolution).solution;
      expect(solution, _grid(_solution));
      expect(cages.isSatisfiedBy(solution), isTrue);
    });

    test('the same grid with one cage sum changed is not unique', () {
      final original = referenceKillerCages(_solution);
      // The first cage, r1c1-r1c3, holds 5, 3 and 4. Any other sum its size
      // allows makes the reference solution wrong.
      final first = original.cageOf(0);
      expect(first.sum, 12);
      final result = CageSet.build(<Cage>[
        for (final cage in original.cages)
          identical(cage, first) ? Cage(cells: cage.cells, sum: 13) : cage,
      ]);
      final altered = (result as ValidCageSet).cages;

      final answer = checkUniqueness(Grid.empty, cages: altered);
      expect(answer, anyOf(isA<AmbiguousSolutions>(), isA<NoSolution>()));
    });

    test('a given that contradicts a cage reports no solution', () {
      // The cages alone admit exactly one completion, with 5 in r1c1, so a
      // 9 there breaks no unit and still leaves nothing.
      final result = checkUniqueness(
        Grid.empty.withDigit(0, 9),
        cages: referenceKillerCages(_solution),
      );
      expect(result, isA<NoSolution>());
    });

    test('ambiguous solutions both satisfy every cage', () {
      // One big cage per row, each summing to 45, says nothing a row does not.
      final rows = cagesFromShape(
        'aaaaaaaaa'
        'bbbbbbbbb'
        'ccccccccc'
        'ddddddddd'
        'eeeeeeeee'
        'fffffffff'
        'ggggggggg'
        'hhhhhhhhh'
        'iiiiiiiii',
        _solution,
      );
      final result = checkUniqueness(_grid(_sevenDigits), cages: rows);
      expect(result, isA<AmbiguousSolutions>());
      final ambiguous = result as AmbiguousSolutions;
      expect(rows.isSatisfiedBy(ambiguous.first), isTrue);
      expect(rows.isSatisfiedBy(ambiguous.second), isTrue);
    });

    test('a classic grid answers exactly as before', () {
      for (final source in <String>[_clues, _sevenDigits, _solution]) {
        final grid = _grid(source);
        expect(
          checkUniqueness(grid, cages: null).runtimeType,
          checkUniqueness(grid).runtimeType,
        );
      }
    });
  });
}
