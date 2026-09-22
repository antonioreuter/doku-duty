import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/streak_freeze.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Constraint 9 for the **calendar**, against a real database.
///
/// `no_deferred_writes_test.dart` asserts the *shape* of the code — that
/// nothing sits between the change and the write. This asserts the write
/// actually lands, and lands before anything a player would see. The two are
/// different failures: a debounce that never fires and a statement that was
/// never issued both lose the day, and only one of them is visible in a diff.
void main() {
  late AppDatabase db;
  late DailyRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DailyRepository(db);
  });
  tearDown(() => db.close());

  /// Reopening against the same file is how an app kill is simulated: anything
  /// still in memory is gone, and only what reached sqlite comes back.
  Future<DailyRepository> afterRestart() async {
    // The in-memory database is the same handle, so the honest simulation is a
    // fresh repository reading rows that were already committed — no cache, no
    // in-flight state.
    return DailyRepository(db);
  }

  group('a completed day survives', () {
    test('it is readable the instant the write returns', () async {
      final day = DatedDay(date: DailyDate(2026, 3, 20), isVerified: true);

      await repository.completeDay(day);

      // Awaited, not scheduled. If this ever needs a pump, a timer has been
      // introduced and constraint 9 is broken.
      expect(await repository.wasCompleted(DailyDate(2026, 3, 20)), isTrue);
    });

    test('it is still there after a restart', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 20), isVerified: true),
      );

      final reopened = await afterRestart();
      final calendar = await reopened.calendar();

      expect(calendar.wasCompleted(DailyDate(2026, 3, 20)), isTrue);
      expect(calendar.streakOn(DailyDate(2026, 3, 20)), 1);
    });

    test('a run of days rebuilds the streak from storage alone', () async {
      for (var day = 14; day <= 20; day++) {
        await repository.completeDay(
          DatedDay(date: DailyDate(2026, 3, day), isVerified: true),
        );
      }

      final calendar = await (await afterRestart()).calendar();

      // Seven rows in, seven days out, and the number derived rather than
      // stored — nothing was written down that could disagree with them.
      expect(calendar.streakOn(DailyDate(2026, 3, 20)), 7);
    });

    test('completing the same day twice changes nothing', () async {
      final day = DatedDay(date: DailyDate(2026, 3, 20), isVerified: true);
      await repository.completeDay(day);
      await repository.completeDay(day);

      final calendar = await repository.calendar();
      expect(calendar.completed, hasLength(1));
    });
  });

  group('an unfinished puzzle marks nothing', () {
    test('a day is not on the calendar until it is completed', () async {
      // The app killed mid-puzzle. Nothing was completed, so nothing is
      // recorded — and crucially the **streak** is untouched rather than
      // broken, because an abandoned attempt is not a missed day.
      final calendar = await repository.calendar();

      expect(calendar.completed, isEmpty);
      expect(calendar.streakOn(DailyDate(2026, 3, 20)), 0);
    });

    test('yesterday\'s streak survives an abandoned attempt today', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 19), isVerified: true),
      );

      // Today was opened and abandoned. The run stands until today is missed
      // outright, which is what stops a player from appearing to lose a streak
      // they still have.
      final calendar = await repository.calendar();
      expect(calendar.streakOn(DailyDate(2026, 3, 20)), 1);
    });
  });

  group('the freeze ledger survives', () {
    test('an untouched ledger means one is held', () async {
      // Including the upgrade case: no row at all, so nothing has been spent,
      // so the player holds one from the moment they open the app (D-117).
      final ledger = await repository.ledger(DailyDate(2026, 3, 20));

      expect(ledger.lastSpent, isNull);
      expect(ledger.isHeld, isTrue);
    });

    test('a spend is written and read back', () async {
      var ledger = await repository.ledger(DailyDate(2026, 3, 20));
      ledger = ledger.spendOn(DailyDate(2026, 3, 20));
      await repository.saveLedger(ledger);

      final reopened = await (await afterRestart()).ledger(
        DailyDate(2026, 3, 21),
      );

      expect(reopened.lastSpent, DailyDate(2026, 3, 20));
      expect(reopened.isHeld, isFalse);
    });

    test('a spend and the day it bridged are both durable', () async {
      // The pairing that matters. A freeze recorded as spent without the day
      // it covered breaks the very **streak** it was spent to protect — the
      // precise failure D-20 exists to prevent.
      await repository.recordFrozen(<DailyDate>[DailyDate(2026, 3, 19)]);
      await repository.saveLedger(
        FreezeLedger(
          lastSpent: DailyDate(2026, 3, 19),
          asOf: DailyDate(2026, 3, 19),
        ),
      );
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 18), isVerified: true),
      );
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 20), isVerified: true),
      );

      final reopened = await afterRestart();
      final calendar = await reopened.calendar();

      expect(calendar.wasFrozen(DailyDate(2026, 3, 19)), isTrue);
      expect(calendar.streakOn(DailyDate(2026, 3, 20)), 3);
      expect((await reopened.ledger(DailyDate(2026, 3, 20))).isHeld, isFalse);
    });

    test(
      'a frozen day is not recorded as one the player turned up for',
      () async {
        await repository.recordFrozen(<DailyDate>[DailyDate(2026, 3, 19)]);

        final calendar = await repository.calendar();

        expect(calendar.wasCompleted(DailyDate(2026, 3, 19)), isFalse);
        expect(calendar.wasFrozen(DailyDate(2026, 3, 19)), isTrue);
      },
    );
  });

  group('the verified flag is carried through storage', () {
    test('an offline day comes back marked', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 20), isVerified: false),
      );

      final rows = await db.select(db.completedDays).get();
      expect(rows.single.isVerified, isFalse);
    });

    test('a verified day comes back verified', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 20), isVerified: true),
      );

      final rows = await db.select(db.completedDays).get();
      expect(rows.single.isVerified, isTrue);
    });
  });
}
