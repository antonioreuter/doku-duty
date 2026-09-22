import 'daily_date.dart';

/// What applying the ledger across an absence did.
class FreezeOutcome {
  const FreezeOutcome({
    required this.ledger,
    required this.frozen,
    required this.streakSurvives,
  });

  /// The ledger after any spend.
  final FreezeLedger ledger;

  /// The days a **streak freeze** covered. At most one.
  final Set<DailyDate> frozen;

  /// Whether the run continued through the absence.
  final bool streakSurvives;
}

/// The **streak freeze** ledger (D-20, D-117).
///
/// One held at a time, regenerating every 7 days, never banked, and spent
/// without the player being asked. There is deliberately no method on this
/// type that offers a freeze to a player for a decision: being asked "use your
/// freeze?" turns a safety net into a choice under loss aversion, which is the
/// shape of the mechanic this product refuses.
///
/// Held state is derived from when one was last spent rather than stored as a
/// count, for the same reason the **streak** is derived from the **calendar**:
/// a count can drift, a date cannot.
class FreezeLedger {
  const FreezeLedger({required this.lastSpent, required this.asOf});

  /// A player who has never spent one holds one immediately.
  ///
  /// Not "earn it over the first week": a player whose second day goes wrong is
  /// exactly who D-20 is written about, and making them wait would put the gap
  /// precisely where the habit is most fragile.
  const FreezeLedger.fresh({required DailyDate on})
    : lastSpent = null,
      asOf = on;

  /// When the last **streak freeze** was consumed, or null if never.
  final DailyDate? lastSpent;

  /// The day this ledger is being read on.
  final DailyDate asOf;

  /// Days between a spend and the next grant.
  static const int regenerationDays = 7;

  /// How many are held: one or none, never more (D-117).
  int get held {
    final spent = lastSpent;
    if (spent == null) return 1;
    return spent.daysUntil(asOf) >= regenerationDays ? 1 : 0;
  }

  bool get isHeld => held > 0;

  /// The same ledger read on a different day.
  FreezeLedger on(DailyDate date) =>
      FreezeLedger(lastSpent: lastSpent, asOf: date);

  /// Consumes the held freeze. A no-op when none is held.
  FreezeLedger spendOn(DailyDate date) {
    if (!isHeld) return this;
    return FreezeLedger(lastSpent: date, asOf: date);
  }

  /// Applies the ledger to a run of missed days.
  ///
  /// **One day only.** A freeze covers the first missed day and no other, so an
  /// absence of two days ends the **streak** whatever is held — which is what
  /// keeps the counter meaning "consecutive days" rather than "days minus
  /// credits" (D-117).
  FreezeOutcome applyTo({required List<DailyDate> missed}) {
    if (missed.isEmpty) {
      return FreezeOutcome(
        ledger: this,
        frozen: const <DailyDate>{},
        streakSurvives: true,
      );
    }

    if (!isHeld) {
      return FreezeOutcome(
        ledger: this,
        frozen: const <DailyDate>{},
        streakSurvives: false,
      );
    }

    final first = missed.first;
    return FreezeOutcome(
      ledger: spendOn(first),
      frozen: <DailyDate>{first},
      streakSurvives: missed.length == 1,
    );
  }
}
