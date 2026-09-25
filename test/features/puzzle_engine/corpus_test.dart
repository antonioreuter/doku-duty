import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

import 'support/corpus.dart';

void main() {
  // Classic techniques only: a **killer** technique needs **cage**s, which no
  // corpus grid has. Its fixtures live in killer_grader_test.dart.
  test('there is an entry for every classic technique in the ladder', () {
    expect(
      corpus.map((entry) => entry.technique).toList(),
      Technique.values.where((technique) => !technique.killerOnly),
      reason: 'a technique with no corpus entry is a grade nothing checks',
    );
  });

  // Checked before any of it is used to test grading. A non-unique puzzle can
  // be "solved" two ways, so the grader's answer about one would mean nothing —
  // and this is the one judgement in the suite that does not come from the
  // technique solver.
  test('every entry is unique by exhaustive search, as is its alternate', () {
    for (final entry in corpus) {
      for (final grid in <String>[entry.clues, entry.alternate]) {
        final result = checkUniqueness(
          grid == entry.clues ? entry.grid : entry.alternateGrid,
        );
        expect(
          result,
          isA<UniqueSolution>(),
          reason: '${entry.technique.name}: $grid',
        );
      }
      expect(
        (checkUniqueness(entry.grid) as UniqueSolution).solution,
        entry.solutionGrid,
        reason: entry.technique.name,
      );
    }
  });

  test('the recorded solution agrees with the clues and is complete', () {
    for (final entry in corpus) {
      expect(
        entry.solutionGrid.isComplete,
        isTrue,
        reason: entry.technique.name,
      );
      for (var cell = 0; cell < 81; cell++) {
        if (entry.grid.isEmptyAt(cell)) continue;
        expect(
          entry.solutionGrid.digitAt(cell),
          entry.grid.digitAt(cell),
          reason: '${entry.technique.name} disagrees at cell $cell',
        );
      }
    }
  });

  // This is what turns "provably requires" into a property the suite checks
  // rather than a claim in a comment.
  test('each entry solves at its rank and stalls one technique lower', () {
    for (final entry in corpus) {
      final atRank = Solver(
        allowed: Technique.upTo(entry.rank).toSet(),
      ).solve(entry.grid);
      expect(
        atRank.solved,
        isTrue,
        reason:
            '${entry.technique.name} must solve with the '
            '${entry.rank.name} ladder',
      );

      final withheld = Solver(
        allowed: Technique.values.take(entry.technique.index).toSet(),
      ).solve(entry.grid);
      expect(
        withheld.solved,
        isFalse,
        reason: '${entry.technique.name} must be needed, not merely used',
      );
    }
  });

  test('an entry never needs a technique harder than its own', () {
    for (final entry in corpus) {
      final outcome = const Solver().solve(entry.grid);
      expect(outcome.solved, isTrue, reason: entry.technique.name);
      expect(outcome.hardestTechnique, entry.technique);
      for (final used in outcome.techniquesUsed) {
        expect(
          used.index,
          lessThanOrEqualTo(entry.technique.index),
          reason: '${entry.technique.name} reached for ${used.name}',
        );
      }
    }
  });

  test('the ladder cannot finish the puzzle recorded as beyond it', () {
    final outcome = const Solver().solve(corpusGrid(puzzleBeyondTheLadder));
    expect(outcome.solved, isFalse);
    expect(outcome.deductions, isNotEmpty, reason: 'it should get some way in');
    expect(
      checkUniqueness(corpusGrid(puzzleBeyondTheLadder)),
      isA<UniqueSolution>(),
    );
  });

  test('the corpus covers all six ranks', () {
    expect(corpus.map((entry) => entry.rank).toSet(), Rank.values.toSet());
  });
}
