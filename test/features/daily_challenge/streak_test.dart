import 'package:doku_duty/features/daily_challenge/domain/daily_calendar.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:flutter_test/flutter_test.dart';

/// The **streak**, which is read and never stored.
///
/// A number that is written down can disagree with the days it claims to count,
/// and two devices holding two numbers cannot be reconciled
/// (`docs/TECH_STACK.md` §3b). So the **calendar** is the state and the
/// **streak** is a function of it. These tests are the specification of that
/// function.
void main() {
  DailyCalendar calendarOf(
    List<String> days, {
    List<String> frozen = const [],
  }) => DailyCalendar(
    completed: days.map(DailyDate.parse).toSet(),
    frozen: frozen.map(DailyDate.parse).toSet(),
  );

  final today = DailyDate(2026, 3, 20);

  group('counting the run', () {
    test('an empty calendar is a streak of nothing', () {
      expect(calendarOf(<String>[]).streakOn(today), 0);
    });

    test('today alone is one', () {
      expect(calendarOf(<String>['2026-03-20']).streakOn(today), 1);
    });

    test('consecutive days up to today count', () {
      expect(
        calendarOf(<String>[
          '2026-03-18',
          '2026-03-19',
          '2026-03-20',
        ]).streakOn(today),
        3,
      );
    });

    test(
      'a run that stopped yesterday still counts, until today is missed',
      () {
        // Mid-morning, before the player has played: the run is alive and the
        // number should not have dropped to zero while they were asleep.
        expect(
          calendarOf(<String>['2026-03-18', '2026-03-19']).streakOn(today),
          2,
        );
      },
    );

    test('a run that stopped the day before yesterday is broken', () {
      expect(
        calendarOf(<String>['2026-03-17', '2026-03-18']).streakOn(today),
        0,
      );
    });

    test('a gap in the middle is not counted through', () {
      expect(
        calendarOf(<String>[
          '2026-03-15',
          '2026-03-16',
          // 17th missed
          '2026-03-19',
          '2026-03-20',
        ]).streakOn(today),
        2,
      );
    });

    test('days after today are ignored', () {
      // A clock that was wound forward and back leaves these behind. They are
      // not counted, and crucially they do not break the run either.
      expect(
        calendarOf(<String>[
          '2026-03-19',
          '2026-03-20',
          '2026-03-25',
        ]).streakOn(today),
        2,
      );
    });

    test('a run crossing a month boundary counts', () {
      expect(
        calendarOf(<String>[
          '2026-02-27',
          '2026-02-28',
          '2026-03-01',
        ]).streakOn(DailyDate(2026, 3, 1)),
        3,
      );
    });

    test('a run crossing a leap day counts', () {
      expect(
        calendarOf(<String>[
          '2028-02-28',
          '2028-02-29',
          '2028-03-01',
        ]).streakOn(DailyDate(2028, 3, 1)),
        3,
      );
    });
  });

  group('a frozen day counts as unbroken', () {
    test('a freeze bridges a single missed day', () {
      expect(
        calendarOf(
          <String>['2026-03-18', '2026-03-20'],
          frozen: <String>['2026-03-19'],
        ).streakOn(today),
        3,
        reason: 'the frozen day is part of the run it preserved',
      );
    });

    test('a freeze does not bridge two missed days', () {
      expect(
        calendarOf(
          <String>['2026-03-17', '2026-03-20'],
          frozen: <String>['2026-03-18'],
        ).streakOn(today),
        1,
      );
    });

    test('a frozen day is not a completed day', () {
      final calendar = calendarOf(
        <String>['2026-03-20'],
        frozen: <String>['2026-03-19'],
      );

      expect(calendar.wasCompleted(DailyDate(2026, 3, 19)), isFalse);
      expect(calendar.wasFrozen(DailyDate(2026, 3, 19)), isTrue);
    });
  });

  group('the streak is never a stored number', () {
    test('unioning two calendars and recomputing is order-independent', () {
      final a = calendarOf(<String>['2026-03-18', '2026-03-19']);
      final b = calendarOf(<String>['2026-03-20']);

      expect(a.union(b).streakOn(today), b.union(a).streakOn(today));
      expect(a.union(b).streakOn(today), 3);
    });

    test('unioning is idempotent', () {
      final a = calendarOf(<String>['2026-03-19', '2026-03-20']);
      expect(a.union(a).streakOn(today), a.streakOn(today));
    });

    test('a device that was behind cannot lower the streak', () {
      // The merge rule that matters: sets union, the number is recomputed, and
      // no stale device can subtract a day somebody actually played.
      final ahead = calendarOf(<String>[
        '2026-03-18',
        '2026-03-19',
        '2026-03-20',
      ]);
      final behind = calendarOf(<String>['2026-03-18']);

      expect(ahead.union(behind).streakOn(today), 3);
    });
  });

  group('the calendar as a month grid', () {
    test('it reports the state of every day in a month', () {
      final calendar = calendarOf(
        <String>['2026-03-01', '2026-03-03'],
        frozen: <String>['2026-03-02'],
      );

      expect(calendar.stateOf(DailyDate(2026, 3, 1)), DayState.completed);
      expect(calendar.stateOf(DailyDate(2026, 3, 2)), DayState.frozen);
      expect(calendar.stateOf(DailyDate(2026, 3, 3)), DayState.completed);
      expect(calendar.stateOf(DailyDate(2026, 3, 4)), DayState.missed);
    });

    test('a new player has missed nothing', () {
      // Constraint 1, and it was a real defect: installing on the 21st drew
      // twenty "missed" days, so the app opened the relationship by telling
      // the player they had already failed at something they could not have
      // done. Nothing is claimed about a day before they arrived.
      final calendar = calendarOf(<String>[]);

      for (var day = 1; day <= 28; day++) {
        expect(
          calendar.stateOf(DailyDate(2026, 3, day), today: today),
          isNot(DayState.missed),
          reason: 'day $day was called a miss by a player who never played',
        );
      }
    });

    test('days before the first one played are not misses', () {
      final calendar = calendarOf(<String>['2026-03-18', '2026-03-19']);

      expect(
        calendar.stateOf(DailyDate(2026, 3, 10), today: today),
        DayState.untracked,
      );
      // But a gap *after* they started is a genuine miss, and still reads as
      // one — the rule softens the beginning, not the record.
      expect(
        calendar.stateOf(DailyDate(2026, 3, 20), today: today),
        DayState.missed,
      );
    });

    test('a day in the future is neither missed nor completed', () {
      final calendar = calendarOf(<String>['2026-03-20']);
      expect(
        calendar.stateOf(DailyDate(2026, 3, 25), today: today),
        DayState.notYet,
      );
    });
  });
}
