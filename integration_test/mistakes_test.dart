import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

/// The half of constraint 9 a host test cannot reach, for the **mistake**
/// tally.
///
/// Host tests prove the count reaches *a* sqlite file. These prove it reaches
/// the real one, on a real OS, through the sqlite the app bundles — and that it
/// is still there in a new process. The process that died has to be a real one.
///
/// Run twice. The first run writes; the second asserts what the first left
/// behind.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const puzzleId = 'mistakes-probe';
  const survivorId = 'mistakes-survivor';
  const clues =
      '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
  const solution =
      '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

  Grid gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

  PuzzleSession session({bool strict = false, int mistakes = 0}) =>
      PuzzleSession.start(
        board: Board.forPuzzle(givens: gridOf(clues)),
        solution: gridOf(solution),
        isStrict: strict,
        attempt: Attempt(mistakes: mistakes),
      );

  testWidgets('a tally written through the sink reaches disk', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final saves = PuzzleSaveRepository(db);
    final sink = RepositoryBoardSink(saves, NoteRepository(db));

    // Cell 2's solution is a 4, so a 7 is wrong and a 4 is not.
    var current = session().tapCell(2).tapDigit(7);
    expect(current.attempt.mistakes, 1);
    await sink.write(
      puzzleId,
      current.board,
      mistakes: current.attempt.mistakes,
    );

    final stored = (await saves.all()).where((s) => s.puzzleId == puzzleId);
    expect(stored.single.mistakes, 1);
  });

  testWidgets('a correction leaves the tally on disk where it was', (
    tester,
  ) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final saves = PuzzleSaveRepository(db);
    final sink = RepositoryBoardSink(saves, NoteRepository(db));

    var current = session().tapCell(2).tapDigit(7);
    await sink.write(
      puzzleId,
      current.board,
      mistakes: current.attempt.mistakes,
    );

    current = current.tapDigit(4);
    expect(current.board.digitAt(2), 4);
    await sink.write(
      puzzleId,
      current.board,
      mistakes: current.attempt.mistakes,
    );

    final stored = (await saves.all()).where((s) => s.puzzleId == puzzleId);
    expect(
      stored.single.mistakes,
      1,
      reason: 'the board is corrected; what happened is not (D-96)',
    );
  });

  testWidgets('an ended attempt is on disk as ended', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final saves = PuzzleSaveRepository(db);
    final sink = RepositoryBoardSink(saves, NoteRepository(db));

    const endedId = 'mistakes-ended-probe';
    var current = session(strict: true);
    for (final cell in const <int>[2, 3, 5]) {
      current = current.tapCell(cell).tapDigit(9);
    }
    expect(current.isOver, isTrue);
    await sink.write(
      endedId,
      current.board,
      mistakes: current.attempt.mistakes,
    );

    // Reopened from the row alone, the attempt is still over: the tally is
    // what decides, so a kill is not a way back into it.
    final stored = (await saves.all()).where((s) => s.puzzleId == endedId);
    final reopened = session(strict: true, mistakes: stored.single.mistakes);
    expect(reopened.isOver, isTrue);
    expect(reopened.mistakesRemaining, 0);
  });

  // The cross-process half: run this file twice, and the second run reads what
  // the first left on disk. A tally that survives only inside one process is
  // not stored at all.
  testWidgets('a tally a previous process wrote is still here', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final saves = PuzzleSaveRepository(db);

    final existing = (await saves.all()).where((s) => s.puzzleId == survivorId);
    if (existing.isEmpty) {
      final sink = RepositoryBoardSink(saves, NoteRepository(db));
      final current = session().tapCell(2).tapDigit(7).tapCell(3).tapDigit(9);
      await sink.write(
        survivorId,
        current.board,
        mistakes: current.attempt.mistakes,
      );
      return;
    }

    expect(
      existing.single.mistakes,
      2,
      reason: 'run this file twice — the second run asserts the first',
    );
  });

  // D-94 on the device: one switch, and a row under the retired key is inert
  // rather than fatal.
  testWidgets('strict mode persists and auto-check is gone', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final settings = SettingsRepository(db);

    await settings.write(AppSetting.strictMode, value: true);
    expect(await settings.read(AppSetting.strictMode), isTrue);

    final all = await settings.readAll();
    expect(all.keys, unorderedEquals(AppSetting.values));
    expect(all.keys.map((s) => s.name), isNot(contains('autoCheck')));

    await settings.reset(AppSetting.strictMode);
    expect(await settings.read(AppSetting.strictMode), isFalse);
  });

  // The flag on the platform's own rasteriser, at the text size the OS is
  // actually set to. Pass --dart-define=doku.largeText=true when the OS text
  // setting has been turned up, so the run refuses to pass at the default.
  testWidgets('a flagged board renders at the OS text setting', (tester) async {
    const expectLarge = bool.fromEnvironment('doku.largeText');

    var board = Board.forPuzzle(givens: gridOf(clues));
    // Row 0's solution is 534678912, so each of these is wrong for its cell.
    for (final (cell, digit) in const <(int, int)>[(2, 9), (3, 9), (5, 9)]) {
      board = (board.place(cell, digit) as EditApplied).board;
    }

    late double scale;
    await tester.pumpWidget(
      MediaQuery.fromView(
        view: tester.view,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              scale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;
              return Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: PuzzleGrid(
                    board: board,
                    flaggedCells: const <int>{2, 3, 5},
                    onCellTapped: (_) {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(scale, closeTo(tester.platformDispatcher.textScaleFactor, 0.001));
    if (expectLarge) {
      expect(
        scale,
        greaterThan(1.3),
        reason: 'the OS text size was not raised, so this proves nothing',
      );
    }

    // The strike is a logical pixel wide, and a fractional device ratio must
    // still give it a physical one — a rule rounded away is constraint 5
    // broken silently.
    expect(
      DokuStroke.interiorDetail * tester.view.devicePixelRatio,
      greaterThanOrEqualTo(1.0),
    );
  });

  // The ended-**attempt** screen, driven through the real app on the device's
  // own rasteriser and text shaper (D-95).
  //
  // The whole app rather than the widget alone: its two choices are private to
  // the screen, and a test that reached inside to pump them would be proving
  // something about a widget nobody can navigate to. Failing three placements
  // the way a player does is what actually exercises it.
  testWidgets('an ended attempt renders on the device', (tester) async {
    const expectLarge = bool.fromEnvironment('doku.largeText');

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await PackRepository(db).installPack(
      packId: 'test',
      version: 1,
      puzzles: <StoredPuzzle>[
        const StoredPuzzle(
          id: 'q-deputy',
          clues: clues,
          solution: solution,
          rank: Rank.deputy,
          seed: 1,
        ),
      ],
    );
    await SettingsRepository(db).write(AppSetting.strictMode, value: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
          appDatabaseProvider.overrideWith((ref) => db),
          packInstallationProvider.overrideWith(
            (ref) async => PackInstallOutcome.alreadyInstalled,
          ),
          persistedStrictModeOverride,
        ],
        child: const DokuDutyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
    await tester.pumpAndSettle();
    expect(find.text('3 mistakes left'), findsOneWidget);

    // The painted grid is the largest square that fits its box, centred — the
    // box itself is rarely square on a phone, which is exactly the difference
    // a host test with a square surface cannot show.
    final box = tester.getRect(find.byType(PuzzleGrid));
    final side = box.width < box.height ? box.width : box.height;
    final origin = Offset(
      box.left + (box.width - side) / 2,
      box.top + (box.height - side) / 2,
    );
    final cellSize = side / 9;

    // Row 0's solution is 534678912, so a 9 is wrong in each of these.
    for (final column in const <int>[2, 3, 5]) {
      await tester.tapAt(
        Offset(
          origin.dx + cellSize * (column + 0.5),
          origin.dy + cellSize * 0.5,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('attempt-ended')), findsOneWidget);
    expect(find.text('Start again'), findsOneWidget);
    expect(find.text('Back to the map'), findsOneWidget);
    expect(find.text('0 mistakes left'), findsOneWidget);

    // Both choices are on screen and hittable at whatever text size the OS is
    // set to — the case a host test with its own scaler cannot prove.
    final scale = tester.platformDispatcher.textScaleFactor;
    if (expectLarge) {
      expect(
        scale,
        greaterThan(1.3),
        reason: 'the OS text size was not raised',
      );
    }
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    for (final key in const <String>['attempt-restart', 'attempt-leave']) {
      final rect = tester.getRect(find.byKey(ValueKey<String>(key)));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$key at ${scale}x');
      expect(
        rect.right,
        lessThanOrEqualTo(screen.width + 0.5),
        reason: '$key runs off the edge at ${scale}x',
      );
      expect(
        rect.shortestSide,
        greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
        reason: '$key at ${scale}x',
      );
    }

    // And starting again works on the device, not only on the host.
    await tester.tap(find.byKey(const ValueKey<String>('attempt-restart')));
    await tester.pumpAndSettle();
    expect(find.text('3 mistakes left'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attempt-ended')), findsNothing);
  });
}
