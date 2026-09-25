import 'package:doku_duty/features/daily_challenge/application/daily_service.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_board_source.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_resolver.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_schedule.dart';
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
class _NoBoards implements DailyBoardSource {
  @override
  Future<DailyBoard?> byId(String id) async => null;
  @override
  Future<DailyBoard?> byRankAndSeed(Rank rank, int seed) async => null;
}

DailyService _dailyOver(DailyRepository repository) => DailyService(
  repository: repository,
  resolver: DailyResolver(schedule: DailySchedule.empty(), source: _NoBoards()),
  clock: DailyClock(offset: null),
);

/// Writes the day, then fails: the failure lands after the day is in sqlite,
/// which is the only place a missing transaction would show.
class _FailsAfterWriting extends DailyService {
  _FailsAfterWriting(DailyRepository repository)
    : super(
        repository: repository,
        resolver: _dailyOver(repository).resolver,
        clock: DailyClock(offset: null),
      );

  @override
  Future<DailyCompletion> complete(DatedDay day) async {
    await super.complete(day);
    throw StateError('failed after the day was written');
  }
}

void main() {
  late AppDatabase db;
  late MintingService minting;
  late TrophyRepository trophies;
  late DailyRepository days;

  final catalogue = AwardCatalogue.forSeason(
    seasonId: 'dust-gulch',
    seasonName: 'Dust Gulch',
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    trophies = TrophyRepository(db);
    days = DailyRepository(db);
    minting = MintingService(
      database: db,
      seasons: SeasonRepository(db),
      trophies: trophies,
      daily: _dailyOver(days),
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

  group('a daily is recorded with what it earns', () {
    DatedDay dated(int day) =>
        DatedDay(date: DailyDate(2026, 4, day), isVerified: false);

    test('the day lands on the calendar and the completion says so', () async {
      final completion = await minting.completeDay(dated(9));

      expect(completion.date, DailyDate(2026, 4, 9));
      expect(completion.streak, 1);
      expect(
        (await days.calendar()).wasCompleted(DailyDate(2026, 4, 9)),
        isTrue,
      );
      expect(await trophies.earned(), isEmpty);
    });

    test('the day that completes a month mints its trophy', () async {
      for (var day = 1; day <= 29; day++) {
        await days.completeDay(dated(day));
      }

      await minting.completeDay(dated(30));

      expect(
        (await trophies.earned()).single.awardId,
        'permanent.perfect-month.2026-04',
      );
    });

    test('a failure after the day is written leaves neither', () async {
      for (var day = 1; day <= 29; day++) {
        await days.completeDay(dated(day));
      }
      final failing = MintingService(
        database: db,
        seasons: SeasonRepository(db),
        trophies: trophies,
        daily: _FailsAfterWriting(days),
      );

      await expectLater(failing.completeDay(dated(30)), throwsStateError);

      expect(
        (await days.calendar()).wasCompleted(DailyDate(2026, 4, 30)),
        isFalse,
        reason: 'the day survived a completion that did not',
      );
      expect(await trophies.earned(), isEmpty);
    });
  });

  group('a perfect month mints (change 14 left this seam)', () {
    DatedDay dated(int year, int month, int day) =>
        DatedDay(date: DailyDate(year, month, day), isVerified: false);

    /// Every day of the month up to [upTo] already on the **calendar**, then
    /// [upTo] + 1 completed through the minting service, as a solve does.
    Future<void> completeAprilThrough(int upTo) async {
      for (var day = 1; day < upTo; day++) {
        await days.completeDay(dated(2026, 4, day));
      }
      await minting.completeDay(dated(2026, 4, upTo));
    }

    test('a complete month mints', () async {
      // April has 30 days.
      await completeAprilThrough(30);

      expect(
        (await trophies.earned()).single.awardId,
        'permanent.perfect-month.2026-04',
      );
    });

    test('every perfect month mints its own trophy', () async {
      // `docs/SPEC.md` §5.3: "a trophy for that month". Keyed on the **award**
      // alone, the second perfect month would collide with the first and mint
      // nothing — a reward silently withheld for every month after the first.
      await completeAprilThrough(30);
      for (var day = 1; day < 31; day++) {
        await days.completeDay(dated(2026, 5, day));
      }
      await minting.completeDay(dated(2026, 5, 31));

      expect((await trophies.earned()).map((t) => t.awardId).toSet(), <String>{
        'permanent.perfect-month.2026-04',
        'permanent.perfect-month.2026-05',
      });
    });

    test('each month\'s trophy names its month', () async {
      await completeAprilThrough(30);

      expect((await trophies.earned()).single.name, contains('April 2026'));
    });

    test('the same month twice mints once', () async {
      // The 30th recorded, then re-recorded — the month is complete both times.
      await completeAprilThrough(30);
      await minting.completeDay(dated(2026, 4, 30));

      expect(await trophies.earned(), hasLength(1));
    });

    test('a month with one gap mints nothing', () async {
      // The 30th never played.
      await completeAprilThrough(29);

      expect(await trophies.earned(), isEmpty);
    });

    test('a frozen day does not complete the month', () async {
      // `docs/SPEC.md` §5.3 gives the trophy for a month of dailies. A day a
      // **streak freeze** bridged kept the **streak** alive, which is what a
      // freeze is for — it is not a day the player turned up.
      for (var day = 1; day < 30; day++) {
        if (day == 14) continue;
        await days.completeDay(dated(2026, 4, day));
      }
      await days.recordFrozen(<DailyDate>[DailyDate(2026, 4, 14)]);

      await minting.completeDay(dated(2026, 4, 30));

      expect(await trophies.earned(), isEmpty);
    });

    test('the permanent trophy carries no season', () async {
      await completeAprilThrough(30);

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
