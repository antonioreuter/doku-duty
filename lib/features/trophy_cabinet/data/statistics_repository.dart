import '../../persistence/data/app_database.dart';

/// What the **cabinet** says the player has done.
class CabinetStatistics {
  const CabinetStatistics({
    required this.puzzlesSolved,
    required this.perfectSolves,
    required this.totalPlayTime,
    required this.byTechnique,
  });

  const CabinetStatistics.empty()
    : puzzlesSolved = 0,
      perfectSolves = 0,
      totalPlayTime = Duration.zero,
      byTechnique = const <Technique, int>{};

  final int puzzlesSolved;
  final int perfectSolves;
  final Duration totalPlayTime;

  /// Puzzles that required each technique. Absent means zero.
  final Map<Technique, int> byTechnique;

  int countFor(Technique technique) => byTechnique[technique] ?? 0;
}

/// Reads the counters. **It does not keep any.**
///
/// The **cabinet** is the first screen to display these, and the temptation
/// when building a statistics screen is to have it total things up itself. It
/// must not: `lifetime_stats` and `technique_stats` are written by
/// `rank_progression` at the moment of a **solve record**, and a second count
/// here could drift from them with nothing able to tell which was right.
///
/// So there is no `record`, no `increment`, and no write of any kind on this
/// class. It reads two tables and stops.
final class StatisticsRepository {
  const StatisticsRepository(this._db);

  final AppDatabase _db;

  Future<CabinetStatistics> read() async {
    final lifetime = await (_db.select(
      _db.lifetimeStats,
    )..where((s) => s.id.equals(LifetimeStats.singletonId))).getSingleOrNull();

    final techniques = await _db.select(_db.techniqueStats).get();

    return CabinetStatistics(
      // A player who has solved nothing has no row, and zero is the honest
      // answer rather than an absence to apologise for.
      puzzlesSolved: lifetime?.puzzlesSolved ?? 0,
      perfectSolves: lifetime?.perfectSolves ?? 0,
      totalPlayTime: Duration(milliseconds: lifetime?.totalPlayMs ?? 0),
      byTechnique: <Technique, int>{
        for (final row in techniques)
          if (row.puzzlesRequiring > 0) row.technique: row.puzzlesRequiring,
      },
    );
  }
}
