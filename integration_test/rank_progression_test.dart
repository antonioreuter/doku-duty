import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grader.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

StoredPuzzle _puzzle(String id, Rank rank) => StoredPuzzle(
  id: id,
  clues: _clues,
  solution: _solution,
  rank: rank,
  seed: 1,
);

/// What progression costs, and whether it survives, on a real platform.
///
/// The host suite proves the rule and the transaction. What this adds is the
/// device's own SQLite and its own Dart runtime: a grade timed on the hardware
/// a player holds, and a **solve record** read back through a database file the
/// platform wrote rather than an in-memory one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('grading costs a fraction of a frame on the device', () {
    final grid = (Grid.parse(_clues) as ValidGrid).grid;
    for (var i = 0; i < 20; i++) {
      grade(grid);
    }

    const runs = 200;
    final watch = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      grade(grid);
    }
    watch.stop();

    final perGrade = watch.elapsedMicroseconds / runs;
    // ignore: avoid_print
    print('DEVICE grade(): ${perGrade.toStringAsFixed(1)} µs per call');
    expect(perGrade, lessThan(16600 / 4));
  });

  test('a solve record is written, and read back, on the device', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final packs = PackRepository(db);
    await packs.installPack(
      packId: 'device',
      version: 1,
      puzzles: <StoredPuzzle>[
        _puzzle('device-greenhorn', Rank.greenhorn),
        _puzzle('device-marshal', Rank.marshal),
      ],
    );

    final progression = ProgressionRepository(db);
    expect(await progression.playerRank(), Rank.greenhorn);
    expect(await progression.unlockedTechniques(), isEmpty);

    final watch = Stopwatch()..start();
    await progression.record(
      puzzleId: 'device-marshal',
      techniquesRequired: <Technique>{
        Technique.nakedSingle,
        Technique.nakedTriple,
      },
      timeTaken: const Duration(minutes: 7),
      attempt: Attempt.fresh,
    );
    watch.stop();
    // ignore: avoid_print
    print('DEVICE solve record write: ${watch.elapsedMicroseconds} µs');

    expect(await packs.isSolved('device-marshal'), isTrue);
    expect(await progression.playerRank(), Rank.marshal);
    expect(await progression.unlockedTechniques(), <Technique>{
      Technique.nakedSingle,
      Technique.nakedTriple,
    });
    expect((await StatisticsRepository(db).lifetime()).perfectSolves, 1);

    // The ratchet, on the platform's own storage.
    await progression.record(
      puzzleId: 'device-greenhorn',
      techniquesRequired: <Technique>{Technique.fullHouse},
      timeTaken: const Duration(minutes: 1),
      attempt: Attempt.fresh,
    );
    expect(await progression.playerRank(), Rank.marshal);
  });

  testWidgets('the record survives a relaunch on this platform', (
    tester,
  ) async {
    // The platform's own filesystem and its own SQLite, not an in-memory
    // database: what survives here is what would survive the OS reclaiming the
    // process (constraint 9).
    final dir = Directory.systemTemp.createTempSync('doku_rank_device');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await PackRepository(first).installPack(
      packId: 'device',
      version: 1,
      puzzles: <StoredPuzzle>[_puzzle('device-ranger', Rank.ranger)],
    );
    await ProgressionRepository(first).record(
      puzzleId: 'device-ranger',
      techniquesRequired: <Technique>{Technique.xWing},
      timeTaken: const Duration(minutes: 9),
      attempt: Attempt.fresh,
    );
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    final progression = ProgressionRepository(second);

    expect(await PackRepository(second).isSolved('device-ranger'), isTrue);
    expect(await progression.playerRank(), Rank.ranger);
    expect(await progression.unlockedTechniques(), <Technique>{
      Technique.xWing,
    });
  });

  testWidgets('the mark clears on this platform once the rank is earned', (
    tester,
  ) async {
    Widget app(AppDatabase db) => ProviderScope(
      overrides: [
        flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
        appDatabaseProvider.overrideWith((ref) => db),
        packInstallationProvider.overrideWith(
          (ref) async => PackInstallOutcome.alreadyInstalled,
        ),
        persistedStrictModeOverride,
      ],
      child: const DokuDutyApp(),
    );

    Finder markOn(Rank rank) => find.descendant(
      of: find.byKey(ValueKey<String>('rank-${rank.name}')),
      matching: find.textContaining('Above your rank'),
    );

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await PackRepository(db).installPack(
      packId: 'device',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values) _puzzle('q-${rank.name}', rank),
      ],
    );

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();
    expect(markOn(Rank.marshal), findsOneWidget);

    await ProgressionRepository(db).record(
      puzzleId: 'q-${Rank.marshal.name}',
      techniquesRequired: <Technique>{Technique.nakedTriple},
      timeTaken: const Duration(minutes: 5),
      attempt: Attempt.fresh,
    );

    // A fresh scope, so the reads are genuinely re-run rather than served from
    // the container this test already warmed. In the app the sink invalidates
    // them the moment a **solve record** lands — proven on the host in
    // `picker_after_solve_test.dart`, which drives the real grid; what this
    // checks on the device is the read itself, on the platform's own storage.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    expect(markOn(Rank.marshal), findsNothing);
    expect(markOn(Rank.greenhorn), findsNothing);
    expect(markOn(Rank.legend), findsOneWidget);
  });
}
