import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grader.dart';
import 'package:doku_duty/features/puzzle_engine/domain/generator.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

void main() {
  const killer = PuzzleGenerator(killer: true);

  group('a seeded cage partition', () {
    test(
      'covers the grid and adds up over the solved grid it was cut from',
      () {
        for (final seed in <int>[0, 1, 7]) {
          final solved = killer.solvedGrid(seed);
          final cages = killer.cagesFor(seed);
          expect(cages.isSatisfiedBy(solved), isTrue, reason: 'seed $seed');
        }
      },
    );

    test('is the same partition every time for the same seed', () {
      for (final seed in <int>[0, 3]) {
        final first = killer.cagesFor(seed).cages;
        final second = killer.cagesFor(seed).cages;
        expect(
          <String>[for (final cage in second) '$cage'],
          <String>[for (final cage in first) '$cage'],
        );
      }
    });
  });

  group('killer digging', () {
    test('every puzzle along the chain is unique under its cages', () {
      for (var seed = 0; seed < 2; seed++) {
        final chain = killer.digChain(seed);
        expect(chain, isNotEmpty, reason: 'seed $seed');
        for (final puzzle in chain) {
          expect(puzzle.cages, isNotNull);
          final result = checkUniqueness(puzzle.clues, cages: puzzle.cages);
          expect(
            result,
            isA<UniqueSolution>(),
            reason: 'seed $seed, ${puzzle.clues.filledCount} clues',
          );
          expect((result as UniqueSolution).solution, puzzle.solution);
        }
      }
    });

    // The shipped-pack rule: a rank is what the grader said about the grid
    // that came out, never what anyone asked for.
    test('every puzzle carries the rank the grader gives it', () {
      for (final puzzle in killer.digChain(4)) {
        final graded = grade(puzzle.clues, cages: puzzle.cages) as Graded;
        expect(puzzle.rank, graded.rank);
        expect(puzzle.hardest, graded.hardest);
      }
    });

    test('digs further than classic, because the sums carry information', () {
      // A classic dig bottoms out around the low twenties; cages let a killer
      // board drop well below that and stay unique.
      final fewest = killer
          .digChain(0)
          .map((puzzle) => puzzle.clues.filledCount)
          .reduce((a, b) => a < b ? a : b);
      expect(fewest, lessThan(17));
    });
  });

  test('a seed round-trips to the same killer puzzle', () {
    for (final puzzle in killer.digChain(1)) {
      final again = killer.puzzleForSeed(puzzle.seed)!;
      expect(again.clues, puzzle.clues);
      expect(again.rank, puzzle.rank);
      expect(
        <String>[for (final cage in again.cages!.cages) '$cage'],
        <String>[for (final cage in puzzle.cages!.cages) '$cage'],
      );
    }
  });

  test('generation is deterministic end to end', () {
    final first = killer.digChain(2);
    final second = killer.digChain(2);
    expect(
      second.map((p) => p.clues.toStorageString()),
      first.map((p) => p.clues.toStorageString()),
    );
  });

  test('a classic puzzle carries no cages', () {
    for (final puzzle in const PuzzleGenerator().digChain(0)) {
      expect(puzzle.cages, isNull);
    }
  });

  test(
    'generate fills killer counts at the ranks asked, graded not labelled',
    () {
      final report = killer.generate(
        wanted: <Rank, int>{Rank.greenhorn: 1, Rank.sheriff: 1},
        maxGridSeeds: 20,
      );
      expect(report.complete, isTrue);
      for (final puzzle in report.puzzles) {
        expect(puzzle.cages, isNotNull);
        expect(puzzle.clues.filledCount, lessThanOrEqualTo(40));
        expect(
          (grade(puzzle.clues, cages: puzzle.cages) as Graded).rank,
          puzzle.rank,
        );
      }
    },
  );
}
