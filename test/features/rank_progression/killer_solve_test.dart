import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';

import '../puzzle_engine/support/killer.dart';
import '../puzzle_engine/support/positions.dart';

/// A **killer** puzzle whose grade needs the 45 rule and reaches Sheriff: dug
/// from the reference board and asserted in `killer_grader_test.dart`.
const String _sheriffByFortyFive =
    '..............................7........8.........2...............................';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'killer',
      version: 1,
      puzzles: <StoredPuzzle>[
        StoredPuzzle(
          id: 'k-sheriff',
          clues: _sheriffByFortyFive,
          solution: referenceSolution,
          rank: Rank.sheriff,
          seed: 1,
          cages: jsonEncode(referenceKillerCages(referenceSolution).toJson()),
        ),
      ],
    );
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        packInstallationProvider.overrideWith(
          (ref) async => PackInstallOutcome.alreadyInstalled,
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Open the puzzle the way the app does, then play it to the end.
  Future<void> openAndSolve() async {
    final opening = (await container.read(
      puzzleOpeningProvider('k-sheriff').future,
    ))!;
    final controller = PuzzleController(
      puzzle: opening.puzzle,
      sink: RepositoryBoardSink(
        PuzzleSaveRepository(db),
        NoteRepository(db),
        ProgressionRepository(db),
      ),
      techniquesRequired: opening.techniquesRequired,
      initial: sessionFor(
        puzzle: opening.puzzle,
        placedValues: null,
        mode: InputMode.cellFirst,
      ),
    );
    addTearDown(controller.dispose);
    for (var cell = 0; cell < 81; cell++) {
      if (_sheriffByFortyFive[cell] != '.') continue;
      controller.tapCell(cell);
      controller.tapKey(DigitKey(int.parse(referenceSolution[cell])));
    }
    await Future<void>.delayed(Duration.zero);
    expect(controller.isSolved, isTrue);
  }

  test('opening a killer puzzle grades it with its cages', () async {
    final opening = (await container.read(
      puzzleOpeningProvider('k-sheriff').future,
    ))!;
    // Graded without its cages this grid is hopeless, and the set comes back
    // empty — which would skip every counter and every lesson in silence.
    expect(opening.techniquesRequired, contains(Technique.fortyFiveRule));
    expect(opening.techniquesRequired, contains(Technique.cageCombination));
  });

  test('a killer solve above the player\'s rank raises it (D-102)', () async {
    final progression = ProgressionRepository(db);
    expect(await progression.playerRank(), Rank.greenhorn);

    await openAndSolve();

    expect(await progression.playerRank(), Rank.sheriff);
  });

  test(
    'a solve needing the 45 rule counts it and unlocks it (D-104)',
    () async {
      await openAndSolve();

      expect(
        await StatisticsRepository(db).countFor(Technique.fortyFiveRule),
        1,
      );
      expect(
        await ProgressionRepository(db).unlockedTechniques(),
        contains(Technique.fortyFiveRule),
      );
    },
  );
}
