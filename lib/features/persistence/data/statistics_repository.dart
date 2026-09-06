import 'package:drift/drift.dart';

import 'app_database.dart';

/// Lifetime and per-technique counters.
///
/// These are the permanent progression layer (D-17). A season rotating out must
/// never touch them — that permanence is what makes rotation feel like a fresh
/// start rather than a loss.
class StatisticsRepository {
  const StatisticsRepository(this._db);

  final AppDatabase _db;

  /// Record a finished puzzle.
  ///
  /// One transaction, so a crash between the lifetime counter and the technique
  /// counters cannot leave them disagreeing about the same puzzle.
  Future<void> recordSolve({
    required Set<Technique> techniquesRequired,
    required Duration timeTaken,
    required bool wasPerfect,
  }) {
    return _db.transaction(() async {
      final current = await lifetime();
      await _db
          .into(_db.lifetimeStats)
          .insertOnConflictUpdate(
            LifetimeStatsCompanion.insert(
              id: const Value(LifetimeStats.singletonId),
              puzzlesSolved: Value(current.puzzlesSolved + 1),
              perfectSolves: Value(
                current.perfectSolves + (wasPerfect ? 1 : 0),
              ),
              totalPlayMs: Value(
                current.totalPlayMs + timeTaken.inMilliseconds,
              ),
              updatedAt: Value(DateTime.now()),
              pendingUpload: const Value(true),
            ),
          );

      for (final technique in techniquesRequired) {
        final existing = await (_db.select(
          _db.techniqueStats,
        )..where((t) => t.technique.equalsValue(technique))).getSingleOrNull();
        await _db
            .into(_db.techniqueStats)
            .insertOnConflictUpdate(
              TechniqueStatsCompanion.insert(
                technique: technique,
                puzzlesRequiring: Value((existing?.puzzlesRequiring ?? 0) + 1),
                updatedAt: Value(DateTime.now()),
                pendingUpload: const Value(true),
              ),
            );
      }
    });
  }

  Future<LifetimeStat> lifetime() async {
    final row = await (_db.select(
      _db.lifetimeStats,
    )..where((s) => s.id.equals(LifetimeStats.singletonId))).getSingleOrNull();
    return row ??
        LifetimeStat(
          id: LifetimeStats.singletonId,
          puzzlesSolved: 0,
          perfectSolves: 0,
          totalPlayMs: 0,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          pendingUpload: false,
        );
  }

  Future<int> countFor(Technique technique) async {
    final row = await (_db.select(
      _db.techniqueStats,
    )..where((t) => t.technique.equalsValue(technique))).getSingleOrNull();
    return row?.puzzlesRequiring ?? 0;
  }

  Future<Map<Technique, int>> allTechniqueCounts() async {
    final rows = await _db.select(_db.techniqueStats).get();
    return <Technique, int>{
      for (final row in rows) row.technique: row.puzzlesRequiring,
    };
  }
}
