import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

import 'support/corpus.dart';

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
}
