import 'package:drift/drift.dart';

import '../../mistake_model/domain/attempt.dart';
import '../../persistence/data/app_database.dart';
import '../../persistence/data/pack_repository.dart';
import '../../persistence/data/statistics_repository.dart';
import '../domain/player_rank.dart';

/// Writes the **solve record**, and answers what it implies.
///
/// One seam for both, because the two are the same fact read in two
/// directions: a **rank** and a **technique unlock** are *derived* from the
/// records rather than stored beside them (D-102, D-104), so a second class
/// holding the reads would only be a place for a cached answer to appear.
///
/// This is `data/`, not `domain/` — it speaks Drift. The rule it defers to for
/// anything it has to *decide* is in `domain/player_rank.dart`, which carries
/// no import heavier than the **rank** enum.
final class ProgressionRepository {
  ProgressionRepository(this._db)
    : _packs = PackRepository(_db),
      _stats = StatisticsRepository(_db);

  final AppDatabase _db;
  final PackRepository _packs;
  final StatisticsRepository _stats;

  /// Record one completed puzzle.
  ///
  /// Every part in a single transaction, so none of them can survive without
  /// the others (constraint 9). `markSolved` and `recordSolve` each open their
  /// own transaction when called directly; drift nests them into this one, so
  /// a failure anywhere rolls the whole record back rather than leaving the
  /// lifetime total standing over a puzzle the picker would hand back.
  /// [alsoInTransaction] runs inside the same transaction, before anything
  /// else is written.
  ///
  /// It exists for `season-map`: a **node** completion and the **solve record**
  /// it came from must be one write, so that a failure leaves neither and the
  /// **node** still reads as the **current node**. Passed in rather than
  /// imported, because the dependency runs the other way — `season-map` reads
  /// **solve record**s, and this layer has no business knowing what a **node**
  /// is.
  ///
  /// It runs *before* the already-solved guard below, and deliberately. The two
  /// are different facts: a **node** is completed by the player finishing it,
  /// and a puzzle carries a **solve record** once ever. A replayed board must
  /// still complete the **node** it was opened from, and returning early would
  /// silently leave that **node** current forever.
  Future<void> record({
    required String puzzleId,
    required Set<Technique> techniquesRequired,
    required Duration timeTaken,
    required Attempt attempt,
    Future<void> Function()? alsoInTransaction,
  }) {
    return _db.transaction(() async {
      await alsoInTransaction?.call();

      // Checked first, and it is not defensive noise: `solvedPuzzles` holds a
      // bare id with no foreign key, so an unknown puzzle would be marked
      // solved without complaint and the counters would rise behind it.
      final puzzle = await _packs.puzzleById(puzzleId);
      if (puzzle == null) {
        throw StateError(
          'no puzzle "$puzzleId" to record a solve against — the pack does not '
          'hold it, so nothing about this solve can be trusted',
        );
      }

      // A puzzle already holding a **solve record** contributes nothing more.
      // `markSolved` upserts and is safe to repeat, but `recordSolve`
      // increments unconditionally — so without this the player who finishes a
      // board, leaves, resumes it and finishes it again raises every counter a
      // second time off one puzzle. The first record stands: a later, worse
      // run must not take away the perfect solve the first one earned.
      if (await _packs.isSolved(puzzleId)) return;

      await _stats.recordSolve(
        techniquesRequired: techniquesRequired,
        timeTaken: timeTaken,
        attempt: attempt,
      );
      await _packs.markSolved(puzzleId);
    });
  }

  /// The player's **rank**: the hardest **rank** they have solved (D-102).
  ///
  /// Derived on every read rather than stored. The join is over solved puzzles
  /// only, and it asks for the distinct **rank**s rather than the rows, so the
  /// query does not grow with how much the player has played.
  Future<Rank> playerRank() async => PlayerRank.from(await solvedRanks());

  /// The distinct **rank**s the player has completed a puzzle at.
  Future<Set<Rank>> solvedRanks() async {
    final query = _db.selectOnly(_db.puzzles, distinct: true)
      ..addColumns(<Expression<Object>>[_db.puzzles.rank])
      ..join(<Join<HasResultSet, dynamic>>[
        innerJoin(
          _db.solvedPuzzles,
          _db.solvedPuzzles.puzzleId.equalsExp(_db.puzzles.id),
        ),
      ]);

    final rows = await query.get();
    return <Rank>{
      for (final row in rows) row.readWithConverter(_db.puzzles.rank)!,
    };
  }

  /// Every technique the player has met — a **technique unlock** each (D-104).
  ///
  /// Read from the counters and nowhere else. A stored set of unlocked
  /// techniques would be a second answer to this question, and the only thing
  /// two answers can do over time is disagree, so there is deliberately no
  /// second answer to keep in step.
  Future<Set<Technique>> unlockedTechniques() async {
    final counts = await _stats.allTechniqueCounts();
    return <Technique>{
      for (final entry in counts.entries)
        if (entry.value > 0) entry.key,
    };
  }
}
