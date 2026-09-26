import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_origin.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/stamps/data/stamp_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/application/cabinet_providers.dart';
import 'package:doku_duty/features/trophy_cabinet/application/minting_service.dart';

import '../grid_input/support/production_solve.dart';

/// An **earning** and its cause are one write (constraint 9, D-133).
///
/// On a file database, like `node_completion_atomicity_test.dart`, and read
/// back through a second connection — which is what a relaunch after an app
/// kill is. An **earning** that survives without its cause is a payment for
/// something the player did not do; a cause that survives without its
/// **earning** is a payment silently withheld.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory dir;
  late File file;
  late ProductionSolve app;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('earning-atomicity');
    file = File('${dir.path}/doku.sqlite');
    app = await ProductionSolve.open(file: file);
  });
  tearDown(() async {
    await app.close();
    dir.deleteSync(recursive: true);
  });

  MintingService minting() => app.container.read(mintingServiceProvider);

  /// What a relaunch sees.
  Future<T> afterRelaunch<T>(Future<T> Function(AppDatabase db) read) async {
    final reopened = AppDatabase(NativeDatabase(file));
    try {
      return await read(reopened);
    } finally {
      await reopened.close();
    }
  }

  group('a failure after the earning leaves neither it nor its cause', () {
    test('the perfect solve', () async {
      await expectLater(
        ProgressionRepository(app.db).record(
          puzzleId: 'fixture-deputy',
          techniquesRequired: const <Technique>{Technique.nakedSingle},
          timeTaken: Duration.zero,
          attempt: Attempt.fresh,
          afterInTransaction: ({required bool isFirstSolve}) async {
            await minting().afterSolve(
              puzzleId: 'fixture-deputy',
              isFirstSolve: isFirstSolve,
              isPerfect: true,
              rank: Rank.deputy,
            );
            throw StateError('failed after earning');
          },
        ),
        throwsStateError,
      );

      expect(await afterRelaunch((db) => StampRepository(db).balance()), 0);
      expect(
        await afterRelaunch(
          (db) => PackRepository(db).isSolved('fixture-deputy'),
        ),
        isFalse,
      );
    });

    test('the daily', () async {
      final day = DatedDay(date: DailyDate(2026, 4, 9), isVerified: false);

      await expectLater(
        ProgressionRepository(app.db).record(
          // No such puzzle, so the **solve record** throws after the day and
          // its **earning** have both been written.
          puzzleId: 'no-such-puzzle',
          techniquesRequired: const <Technique>{},
          timeTaken: Duration.zero,
          attempt: Attempt.fresh,
          alsoInTransaction: () => minting().completeDay(day),
        ),
        throwsStateError,
      );

      expect(await afterRelaunch((db) => StampRepository(db).balance()), 0);
      expect(
        await afterRelaunch((db) => DailyRepository(db).wasCompleted(day.date)),
        isFalse,
      );
    });
  });

  test('a completed boss node played again earns nothing more', () async {
    await SeasonRepository(app.db).enterSeason(SeasonOne.id);
    final catalogue = app.container.read(awardCatalogueProvider);
    Future<void> beatBoss() => minting().completeNode(
      seasonId: SeasonOne.id,
      seasonName: SeasonOne.season.name,
      position: 22,
      type: NodeType.boss,
      nodeCount: SeasonOne.season.nodes.length,
      catalogue: catalogue,
    );

    await beatBoss();
    await beatBoss();

    expect(await afterRelaunch((db) => StampRepository(db).balance()), 20);
  });

  test('a solved board completed again earns nothing more', () async {
    app.container.read(puzzleOriginProvider.notifier).openFreePlay();

    await app.solve(Rank.deputy);
    await app.solve(Rank.deputy);

    // One perfect solve, once: the second completion is the same puzzle.
    expect(await afterRelaunch((db) => StampRepository(db).balance()), 3);
  });
}
