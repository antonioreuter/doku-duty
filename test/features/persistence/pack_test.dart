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
}
