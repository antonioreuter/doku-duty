import 'package:drift/drift.dart';

import '../../persistence/data/app_database.dart';
import '../domain/earning.dart';

/// Records **earning**s and reads the balance they add up to.
///
/// **There is no `setBalance` and no `spend`.** The balance is not stored, so
/// there is nothing to set (D-133); spending is change 19's and will be a
/// record of its own. The class offers no way to take an **earning** back, for
/// the reason every progress repository here gives: constraint 1 is safer
/// enforced by the operation not existing.
final class StampRepository {
  const StampRepository(this._db);

  final AppDatabase _db;

  /// Records [earnings], ignoring any whose event is already recorded, and
  /// returns the ones that were new.
  ///
  /// **Idempotent by insertion, not by checking first**, so a repeated write,
  /// a retried transaction or a board completed twice pays once without any
  /// caller having to look. Each statement is awaited in turn, so a caller can
  /// wrap this in the transaction of the event that earned it and know the two
  /// commit together or not at all (constraint 9).
  Future<List<Earning>> earn(Iterable<Earning> earnings) async {
    final written = <Earning>[];
    for (final earning in earnings) {
      final row = await _db
          .into(_db.earnings)
          .insertReturningOrNull(
            EarningsCompanion.insert(
              key: earning.key,
              amount: earning.amount,
              earnedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
              pendingUpload: const Value(true),
            ),
            onConflict: DoNothing(),
          );
      if (row != null) written.add(earning);
    }
    return written;
  }

  /// The player's **stamp**s: the sum of every **earning**, read now.
  Future<int> balance() async {
    final total = _db.earnings.amount.sum();
    final query = _db.selectOnly(_db.earnings)
      ..addColumns(<Expression<Object>>[total]);
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }
}
