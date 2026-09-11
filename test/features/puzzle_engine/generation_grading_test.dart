import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/generator.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grader.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

import 'support/corpus.dart';

void main() {
  const generator = PuzzleGenerator();

  // The one bug here that ships silently. Asking for a Marshal puzzle and
  // labelling whatever comes back Marshal makes the whole ladder a lie, and a
  // player finding a Marshal puzzle trivial reports it as nothing at all.
  group('the stored rank is the grade the puzzle earned', () {
    test('every generated puzzle grades to the rank it carries', () {
      for (var seed = 0; seed < 4; seed++) {
        for (final puzzle in generator.digChain(seed)) {
          final graded = grade(puzzle.clues);
          expect(graded, isA<Graded>(), reason: 'seed ${puzzle.seed}');
          expect((graded as Graded).rank, puzzle.rank);
          expect(graded.hardest, puzzle.hardest);
        }
      }
    });

    test('asking for one rank never relabels a puzzle of another', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.marshal: 4},
        maxGridSeeds: 200,
      );

      expect(report.puzzles, isNotEmpty);
      for (final puzzle in report.puzzles) {
        expect(puzzle.rank, Rank.marshal);
        // Re-graded from the clues alone, with nothing said about the request.
        expect((grade(puzzle.clues) as Graded).rank, Rank.marshal);
      }
    });

    test(
      'a puzzle that grades below the request is discarded, not relabelled',
      () {
        // Every dig produces far more easy puzzles than Marshal ones, so a run
        // asking only for Marshal must be throwing the rest away rather than
        // renaming them.
        final report = generator.generate(
          wanted: <Rank, int>{Rank.marshal: 3},
          maxGridSeeds: 200,
        );

        expect(report.discarded, greaterThan(report.puzzles.length));
        expect(report.puzzles.map((puzzle) => puzzle.rank).toSet(), <Rank>{
          Rank.marshal,
        });
      },
    );

    test('the rank always matches its hardest technique (D-57)', () {
      for (final puzzle in generator.digChain(6)) {
        expect(puzzle.rank, puzzle.hardest.introducedAt);
      }
    });
  });

  group('a puzzle the ladder cannot finish is discarded', () {
    test('such puzzles exist and the grader calls them ungradable', () {
      expect(grade(corpusGrid(puzzleBeyondTheLadder)), isA<Ungradable>());
    });

    // Re-walks the dig with the engine alone and compares. Anything uniquely
    // solvable but ungradable must be absent from the chain, and anything
    // gradable must be present — a filter that dropped gradable puzzles would
    // quietly bias the pack.
    test('the chain is exactly the gradable grids along the dig', () {
      for (var gridSeed = 0; gridSeed < 3; gridSeed++) {
        final solution = generator.solvedGrid(gridSeed);
        var clues = solution;
        final gradable = <String>[];
        final ungradable = <String>[];

        for (final cell in generator.digOrder(gridSeed)) {
          final candidate = clues.cleared(cell);
          if (checkUniqueness(candidate) is! UniqueSolution) continue;
          clues = candidate;
          final target = grade(clues) is Graded ? gradable : ungradable;
          target.add(clues.toStorageString());
        }

        final chain = generator
            .digChain(gridSeed)
            .map((puzzle) => puzzle.clues.toStorageString())
            .toList();
        expect(chain, gradable, reason: 'grid seed $gridSeed');
        for (final dropped in ungradable) {
          expect(chain, isNot(contains(dropped)));
        }
      }
    });

    test('nothing ungradable is filed under Legend', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.legend: 2},
        maxGridSeeds: 200,
      );
      for (final puzzle in report.puzzles) {
        final graded = grade(puzzle.clues);
        expect(graded, isA<Graded>());
        expect((graded as Graded).rank, Rank.legend);
      }
    });
  });

  // A dig passes through every clue count on the way down, so without a ceiling
  // most of what it offers is a nearly-finished grid: an eighty-clue puzzle is
  // one full house from solved, grades Greenhorn honestly, and is no kind of
  // puzzle.
  group('a shipped puzzle is a puzzle', () {
    test('nothing over forty clues is selected, at any rank', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.greenhorn: 25, Rank.deputy: 10},
        maxGridSeeds: 200,
      );

      expect(report.puzzles, isNotEmpty);
      for (final puzzle in report.puzzles) {
        expect(
          puzzle.clues.filledCount,
          lessThanOrEqualTo(PuzzleGenerator.defaultMaxClues),
          reason: 'seed ${puzzle.seed}',
        );
      }
    });

    test('the gentlest rank is still a puzzle', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.greenhorn: 20},
        maxGridSeeds: 200,
      );
      for (final puzzle in report.puzzles) {
        expect(puzzle.rank, Rank.greenhorn);
        expect(puzzle.clues.filledCount, lessThanOrEqualTo(40));
        expect(puzzle.clues.filledCount, greaterThan(16));
      }
    });

    test(
      'the ceiling is a selection rule, not a change to what a seed names',
      () {
        // digChain still offers the whole dig; the seed keeps its meaning.
        final chain = generator.digChain(0);
        expect(
          chain.any((puzzle) => puzzle.clues.filledCount > 40),
          isTrue,
          reason: 'the chain itself is unfiltered',
        );
        for (final puzzle in chain) {
          expect(generator.puzzleForSeed(puzzle.seed)!.clues, puzzle.clues);
        }
      },
    );

    test('a tighter ceiling is honoured when asked for', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.greenhorn: 5},
        maxGridSeeds: 200,
        maxClues: 30,
      );
      for (final puzzle in report.puzzles) {
        expect(puzzle.clues.filledCount, lessThanOrEqualTo(30));
      }
    });
  });

  group('the run is bounded', () {
    test('an unreachable request gives up and reports the shortfall', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.legend: 100000},
        maxGridSeeds: 2,
      );

      expect(report.complete, isFalse);
      expect(report.gridSeedsTried, 2);
      expect(report.shortfall[Rank.legend], isNotNull);
      expect(
        report.shortfall[Rank.legend],
        100000 - (report.found[Rank.legend] ?? 0),
      );
    });

    test(
      'a satisfied request stops early rather than using its whole budget',
      () {
        final report = generator.generate(
          wanted: <Rank, int>{Rank.greenhorn: 2},
          maxGridSeeds: 500,
        );

        expect(report.complete, isTrue);
        expect(report.gridSeedsTried, lessThan(500));
        expect(report.found[Rank.greenhorn], 2);
        expect(report.shortfall, isEmpty);
      },
    );

    test('it reports what it looked at, not only what it kept', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.sheriff: 2},
        maxGridSeeds: 20,
      );
      expect(report.candidatesConsidered, greaterThan(report.puzzles.length));
      expect(
        report.candidatesConsidered,
        report.puzzles.length + report.discarded,
      );
    });

    test('no two kept puzzles share a clue grid', () {
      final report = generator.generate(
        wanted: <Rank, int>{Rank.greenhorn: 30, Rank.deputy: 30},
        maxGridSeeds: 200,
      );
      final grids = report.puzzles
          .map((puzzle) => puzzle.clues.toStorageString())
          .toList();
      expect(grids.toSet(), hasLength(grids.length));
    });
  });

  // The shipped pack is committed, so a run that answered differently would
  // either show up as a diff nobody asked for or — worse — not show up at all,
  // because the pack was never regenerated to notice.
  test('a whole run is reproducible from its seed', () {
    Map<Rank, int> split() => <Rank, int>{
      Rank.greenhorn: 6,
      Rank.deputy: 6,
      Rank.sheriff: 4,
      Rank.marshal: 2,
    };

    final first = generator.generate(
      wanted: split(),
      firstGridSeed: 20260909,
      maxGridSeeds: 300,
    );
    final second = generator.generate(
      wanted: split(),
      firstGridSeed: 20260909,
      maxGridSeeds: 300,
    );

    expect(first.complete, isTrue);
    expect(second.gridSeedsTried, first.gridSeedsTried);
    expect(second.candidatesConsidered, first.candidatesConsidered);
    expect(second.discarded, first.discarded);
    expect(second.puzzles, hasLength(first.puzzles.length));
    for (var i = 0; i < first.puzzles.length; i++) {
      expect(second.puzzles[i].seed, first.puzzles[i].seed);
      expect(
        second.puzzles[i].clues.toStorageString(),
        first.puzzles[i].clues.toStorageString(),
      );
      expect(second.puzzles[i].rank, first.puzzles[i].rank);
    }
  });

  test('a different seed gives a different pack', () {
    const wanted = <Rank, int>{Rank.deputy: 5};
    final a = generator.generate(wanted: wanted, firstGridSeed: 1);
    final b = generator.generate(wanted: wanted, firstGridSeed: 5000);
    expect(
      b.puzzles.map((p) => p.seed).toSet(),
      isNot(a.puzzles.map((p) => p.seed).toSet()),
    );
  });
}
