import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/daily_challenge/application/daily_providers.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_origin.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/season_map/application/season_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/application/cabinet_providers.dart';
import 'package:doku_duty/features/trophy_cabinet/application/minting_service.dart';
import 'package:doku_duty/features/trophy_cabinet/data/trophy_repository.dart';

import '../grid_input/support/production_solve.dart';

/// Mints the **rank** **trophy**s, then fails: the failure lands after every
/// write the solve makes, which is the only place a missing transaction shows.
class _FailsAfterMinting extends MintingService {
  _FailsAfterMinting(Ref ref)
    : super(
        database: ref.watch(appDatabaseProvider),
        seasons: ref.watch(seasonRepositoryProvider),
        trophies: ref.watch(trophyRepositoryProvider),
        daily: ref.watch(dailyServiceProvider),
      );

  @override
  Future<void> afterRankReached(Rank rank) async {
    await super.afterRankReached(rank);
    throw StateError('failed after minting');
  }
}

/// **Rank** **trophy**s mint from a solve in the running app.
///
/// `MintingService.afterRankReached` was tested alone and called by nothing
/// else, so no player ever received one. These drive the app's own sink.
void main() {
  late ProductionSolve app;
  late TrophyRepository trophies;

  setUp(() async {
    app = await ProductionSolve.open();
    trophies = TrophyRepository(app.db);
  });
  tearDown(() => app.close());

  PuzzleOriginNotifier opener() =>
      app.container.read(puzzleOriginProvider.notifier);

  test('a free-play solve that reaches Sheriff mints its trophy', () async {
    opener().openFreePlay();

    await app.solve(Rank.sheriff);

    expect(await trophies.hasEarned('permanent.rank.sheriff'), isTrue);
    expect(await trophies.hasEarned('permanent.rank.marshal'), isFalse);
  });

  test('a trail solve mints the rank trophy too', () async {
    final seasonId = app.container.read(currentSeasonProvider).id;
    await SeasonRepository(app.db).enterSeason(seasonId);
    opener().openNode(1);

    await app.solve(Rank.marshal);

    expect(await trophies.hasEarned('permanent.rank.marshal'), isTrue);
    expect(
      await trophies.hasEarned('permanent.rank.sheriff'),
      isTrue,
      reason: 'a jump of two ranks mints both',
    );
  });

  test('a daily solve mints the rank trophy too', () async {
    opener().openDaily(
      DatedDay(date: DailyDate(2026, 3, 20), isVerified: false),
    );

    await app.solve(Rank.sheriff);

    expect(await trophies.hasEarned('permanent.rank.sheriff'), isTrue);
  });

  test(
    'a rank held before its trophy could mint is minted on the next solve',
    () async {
      // Reached the way every player before `wire-completion-events` reached
      // it: a **solve record** written with nothing minted behind it.
      await ProgressionRepository(app.db).record(
        puzzleId: 'fixture-sheriff',
        techniquesRequired: const <Technique>{Technique.nakedSingle},
        timeTaken: Duration.zero,
        attempt: Attempt.fresh,
      );
      expect(await trophies.hasEarned('permanent.rank.sheriff'), isFalse);

      opener().openFreePlay();
      await app.solve(Rank.greenhorn);

      expect(await trophies.hasEarned('permanent.rank.sheriff'), isTrue);
    },
  );

  group('a daily that raises the rank', () {
    late ProductionSolve failing;

    setUp(() async {
      failing = await ProductionSolve.open(
        overrides: [
          mintingServiceProvider.overrideWith(_FailsAfterMinting.new),
        ],
      );
    });
    tearDown(() => failing.close());

    test('writes the day, the solve record and the trophy, or none', () async {
      final day = DailyDate(2026, 3, 20);
      failing.container
          .read(puzzleOriginProvider.notifier)
          .openDaily(DatedDay(date: day, isVerified: false));

      final errors = await failing.solve(Rank.sheriff, expectFailure: true);
      expect(errors, [isStateError]);

      expect(
        await PackRepository(failing.db).isSolved('fixture-sheriff'),
        isFalse,
      );
      expect(
        (await DailyRepository(failing.db).calendar()).wasCompleted(day),
        isFalse,
      );
      expect(await TrophyRepository(failing.db).earned(), isEmpty);
    });
  });
}
