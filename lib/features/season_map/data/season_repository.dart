import 'package:drift/drift.dart';

import '../../persistence/data/app_database.dart';
import '../domain/trail_progress.dart';

/// Reads and writes where the player stands on the **trail**.
///
/// This is `data/`, not `domain/` — it speaks Drift. Everything it has to
/// *decide* is in `domain/trail_progress.dart`, which carries no import heavier
/// than the **season** model.
///
/// **There is no `uncomplete`.** The class offers no operation that withdraws a
/// completion, for the same reason [TrailProgress] offers none: D-20 and
/// constraint 1 are safer enforced by the absence of the operation than by
/// every caller remembering not to reach for it.
final class SeasonRepository {
  const SeasonRepository(this._db);

  final AppDatabase _db;

  /// Which **season** the player is walking, or null if they have walked none.
  ///
  /// Null is a starting position, not an error: a fresh install and an upgraded
  /// one both read null and both begin at **node** 1 of whichever **season** is
  /// in force.
  Future<String?> currentSeasonId() async {
    final row = await (_db.select(
      _db.seasonStates,
    )..where((s) => s.id.equals(SeasonStates.singletonId))).getSingleOrNull();
    return row?.seasonId;
  }

  /// Record that [seasonId] is the **season** in force.
  ///
  /// Idempotent: calling it for the **season** already in force leaves
  /// `startedAt` alone. That matters because this runs on every launch, and a
  /// stamp that moved each time would make "when did this player start the
  /// season" unanswerable.
  Future<void> enterSeason(String seasonId) async {
    final existing = await currentSeasonId();
    if (existing == seasonId) return;

    await _db
        .into(_db.seasonStates)
        .insertOnConflictUpdate(
          SeasonStatesCompanion.insert(
            id: const Value(SeasonStates.singletonId),
            seasonId: seasonId,
            startedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  /// What the player has completed in [seasonId].
  ///
  /// A **season** with no rows reads as [TrailProgress.fresh] — **node** 1
  /// current — rather than as missing data. That is the whole reason rotation
  /// needs no deletion: a successor's id simply has no rows yet.
  Future<TrailProgress> progressFor(String seasonId) async {
    final rows = await (_db.select(
      _db.completedNodes,
    )..where((n) => n.seasonId.equals(seasonId))).get();
    return TrailProgress(
      completed: <int>{for (final row in rows) row.position},
    );
  }

  /// Record that a **node** was completed.
  ///
  /// Written at the moment of completion, never on a timer (constraint 9).
  /// `insertOnConflictUpdate` rather than plain insert so completing a
  /// **node** twice costs a write and changes nothing — the same idempotence
  /// the **solve record** has, and needed for the same reason: a second
  /// completion of one board must not be worth a second **node**.
  Future<void> completeNode({required String seasonId, required int position}) {
    return _db
        .into(_db.completedNodes)
        .insertOnConflictUpdate(
          CompletedNodesCompanion.insert(
            seasonId: seasonId,
            position: position,
            completedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  /// How many times this **boss node** has been attempted.
  ///
  /// Zero for one never attempted. **Nothing reads this to decide whether an
  /// attempt may happen** — D-22 gives a **boss node** unlimited free retries,
  /// and this count exists for `add-trophy-cabinet`'s statistics and for the
  /// player's own interest.
  Future<int> bossAttempts({
    required String seasonId,
    required int position,
  }) async {
    final row =
        await (_db.select(_db.bossAttempts)..where(
              (b) => b.seasonId.equals(seasonId) & b.position.equals(position),
            ))
            .getSingleOrNull();
    return row?.attempts ?? 0;
  }

  /// Count one more attempt at a **boss node**.
  Future<void> recordBossAttempt({
    required String seasonId,
    required int position,
  }) async {
    final current = await bossAttempts(seasonId: seasonId, position: position);
    await _db
        .into(_db.bossAttempts)
        .insertOnConflictUpdate(
          BossAttemptsCompanion.insert(
            seasonId: seasonId,
            position: position,
            attempts: Value(current + 1),
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }
}
