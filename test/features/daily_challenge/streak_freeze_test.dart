import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/streak_freeze.dart';
import 'package:flutter_test/flutter_test.dart';

/// The **streak freeze**: granted weekly, never banked, spent without asking.
///
/// D-20 settled that it applies itself, because the moment a freeze is needed
/// is the moment the player was not opening the app. D-117 settled the accrual.
/// Both halves are here, and the negative cases are the ones that matter —
/// "does not accumulate" and "covers one day only" are what stop the **streak**
/// from quietly becoming a number nobody can compute.
void main() {
  group('accrual', () {
    test('a new player holds one straight away', () {
      // Nothing is earned by waiting a week before the safety net exists. A
      // player whose second day goes wrong is exactly who D-20 is about.
      final ledger = FreezeLedger.fresh(on: DailyDate(2026, 3, 1));
      expect(ledger.isHeld, isTrue);
    });

    test('a spent freeze returns after seven days', () {
      var ledger = FreezeLedger.fresh(on: DailyDate(2026, 3, 1));
      ledger = ledger.spendOn(DailyDate(2026, 3, 2));
      expect(ledger.isHeld, isFalse);

      expect(
        ledger.on(DailyDate(2026, 3, 8)).isHeld,
        isFalse,
        reason: 'six days after spending is too early',
      );
      expect(
        ledger.on(DailyDate(2026, 3, 9)).isHeld,
        isTrue,
        reason: 'seven days after spending it is back',
      );
    });

    test('holding one for another seven days does not bank a second', () {
      final ledger = FreezeLedger.fresh(on: DailyDate(2026, 3, 1));
      final later = ledger.on(DailyDate(2026, 3, 30));

      expect(later.isHeld, isTrue);
      expect(later.held, 1, reason: 'freezes accumulated, which D-117 forbids');
    });

    test('a long absence does not accrue a pile', () {
      // The failure D-117 exists to prevent: come back after a year and the
      // streak survives arbitrarily many missed days.
      var ledger = FreezeLedger.fresh(on: DailyDate(2026, 3, 1));
      ledger = ledger.on(DailyDate(2027, 3, 1));
      expect(ledger.held, 1);
    });
  });

  group('consumption', () {
    test('it is spent on a missed day without being offered', () {
      // There is no "use your freeze?" entry point on this type, by design.
      // Being asked turns a safety net into a decision under loss aversion,
      // which is the mechanic this game refuses.
      final ledger = FreezeLedger.fresh(on: DailyDate(2026, 3, 1));
      final after = ledger.spendOn(DailyDate(2026, 3, 2));

      expect(after.isHeld, isFalse);
      expect(after.lastSpent, DailyDate(2026, 3, 2));
    });

    test('spending when none is held changes nothing', () {
      var ledger = FreezeLedger.fresh(on: DailyDate(2026, 3, 1));
      ledger = ledger.spendOn(DailyDate(2026, 3, 2));
      final again = ledger.spendOn(DailyDate(2026, 3, 3));

      expect(again.isHeld, isFalse);
      expect(
        again.lastSpent,
        DailyDate(2026, 3, 2),
        reason: 'a freeze that was not held was somehow spent',
      );
    });
  });

  group('applying it across an absence', () {
    test('one missed day with a freeze keeps the streak', () {
      final outcome = FreezeLedger.fresh(
        on: DailyDate(2026, 3, 1),
      ).applyTo(missed: <DailyDate>[DailyDate(2026, 3, 2)]);

      expect(outcome.frozen, <DailyDate>{DailyDate(2026, 3, 2)});
      expect(outcome.streakSurvives, isTrue);
    });

    test('one missed day without a freeze breaks it', () {
      var ledger = FreezeLedger.fresh(on: DailyDate(2026, 3, 1));
      ledger = ledger.spendOn(DailyDate(2026, 3, 2));

      final outcome = ledger.applyTo(
        missed: <DailyDate>[DailyDate(2026, 3, 3)],
      );

      expect(outcome.frozen, isEmpty);
      expect(outcome.streakSurvives, isFalse);
    });

    test('two consecutive missed days break it even holding a freeze', () {
      final outcome = FreezeLedger.fresh(on: DailyDate(2026, 3, 1)).applyTo(
        missed: <DailyDate>[DailyDate(2026, 3, 2), DailyDate(2026, 3, 3)],
      );

      expect(
        outcome.frozen.length,
        1,
        reason: 'a single freeze covered more than one day',
      );
      expect(outcome.streakSurvives, isFalse);
    });

    test('missing nothing spends nothing', () {
      final outcome = FreezeLedger.fresh(
        on: DailyDate(2026, 3, 1),
      ).applyTo(missed: <DailyDate>[]);

      expect(outcome.frozen, isEmpty);
      expect(outcome.streakSurvives, isTrue);
      expect(outcome.ledger.isHeld, isTrue);
    });
  });

  group('what a missed day never costs', () {
    test('breaking a streak is the whole of the consequence', () {
      // Constraint 1 and D-20. The type has no route to season progress, to a
      // rank, or to a trophy — there is nothing else here to take away, and
      // that is the point rather than an omission.
      final outcome = FreezeLedger.fresh(on: DailyDate(2026, 3, 1)).applyTo(
        missed: <DailyDate>[DailyDate(2026, 3, 2), DailyDate(2026, 3, 3)],
      );

      expect(outcome.streakSurvives, isFalse);
      expect(outcome.ledger.held, isNonNegative);
    });
  });
}
