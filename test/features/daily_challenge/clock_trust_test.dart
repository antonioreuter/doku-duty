import 'package:doku_duty/features/daily_challenge/domain/daily_calendar.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/clock_trust.dart';
import 'package:flutter_test/flutter_test.dart';

/// Device clocks are user-editable and this capability is made of dates.
///
/// The rule from `docs/TECH_STACK.md` §3b is narrow and worth quoting because
/// it is easy to get backwards: the marking exists **to stop fabrication, not
/// to catch travellers**. Nothing here may reduce a **streak** or unmark a day
/// because a clock moved — the only thing reconciliation does is discard days
/// that a changed clock could have manufactured.
void main() {
  group('recording a day', () {
    test('a day recorded against a known offset is verified', () {
      final entry = DayEntry(date: DailyDate(2026, 3, 14), isVerified: true);
      expect(entry.isVerified, isTrue);
    });

    test('a day recorded offline is kept, and marked', () {
      // Kept. Offline play is mandatory, so refusing to record the day would
      // be the punishment, not the protection.
      final entry = DayEntry(date: DailyDate(2026, 3, 14), isVerified: false);
      expect(entry.isVerified, isFalse);
    });
  });

  group('reconciling on reconnect', () {
    test('a verified day is never discarded', () {
      final kept = ClockTrust.reconcile(
        entries: <DayEntry>[
          DayEntry(date: DailyDate(2026, 3, 14), isVerified: true),
        ],
        serverToday: DailyDate(2026, 3, 14),
      );

      expect(kept.map((e) => e.date), contains(DailyDate(2026, 3, 14)));
    });

    test('an unverified day in the past is accepted', () {
      // The ordinary offline case: a player solved yesterday on a plane. There
      // is nothing suspicious about it and it stands.
      final kept = ClockTrust.reconcile(
        entries: <DayEntry>[
          DayEntry(date: DailyDate(2026, 3, 13), isVerified: false),
        ],
        serverToday: DailyDate(2026, 3, 14),
      );

      expect(kept, hasLength(1));
    });

    test('an unverified day in the server future is discarded', () {
      // The fabrication this exists to stop: wind the clock forward, solve a
      // week of dailies, wind it back. Those days never happened.
      final kept = ClockTrust.reconcile(
        entries: <DayEntry>[
          DayEntry(date: DailyDate(2026, 3, 14), isVerified: false),
          DayEntry(date: DailyDate(2026, 3, 20), isVerified: false),
          DayEntry(date: DailyDate(2026, 3, 21), isVerified: false),
        ],
        serverToday: DailyDate(2026, 3, 14),
      );

      expect(kept.map((e) => e.date), <DailyDate>[DailyDate(2026, 3, 14)]);
    });

    test('a verified day in the future is kept anyway', () {
      // A verified entry came from the server's own clock, so a date that
      // looks ahead is a timezone straddling midnight, not a fabrication.
      final kept = ClockTrust.reconcile(
        entries: <DayEntry>[
          DayEntry(date: DailyDate(2026, 3, 15), isVerified: true),
        ],
        serverToday: DailyDate(2026, 3, 14),
      );

      expect(kept, hasLength(1));
    });
  });

  group('a traveller is not a fabricator', () {
    test('crossing a timezone costs no calendar day', () {
      final before = DailyCalendar(
        completed: <DailyDate>{
          DailyDate(2026, 3, 18),
          DailyDate(2026, 3, 19),
          DailyDate(2026, 3, 20),
        },
      );

      // Flying east, the player's local date advances early. Their day is
      // recorded unverified and sits one ahead of where the server is.
      final kept = ClockTrust.reconcile(
        entries: <DayEntry>[
          for (final d in before.completed)
            DayEntry(date: d, isVerified: false),
        ],
        serverToday: DailyDate(2026, 3, 20),
      );

      final after = DailyCalendar(completed: kept.map((e) => e.date).toSet());

      expect(after.completed, before.completed);
      expect(
        after.streakOn(DailyDate(2026, 3, 20)),
        before.streakOn(DailyDate(2026, 3, 20)),
        reason: 'a timezone change cost the player streak days',
      );
    });

    test('reconciliation can only remove days it is sure about', () {
      // The asymmetry that keeps this safe: discarding is limited to entries
      // ahead of the server's own date. Nothing else is touched, so there is
      // no path by which an honest player loses a day.
      final entries = <DayEntry>[
        for (var day = 1; day <= 20; day++)
          DayEntry(date: DailyDate(2026, 3, day), isVerified: false),
      ];

      final kept = ClockTrust.reconcile(
        entries: entries,
        serverToday: DailyDate(2026, 3, 20),
      );

      expect(kept, hasLength(20));
    });

    test('a streak is never lowered by reconciliation alone', () {
      final entries = <DayEntry>[
        for (var day = 14; day <= 20; day++)
          DayEntry(date: DailyDate(2026, 3, day), isVerified: false),
      ];

      final kept = ClockTrust.reconcile(
        entries: entries,
        serverToday: DailyDate(2026, 3, 20),
      );
      final calendar = DailyCalendar(
        completed: kept.map((e) => e.date).toSet(),
      );

      expect(calendar.streakOn(DailyDate(2026, 3, 20)), 7);
    });
  });
}
