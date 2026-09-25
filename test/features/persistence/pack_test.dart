import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';

void main() {
  late AppDatabase db;
  late PackRepository packs;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    packs = PackRepository(db);
  });
  tearDown(() => db.close());

  // A minimal grid. Not a real puzzle — generation and grading are change 5's
  // business, and this layer must never be the thing that decides a rank.
  const clues =
      '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....'
      '419..5....8..79';
  const solution =
      '534678912672195348198342567859761423426853791713924856961537284'
      '287419635345286179';

  StoredPuzzle puzzle(String id, Rank rank) => StoredPuzzle(
    id: id,
    clues: clues,
    solution: solution,
    rank: rank,
    seed: 12345,
  );

  Future<void> install({
    String packId = 'season-1',
    int version = 1,
    String puzzleId = 'q1',
    Rank rank = Rank.deputy,
    List<StoredPuzzle>? puzzles,
  }) => packs.installPack(
    packId: packId,
    version: version,
    puzzles: puzzles ?? <StoredPuzzle>[puzzle(puzzleId, rank)],
  );

  group('a stored puzzle', () {
    // D-32: each puzzle carries its solution, its required-technique grade,
    // and its seed. All three, or the engine has to recompute what was already
    // decided offline.
    test('carries its clues, solution, rank, and seed', () async {
      await install();

      final puzzle = await packs.puzzleById('q1');
      expect(puzzle, isNotNull);
      expect(puzzle!.clues, clues);
      expect(puzzle.solution, solution);
      expect(puzzle.rank, Rank.deputy);
      expect(puzzle.seed, 12345);
    });

    test('is readable with no network', () async {
      // Nothing in this layer can reach the network; the assertion is that a
      // read needs nothing but the database.
      await install();
      expect(await packs.puzzleById('q1'), isNotNull);
    });

    test('belongs to a versioned pack', () async {
      await install(version: 3);
      expect(await packs.packVersion('season-1'), 3);
    });
  });

  group('selecting by rank', () {
    test('returns a puzzle of the requested rank', () async {
      await install(
        puzzles: <StoredPuzzle>[
          puzzle('easy', Rank.greenhorn),
          puzzle('hard', Rank.legend),
        ],
      );

      expect((await packs.nextUnsolved(Rank.legend))?.id, 'hard');
      expect((await packs.nextUnsolved(Rank.greenhorn))?.id, 'easy');
    });

    // Change 5 tops up on this signal. An exception would be the wrong shape
    // for a condition that happens in normal play.
    test('reports absence as a normal result, not an error', () async {
      await install(rank: Rank.greenhorn);

      await expectLater(packs.nextUnsolved(Rank.legend), completes);
      expect(await packs.nextUnsolved(Rank.legend), isNull);
    });

    test('does not return a puzzle the player already solved', () async {
      await install(puzzleId: 'q1', rank: Rank.deputy);
      expect((await packs.nextUnsolved(Rank.deputy))?.id, 'q1');

      await packs.markSolved('q1');
      expect(await packs.nextUnsolved(Rank.deputy), isNull);
    });
  });

  group('installing a newer pack version', () {
    test('preserves which puzzles the player has solved', () async {
      await install(puzzleId: 'q1');
      await packs.markSolved('q1');

      await install(version: 2, puzzleId: 'q1');

      expect(await packs.packVersion('season-1'), 2);
      expect(
        await packs.isSolved('q1'),
        isTrue,
        reason: 'a pack refresh must not undo the player\'s progress',
      );
    });

    test('an older version is not installed over a newer one', () async {
      await install(version: 5);
      await install(version: 2);
      expect(await packs.packVersion('season-1'), 5);
    });

    // Packs are immutable per version: the same version always means the same
    // content, so reinstalling it is a no-op rather than a refresh.
    test('reinstalling the same version changes nothing', () async {
      await install(
        version: 2,
        puzzles: <StoredPuzzle>[puzzle('a', Rank.deputy)],
      );
      await install(
        version: 2,
        puzzles: <StoredPuzzle>[puzzle('b', Rank.deputy)],
      );

      expect(await packs.puzzleById('a'), isNotNull);
      expect(await packs.puzzleById('b'), isNull);
    });
  });

  // D-127: **killer** is reached only from a **variant node**. The kind is
  // asked for at the query, so no caller can be handed the other one by
  // forgetting to filter.
  group('selecting by rank and kind', () {
    // Opaque to this layer: it stores **cage**s, it does not read them.
    const cages = '[{"sum":3,"cells":[0,1]}]';
    StoredPuzzle killer(String id, Rank rank) => StoredPuzzle(
      id: id,
      clues: clues,
      solution: solution,
      rank: rank,
      seed: 777,
      cages: cages,
    );

    test('a killer puzzle stores its cages, and a classic one none', () async {
      await install(
        puzzles: <StoredPuzzle>[
          puzzle('c1', Rank.deputy),
          killer('k1', Rank.deputy),
        ],
      );
      expect((await packs.puzzleById('k1'))!.cages, cages);
      expect((await packs.puzzleById('c1'))!.cages, isNull);
    });

    test('classic is the default, and never returns a killer puzzle', () async {
      // The killer id sorts first, so an unfiltered query would pick it.
      await install(
        puzzles: <StoredPuzzle>[
          killer('a-killer', Rank.sheriff),
          puzzle('b-classic', Rank.sheriff),
        ],
      );
      expect((await packs.nextUnsolved(Rank.sheriff))?.id, 'b-classic');
      expect(
        (await packs.nextUnsolved(Rank.sheriff, kind: PuzzleKind.classic))?.id,
        'b-classic',
      );
    });

    test('asking for killer returns only a killer puzzle', () async {
      await install(
        puzzles: <StoredPuzzle>[
          puzzle('a-classic', Rank.sheriff),
          killer('b-killer', Rank.sheriff),
        ],
      );
      expect(
        (await packs.nextUnsolved(Rank.sheriff, kind: PuzzleKind.killer))?.id,
        'b-killer',
      );
    });

    test('no killer left is an absence, never a classic stand-in', () async {
      await install(
        puzzles: <StoredPuzzle>[
          puzzle('c1', Rank.sheriff),
          killer('k1', Rank.sheriff),
        ],
      );
      await packs.markSolved('k1');
      expect(
        await packs.nextUnsolved(Rank.sheriff, kind: PuzzleKind.killer),
        isNull,
      );
      expect((await packs.nextUnsolved(Rank.sheriff))?.id, 'c1');
    });

    test(
      'the daily\'s seeded choice is classic only, for every seed',
      () async {
        await install(
          puzzles: <StoredPuzzle>[
            killer('a-killer', Rank.marshal),
            puzzle('b-classic', Rank.marshal),
            killer('c-killer', Rank.marshal),
          ],
        );
        for (var seed = 0; seed < 12; seed++) {
          final chosen = await packs.puzzleByRankAndSeed(Rank.marshal, seed);
          expect(chosen?.id, 'b-classic', reason: 'seed $seed');
        }
      },
    );

    test('a rank holding only killer puzzles has no daily board', () async {
      await install(puzzles: <StoredPuzzle>[killer('k1', Rank.legend)]);
      expect(await packs.puzzleByRankAndSeed(Rank.legend, 3), isNull);
    });
  });
}
