import 'dart:math';

import 'grader.dart';
import 'grid.dart';
import 'grid_geometry.dart';
import 'rank.dart';
import 'technique.dart';
import 'uniqueness.dart';

/// A puzzle the generator produced, with everything a **pack** row needs.
final class GeneratedPuzzle {
  const GeneratedPuzzle({
    required this.seed,
    required this.clues,
    required this.solution,
    required this.hardest,
    required this.rank,
  });

  /// Reproduces this exact puzzle through [PuzzleGenerator.puzzleForSeed].
  final int seed;

  final Grid clues;

  /// The solution the exhaustive check returned, not the grid it was dug from.
  /// They are the same grid; a test is what keeps them so.
  final Grid solution;

  /// The hardest technique the grader said this puzzle needs.
  final Technique hardest;

  /// The **rank** that technique implies (D-07, D-57). Never a request.
  final Rank rank;
}

/// What one generation run produced, and what it could not.
final class GenerationReport {
  const GenerationReport({
    required this.puzzles,
    required this.wanted,
    required this.gridSeedsTried,
    required this.candidatesConsidered,
    required this.discarded,
  });

  final List<GeneratedPuzzle> puzzles;

  /// How many were asked for at each **rank**.
  final Map<Rank, int> wanted;

  final int gridSeedsTried;

  /// Every uniquely-solvable grid the digs produced, kept or not.
  final int candidatesConsidered;

  /// Candidates thrown away: ungradable, or at a **rank** already full.
  final int discarded;

  Map<Rank, int> get found => <Rank, int>{
    for (final rank in Rank.values)
      rank: puzzles.where((puzzle) => puzzle.rank == rank).length,
  };

  /// What the run fell short by. Empty when it delivered everything asked for.
  Map<Rank, int> get shortfall => <Rank, int>{
    for (final entry in wanted.entries)
      if (entry.value - (found[entry.key] ?? 0) > 0)
        entry.key: entry.value - (found[entry.key] ?? 0),
  };

  bool get complete => shortfall.isEmpty;
}

/// Produces graded, uniquely-solvable puzzles from a seed.
///
/// **Offline only** (D-32, `docs/TECH_STACK.md` §4). Nothing here runs on a
/// device: generating and grading an expert puzzle is slow enough to be felt,
/// and pre-generation is what buys full offline play and a daily challenge that
/// is the same puzzle for everyone.
///
/// The rule the whole thing rests on: a puzzle's **rank** is what the grader
/// said about the grid that came out, never what the caller asked for. Asking
/// for a Marshal puzzle and labelling whatever appears Marshal would make the
/// ladder a lie, and it is the one bug here that ships silently.
final class PuzzleGenerator {
  const PuzzleGenerator();

  /// Bits of a seed that carry the clue count the dig stopped at.
  static const int _stopBits = 7;
  static const int _stopMask = (1 << _stopBits) - 1;

  /// The seed naming the puzzle dug from [gridSeed] and stopped at
  /// [clueCount] givens.
  static int seedFor(int gridSeed, int clueCount) =>
      (gridSeed << _stopBits) | (clueCount & _stopMask);

  static int gridSeedOf(int seed) => seed >> _stopBits;

  static int clueCountOf(int seed) => seed & _stopMask;

  /// A complete, valid grid, the same one every time for [seed].
  Grid solvedGrid(int seed) {
    final random = Random(seed);
    final digits = List<int>.filled(GridGeometry.cellCount, Grid.blank);

    bool fill(int cell) {
      if (cell == GridGeometry.cellCount) return true;
      final options = List<int>.generate(9, (i) => i + 1)..shuffle(random);
      for (final digit in options) {
        var legal = true;
        for (final peer in GridGeometry.peersOf(cell)) {
          if (digits[peer] == digit) {
            legal = false;
            break;
          }
        }
        if (!legal) continue;
        digits[cell] = digit;
        if (fill(cell + 1)) return true;
        digits[cell] = Grid.blank;
      }
      return false;
    }

    fill(0);
    return Grid.fromDigits(digits);
  }

  /// Every puzzle dug out of `solvedGrid(gridSeed)`, most clues first.
  ///
  /// Clues come out in a seeded order, and a removal that would leave more than
  /// one solution is put back rather than carried forward — so every entry in
  /// the chain is a puzzle in its own right, at its own **rank**. One dig
  /// therefore supplies the easy ranks and the hard ones from the same work.
  List<GeneratedPuzzle> digChain(int gridSeed) {
    final solution = solvedGrid(gridSeed);
    final order = digOrder(gridSeed);

    final chain = <GeneratedPuzzle>[];
    var clues = solution;
    for (final cell in order) {
      final candidate = clues.cleared(cell);
      if (checkUniqueness(candidate) is! UniqueSolution) continue;
      clues = candidate;

      final graded = grade(clues);
      if (graded is! Graded || graded.hardest == null) continue;
      chain.add(
        GeneratedPuzzle(
          seed: seedFor(gridSeed, clues.filledCount),
          clues: clues,
          solution: solution,
          hardest: graded.hardest!,
          rank: graded.rank,
        ),
      );
    }
    return chain;
  }

  /// The order clues are taken out in for [gridSeed].
  ///
  /// Public because it is half of what makes a seed reproducible — the other
  /// half being [solvedGrid] — and because a test that cannot re-walk the dig
  /// cannot check which candidates were dropped.
  List<int> digOrder(int gridSeed) =>
      List<int>.generate(GridGeometry.cellCount, (i) => i)
        ..shuffle(Random(gridSeed ^ _orderSalt));

  /// The one puzzle [seed] names, or null when it names none.
  GeneratedPuzzle? puzzleForSeed(int seed) {
    final clueCount = clueCountOf(seed);
    for (final puzzle in digChain(gridSeedOf(seed))) {
      if (puzzle.clues.filledCount == clueCount) return puzzle;
    }
    return null;
  }

  /// The most clues a shipped puzzle may carry.
  ///
  /// A dig passes through every clue count on its way down, so without a
  /// ceiling most of what it offers is a nearly-finished grid — an eighty-clue
  /// puzzle is one full house from solved, and grades Greenhorn honestly while
  /// being no kind of puzzle. Forty is the top of the ordinary easy-sudoku
  /// range: a Greenhorn puzzle at 26 to 40 clues still needs nothing harder
  /// than a naked single, and is a puzzle a person would recognise as one.
  static const int defaultMaxClues = 40;

  /// Fill the requested counts, taking whatever the grader hands back.
  ///
  /// Bounded on purpose: a **rank** that is slow to reach gives up after
  /// [maxGridSeeds] and reports what it found. A generator that ran for ever
  /// rather than admitting a shortfall would be discovered as a hung build.
  ///
  /// The ceiling is applied here rather than in [digChain] so that a seed keeps
  /// naming the same puzzle whatever a given run was selecting for.
  GenerationReport generate({
    required Map<Rank, int> wanted,
    int firstGridSeed = 0,
    int maxGridSeeds = 4000,
    int maxClues = defaultMaxClues,
    void Function(GenerationReport progress)? onGridSeed,
  }) {
    final kept = <GeneratedPuzzle>[];
    final byRank = <Rank, int>{for (final rank in Rank.values) rank: 0};
    final seenClues = <String>{};
    var considered = 0;
    var discarded = 0;
    var tried = 0;

    for (
      var gridSeed = firstGridSeed;
      gridSeed < firstGridSeed + maxGridSeeds;
      gridSeed++
    ) {
      tried++;
      for (final puzzle in digChain(gridSeed)) {
        if (puzzle.clues.filledCount > maxClues) continue;
        considered++;
        final room = (wanted[puzzle.rank] ?? 0) - byRank[puzzle.rank]!;
        // A clue grid already in the pack is the same puzzle under a second id.
        if (room <= 0 || !seenClues.add(puzzle.clues.toStorageString())) {
          discarded++;
          continue;
        }
        kept.add(puzzle);
        byRank[puzzle.rank] = byRank[puzzle.rank]! + 1;
      }

      final progress = GenerationReport(
        puzzles: kept,
        wanted: wanted,
        gridSeedsTried: tried,
        candidatesConsidered: considered,
        discarded: discarded,
      );
      onGridSeed?.call(progress);
      if (progress.complete) return progress;
    }

    return GenerationReport(
      puzzles: kept,
      wanted: wanted,
      gridSeedsTried: tried,
      candidatesConsidered: considered,
      discarded: discarded,
    );
  }

  /// Keeps the dig order independent of the digits, so two seeds that happened
  /// to shuffle alike do not also dig alike.
  static const int _orderSalt = 0x5EED;
}
