import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';

import 'support/fixture_pack.dart';

void main() {
  late AppDatabase db;
  late StatisticsRepository stats;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    stats = StatisticsRepository(db);
  });
  tearDown(() => db.close());

  group('a solved puzzle', () {
    test('updates the lifetime counters', () async {
      await stats.recordSolve(
        techniquesRequired: <Technique>{Technique.nakedSingle},
        timeTaken: const Duration(minutes: 4),
        wasPerfect: true,
      );

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 1);
      expect(lifetime.perfectSolves, 1);
      expect(lifetime.totalPlayMs, const Duration(minutes: 4).inMilliseconds);
    });

    test('accumulates across solves', () async {
      for (var i = 0; i < 3; i++) {
        await stats.recordSolve(
          techniquesRequired: <Technique>{Technique.hiddenSingle},
          timeTaken: const Duration(minutes: 2),
          wasPerfect: i.isEven,
        );
      }

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 3);
      expect(lifetime.perfectSolves, 2);
      expect(await stats.countFor(Technique.hiddenSingle), 3);
    });

    test('a solve with mistakes is counted but is not perfect', () async {
      await stats.recordSolve(
        techniquesRequired: <Technique>{Technique.nakedPair},
        timeTaken: const Duration(minutes: 9),
        wasPerfect: false,
      );

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 1);
      expect(lifetime.perfectSolves, 0);
    });

    test('counts every technique the puzzle required', () async {
      await stats.recordSolve(
        techniquesRequired: <Technique>{
          Technique.nakedSingle,
          Technique.hiddenSingle,
          Technique.xWing,
        },
        timeTaken: const Duration(minutes: 20),
        wasPerfect: false,
      );

      expect(await stats.allTechniqueCounts(), <Technique, int>{
        Technique.nakedSingle: 1,
        Technique.hiddenSingle: 1,
        Technique.xWing: 1,
      });
      expect(await stats.countFor(Technique.swordfish), 0);
    });
  });

  group('before anything is solved', () {
    test('reads as zero rather than as missing', () async {
      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 0);
      expect(lifetime.perfectSolves, 0);
      expect(await stats.countFor(Technique.xyWing), 0);
      expect(await stats.allTechniqueCounts(), isEmpty);
    });
  });

  group('permanence', () {
    // D-17. The permanent layer is what stops a season rotating out feeling
    // like loss, so it must survive the season going away entirely.
    test('statistics survive a season rotating out', () async {
      final packs = PackRepository(db);
      await installFixturePack(packs);
      await packs.markSolved('fixture-${Rank.deputy.name}');
      await stats.recordSolve(
        techniquesRequired: <Technique>{Technique.hiddenSingle},
        timeTaken: const Duration(minutes: 5),
        wasPerfect: true,
      );

      // The season's pack and everything scoped to it goes away.
      await db.delete(db.puzzles).go();
      await db.delete(db.packs).go();
      await db.delete(db.solvedPuzzles).go();

      final lifetime = await stats.lifetime();
      expect(lifetime.puzzlesSolved, 1);
      expect(await stats.countFor(Technique.hiddenSingle), 1);
    });
  });
}
