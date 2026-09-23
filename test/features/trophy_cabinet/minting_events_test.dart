import 'package:doku_duty/features/daily_challenge/domain/daily_calendar.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/application/minting_service.dart';
import 'package:doku_duty/features/trophy_cabinet/data/trophy_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which recorded events mint which **trophy**s.
///
/// The seams `add-season-map` and `add-daily-challenge` each left are filled
/// here. Their own tests were **deleted and replaced** by this change rather
/// than edited into agreement — a test asserting "nothing is minted" surviving
/// into the change that mints would block the feature it was written to hand
/// over.
void main() {
  late AppDatabase db;
  late MintingService minting;
  late TrophyRepository trophies;

  final catalogue = AwardCatalogue.forSeason(
    seasonId: 'dust-gulch',
    seasonName: 'Dust Gulch',
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    trophies = TrophyRepository(db);
    minting = MintingService(
      database: db,
      seasons: SeasonRepository(db),
      trophies: trophies,
    );
    await SeasonRepository(db).enterSeason('dust-gulch');
  });
  tearDown(() => db.close());

  Future<void> complete(int position) => minting.completeNode(
    seasonId: 'dust-gulch',
    seasonName: 'Dust Gulch',
    position: position,
    nodeCount: 42,
    catalogue: catalogue,
  );

  group('a boss node mints (change 15 left this seam)', () {
    test('completing the midpoint boss mints its trophy', () async {
      await complete(22);

      final earned = await trophies.earned();
      expect(earned, hasLength(1));
      expect(earned.single.awardId, 'dust-gulch.boss.22');
      expect(earned.single.seasonName, 'Dust Gulch');
    });

    test('an ordinary node mints nothing', () async {
      await complete(7);
      expect(await trophies.earned(), isEmpty);
    });

    test('both bosses mint separately', () async {
      await complete(22);
      await complete(41);

      expect((await trophies.earned()).map((t) => t.awardId).toSet(), <String>{
        'dust-gulch.boss.22',
        'dust-gulch.boss.41',
      });
    });

    test('completing the same boss twice mints once', () async {
      await complete(22);
      await complete(22);
      expect(await trophies.earned(), hasLength(1));
    });
  });

  group('closing the season mints (D-119)', () {
    test('the last node closes the case', () async {
      for (var position = 1; position <= 42; position++) {
        await complete(position);
      }

      final ids = (await trophies.earned()).map((t) => t.awardId).toSet();
      expect(ids, contains('dust-gulch.closed'));
    });

    test('forty-one nodes do not', () async {
      for (var position = 1; position <= 41; position++) {
        await complete(position);
      }

      final ids = (await trophies.earned()).map((t) => t.awardId).toSet();
      expect(ids, isNot(contains('dust-gulch.closed')));
      // The two bosses are in there, though — 41 is one of them.
      expect(ids, hasLength(2));
    });

    test('the closing trophy names the territory', () async {
      for (var position = 1; position <= 42; position++) {
        await complete(position);
      }

      final closed = (await trophies.earned()).firstWhere(
        (t) => t.awardId == 'dust-gulch.closed',
      );
      expect(closed.name, contains('Dust Gulch'));
      expect(closed.seasonName, 'Dust Gulch');
    });
  });

  group('a perfect month mints (change 14 left this seam)', () {
    DailyCalendar monthOf(int upTo) => DailyCalendar(
      completed: <DailyDate>{
        for (var day = 1; day <= upTo; day++) DailyDate(2026, 4, day),
      },
    );

    test('a complete month mints', () async {
      // April has 30 days.
      await minting.afterDailyCompleted(
        calendar: monthOf(30),
        day: DailyDate(2026, 4, 30),
      );

      expect(
        (await trophies.earned()).single.awardId,
        'permanent.perfect-month.2026-04',
      );
    });

    test('every perfect month mints its own trophy', () async {
      // `docs/SPEC.md` §5.3: "a trophy for that month". Keyed on the **award**
      // alone, the second perfect month would collide with the first and mint
      // nothing — a reward silently withheld for every month after the first.
      await minting.afterDailyCompleted(
        calendar: monthOf(30),
        day: DailyDate(2026, 4, 30),
      );
      await minting.afterDailyCompleted(
        calendar: DailyCalendar(
          completed: <DailyDate>{
            for (var day = 1; day <= 31; day++) DailyDate(2026, 5, day),
          },
        ),
        day: DailyDate(2026, 5, 31),
      );

      expect((await trophies.earned()).map((t) => t.awardId).toSet(), <String>{
        'permanent.perfect-month.2026-04',
        'permanent.perfect-month.2026-05',
      });
    });

    test('each month\'s trophy names its month', () async {
      await minting.afterDailyCompleted(
        calendar: monthOf(30),
        day: DailyDate(2026, 4, 30),
      );

      expect((await trophies.earned()).single.name, contains('April 2026'));
    });

    test('the same month twice mints once', () async {
      // The 30th recorded, then re-recorded — the month is complete both times.
      for (var i = 0; i < 2; i++) {
        await minting.afterDailyCompleted(
          calendar: monthOf(30),
          day: DailyDate(2026, 4, 30),
        );
      }

      expect(await trophies.earned(), hasLength(1));
    });

    test('a month with one gap mints nothing', () async {
      await minting.afterDailyCompleted(
        calendar: monthOf(29),
        day: DailyDate(2026, 4, 29),
      );

      expect(await trophies.earned(), isEmpty);
    });

    test('a frozen day does not complete the month', () async {
      // `docs/SPEC.md` §5.3 gives the trophy for a month of dailies. A day a
      // **streak freeze** bridged kept the **streak** alive, which is what a
      // freeze is for — it is not a day the player turned up.
      final withFreeze = DailyCalendar(
        completed: <DailyDate>{
          for (var day = 1; day <= 30; day++)
            if (day != 14) DailyDate(2026, 4, day),
        },
        frozen: <DailyDate>{DailyDate(2026, 4, 14)},
      );

      await minting.afterDailyCompleted(
        calendar: withFreeze,
        day: DailyDate(2026, 4, 30),
      );

      expect(await trophies.earned(), isEmpty);
    });

    test('the permanent trophy carries no season', () async {
      await minting.afterDailyCompleted(
        calendar: monthOf(30),
        day: DailyDate(2026, 4, 30),
      );

      expect((await trophies.earned()).single.seasonId, isNull);
    });
  });

  group('reaching a rank mints', () {
    test('every rank at or below is minted, not only the newest', () async {
      // A player can cross two **rank**s on one solve. Minting the whole run
      // covers it, and idempotence makes the repetition free.
      await minting.afterRankReached(Rank.marshal);

      final ids = (await trophies.earned()).map((t) => t.awardId).toSet();
      expect(ids, <String>{'permanent.rank.sheriff', 'permanent.rank.marshal'});
    });

    test('greenhorn mints nothing, because everybody starts there', () async {
      await minting.afterRankReached(Rank.greenhorn);
      expect(await trophies.earned(), isEmpty);
    });

    test('reaching the same rank again mints nothing new', () async {
      await minting.afterRankReached(Rank.sheriff);
      await minting.afterRankReached(Rank.sheriff);
      expect(await trophies.earned(), hasLength(1));
    });
  });

  group('what still mints nothing', () {
    test('no stamp is minted — add-stamps (18) still owns that', () async {
      await complete(22);
      for (var position = 1; position <= 42; position++) {
        await complete(position);
      }

      final tables = db.allTables.map((t) => t.actualTableName).toList();
      expect(
        tables.any((t) => t.contains('stamp')),
        isFalse,
        reason: 'a stamp table appeared before add-stamps',
      );
    });

    test('a chest node mints nothing yet', () async {
      // Chests are at 11, 21, 32 and 42 (D-120). Completing one earns a
      // **stamp** under change 18 and, today, nothing at all — 42 is the
      // exception only because it also closes the season.
      await complete(11);
      expect(await trophies.earned(), isEmpty);
    });
  });
}
