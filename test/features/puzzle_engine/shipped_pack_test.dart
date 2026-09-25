import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/generator.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grader.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

/// Checks the file that actually ships.
///
/// The generator's own tests say the generator works; these say *this pack* is
/// correct, and they are not the same claim. The pack is committed, so a bad
/// puzzle in it outlives the commit that produced it — and nothing else in the
/// suite would ever look at it.
void main() {
  const packPath = 'assets/packs/frontier-1.json';

  /// The split `tool/generate_pack.dart` ships, and `assets/packs/README.md`
  /// records. Restated here so the file cannot quietly be regenerated smaller.
  const expected = <Rank, int>{
    Rank.greenhorn: 70,
    Rank.deputy: 70,
    Rank.sheriff: 60,
    Rank.marshal: 50,
    Rank.ranger: 35,
    Rank.legend: 20,
  };

  /// The **killer** split, for **variant node**s. Every **rank** needs some,
  /// because a published **season** may put a **variant node** at any of them.
  const expectedKiller = <Rank, int>{
    Rank.greenhorn: 12,
    Rank.deputy: 12,
    Rank.sheriff: 12,
    Rank.marshal: 12,
    Rank.ranger: 12,
    Rank.legend: 12,
  };

  late Pack pack;

  setUpAll(() {
    final file = File(packPath);
    expect(file.existsSync(), isTrue, reason: '$packPath is missing');
    final result = Pack.parse(file.readAsStringSync());
    expect(
      result,
      isA<ParsedPack>(),
      reason: result is InvalidPack ? result.description : '',
    );
    pack = (result as ParsedPack).pack;
  });

  Grid gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

  test('it is the pack the app declares', () {
    expect(pack.packId, 'frontier-1');
    expect(pack.version, 2);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains(packPath),
      reason: 'the pack is generated but never bundled',
    );
  });

  // Constraint 8, at the only point where breaking it reaches a player. A
  // **killer** puzzle is checked under its **cage**s, which is the only way
  // most of them are unique at all.
  test('every puzzle has exactly one solution, and it is the stored one', () {
    for (final puzzle in pack.puzzles) {
      final result = checkUniqueness(gridOf(puzzle.clues), cages: puzzle.cages);
      expect(result, isA<UniqueSolution>(), reason: puzzle.id);
      expect(
        (result as UniqueSolution).solution,
        gridOf(puzzle.solution),
        reason: '${puzzle.id} stores a solution that is not its own',
      );
    }
  });

  test('every stored solution agrees with its clues and is complete', () {
    for (final puzzle in pack.puzzles) {
      final clues = gridOf(puzzle.clues);
      final solution = gridOf(puzzle.solution);
      expect(solution.isComplete, isTrue, reason: puzzle.id);
      for (var cell = 0; cell < 81; cell++) {
        if (clues.isEmptyAt(cell)) continue;
        expect(
          solution.digitAt(cell),
          clues.digitAt(cell),
          reason: '${puzzle.id} disagrees with its own clues at cell $cell',
        );
      }
    }
  });

  // Catches a pack generated against an older engine: the file would still
  // parse, still be unique, and carry grades this solver no longer agrees with.
  test('every stored rank is what the grader returns for it now', () {
    for (final puzzle in pack.puzzles) {
      final graded = grade(gridOf(puzzle.clues), cages: puzzle.cages);
      expect(graded, isA<Graded>(), reason: '${puzzle.id} is ungradable');
      expect(
        (graded as Graded).rank,
        puzzle.rank,
        reason: '${puzzle.id} is stored as ${puzzle.rank.name}',
      );
    }
  });

  test('all six ranks are present, in the counts the tool shipped', () {
    final classic = pack.puzzles.where((p) => !p.isKiller);
    for (final rank in Rank.values) {
      final count = classic.where((p) => p.rank == rank).length;
      expect(count, expected[rank], reason: rank.name);
      expect(count, greaterThan(0), reason: rank.name);
    }
    expect(classic, hasLength(305));
  });

  test('every rank has killer puzzles, in the counts the tool shipped', () {
    final killer = pack.puzzles.where((p) => p.isKiller);
    for (final rank in Rank.values) {
      final count = killer.where((p) => p.rank == rank).length;
      expect(count, expectedKiller[rank], reason: rank.name);
      expect(count, greaterThan(0), reason: rank.name);
    }
  });

  test('every killer solution satisfies its cages', () {
    for (final puzzle in pack.puzzles.where((p) => p.isKiller)) {
      expect(
        puzzle.cages!.isSatisfiedBy(gridOf(puzzle.solution)),
        isTrue,
        reason: puzzle.id,
      );
    }
  });

  test('no two puzzles share a clue grid', () {
    final grids = pack.puzzles.map((puzzle) => puzzle.clues).toList();
    expect(
      grids.toSet(),
      hasLength(grids.length),
      reason: 'the same puzzle would be handed out twice under two ids',
    );
  });

  test('every id is unique', () {
    final ids = pack.puzzles.map((puzzle) => puzzle.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  // A regenerated pack must not re-key a puzzle the player has already solved:
  // the id is derived from the seed, and the seed reproduces the puzzle. The
  // two kinds share a seed encoding, so the prefix is what keeps them apart.
  test('every id is derived from its seed and kind, so it is stable', () {
    for (final puzzle in pack.puzzles) {
      final prefix = puzzle.isKiller ? 'k' : 'q';
      expect(puzzle.id, '$prefix${puzzle.seed}', reason: puzzle.id);
    }
    for (final killer in <bool>[false, true]) {
      final ofKind = pack.puzzles.where((p) => p.isKiller == killer);
      expect(ofKind.map((p) => p.seed).toSet(), hasLength(ofKind.length));
    }
  });

  test('a seed reproduces the puzzle it is stored on', () {
    // Costly per puzzle, so a spread rather than all 305 — one per rank, and
    // the whole pack is covered by the uniqueness and grading tests above.
    for (final killer in <bool>[false, true]) {
      final generator = PuzzleGenerator(killer: killer);
      for (final rank in Rank.values) {
        final puzzle = pack.puzzles.firstWhere(
          (p) => p.rank == rank && p.isKiller == killer,
        );
        final regenerated = generator.puzzleForSeed(puzzle.seed);
        expect(regenerated, isNotNull, reason: puzzle.id);
        expect(regenerated!.clues.toStorageString(), puzzle.clues);
        expect(regenerated.solution.toStorageString(), puzzle.solution);
        expect(regenerated.rank, puzzle.rank);
        expect(regenerated.cages, puzzle.cages, reason: puzzle.id);
      }
    }
  });

  test('no puzzle carries more than forty clues', () {
    for (final puzzle in pack.puzzles) {
      expect(
        gridOf(puzzle.clues).filledCount,
        lessThanOrEqualTo(PuzzleGenerator.defaultMaxClues),
        reason: '${puzzle.id} is a nearly-finished grid, not a puzzle',
      );
    }
  });

  test('the file stays small enough to bundle without thought', () {
    final kilobytes = File(packPath).lengthSync() / 1024;
    expect(kilobytes, lessThan(512), reason: '${kilobytes.round()} KB');
  });
}
