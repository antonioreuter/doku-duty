import 'package:drift/drift.dart';

import '../../persistence/data/app_database.dart';
import '../domain/award.dart';

/// Reads and mints **trophy**s.
///
/// **There is no `remove` and no `unmint`.** The class offers no operation that
/// withdraws a **trophy**, for the reason `SeasonRepository` gives about
/// completions and `DailyRepository` gives about days: constraint 1 is safer
/// enforced by the operation not existing than by every caller remembering not
/// to reach for it.
final class TrophyRepository {
  const TrophyRepository(this._db);

  final AppDatabase _db;

  /// Mints [award], or does nothing if it is already minted.
  ///
  /// **Idempotent by insertion, not by checking first.** `insertOrIgnore`
  /// leaves the existing row alone, which is what keeps the original
  /// `earnedAt` — a **trophy** records when something *first* happened, and a
  /// **cabinet** that restamps its own history on a re-earn is worth less than
  /// one that does not (D-124).
  ///
  /// Issues one statement and awaits it, so a caller can wrap this in the same
  /// transaction as the event that earned it and know the two commit together
  /// or not at all (constraint 9).
  Future<void> mint({required Award award, required String? seasonName}) {
    return _db
        .into(_db.trophies)
        .insert(
          TrophiesCompanion.insert(
            awardId: award.id,
            name: award.name,
            seasonId: Value(award.seasonId),
            seasonName: Value(seasonName),
            earnedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
          onConflict: DoNothing(),
        );
  }

  /// Every **trophy**, newest first.
  Future<List<Trophy>> earned() {
    return (_db.select(_db.trophies)
          ..orderBy(<OrderingTerm Function($TrophiesTable)>[
            (t) =>
                OrderingTerm(expression: t.earnedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<bool> hasEarned(String awardId) async {
    final row = await (_db.select(
      _db.trophies,
    )..where((t) => t.awardId.equals(awardId))).getSingleOrNull();
    return row != null;
  }

  /// The ids already minted, for deciding which **award**s are **unfiled**.
  Future<Set<String>> earnedIds() async {
    final rows = await _db.select(_db.trophies).get();
    return <String>{for (final row in rows) row.awardId};
  }
}
