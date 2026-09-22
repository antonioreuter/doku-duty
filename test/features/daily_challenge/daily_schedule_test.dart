import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_schedule.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which board is today's.
///
/// Two routes, and the second exists so the first is allowed to run out
/// (D-115). Nothing here touches a database: resolution decides *what to ask
/// for*, and the asking is somebody else's job.
void main() {
  DailySchedule scheduleFor(Map<String, String> entries) => DailySchedule(
    entries: entries.map((iso, id) => MapEntry(DailyDate.parse(iso), id)),
  );

  group('the schedule names the board', () {
    test('a covered date resolves to the puzzle it names', () {
      final schedule = scheduleFor({'2026-03-14': 'q-042'});

      final resolution = schedule.resolve(DailyDate(2026, 3, 14));

      expect(resolution, isA<NamedPuzzle>());
      expect((resolution as NamedPuzzle).puzzleId, 'q-042');
    });

    test('two players on the same date are sent to the same puzzle', () {
      final schedule = scheduleFor({'2026-03-14': 'q-042'});

      expect(
        schedule.resolve(DailyDate(2026, 3, 14)),
        schedule.resolve(DailyDate(2026, 3, 14)),
      );
    });

    test('adjacent dates are not confused for one another', () {
      final schedule = scheduleFor({
        '2026-03-14': 'q-042',
        '2026-03-15': 'q-043',
      });

      expect(
        (schedule.resolve(DailyDate(2026, 3, 15)) as NamedPuzzle).puzzleId,
        'q-043',
      );
    });
  });

  group('the schedule runs out', () {
    test('an uncovered date falls back to a derived board', () {
      final schedule = scheduleFor({'2026-03-14': 'q-042'});

      expect(schedule.resolve(DailyDate(2026, 9, 1)), isA<DerivedFromPack>());
    });

    test('an empty schedule resolves every date', () {
      // The case a player who has never reached the network is in. There is no
      // date on which the daily is simply absent (D-115, constraint 1).
      final schedule = DailySchedule.empty();

      for (final date in <DailyDate>[
        DailyDate(2026, 1, 1),
        DailyDate(2030, 6, 15),
        DailyDate(2099, 12, 31),
      ]) {
        expect(schedule.resolve(date), isA<DerivedFromPack>());
      }
    });

    test('the derived board is stable for a date', () {
      final a = DailySchedule.empty().resolve(DailyDate(2026, 9, 1));
      final b = DailySchedule.empty().resolve(DailyDate(2026, 9, 1));

      expect(a, b);
      expect((a as DerivedFromPack).seed, (b as DerivedFromPack).seed);
    });

    test('different dates derive different boards', () {
      final seeds = <int>{
        for (var day = 1; day <= 28; day++)
          (DailySchedule.empty().resolve(DailyDate(2026, 9, day))
                  as DerivedFromPack)
              .seed,
      };

      // Not a hash-quality claim — just that the seed is a function of the
      // date and not a constant, which a naive implementation gets wrong.
      expect(seeds.length, 28);
    });
  });

  group('the weekly ramp', () {
    // D-116: a published week rises in rank from its start to its end, and the
    // derived fallback follows the same shape so a player who outruns the
    // schedule does not also lose the curve.
    test('rank rises across the week', () {
      final ranks = <Rank>[
        for (var day = 16; day <= 22; day++)
          (DailySchedule.empty().resolve(DailyDate(2026, 3, day))
                  as DerivedFromPack)
              .rank,
      ];

      // 2026-03-16 is a Monday, so this is one full Monday-to-Sunday week.
      for (var i = 1; i < ranks.length; i++) {
        expect(
          ranks[i].index,
          greaterThanOrEqualTo(ranks[i - 1].index),
          reason: 'rank fell between day $i and ${i - 1} of the week',
        );
      }
      expect(ranks.first.index, lessThan(ranks.last.index));
    });

    test('the same weekday always carries the same rank', () {
      Rank rankOn(DailyDate d) =>
          (DailySchedule.empty().resolve(d) as DerivedFromPack).rank;

      expect(rankOn(DailyDate(2026, 3, 16)), rankOn(DailyDate(2026, 3, 23)));
      expect(rankOn(DailyDate(2026, 3, 22)), rankOn(DailyDate(2026, 3, 29)));
    });

    test('the ramp never asks for a rank that does not exist', () {
      for (var day = 1; day <= 31; day++) {
        final resolution =
            DailySchedule.empty().resolve(DailyDate(2026, 3, day))
                as DerivedFromPack;
        expect(Rank.values, contains(resolution.rank));
      }
    });

    test('the easiest day of the week is not the hardest rank', () {
      // A Greenhorn has to be able to finish *some* day of the week, or the
      // streak becomes a counter they can never start (D-116).
      final monday =
          DailySchedule.empty().resolve(DailyDate(2026, 3, 16))
              as DerivedFromPack;
      expect(monday.rank, isNot(Rank.legend));
      expect(monday.rank.index, lessThanOrEqualTo(Rank.deputy.index));
    });
  });

  group('reading a published schedule', () {
    test('a well-formed document is read', () {
      final schedule = DailySchedule.fromJson(<String, Object?>{
        'schema_version': 1,
        'days': <Object?>[
          <String, Object?>{'date': '2026-03-14', 'puzzle_id': 'q-042'},
          <String, Object?>{'date': '2026-03-15', 'puzzle_id': 'q-043'},
        ],
      });

      expect(schedule.covers(DailyDate(2026, 3, 14)), isTrue);
      expect(schedule.covers(DailyDate(2026, 3, 16)), isFalse);
    });

    test('a malformed document is refused into the empty schedule', () {
      // Refused, never thrown. A bad publish degrades to the derived board,
      // which is the same thing an absent publish does — the player sees a
      // daily either way (D-115).
      for (final bad in <Object?>[
        null,
        'not a document',
        <String, Object?>{'days': 'not a list'},
        <String, Object?>{
          'days': <Object?>[
            <String, Object?>{'date': 'not-a-date', 'puzzle_id': 'q-1'},
          ],
        },
        <String, Object?>{
          'days': <Object?>[
            <String, Object?>{'date': '2026-03-14'},
          ],
        },
      ]) {
        final schedule = DailySchedule.fromJson(bad);
        expect(schedule.isEmpty, isTrue);
        expect(
          schedule.resolve(DailyDate(2026, 3, 14)),
          isA<DerivedFromPack>(),
        );
      }
    });

    test('a document shaped like the published season is read', () {
      // The shape `lib/features/remote_config/PUBLISHING.md` documents, read
      // back here so the two cannot drift apart without a test noticing.
      final schedule = DailySchedule.fromJson(<String, Object?>{
        'schema_version': 1,
        'days': <Object?>[
          for (var day = 16; day <= 22; day++)
            <String, Object?>{
              'date': '2026-03-${day.toString().padLeft(2, '0')}',
              'puzzle_id': 'q-$day',
            },
        ],
      });

      for (var day = 16; day <= 22; day++) {
        expect(schedule.covers(DailyDate(2026, 3, day)), isTrue);
      }
      expect(schedule.covers(DailyDate(2026, 3, 23)), isFalse);
    });

    test('publishing ahead of the pack is safe', () {
      // The case a publisher will actually hit. A named puzzle the installed
      // **pack**s lack is not a failure: the day falls back to the derived
      // board and starts using the named one when the **pack** arrives. The
      // schedule itself still reads it as covered — the fallback happens at
      // resolution, not at parse.
      final schedule = DailySchedule.fromJson(<String, Object?>{
        'days': <Object?>[
          <String, Object?>{'date': '2026-03-14', 'puzzle_id': 'not-shipped'},
        ],
      });

      expect(schedule.covers(DailyDate(2026, 3, 14)), isTrue);
      expect(
        schedule.resolve(DailyDate(2026, 3, 14)),
        const NamedPuzzle('not-shipped'),
      );
    });

    test('an ISO-8601 datetime is refused, not truncated', () {
      // Publishing an instant where a local calendar date belongs is the
      // mistake the document warns about. Refused into the fallback rather
      // than silently reinterpreted as a day in some other timezone.
      final schedule = DailySchedule.fromJson(<String, Object?>{
        'days': <Object?>[
          <String, Object?>{'date': '2026-03-14T00:00:00Z', 'puzzle_id': 'q-1'},
        ],
      });

      expect(schedule.isEmpty, isTrue);
    });

    test('one bad day does not discard the good ones', () {
      final schedule = DailySchedule.fromJson(<String, Object?>{
        'days': <Object?>[
          <String, Object?>{'date': '2026-03-14', 'puzzle_id': 'q-042'},
          <String, Object?>{'date': 'rubbish', 'puzzle_id': 'q-043'},
        ],
      });

      expect(schedule.covers(DailyDate(2026, 3, 14)), isTrue);
      expect(schedule.isEmpty, isFalse);
    });
  });
}
