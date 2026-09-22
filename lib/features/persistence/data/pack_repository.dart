import 'package:drift/drift.dart';

import 'app_database.dart';

/// A puzzle as callers hand it in, before it is a database row.
class StoredPuzzle {
  const StoredPuzzle({
    required this.id,
    required this.clues,
    required this.solution,
    required this.rank,
    required this.seed,
  });

  final String id;
  final String clues;
  final String solution;
  final Rank rank;
  final int seed;
}

/// Reads puzzles and installs packs.
///
/// This layer stores a graded puzzle; it cannot produce or verify one. The
/// solver, the generator, and the technique grader are `add-puzzle-engine`.
class PackRepository {
  const PackRepository(this._db);

  final AppDatabase _db;

  /// Install or refresh a pack.
  ///
  /// Refusing to go backwards is deliberate: packs arrive from a CDN, and an
  /// out-of-order or cached response must not downgrade what is already
  /// installed.
  Future<void> installPack({
    required String packId,
    required int version,
    required List<StoredPuzzle> puzzles,
  }) {
    return _db.transaction(() async {
      final existing = await packVersion(packId);
      if (existing != null && existing >= version) return;

      await _db
          .into(_db.packs)
          .insertOnConflictUpdate(
            PacksCompanion.insert(packId: packId, version: version),
          );

      // Bulk content, not player state — a batch is right here, and it is the
      // one place in this layer where deferring a write costs nothing, because
      // nothing a player did is waiting on it.
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.puzzles, <PuzzlesCompanion>[
          for (final puzzle in puzzles)
            PuzzlesCompanion.insert(
              id: puzzle.id,
              packId: packId,
              clues: puzzle.clues,
              solution: puzzle.solution,
              rank: puzzle.rank,
              seed: puzzle.seed,
            ),
        ]);
      });
    });
  }

  Future<int?> packVersion(String packId) async {
    final row = await (_db.select(
      _db.packs,
    )..where((p) => p.packId.equals(packId))).getSingleOrNull();
    return row?.version;
  }

  Future<Puzzle?> puzzleById(String id) => (_db.select(
    _db.puzzles,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  /// The next puzzle of [rank] the player has not solved, or null.
  ///
  /// Null is a normal answer, not a failure: running out is how a top-up is
  /// triggered, and an exception would make an ordinary condition look like a
  /// fault.
  Future<Puzzle?> nextUnsolved(Rank rank) {
    final solved = _db.selectOnly(_db.solvedPuzzles)
      ..addColumns(<Expression<Object>>[_db.solvedPuzzles.puzzleId]);

    return (_db.select(_db.puzzles)
          ..where((p) => p.rank.equalsValue(rank) & p.id.isNotInQuery(solved))
          ..limit(1))
        .getSingleOrNull();
  }

  /// A puzzle of [rank] chosen by [seed], deterministically.
  ///
  /// **Deliberately blind to what the player has solved.** [nextUnsolved] is
  /// right for **free play**, where the point is to serve something new, and
  /// wrong for the **daily challenge**, where the point is that everybody with
  /// the same **pack** gets the same board — and what each player has solved is
  /// the one thing guaranteed to differ between them (D-115).
  ///
  /// Ordered by id so the choice does not depend on insertion order, which a
  /// **pack** top-up changes.
  Future<Puzzle?> puzzleByRankAndSeed(Rank rank, int seed) async {
    final rows =
        await (_db.select(_db.puzzles)
              ..where((p) => p.rank.equalsValue(rank))
              ..orderBy(<OrderingTerm Function($PuzzlesTable)>[
                (p) => OrderingTerm(expression: p.id),
              ]))
            .get();
    if (rows.isEmpty) return null;
    return rows[seed.abs() % rows.length];
  }

  Future<void> markSolved(String puzzleId) {
    return _db
        .into(_db.solvedPuzzles)
        .insertOnConflictUpdate(
          SolvedPuzzlesCompanion.insert(
            puzzleId: puzzleId,
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  Future<bool> isSolved(String puzzleId) async {
    final row = await (_db.select(
      _db.solvedPuzzles,
    )..where((s) => s.puzzleId.equals(puzzleId))).getSingleOrNull();
    return row != null;
  }
}
