import 'dart:math';

import 'cage.dart';
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
    this.cages,
  });

  /// Reproduces this exact puzzle through [PuzzleGenerator.puzzleForSeed], on
  /// a generator of the same kind.
  final int seed;

  /// The **cage**s of a **killer** puzzle, or null for a classic one.
  final CageSet? cages;

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
///
/// A **killer** generator ([killer]) digs the same seeded grid under a seeded
/// **cage** partition, asking uniqueness and the grade of each step with the
/// **cage**s in hand. Everything else — the seed, the dig, the selection — is
/// shared, so the two kinds cannot drift apart in how they choose.
final class PuzzleGenerator {
  const PuzzleGenerator({this.killer = false});

  /// Whether this generator makes **killer** puzzles rather than classic ones.
  final bool killer;

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
    final cages = killer ? cagesFor(gridSeed) : null;
    var clues = solution;
    for (final cell in order) {
      final candidate = clues.cleared(cell);
      if (checkUniqueness(candidate, cages: cages) is! UniqueSolution) {
        continue;
      }
      clues = candidate;

      final graded = grade(clues, cages: cages);
      if (graded is! Graded || graded.hardest == null) continue;
      chain.add(
        GeneratedPuzzle(
          seed: seedFor(gridSeed, clues.filledCount),
          clues: clues,
          solution: solution,
          hardest: graded.hardest!,
          rank: graded.rank,
          cages: cages,
        ),
      );
    }
    return chain;
  }

  /// The **cage** partition of `solvedGrid(gridSeed)`, the same every time.
  ///
  /// Grown from a seeded walk: each **cage** starts at the first cell not yet
  /// taken, aims for a seeded size, and only takes a neighbour whose digit it
  /// does not already hold — the solution must satisfy every **cage** it is
  /// cut from. A single cell left stranded joins a neighbouring **cage** where
  /// one can take it, because a one-cell **cage** is a given in disguise.
  CageSet cagesFor(int gridSeed) {
    final solution = solvedGrid(gridSeed);
    final random = Random(gridSeed ^ _cageSalt);
    final owner = List<int>.filled(GridGeometry.cellCount, -1);
    final members = <List<int>>[];
    final digitsHeld = <int>[];

    int bit(int cell) => 1 << (solution.digitAt(cell) - 1);

    for (var start = 0; start < GridGeometry.cellCount; start++) {
      if (owner[start] != -1) continue;
      final id = members.length;
      final target = _cageSizes[random.nextInt(_cageSizes.length)];
      final cells = <int>[start];
      owner[start] = id;
      var held = bit(start);
      while (cells.length < target) {
        final frontier = <int>[
          for (final cell in cells)
            for (final next in _edgeNeighbours(cell))
              if (owner[next] == -1 && held & bit(next) == 0) next,
        ]..sort();
        if (frontier.isEmpty) break;
        final next = frontier[random.nextInt(frontier.length)];
        owner[next] = id;
        cells.add(next);
        held |= bit(next);
      }
      members.add(cells);
      digitsHeld.add(held);
    }

    for (var id = 0; id < members.length; id++) {
      if (members[id].length != 1) continue;
      final cell = members[id].single;
      int? into;
      for (final next in _edgeNeighbours(cell)) {
        final other = owner[next];
        if (other == id || members[other].length >= GridGeometry.maxDigit) {
          continue;
        }
        if (digitsHeld[other] & bit(cell) != 0) continue;
        if (into == null || members[other].length < members[into].length) {
          into = other;
        }
      }
      if (into == null) continue;
      members[into].add(cell);
      digitsHeld[into] |= bit(cell);
      owner[cell] = into;
      members[id] = <int>[];
    }

    final result = CageSet.build(<Cage>[
      for (final cells in members)
        if (cells.isNotEmpty)
          Cage(
            cells: cells,
            sum: cells.fold(0, (sum, cell) => sum + solution.digitAt(cell)),
          ),
    ]);
    // A partition cut from a valid solved grid is valid by construction; this
    // is the assertion that says so, not a path anything takes.
    return (result as ValidCageSet).cages;
  }

  /// Seeded **cage** sizes, drawn uniformly from this list: mostly twos and
  /// threes, as a published **killer** is, with the occasional larger one.
  static const List<int> _cageSizes = <int>[2, 2, 2, 3, 3, 3, 3, 4, 4, 5];

  static Iterable<int> _edgeNeighbours(int cell) sync* {
    final row = GridGeometry.rowOf(cell);
    final column = GridGeometry.columnOf(cell);
    if (row > 0) yield cell - GridGeometry.side;
    if (row < GridGeometry.side - 1) yield cell + GridGeometry.side;
    if (column > 0) yield cell - 1;
    if (column < GridGeometry.side - 1) yield cell + 1;
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

  /// Keeps the **cage** partition independent of the dig order and the digits.
  static const int _cageSalt = 0xCA6E;
}
