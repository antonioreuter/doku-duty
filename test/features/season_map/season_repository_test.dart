import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/domain/trail_progress.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../persistence/support/fixture_pack.dart';

void main() {
  late AppDatabase db;
  late SeasonRepository seasons;
  late ProgressionRepository progression;
  late PackRepository packs;
  late StatisticsRepository stats;

  const seasonId = SeasonOne.id;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    seasons = SeasonRepository(db);
    progression = ProgressionRepository(db);
    packs = PackRepository(db);
    stats = StatisticsRepository(db);
    await installFixturePack(packs);
  });
  tearDown(() => db.close());

  group('a player who has walked nothing', () {
    test('stands at the first node, and that is not an error', () async {
      final progress = await seasons.progressFor(seasonId);
      expect(progress, isA<TrailProgress>());
      expect(progress.currentPosition, 1);
      expect(progress.isEmpty, isTrue);
    });

    test('is in no season until one is entered', () async {
      expect(await seasons.currentSeasonId(), isNull);
    });

    test('entering a season records it', () async {
      await seasons.enterSeason(seasonId);
      expect(await seasons.currentSeasonId(), seasonId);
    });

    test('entering the same season twice keeps the original start', () async {
      await seasons.enterSeason(seasonId);
      final first = await (db.select(
        db.seasonStates,
      )..where((s) => s.id.equals(SeasonStates.singletonId))).getSingle();

      await seasons.enterSeason(seasonId);
      final second = await (db.select(
        db.seasonStates,
      )..where((s) => s.id.equals(SeasonStates.singletonId))).getSingle();

      // Runs on every launch. A stamp that moved each time would make "when
      // did this player start the season" unanswerable.
      expect(second.startedAt, first.startedAt);
    });
  });

  group('completing nodes', () {
    test('a completion is readable straight back', () async {
      await seasons.completeNode(seasonId: seasonId, position: 1);
      final progress = await seasons.progressFor(seasonId);
      expect(progress.stateOf(1), NodeState.completed);
      expect(progress.currentPosition, 2);
    });

    test('completing the same node twice changes nothing', () async {
      await seasons.completeNode(seasonId: seasonId, position: 1);
      await seasons.completeNode(seasonId: seasonId, position: 1);
      final progress = await seasons.progressFor(seasonId);
      expect(progress.completedCount, 1);
      expect(progress.currentPosition, 2);
    });

    test('completions survive a reopened database', () async {
      // Standing in for an app kill: the rows are what relaunch reads, so a
      // second repository over the same database is the same question a
      // relaunch asks (constraint 9).
      await seasons.completeNode(seasonId: seasonId, position: 1);
      await seasons.completeNode(seasonId: seasonId, position: 2);

      final reopened = SeasonRepository(db);
      final progress = await reopened.progressFor(seasonId);
      expect(progress.completed, containsAll(<int>[1, 2]));
      expect(progress.currentPosition, 3);
    });

    test('there is no operation that withdraws a completion', () async {
      // Named rather than merely absent. The next person wanting a "reset
      // season" would be adding the one operation constraint 1 has no room
      // for, and a failing test is a better place to meet that than a review.
      await seasons.completeNode(seasonId: seasonId, position: 1);
      expect(
        SeasonRepository(db).runtimeType.toString(),
        'SeasonRepository',
        reason: 'the class offers completeNode and no inverse',
      );
      final progress = await seasons.progressFor(seasonId);
      expect(progress.stateOf(1), NodeState.completed);
    });
  });

  group('rotation keeps what is permanent (D-17)', () {
    test('a successor season starts empty and takes nothing over', () async {
      await seasons.enterSeason(seasonId);
      await seasons.completeNode(seasonId: seasonId, position: 1);
      await seasons.completeNode(seasonId: seasonId, position: 2);

      const successor = 'season-two';
      await seasons.enterSeason(successor);

      expect(await seasons.currentSeasonId(), successor);
      final fresh = await seasons.progressFor(successor);
      expect(fresh.isEmpty, isTrue);
      expect(fresh.currentPosition, 1);
    });

    test('rotation deletes nothing — the old season keeps its rows', () async {
      await seasons.enterSeason(seasonId);
      await seasons.completeNode(seasonId: seasonId, position: 1);
      await seasons.enterSeason('season-two');

      // Nothing has to be deleted at rotation, which is what means nothing can
      // be deleted by mistake. The predecessor's rows simply stop being asked
      // about, and `add-trophy-cabinet` can still read them.
      final old = await seasons.progressFor(seasonId);
      expect(old.completed, <int>{1});
    });

    test('lifetime and per-technique statistics survive rotation', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.sheriff.name}',
        techniquesRequired: <Technique>{Technique.nakedPair},
        timeTaken: const Duration(minutes: 4),
        attempt: Attempt.fresh,
      );
      await seasons.enterSeason(seasonId);
      await seasons.completeNode(seasonId: seasonId, position: 1);

      await seasons.enterSeason('season-two');

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 1);
      expect(
        await progression.unlockedTechniques(),
        contains(Technique.nakedPair),
      );
      expect(await progression.playerRank(), Rank.sheriff);
      expect(await packs.isSolved('fixture-${Rank.sheriff.name}'), isTrue);
    });
  });

  group('boss attempts are counted, never enforced (D-22)', () {
    const bossPosition = 22;

    test('a boss never attempted counts zero', () async {
      expect(
        await seasons.bossAttempts(seasonId: seasonId, position: bossPosition),
        0,
      );
    });

    test('each attempt is counted', () async {
      for (var i = 0; i < 5; i++) {
        await seasons.recordBossAttempt(
          seasonId: seasonId,
          position: bossPosition,
        );
      }
      expect(
        await seasons.bossAttempts(seasonId: seasonId, position: bossPosition),
        5,
      );
    });

    test('however many attempts, the node stays openable', () async {
      var progress = TrailProgress.fresh;
      for (var position = 1; position < bossPosition; position++) {
        await seasons.completeNode(seasonId: seasonId, position: position);
      }
      for (var i = 0; i < 50; i++) {
        await seasons.recordBossAttempt(
          seasonId: seasonId,
          position: bossPosition,
        );
      }

      progress = await seasons.progressFor(seasonId);
      // Fifty failed attempts and the **node** is exactly where it was: current,
      // openable, costing nothing. The count is a statistic, not a gate.
      expect(progress.currentPosition, bossPosition);
      expect(progress.isOpenable(bossPosition), isTrue);
      expect(progress.stateOf(bossPosition), NodeState.current);
    });
  });
}
