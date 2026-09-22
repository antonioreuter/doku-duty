import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which day it is, for a capability where that is the whole question.
///
/// A **daily challenge** rolls over at midnight *local* time, and a **streak**
/// is a run of those days. Every bug in here is a player losing a counter they
/// held for a year, so the awkward cases — DST in both directions, a timezone
/// move, a clock the player edited — are the point of the file rather than an
/// afterthought.
void main() {
  group('a day is local, not UTC', () {
    test('an instant just before local midnight is still today', () {
      final date = DailyDate.from(DateTime(2026, 3, 14, 23, 59, 59));
      expect(date, DailyDate(2026, 3, 14));
    });

    test('an instant just after local midnight is tomorrow', () {
      final date = DailyDate.from(DateTime(2026, 3, 15, 0, 0, 1));
      expect(date, DailyDate(2026, 3, 15));
    });

    test('the time of day is discarded entirely', () {
      expect(
        DailyDate.from(DateTime(2026, 3, 14, 6)),
        DailyDate.from(DateTime(2026, 3, 14, 18)),
      );
    });
  });

  group('daylight saving', () {
    test('a 23-hour day is one day', () {
      // Spring forward: 02:00 becomes 03:00, so the local day is short. It is
      // still exactly one day on the calendar, and a player who solved at 01:00
      // and again at 23:00 has solved one day, not two.
      final early = DailyDate.from(DateTime(2026, 3, 29, 1, 30));
      final late = DailyDate.from(DateTime(2026, 3, 29, 23, 30));
      expect(early, late);
    });

    test('a 25-hour day is one day', () {
      // Autumn back: 03:00 becomes 02:00, so 02:30 happens twice. Both are the
      // same date and neither creates a second day.
      final first = DailyDate.from(DateTime(2026, 10, 25, 2, 30));
      final second = DailyDate.from(DateTime(2026, 10, 25, 2, 30));
      expect(first, second);
    });
  });

  group('ordering and adjacency', () {
    test('yesterday precedes today', () {
      expect(DailyDate(2026, 3, 14) < DailyDate(2026, 3, 15), isTrue);
    });

    test('the day after the last of a month is the first of the next', () {
      expect(DailyDate(2026, 3, 31).next, DailyDate(2026, 4, 1));
    });

    test('the day after 28 February in a leap year is the 29th', () {
      expect(DailyDate(2028, 2, 28).next, DailyDate(2028, 2, 29));
      expect(DailyDate(2028, 2, 29).next, DailyDate(2028, 3, 1));
    });

    test('the day after 28 February in a common year is 1 March', () {
      expect(DailyDate(2026, 2, 28).next, DailyDate(2026, 3, 1));
    });

    test('the day before the first of a month is the last of the previous', () {
      expect(DailyDate(2026, 4, 1).previous, DailyDate(2026, 3, 31));
    });

    test('days between counts the gap, not the endpoints', () {
      expect(DailyDate(2026, 3, 14).daysUntil(DailyDate(2026, 3, 14)), 0);
      expect(DailyDate(2026, 3, 14).daysUntil(DailyDate(2026, 3, 15)), 1);
      expect(DailyDate(2026, 3, 31).daysUntil(DailyDate(2026, 4, 1)), 1);
    });

    test('days between survives a DST boundary', () {
      // Naively subtracting two DateTimes across a spring-forward gives 23
      // hours, which integer-divides to zero days. A calendar day is not a
      // duration, and this is the test that says so.
      expect(DailyDate(2026, 3, 28).daysUntil(DailyDate(2026, 3, 30)), 2);
      expect(DailyDate(2026, 10, 24).daysUntil(DailyDate(2026, 10, 26)), 2);
    });
  });

  group('weekday, for the weekly ramp', () {
    test('the ramp reads a stable day of week', () {
      // 2026-03-16 is a Monday.
      expect(DailyDate(2026, 3, 16).weekday, DateTime.monday);
      expect(DailyDate(2026, 3, 22).weekday, DateTime.sunday);
    });
  });

  group('the clock the date came from', () {
    test('a date taken from a known server offset is verified', () {
      final clock = DailyClock(offset: const Duration(seconds: 3));
      expect(clock.today().isVerified, isTrue);
    });

    test('a date taken from the device clock alone is not', () {
      // Offline, the local clock is trusted and the entry is marked, so a
      // reconciliation can later tell a traveller from a fabrication
      // (`docs/TECH_STACK.md` §3b).
      final clock = DailyClock(offset: null);
      expect(clock.today().isVerified, isFalse);
    });

    test('the offset moves the date when it straddles midnight', () {
      final justBefore = DateTime(2026, 3, 14, 23, 59, 30);
      final clock = DailyClock(
        offset: const Duration(minutes: 1),
        now: () => justBefore,
      );
      expect(clock.today().date, DailyDate(2026, 3, 15));
    });
  });

  group('round trip', () {
    test('a date survives being stored and read back', () {
      final date = DailyDate(2026, 3, 14);
      expect(DailyDate.parse(date.toIso()), date);
    });

    test('the stored form sorts lexically in date order', () {
      final sorted = <String>[
        DailyDate(2026, 10, 2).toIso(),
        DailyDate(2026, 3, 14).toIso(),
        DailyDate(2026, 3, 9).toIso(),
      ]..sort();
      expect(sorted, <String>['2026-03-09', '2026-03-14', '2026-10-02']);
    });
  });
}
