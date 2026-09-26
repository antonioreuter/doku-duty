import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/daily_challenge/application/daily_service.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_board_source.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_resolver.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_schedule.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/stamps/data/stamp_repository.dart';
import 'package:doku_duty/features/stamps/domain/earning.dart';
import 'package:doku_duty/features/trophy_cabinet/application/minting_service.dart';
import 'package:doku_duty/features/trophy_cabinet/data/trophy_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';

class _NoBoards implements DailyBoardSource {
  @override
  Future<DailyBoard?> byId(String id) async => null;
  @override
  Future<DailyBoard?> byRankAndSeed(Rank rank, int seed) async => null;
}

/// Every **earning** goes through `MintingService`, inside the transaction of
/// the event that earned it (D-133, constraint 9).
void main() {
  late AppDatabase db;
  late MintingService minting;
  late StampRepository stamps;
  late DailyRepository days;

  final catalogue = AwardCatalogue.forSeason(
    seasonId: 'dust-gulch',
    seasonName: 'Dust Gulch',
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    stamps = StampRepository(db);
    days = DailyRepository(db);
    minting = MintingService(
      database: db,
      seasons: SeasonRepository(db),
      trophies: TrophyRepository(db),
      stamps: stamps,
      daily: DailyService(
        repository: days,
        resolver: DailyResolver(
          schedule: DailySchedule.empty(),
          source: _NoBoards(),
        ),
        clock: DailyClock(offset: null),
      ),
    );
    await SeasonRepository(db).enterSeason('dust-gulch');
  });
  tearDown(() => db.close());

  Future<List<Earning>> completeNode(int position, NodeType type) =>
      minting.completeNode(
        seasonId: 'dust-gulch',
        seasonName: 'Dust Gulch',
        position: position,
        type: type,
        nodeCount: 42,
        catalogue: catalogue,
      );

  DatedDay dated(int day) =>
      DatedDay(date: DailyDate(2026, 4, day), isVerified: false);

  group('a node', () {
    test('a chest earns 12, once', () async {
      expect(await completeNode(11, NodeType.chest), const <Earning>[
        Earning(key: 'chest:dust-gulch:11', amount: 12),
      ]);
      expect(await completeNode(11, NodeType.chest), isEmpty);
      expect(await stamps.balance(), 12);
    });

    test('a boss earns 20 beside its trophy', () async {
      await completeNode(22, NodeType.boss);

      expect(await stamps.balance(), 20);
      expect(
        await TrophyRepository(db).hasEarned('dust-gulch.boss.22'),
        isTrue,
      );
    });

    test('a boss played again earns nothing more', () async {
      await completeNode(22, NodeType.boss);
      expect(await completeNode(22, NodeType.boss), isEmpty);
      expect(await stamps.balance(), 20);
    });

    test('a puzzle node earns nothing of its own', () async {
      expect(await completeNode(5, NodeType.puzzle), isEmpty);
      expect(await stamps.balance(), 0);
    });
  });

  group('a day', () {
    test('a completed day earns 2', () async {
      expect(await minting.completeDay(dated(9)), const <Earning>[
        Earning(key: 'daily:2026-04-09', amount: 2),
      ]);
    });

    test('the seventh day of a streak earns 12', () async {
      for (var day = 3; day < 9; day++) {
        await days.completeDay(dated(day));
      }

      final earned = await minting.completeDay(dated(9));

      expect(earned.fold<int>(0, (sum, e) => sum + e.amount), 12);
      expect(earned.map((e) => e.key), contains('streak:2026-04-03:7'));
    });

    test('the same day recorded twice pays once', () async {
      await minting.completeDay(dated(9));
      expect(await minting.completeDay(dated(9)), isEmpty);
      expect(await stamps.balance(), 2);
    });
  });

  group('a solve', () {
    test('a perfect first solve earns 3', () async {
      expect(
        await minting.afterSolve(
          puzzleId: 'p-1',
          isFirstSolve: true,
          isPerfect: true,
          rank: Rank.greenhorn,
        ),
        const <Earning>[Earning(key: 'perfect:p-1', amount: 3)],
      );
    });

    test('a solve with a mistake earns nothing', () async {
      expect(
        await minting.afterSolve(
          puzzleId: 'p-1',
          isFirstSolve: true,
          isPerfect: false,
          rank: Rank.greenhorn,
        ),
        isEmpty,
      );
    });

    test('a clean replay of a solved puzzle earns nothing (D-133)', () async {
      expect(
        await minting.afterSolve(
          puzzleId: 'p-1',
          isFirstSolve: false,
          isPerfect: true,
          rank: Rank.greenhorn,
        ),
        isEmpty,
      );
    });

    test('it still mints the rank trophies it did before', () async {
      await minting.afterSolve(
        puzzleId: 'p-1',
        isFirstSolve: true,
        isPerfect: false,
        rank: Rank.sheriff,
      );

      expect(
        await TrophyRepository(db).hasEarned('permanent.rank.sheriff'),
        isTrue,
      );
    });
  });
}
