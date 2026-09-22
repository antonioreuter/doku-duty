import 'package:drift/drift.dart';

import '../../persistence/data/app_database.dart';
import '../domain/daily_calendar.dart';
import '../domain/daily_date.dart';
import '../domain/streak_freeze.dart';

/// Reads and writes the **calendar** and the **streak freeze** ledger.
///
/// This is `data/`, not `domain/` — it speaks Drift. Everything it has to
/// *decide* lives in `domain/`, which takes no Flutter or Drift import: the
/// **streak** is computed by [DailyCalendar], the freeze rules by
/// [FreezeLedger], and this class only moves rows.
///
/// **There is no `uncomplete` and no `setStreak`.** The first is absent for the
/// reason `SeasonRepository` gives — constraint 1 is safer enforced by the
/// operation not existing than by every caller remembering not to reach for it.
/// The second is absent because the **streak** is not stored at all: it is read
/// from the days, so there is nothing to set (`docs/TECH_STACK.md` §3b).
final class DailyRepository {
  const DailyRepository(this._db);

  final AppDatabase _db;

  /// Every recorded day, as the **calendar**.
  Future<DailyCalendar> calendar() async {
    final rows = await _db.select(_db.completedDays).get();
    return DailyCalendar(
      completed: <DailyDate>{
        for (final row in rows)
          if (!row.wasFrozen) DailyDate.parse(row.day),
      },
      frozen: <DailyDate>{
        for (final row in rows)
          if (row.wasFrozen) DailyDate.parse(row.day),
      },
    );
  }

  /// Records a completed day.
  ///
  /// **One statement, issued the moment the day is completed** — never batched
  /// with the celebration, never deferred to a timer (constraint 9). A day lost
  /// to an app kill is a broken **streak**, and a **streak** is the one number
  /// in this product a player may have held for a year.
  Future<void> completeDay(DatedDay day) {
    return _db
        .into(_db.completedDays)
        .insertOnConflictUpdate(
          CompletedDaysCompanion.insert(
            day: day.date.toIso(),
            isVerified: Value(day.isVerified),
            wasFrozen: const Value(false),
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  /// Records that a **streak freeze** bridged these days.
  ///
  /// Written the same way and for the same reason: a freeze that was spent but
  /// not recorded would break the **streak** it was spent to protect, which is
  /// the precise failure D-20 exists to prevent.
  Future<void> recordFrozen(Iterable<DailyDate> days) async {
    for (final day in days) {
      await _db
          .into(_db.completedDays)
          .insertOnConflictUpdate(
            CompletedDaysCompanion.insert(
              day: day.toIso(),
              isVerified: const Value(false),
              wasFrozen: const Value(true),
              updatedAt: Value(DateTime.now()),
              pendingUpload: const Value(true),
            ),
          );
    }
  }

  /// The **streak freeze** ledger as it stands on [asOf].
  ///
  /// An absent row means none has ever been spent, which by D-117 means the
  /// player holds one — including on the day they upgrade into this version.
  Future<FreezeLedger> ledger(DailyDate asOf) async {
    final row =
        await (_db.select(_db.streakFreezeLedgers)
              ..where((f) => f.id.equals(StreakFreezeLedgers.singletonId)))
            .getSingleOrNull();

    final lastSpent = row?.lastSpentDay;
    return FreezeLedger(
      lastSpent: lastSpent == null ? null : DailyDate.parse(lastSpent),
      asOf: asOf,
    );
  }

  Future<void> saveLedger(FreezeLedger ledger) {
    return _db
        .into(_db.streakFreezeLedgers)
        .insertOnConflictUpdate(
          StreakFreezeLedgersCompanion.insert(
            id: Value(StreakFreezeLedgers.singletonId),
            lastSpentDay: Value(ledger.lastSpent?.toIso()),
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  /// Whether today has already been completed, so the board is not offered a
  /// second time as though it were unplayed.
  Future<bool> wasCompleted(DailyDate date) async {
    final row = await (_db.select(
      _db.completedDays,
    )..where((d) => d.day.equals(date.toIso()))).getSingleOrNull();
    return row != null;
  }
}
