import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/generator.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

void main() {
  const generator = PuzzleGenerator();

  group('a seeded solved grid', () {
    test('is a complete, valid grid', () {
      for (final seed in <int>[0, 1, 7, 20260909]) {
        final grid = generator.solvedGrid(seed);
        expect(grid.isFull, isTrue, reason: 'seed $seed');
        expect(grid.isComplete, isTrue, reason: 'seed $seed');
      }
    });

    test('is the same grid every time for the same seed', () {
      for (final seed in <int>[0, 3, 512]) {
        expect(generator.solvedGrid(seed), generator.solvedGrid(seed));
      }
    });

    test('different seeds give different grids', () {
      final grids = <Grid>{
        for (var seed = 0; seed < 8; seed++) generator.solvedGrid(seed),
      };
      expect(grids, hasLength(8));
    });
  });

  group('digging', () {
    // Uniqueness is asked of the exhaustive search, never of the technique
    // solver: a solver that fails to finish has run out of techniques, which is
    // not the same claim as the puzzle being ambiguous (constraint 8).
    test('every puzzle along the chain still has exactly one solution', () {
      for (var seed = 0; seed < 3; seed++) {
        final chain = generator.digChain(seed);
        expect(chain, isNotEmpty, reason: 'seed $seed');
        for (final puzzle in chain) {
          expect(
            checkUniqueness(puzzle.clues),
            isA<UniqueSolution>(),
            reason: 'seed $seed, ${puzzle.clues.filledCount} clues',
          );
        }
      }
    });

    test('the chain only ever removes clues', () {
      final chain = generator.digChain(11);
      final solved = generator.solvedGrid(11);
      for (var i = 0; i < chain.length; i++) {
        final clues = chain[i].clues;
        expect(clues.filledCount, lessThan(81));
        if (i > 0) {
          expect(clues.filledCount, lessThan(chain[i - 1].clues.filledCount));
        }
        // Every clue that survives is the solution's digit in that cell.
        for (var cell = 0; cell < 81; cell++) {
          if (clues.isEmptyAt(cell)) continue;
          expect(clues.digitAt(cell), solved.digitAt(cell));
        }
      }
    });

    test('the stored solution is the one the uniqueness check returned', () {
      for (var seed = 0; seed < 3; seed++) {
        final solved = generator.solvedGrid(seed);
        for (final puzzle in generator.digChain(seed)) {
          final unique = checkUniqueness(puzzle.clues) as UniqueSolution;
          expect(puzzle.solution, unique.solution);
          expect(puzzle.solution, solved);
        }
      }
    });

    test('a puzzle never ships graded by nothing', () {
      for (final puzzle in generator.digChain(5)) {
        expect(puzzle.rank, puzzle.hardest.introducedAt);
      }
    });
  });

  group('a seed names exactly one puzzle', () {
    test('the seed round-trips back to the puzzle it produced', () {
      for (var gridSeed = 0; gridSeed < 3; gridSeed++) {
        for (final puzzle in generator.digChain(gridSeed)) {
          final again = generator.puzzleForSeed(puzzle.seed);
          expect(again, isNotNull, reason: 'seed ${puzzle.seed}');
          expect(again!.clues, puzzle.clues);
          expect(again.solution, puzzle.solution);
          expect(again.rank, puzzle.rank);
          expect(again.seed, puzzle.seed);
        }
      }
    });

    test('a seed naming no puzzle answers null rather than inventing one', () {
      // Clue count 81 is the solved grid: nothing was dug, so no puzzle.
      expect(generator.puzzleForSeed(PuzzleGenerator.seedFor(0, 81)), isNull);
    });

    test('every seed in a chain is distinct', () {
      final chain = generator.digChain(2);
      expect(chain.map((p) => p.seed).toSet(), hasLength(chain.length));
    });
  });

  // Generation runs offline and its output is committed, so a change of answer
  // between runs would show up as a diff nobody asked for — or worse, not show
  // up at all because the pack was not regenerated.
  test('generation is deterministic end to end', () {
    for (var seed = 0; seed < 3; seed++) {
      final first = generator.digChain(seed);
      final second = generator.digChain(seed);
      expect(first.length, second.length);
      for (var i = 0; i < first.length; i++) {
        expect(
          second[i].clues.toStorageString(),
          first[i].clues.toStorageString(),
        );
        expect(second[i].seed, first[i].seed);
        expect(second[i].rank, first[i].rank);
      }
    }
  });
}
