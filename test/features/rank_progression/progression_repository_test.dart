import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';

import '../persistence/support/fixture_pack.dart';

void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late PackRepository packs;
  late StatisticsRepository stats;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    progression = ProgressionRepository(db);
    packs = PackRepository(db);
    stats = StatisticsRepository(db);
    await installFixturePack(packs);
  });
  tearDown(() => db.close());

  group('a completed puzzle', () {
    test('writes all four parts of the solve record', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.sheriff.name}',
        techniquesRequired: <Technique>{
          Technique.nakedSingle,
          Technique.pointingPair,
        },
        timeTaken: const Duration(minutes: 3),
        attempt: Attempt.fresh,
      );

      expect(await packs.isSolved('fixture-${Rank.sheriff.name}'), isTrue);

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 1);
      expect(lifetime.perfectSolves, 1);
      expect(lifetime.totalPlayMs, const Duration(minutes: 3).inMilliseconds);

      expect(await stats.countFor(Technique.nakedSingle), 1);
      expect(await stats.countFor(Technique.pointingPair), 1);
    });

    test('records an imperfect attempt without a perfect solve', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.deputy.name}',
        techniquesRequired: <Technique>{Technique.hiddenSingle},
        timeTaken: const Duration(minutes: 1),
        attempt: const Attempt(mistakes: 2),
      );

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 1);
      expect(lifetime.perfectSolves, 0);
    });
  });

  group('the parts are written together', () {
    test('a failure part-way leaves none of them', () async {
      // What this actually catches: the naive implementation — call
      // `recordSolve`, then `markSolved` — raises the counters and then marks
      // nothing, because `solvedPuzzles` holds a bare puzzle id with no foreign
      // key and accepts an unknown one without complaint. The lifetime total
      // would climb off a puzzle that was never recorded as solved, and the
      // picker would hand that puzzle back. Recording against a puzzle the pack
      // does not have must write nothing at all.
      await expectLater(
        progression.record(
          puzzleId: 'no-such-puzzle',
          techniquesRequired: <Technique>{Technique.nakedSingle},
          timeTaken: const Duration(minutes: 1),
          attempt: Attempt.fresh,
        ),
        throwsA(isA<Object>()),
      );

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 0, reason: 'lifetime counter committed');
      expect(await stats.countFor(Technique.nakedSingle), 0);
      expect(await packs.isSolved('no-such-puzzle'), isFalse);
    });
  });

  group('a puzzle completed twice', () {
    test('counts once', () async {
      // `markSolved` is idempotent on its own — it upserts — but `recordSolve`
      // increments unconditionally, so without a guard the second completion
      // would raise every counter again off one puzzle. A player who finishes,
      // leaves, resumes the finished board and finishes it again would inflate
      // their own lifetime total.
      for (var i = 0; i < 3; i++) {
        await progression.record(
          puzzleId: 'fixture-${Rank.marshal.name}',
          techniquesRequired: <Technique>{Technique.nakedTriple},
          timeTaken: const Duration(minutes: 5),
          attempt: Attempt.fresh,
        );
      }

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 1);
      expect(lifetime.perfectSolves, 1);
      expect(lifetime.totalPlayMs, const Duration(minutes: 5).inMilliseconds);
      expect(await stats.countFor(Technique.nakedTriple), 1);
    });

    test('a second solve does not overwrite the first as imperfect', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.deputy.name}',
        techniquesRequired: <Technique>{Technique.hiddenSingle},
        timeTaken: const Duration(minutes: 2),
        attempt: Attempt.fresh,
      );
      await progression.record(
        puzzleId: 'fixture-${Rank.deputy.name}',
        techniquesRequired: <Technique>{Technique.hiddenSingle},
        timeTaken: const Duration(minutes: 9),
        attempt: const Attempt(mistakes: 3),
      );

      final lifetime = await stats.lifetime();
      expect(lifetime.perfectSolves, 1, reason: 'the perfect solve was lost');
      expect(lifetime.puzzlesSolved, 1);
    });

    test('a different puzzle at the same rank still counts', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.sheriff.name}',
        techniquesRequired: <Technique>{Technique.nakedPair},
        timeTaken: const Duration(minutes: 1),
        attempt: Attempt.fresh,
      );
      await progression.record(
        puzzleId: 'fixture-${Rank.ranger.name}',
        techniquesRequired: <Technique>{Technique.xWing},
        timeTaken: const Duration(minutes: 1),
        attempt: Attempt.fresh,
      );

      expect((await stats.lifetime()).puzzlesSolved, 2);
    });
  });

  group('the techniques counted are the ones supplied', () {
    test('a rank is not a technique list', () async {
      // A Legend puzzle that happened to need only a naked single counts one
      // technique, not the eleven the **rank** permits. `Technique.upTo` is the
      // tempting shortcut here and it would be wrong: a **rank** says what a
      // puzzle *may* require, and the statistic is about what it *did*.
      await progression.record(
        puzzleId: 'fixture-${Rank.legend.name}',
        techniquesRequired: <Technique>{Technique.nakedSingle},
        timeTaken: const Duration(minutes: 1),
        attempt: Attempt.fresh,
      );

      expect(await stats.countFor(Technique.nakedSingle), 1);
      for (final technique in Technique.values) {
        if (technique == Technique.nakedSingle) continue;
        expect(
          await stats.countFor(technique),
          0,
          reason: '$technique was counted but not required',
        );
      }
    });

    test('a puzzle requiring several counts each of them once', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.ranger.name}',
        techniquesRequired: <Technique>{
          Technique.nakedSingle,
          Technique.hiddenPair,
          Technique.xWing,
        },
        timeTaken: const Duration(minutes: 8),
        attempt: Attempt.fresh,
      );

      expect(await stats.countFor(Technique.nakedSingle), 1);
      expect(await stats.countFor(Technique.hiddenPair), 1);
      expect(await stats.countFor(Technique.xWing), 1);
      expect(await stats.countFor(Technique.swordfish), 0);
    });
  });

  group('a technique unlock', () {
    test('nothing is unlocked before anything is solved', () async {
      expect(await progression.unlockedTechniques(), isEmpty);
    });

    test('a technique unlocks when a solve counts it', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.sheriff.name}',
        techniquesRequired: <Technique>{
          Technique.nakedSingle,
          Technique.pointingPair,
        },
        timeTaken: const Duration(minutes: 3),
        attempt: Attempt.fresh,
      );

      expect(await progression.unlockedTechniques(), <Technique>{
        Technique.nakedSingle,
        Technique.pointingPair,
      });
    });

    test('a technique never required does not read as unlocked', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.greenhorn.name}',
        techniquesRequired: <Technique>{Technique.fullHouse},
        timeTaken: const Duration(minutes: 1),
        attempt: Attempt.fresh,
      );

      final unlocked = await progression.unlockedTechniques();
      expect(unlocked.contains(Technique.fullHouse), isTrue);
      expect(unlocked.contains(Technique.xWing), isFalse);
    });

    test('the unlock is the counter, with no second record kept', () async {
      // D-104: unlocked *is* "counter above zero". Writing the counter by any
      // route unlocks the technique, because there is nowhere else to look.
      await stats.recordSolve(
        techniquesRequired: <Technique>{Technique.swordfish},
        timeTaken: const Duration(minutes: 1),
        attempt: Attempt.fresh,
      );

      expect(await progression.unlockedTechniques(), <Technique>{
        Technique.swordfish,
      });
    });
  });

  group('the player rank follows the records', () {
    test('a player who has solved nothing is at Greenhorn', () async {
      expect(await progression.playerRank(), Rank.greenhorn);
    });

    test('rises to the hardest rank solved, and no further', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.marshal.name}',
        techniquesRequired: <Technique>{Technique.nakedTriple},
        timeTaken: const Duration(minutes: 6),
        attempt: Attempt.fresh,
      );

      expect(await progression.playerRank(), Rank.marshal);
    });

    test('an easier solve afterwards does not lower it', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.legend.name}',
        techniquesRequired: <Technique>{Technique.simpleChain},
        timeTaken: const Duration(minutes: 20),
        attempt: Attempt.fresh,
      );
      await progression.record(
        puzzleId: 'fixture-${Rank.greenhorn.name}',
        techniquesRequired: <Technique>{Technique.fullHouse},
        timeTaken: const Duration(minutes: 1),
        attempt: Attempt.fresh,
      );

      expect(await progression.playerRank(), Rank.legend);
    });
  });

  group('a database written by an earlier build', () {
    test('reports Greenhorn and no unlocks, rather than failing', () async {
      // The upgrade case, and it is the common one: until this change nothing
      // called `markSolved` or `recordSolve`, so every existing install has an
      // empty `solvedPuzzles` table and empty counters however much the player
      // has played. That must read as a starting position — not an error, and
      // not an empty result the picker would have to interpret for itself.
      //
      // No schema change comes with this change, so there is no migration to
      // get wrong; what there is instead is a derived read over tables that
      // are legitimately empty.
      expect(await progression.playerRank(), Rank.greenhorn);
      expect(await progression.unlockedTechniques(), isEmpty);
      expect(await progression.solvedRanks(), isEmpty);
      expect((await stats.lifetime()).puzzlesSolved, 0);
    });

    test('a solve after the upgrade starts the record from there', () async {
      await progression.record(
        puzzleId: 'fixture-${Rank.sheriff.name}',
        techniquesRequired: <Technique>{Technique.pointingPair},
        timeTaken: const Duration(minutes: 3),
        attempt: Attempt.fresh,
      );

      expect(await progression.playerRank(), Rank.sheriff);
      expect((await stats.lifetime()).puzzlesSolved, 1);
    });
  });

  group('what runs after the solve record', () {
    Future<void> recordSheriff({
      Future<void> Function({required bool isFirstSolve})? after,
    }) => progression.record(
      puzzleId: 'fixture-${Rank.sheriff.name}',
      techniquesRequired: <Technique>{Technique.nakedSingle},
      timeTaken: Duration.zero,
      attempt: Attempt.fresh,
      afterInTransaction: after,
    );

    test('it sees the rank the solve just raised', () async {
      // The reason it runs *after*: a **rank** is derived from the **solve
      // record**s (D-102), so a hook that ran first would read the old one.
      Rank? seen;
      await recordSheriff(
        after: ({required bool isFirstSolve}) async =>
            seen = await progression.playerRank(),
      );

      expect(seen, Rank.sheriff);
    });

    test('it runs for a puzzle that already holds a record', () async {
      await recordSheriff();

      var ran = false;
      await recordSheriff(
        after: ({required bool isFirstSolve}) async => ran = true,
      );

      expect(
        ran,
        isTrue,
        reason:
            'a player who reached a rank before its trophy could mint gets it '
            'on their next solve, including a replayed one',
      );
    });

    test('a throw from it rolls the solve record back', () async {
      await expectLater(
        recordSheriff(
          after: ({required bool isFirstSolve}) async =>
              throw StateError('minting failed'),
        ),
        throwsStateError,
      );

      expect(await packs.isSolved('fixture-${Rank.sheriff.name}'), isFalse);
      expect((await stats.lifetime()).puzzlesSolved, 0);
    });

    test('it is told whether this solve wrote the record (D-133)', () async {
      final firsts = <bool>[];
      Future<void> note({required bool isFirstSolve}) async =>
          firsts.add(isFirstSolve);

      await recordSheriff(after: note);
      await recordSheriff(after: note);

      // Only the first can pay the perfect solve.
      expect(firsts, <bool>[true, false]);
    });
  });
}
